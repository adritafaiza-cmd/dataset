// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51.
// Verilog-2001 flattening of isochronous_4phase_handshake.

module isochronous_4phase_handshake (
    input  src_clk_i,
    input  src_rst_ni,
    input  src_valid_i,
    output src_ready_o,
    input  dst_clk_i,
    input  dst_rst_ni,
    output dst_valid_o,
    input  dst_ready_i
);

    reg src_req_q, src_ack_q;
    reg dst_req_q, dst_ack_q;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            src_req_q <= 1'b0;
        else if (src_valid_i && src_ready_o)
            src_req_q <= ~src_req_q;
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            src_ack_q <= 1'b0;
        else
            src_ack_q <= dst_ack_q;
    end

    assign src_ready_o = (src_req_q == src_ack_q);

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            dst_ack_q <= 1'b0;
        else if (dst_valid_o && dst_ready_i)
            dst_ack_q <= ~dst_ack_q;
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            dst_req_q <= 1'b0;
        else
            dst_req_q <= src_req_q;
    end

    assign dst_valid_o = (dst_req_q != dst_ack_q);

endmodule
