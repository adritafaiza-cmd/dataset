// Copyright 2018 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51.
// Verilog-2001 flattening of pulp-platform/common_cells cdc_fifo_2phase.

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

    localparam PTRW = LOG_DEPTH + 1;
    localparam [PTRW-1:0] PTR_FULL = {1'b1, {LOG_DEPTH{1'b0}}};

    reg [WIDTH-1:0] fifo_data [0:(1<<LOG_DEPTH)-1];
    reg [PTRW-1:0] src_wptr_q, dst_rptr_q;
    wire [PTRW-1:0] dst_wptr, src_rptr;
    integer i;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wptr_q <= {PTRW{1'b0}};
            for (i = 0; i < (1<<LOG_DEPTH); i = i + 1)
                fifo_data[i] <= {WIDTH{1'b0}};
        end else if (src_valid_i && src_ready_o) begin
            fifo_data[src_wptr_q[LOG_DEPTH-1:0]] <= src_data_i;
            src_wptr_q <= src_wptr_q + 1'b1;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            dst_rptr_q <= {PTRW{1'b0}};
        else if (dst_valid_o && dst_ready_i)
            dst_rptr_q <= dst_rptr_q + 1'b1;
    end

    assign src_ready_o = ((src_wptr_q ^ src_rptr) != PTR_FULL);
    assign dst_valid_o = (dst_rptr_q != dst_wptr);
    assign dst_data_o  = fifo_data[dst_rptr_q[LOG_DEPTH-1:0]];

    cdc_2phase #(.WIDTH(PTRW)) i_cdc_wptr (
        .src_rst_ni(src_rst_ni), .src_clk_i(src_clk_i),
        .src_data_i(src_wptr_q), .src_valid_i(1'b1), .src_ready_o(),
        .dst_rst_ni(dst_rst_ni), .dst_clk_i(dst_clk_i),
        .dst_data_o(dst_wptr), .dst_valid_o(), .dst_ready_i(1'b1)
    );

    cdc_2phase #(.WIDTH(PTRW)) i_cdc_rptr (
        .src_rst_ni(dst_rst_ni), .src_clk_i(dst_clk_i),
        .src_data_i(dst_rptr_q), .src_valid_i(1'b1), .src_ready_o(),
        .dst_rst_ni(src_rst_ni), .dst_clk_i(src_clk_i),
        .dst_data_o(src_rptr), .dst_valid_o(), .dst_ready_i(1'b1)
    );

endmodule
