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
    wire [LOG_DEPTH:0]     src_gray;
    wire [LOG_DEPTH:0]     src_gray_sync;
    wire [LOG_DEPTH:0]     dst_gray;
    wire [LOG_DEPTH:0]     dst_gray_sync;
    wire                   src_clear_sync;
    wire                   dst_clear_sync;
    reg                    fifo_full;
    reg                    fifo_empty;
    reg [LOG_DEPTH-1:0]    fifo_waddr;
    reg [LOG_DEPTH-1:0]    fifo_raddr;
    reg [WIDTH-1:0]        fifo_data [0:(2**LOG_DEPTH)-1];

    // Gray counters
    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_counter_src (
        .clk_i   (src_clk_i),
        .rst_ni  (src_rst_ni),
        .clear_i (src_clear_i),
        .gray_o  (src_gray),
        .count_o (fifo_waddr)
    );

    gray_counter #(.LOG_DEPTH(LOG_DEPTH)) gray_counter_dst (
        .clk_i   (dst_clk_i),
        .rst_ni  (dst_rst_ni),
        .clear_i (dst_clear_i),
        .gray_o  (dst_gray),
        .count_o (fifo_raddr)
    );

    // Synchronizers
    sync_register sync_register_gray_src (
        .clk_i (dst_clk_i),
        .rst_ni (dst_rst_ni),
        .d_i (src_gray),
        .q_o (src_gray_sync)
    );

    sync_register sync_register_gray_dst (
        .clk_i (src_clk_i),
        .rst_ni (src_rst_ni),
        .d_i (dst_gray),
        .q_o (dst_gray_sync)
    );

    sync_register sync_register_clear_src (
        .clk_i (dst_clk_i),
        .rst_ni (dst_rst_ni),
        .d_i (src_clear_i),
        .q_o (src_clear_sync)
    );

    sync_register sync_register_clear_dst (
        .clk_i (src_clk_i),
        .rst_ni (src_rst_ni),
        .d_i (dst_clear_i),
        .q_o (dst_clear_sync)
    );

    // FIFO control logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            fifo_full <= 1'b0;
            src_ready_o <= 1'b1;
            src_clear_pending_o <= 1'b0;
        end else begin
            if (src_clear_i) begin
                fifo_waddr <= {LOG_DEPTH{1'b0}};
                fifo_full <= 1'b0;
                src_ready_o <= 1'b1;
                src_clear_pending_o <= 1'b1;
            end else begin
                src_ready_o <= ~fifo_full;
                src_clear_pending_o <= 1'b0;

                if (src_valid_i && src_ready_o) begin
                    fifo_data[fifo_waddr] <= src_data_i;
                end

                if (src_valid_i && src_ready_o) begin
                    fifo_full <= (src_gray == {1'b1, dst_gray_sync[LOG_DEPTH-1:0]});
                end
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            fifo_empty <= 1'b1;
            dst_valid_o <= 1'b0;
            dst_data_o <= {WIDTH{1'b0}};
            dst_clear_pending_o <= 1'b0;
        end else begin
            if (dst_clear_i) begin
                fifo_raddr <= {LOG_DEPTH{1'b0}};
                fifo_empty <= 1'b1;
                dst_valid_o <= 1'b0;
                dst_clear_pending_o <= 1'b1;
            end else begin
                dst_valid_o <= ~fifo_empty;

                if (dst_ready_i && dst_valid_o) begin
                    fifo_raddr <= fifo_raddr + 1;
                end

                if (dst_ready_i && dst_valid_o) begin
                    fifo_empty <= (src_gray_sync == {1'b0, dst_gray[LOG_DEPTH-1:0]});
                end

                if (dst_valid_o) begin
                    dst_data_o <= fifo_data[fifo_raddr];
                end
            end
        end
    end

endmodule

module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input                  clear_i,
    output [LOG_DEPTH:0]   gray_o,
    output [LOG_DEPTH-1:0] count_o
);

    reg [LOG_DEPTH-1:0]    count;
    reg [LOG_DEPTH-1:0]    next_count;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            count <= {LOG_DEPTH{1'b0}};
        end else if (clear_i) begin
            count <= {LOG_DEPTH{1'b0}};
        end else begin
            count <= next_count;
        end
    end

    always @(*) begin
        next_count = count + 1;
        gray_o = count ^ (count >> 1);
        count_o = count;
    end

endmodule

module sync_register (
    input                  clk_i,
    input                  rst_ni,
    input                  d_i,
    output reg             q_o
);

    reg                    sync_stage_0;
    reg                    sync_stage_1;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_stage_0 <= 1'b0;
            sync_stage_1 <= 1'b0;
            q_o <= 1'b0;
        end else begin
            sync_stage_0 <= d_i;
            sync_stage_1 <= sync_stage_0;
            q_o <= sync_stage_1;
        end
    end

endmodule
