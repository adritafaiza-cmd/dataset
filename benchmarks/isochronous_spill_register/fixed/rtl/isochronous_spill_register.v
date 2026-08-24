// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51.
// Verilog-2001 flattening of isochronous_spill_register.

module isochronous_spill_register #(
    parameter WIDTH = 8
)(
    input              src_clk_i,
    input              src_rst_ni,
    input              src_valid_i,
    output             src_ready_o,
    input  [WIDTH-1:0] src_data_i,
    input              dst_clk_i,
    input              dst_rst_ni,
    output             dst_valid_o,
    input              dst_ready_i,
    output [WIDTH-1:0] dst_data_o
);

    reg [1:0] wr_pointer_q, rd_pointer_q;
    reg [WIDTH-1:0] mem0, mem1;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            wr_pointer_q <= 2'b00;
        else if (src_valid_i && src_ready_o)
            wr_pointer_q <= wr_pointer_q + 2'd1;
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            rd_pointer_q <= 2'b00;
        else if (dst_valid_o && dst_ready_i)
            rd_pointer_q <= rd_pointer_q + 2'd1;
    end

    always @(posedge src_clk_i) begin
        if (src_valid_i && src_ready_o) begin
            if (wr_pointer_q[0] == 1'b0)
                mem0 <= src_data_i;
            else
                mem1 <= src_data_i;
        end
    end

    assign src_ready_o = ((rd_pointer_q ^ wr_pointer_q) != 2'b10);
    assign dst_valid_o = ((rd_pointer_q ^ wr_pointer_q) != 2'b00);
    assign dst_data_o  = rd_pointer_q[0] ? mem1 : mem0;

endmodule
