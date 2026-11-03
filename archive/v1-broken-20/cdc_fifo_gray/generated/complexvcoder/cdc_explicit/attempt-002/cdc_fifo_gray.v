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

    // Internal signals
    logic [WIDTH-1:0] data_out;
    logic valid_out;
    logic ready_out;

    // Gray counter instances
    gray_counter #(
        .WIDTH(4)
    ) src_count (
        .clk(src_clk_i),
        .rst_n(src_rst_ni),
        .count()
    );

    gray_counter #(
        .WIDTH(4)
    ) dst_count (
        .clk(dst_clk_i),
        .rst_n(dst_rst_ni),
        .count()
    );

    // FIFO synchronization instance
    fifo_sync #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) fifo_sync_inst (
        .data_in(src_data_i),
        .valid_in(src_valid_i),
        .ready_in(dst_ready_i),
        .clk_src(src_clk_i),
        .rst_n_src(src_rst_ni),
        .clk_dst(dst_clk_i),
        .rst_n_dst(dst_rst_ni),
        .src_gray(src_count.count),
        .dst_gray(dst_count.count),
        .data_out(data_out),
        .valid_out(valid_out),
        .ready_out(ready_out)
    );

    // Assign output ports
    assign src_ready_o = ready_out;
    assign dst_data_o = data_out;
    assign dst_valid_o = valid_out;

endmodule

module gray_counter #(
    parameter WIDTH = 4
)(
    input clk,
    input rst_n,
    output reg [WIDTH-1:0] count
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
        end else begin
            count <= count + 1;
        end
    end

endmodule

module fifo_sync #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
)(
    input [WIDTH-1:0] data_in,
    input valid_in,
    input ready_in,
    input clk_src,
    input rst_n_src,
    input clk_dst,
    input rst_n_dst,
    input [3:0] src_gray,
    input [3:0] dst_gray,
    output reg [WIDTH-1:0] data_out,
    output reg valid_out,
    output reg ready_out
);

    // FIFO logic here
    // This is a placeholder for the actual FIFO logic
    // which should be implemented according to the CDC/RDC requirements

endmodule
