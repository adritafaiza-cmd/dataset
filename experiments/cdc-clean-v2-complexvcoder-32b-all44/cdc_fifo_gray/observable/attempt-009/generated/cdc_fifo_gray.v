module cdc_fifo_gray #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    wire [LOG_DEPTH-1:0] src_gray_wptr;
    wire [LOG_DEPTH-1:0] dst_gray_rptr;
    wire [LOG_DEPTH-1:0] sync_src_wptr;
    wire [LOG_DEPTH-1:0] sync_dst_rptr;
    wire [WIDTH-1:0]     fifo_data_out;
    wire                 src_wptr_inc;
    wire                 dst_rptr_inc;

    // Write pointer generation
    gray_counter #(.LOG_DEPTH(LOG_DEPTH))
    src_gray_counter (
        .clk_i  (src_clk_i),
        .rst_ni (src_rst_ni),
        .count_o(src_gray_wptr),
        .en_i   (src_wptr_inc)
    );

    // Read pointer generation
    gray_counter #(.LOG_DEPTH(LOG_DEPTH))
    dst_gray_counter (
        .clk_i  (dst_clk_i),
        .rst_ni (dst_rst_ni),
        .count_o(dst_gray_rptr),
        .en_i   (dst_rptr_inc)
    );

    // Synchronize write pointer to destination clock domain
    sync_gray_counter #(.LOG_DEPTH(LOG_DEPTH), .SYNC_STAGES(SYNC_STAGES))
    sync_src_gray_wptr (
        .clk_i  (dst_clk_i),
        .rst_ni (dst_rst_ni),
        .data_i (src_gray_wptr),
        .data_o (sync_src_wptr)
    );

    // Synchronize read pointer to source clock domain
    sync_gray_counter #(.LOG_DEPTH(LOG_DEPTH), .SYNC_STAGES(SYNC_STAGES))
    sync_dst_gray_rptr (
        .clk_i  (src_clk_i),
        .rst_ni (src_rst_ni),
        .data_i (dst_gray_rptr),
        .data_o (sync_dst_rptr)
    );

    // FIFO memory for data storage
    fifo_memory #(.WIDTH(WIDTH), .LOG_DEPTH(LOG_DEPTH))
    fifo_memory_inst (
        .clk_i     (src_clk_i),
        .rst_ni    (src_rst_ni),
        .wr_en_i   (src_wptr_inc),
        .rd_en_i   (dst_rptr_inc),
        .wr_addr_i (sync_dst_rptr),
        .rd_addr_i (sync_src_wptr),
        .data_i    (src_data_i),
        .data_o    (fifo_data_out)
    );

    // Ready and valid signals
    assign src_wptr_inc = src_valid_i & src_ready_o;
    assign dst_rptr_inc = dst_valid_o & dst_ready_i;
    assign src_ready_o = !(sync_src_wptr == sync_dst_rptr);
    assign dst_valid_o = !(sync_src_wptr == sync_dst_rptr);
    assign dst_data_o = fifo_data_out;

endmodule

module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  clk_i,
    input                  rst_ni,
    output [LOG_DEPTH-1:0] count_o,
    input                  en_i
);

    reg [LOG_DEPTH-1:0] bin_count;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            bin_count <= {LOG_DEPTH{1'b0}};
        end else if (en_i) begin
            bin_count <= bin_count + 1;
        end
    end

    assign count_o = (bin_count >> 1) ^ bin_count;

endmodule

module sync_gray_counter #(
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
)(
    input                  clk_i,
    input                  rst_ni,
    input  [LOG_DEPTH-1:0] data_i,
    output [LOG_DEPTH-1:0] data_o
);

    reg [LOG_DEPTH-1:0] sync_stage [SYNC_STAGES-1:0];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_stage[0] <= {LOG_DEPTH{1'b0}};
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_stage[i] <= {LOG_DEPTH{1'b0}};
            end
        end else begin
            sync_stage[0] <= data_i;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_stage[i] <= sync_stage[i-1];
            end
        end
    end

    assign data_o = sync_stage[SYNC_STAGES-1];

endmodule

module fifo_memory #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  clk_i,
    input                  rst_ni,
    input                  wr_en_i,
    input                  rd_en_i,
    input  [LOG_DEPTH-1:0] wr_addr_i,
    input  [LOG_DEPTH-1:0] rd_addr_i,
    input  [WIDTH-1:0]     data_i,
    output [WIDTH-1:0]     data_o
);

    reg [WIDTH-1:0] memory [2**LOG_DEPTH-1:0];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (int i = 0; i < 2**LOG_DEPTH; i = i + 1) begin
                memory[i] <= {WIDTH{1'b0}};
            end
        end else if (wr_en_i) begin
            memory[wr_addr_i] <= data_i;
        end
    end

    assign data_o = memory[rd_addr_i];

endmodule
