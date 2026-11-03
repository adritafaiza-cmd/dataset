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
    reg [LOG_DEPTH:0]      src_gray;
    reg [LOG_DEPTH:0]      dst_gray;
    reg [LOG_DEPTH:0]      sync_src_gray_reg;
    reg [LOG_DEPTH:0]      sync_dst_gray_reg;
    reg [LOG_DEPTH:0]      src_gray_next;
    reg [LOG_DEPTH:0]      dst_gray_next;
    reg                    src_full;
    reg                    dst_empty;
    reg                    src_clear_reg;
    reg                    dst_clear_reg;
    reg                    src_clear_active;
    reg                    dst_clear_active;
    reg                    src_clear_done;
    reg                    dst_clear_done;
    reg  [WIDTH-1:0]       src_fifo [0:(1<<LOG_DEPTH)-1];
    reg  [LOG_DEPTH-1:0]   src_wr_ptr;
    reg  [LOG_DEPTH-1:0]   src_rd_ptr;
    reg  [LOG_DEPTH-1:0]   dst_wr_ptr;
    reg  [LOG_DEPTH-1:0]   dst_rd_ptr;

    // Gray counter module
    module gray_counter #(
        parameter WIDTH = LOG_DEPTH+1
    )(
        input  [WIDTH-1:0] binary,
        output [WIDTH-1:0] gray
    );
        assign gray = binary ^ (binary >> 1);
    endmodule

    // Sync register module
    module sync_register #(
        parameter WIDTH = LOG_DEPTH+1,
        parameter STAGES = SYNC_STAGES
    )(
        input clk,
        input rst_ni,
        input [WIDTH-1:0] d,
        output [WIDTH-1:0] q
    );
        reg [WIDTH-1:0] sync_reg [0:STAGES-1];

        always @(posedge clk or negedge rst_ni) begin
            if (!rst_ni) begin
                sync_reg[0] <= 0;
                for (int i = 1; i < STAGES; i = i + 1) begin
                    sync_reg[i] <= 0;
                end
            end else begin
                sync_reg[0] <= d;
                for (int i = 1; i < STAGES; i = i + 1) begin
                    sync_reg[i] <= sync_reg[i-1];
                end
            end
        end

        assign q = sync_reg[STAGES-1];
    endmodule

    // Source side logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= 0;
            src_rd_ptr <= 0;
            src_gray <= 0;
            src_clear_reg <= 0;
            src_clear_active <= 0;
            src_clear_done <= 0;
        end else begin
            // Clear logic
            if (src_clear_i) begin
                src_clear_reg <= 1;
                src_clear_active <= 1;
                src_clear_done <= 0;
                src_wr_ptr <= 0;
                src_rd_ptr <= 0;
                src_gray <= 0;
            end else if (src_clear_active && dst_empty) begin
                src_clear_active <= 0;
                src_clear_done <= 1;
            end

            // Write logic
            if (!src_full && src_valid_i) begin
                src_fifo[src_wr_ptr] <= src_data_i;
                src_wr_ptr <= src_wr_ptr + 1;
            end

            // Gray code calculation
            gray_counter #(.WIDTH(LOG_DEPTH+1)) src_gray_counter (
                .binary(src_wr_ptr),
                .gray(src_gray_next)
            );

            // Update gray code
            if (!src_full && src_valid_i) begin
                src_gray <= src_gray_next;
            end
        end
    end

    // Destination side logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wr_ptr <= 0;
            dst_rd_ptr <= 0;
            dst_gray <= 0;
            dst_clear_reg <= 0;
            dst_clear_active <= 0;
            dst_clear_done <= 0;
        end else begin
            // Clear logic
            if (dst_clear_i) begin
                dst_clear_reg <= 1;
                dst_clear_active <= 1;
                dst_clear_done <= 0;
                dst_wr_ptr <= 0;
                dst_rd_ptr <= 0;
                dst_gray <= 0;
            end else if (dst_clear_active && dst_empty) begin
                dst_clear_active <= 0;
                dst_clear_done <= 1;
            end

            // Read logic
            if (!dst_empty && dst_ready_i) begin
                dst_rd_ptr <= dst_rd_ptr + 1;
            end

            // Gray code calculation
            gray_counter #(.WIDTH(LOG_DEPTH+1)) dst_gray_counter (
                .binary(dst_rd_ptr),
                .gray(dst_gray_next)
            );

            // Update gray code
            if (!dst_empty && dst_ready_i) begin
                dst_gray <= dst_gray_next;
            end
        end
    end

    // Synchronizers
    sync_register #(.WIDTH(LOG_DEPTH+1), .STAGES(SYNC_STAGES)) sync_src_gray (
        .clk(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .d(src_gray),
        .q(sync_src_gray_reg)
    );

    sync_register #(.WIDTH(LOG_DEPTH+1), .STAGES(SYNC_STAGES)) sync_dst_gray (
        .clk(src_clk_i),
        .rst_ni(src_rst_ni),
        .d(dst_gray),
        .q(sync_dst_gray_reg)
    );

    // Full and empty logic
    always @(*) begin
        src_full = (src_gray_next == (sync_dst_gray_reg ^ {sync_dst_gray_reg[LOG_DEPTH-1:0], 1'b1}));
        dst_empty = (sync_src_gray_reg == (dst_gray_next ^ {dst_gray_next[LOG_DEPTH-1:0], 1'b1}));
    end

    // Outputs
    assign src_ready_o = !src_full;
    assign src_clear_pending_o = !src_clear_done;
    assign dst_data_o = src_fifo[dst_rd_ptr];
    assign dst_valid_o = !dst_empty;
    assign dst_clear_pending_o = !dst_clear_done;

endmodule
