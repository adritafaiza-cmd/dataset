module cdc_fifo_gray_clearable #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input                  src_clear_i,
    output                 src_clear_pending_o,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    input                  dst_clear_i,
    output                 dst_clear_pending_o,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    // Internal signals
    wire [LOG_DEPTH:0] gray_src;
    wire [LOG_DEPTH:0] gray_dst;
    wire [LOG_DEPTH:0] gray_src_synced;
    wire [LOG_DEPTH:0] gray_dst_synced;
    reg  [LOG_DEPTH:0] write_ptr;
    reg  [LOG_DEPTH:0] read_ptr;
    reg  [WIDTH-1:0] fifo_mem [1 << LOG_DEPTH - 1 : 0];
    reg                full;
    reg                empty;
    reg                src_clear_active;
    reg                dst_clear_active;

    // Gray counter for source
    gray_counter #(.LOG_DEPTH(LOG_DEPTH))
    gray_counter_src (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .clear_i(src_clear_i),
        .gray_o(gray_src)
    );

    // Gray counter for destination
    gray_counter #(.LOG_DEPTH(LOG_DEPTH))
    gray_counter_dst (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .clear_i(dst_clear_i),
        .gray_o(gray_dst)
    );

    // Synchronize source Gray counter to destination clock domain
    sync_gray #(.LOG_DEPTH(LOG_DEPTH), .SYNC_STAGES(SYNC_STAGES))
    sync_gray_src_to_dst (
        .src_clk_i(src_clk_i),
        .dst_clk_i(dst_clk_i),
        .src_gray_i(gray_src),
        .dst_gray_o(gray_src_synced)
    );

    // Synchronize destination Gray counter to source clock domain
    sync_gray #(.LOG_DEPTH(LOG_DEPTH), .SYNC_STAGES(SYNC_STAGES))
    sync_gray_dst_to_src (
        .src_clk_i(dst_clk_i),
        .dst_clk_i(src_clk_i),
        .src_gray_i(gray_dst),
        .dst_gray_o(gray_dst_synced)
    );

    // FIFO control logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            write_ptr <= 0;
            src_clear_active <= 0;
            full <= 0;
            empty <= 1;
        end else begin
            if (src_clear_i) begin
                write_ptr <= 0;
                src_clear_active <= 1;
                full <= 0;
                empty <= 1;
            end else if (src_valid_i && !full) begin
                fifo_mem[write_ptr[LOG_DEPTH-1:0]] <= src_data_i;
                write_ptr <= write_ptr + 1;
                empty <= 0;
                if (write_ptr[LOG_DEPTH:0] == gray_dst_synced) begin
                    full <= 1;
                end
            end
            if (gray_src_synced == gray_dst_synced) begin
                src_clear_active <= 0;
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            read_ptr <= 0;
            dst_clear_active <= 0;
            dst_valid_o <= 0;
        end else begin
            if (dst_clear_i) begin
                read_ptr <= 0;
                dst_clear_active <= 1;
                dst_valid_o <= 0;
            end else if (dst_ready_i && dst_valid_o) begin
                read_ptr <= read_ptr + 1;
                if (read_ptr[LOG_DEPTH:0] == gray_src_synced) begin
                    dst_valid_o <= 0;
                end else begin
                    dst_valid_o <= 1;
                end
            end else if (!dst_valid_o && (read_ptr[LOG_DEPTH-1:0] != gray_src_synced[LOG_DEPTH-1:0])) begin
                dst_data_o <= fifo_mem[read_ptr[LOG_DEPTH-1:0]];
                dst_valid_o <= 1;
            end
            if (gray_src_synced == gray_dst_synced) begin
                dst_clear_active <= 0;
            end
        end
    end

    // Ready and pending signals
    assign src_ready_o = !full;
    assign src_clear_pending_o = src_clear_active;
    assign dst_clear_pending_o = dst_clear_active;

endmodule

module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  rst_ni,
    input                  clk_i,
    input                  clear_i,
    output reg [LOG_DEPTH:0] gray_o
);

    reg [LOG_DEPTH:0] counter;
    reg [LOG_DEPTH:0] gray;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            counter <= 0;
            gray_o <= 0;
        end else if (clear_i) begin
            counter <= 0;
            gray_o <= 0;
        end else begin
            counter <= counter + 1;
            gray_o <= counter ^ (counter >> 1);
        end
    end

endmodule

module sync_gray #(
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  src_clk_i,
    input                  dst_clk_i,
    input  [LOG_DEPTH:0] src_gray_i,
    output reg [LOG_DEPTH:0] dst_gray_o
);

    reg [LOG_DEPTH:0] sync_reg [SYNC_STAGES-1:0];

    always @(posedge src_clk_i) begin
        sync_reg[0] <= src_gray_i;
        for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
            sync_reg[i] <= sync_reg[i-1];
        end
    end

    always @(posedge dst_clk_i) begin
        dst_gray_o <= sync_reg[SYNC_STAGES-1];
    end

endmodule
