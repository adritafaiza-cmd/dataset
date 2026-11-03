module cdc_fifo_2phase #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
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

    // Instantiate the memory module
    memory #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) memory_inst (
        .src_rst_ni   (src_rst_ni),
        .src_clk_i    (src_clk_i),
        .src_data_i   (src_data_i),
        .src_valid_i  (src_valid_i),
        .src_ready_o  (src_ready_o),
        .dst_rst_ni   (dst_rst_ni),
        .dst_clk_i    (dst_clk_i),
        .dst_data_o   (memory_inst_dst_data_o),
        .dst_ready_i  (dst_ready_i)
    );

    // Instantiate the sync_stage module
    sync_stage #(
        .WIDTH(WIDTH)
    ) sync_stage_inst (
        .src_rst_ni   (src_rst_ni),
        .src_clk_i    (src_clk_i),
        .dst_rst_ni   (dst_rst_ni),
        .dst_clk_i    (dst_clk_i),
        .dst_valid_o  (sync_stage_inst_dst_valid_o),
        .dst_data_o   (sync_stage_inst_dst_data_o)
    );

    // Internal signal connections
    assign memory_inst.dst_data_i = sync_stage_inst_dst_data_o;

    // Output assignments
    assign dst_data_o = memory_inst_dst_data_o;
    assign dst_valid_o = sync_stage_inst_dst_valid_o;

    // Internal signals
    wire [WIDTH-1:0] memory_inst_dst_data_o;
    wire             sync_stage_inst_dst_valid_o;
    wire [WIDTH-1:0] sync_stage_inst_dst_data_o;

endmodule

module memory #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    output [WIDTH-1:0]     dst_data_o,
    input                  dst_ready_i
);

    localparam DEPTH = 1 << LOG_DEPTH;
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;
    reg [$clog2(DEPTH):0] count;

    // Write pointer and count update
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr <= 0;
            count <= 0;
        end else if (src_valid_i && src_ready_o) begin
            mem[wr_ptr] <= src_data_i;
            wr_ptr <= wr_ptr + 1;
            count <= count + 1;
        end
    end

    // Read pointer and count update
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr <= 0;
            count <= 0;
        end else if (dst_valid_o && dst_ready_i) begin
            rd_ptr <= rd_ptr + 1;
            count <= count - 1;
        end
    end

    // Source ready signal
    assign src_ready_o = (count < DEPTH);

    // Destination valid signal
    assign dst_valid_o = (count > 0);

    // Destination data output
    assign dst_data_o = mem[rd_ptr];

endmodule

module sync_stage #(
    parameter WIDTH = 8
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    output                 dst_valid_o,
    output [WIDTH-1:0]     dst_data_o
);

    reg [WIDTH-1:0] stage1, stage2;
    reg valid1, valid2;

    // First stage of synchronization
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            stage1 <= 0;
            valid1 <= 0;
        end else begin
            stage1 <= stage2;
            valid1 <= valid2;
        end
    end

    // Second stage of synchronization
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            stage2 <= 0;
            valid2 <= 0;
        end else begin
            stage2 <= stage1;
            valid2 <= valid1;
        end
    end

    // Output assignments
    assign dst_data_o = stage2;
    assign dst_valid_o = valid2;

endmodule
