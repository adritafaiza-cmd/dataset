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

    // One coordinated POR for both pointer CDCs; children must not AND again.
    wire common_rst_ni = src_rst_ni & dst_rst_ni;
    wire src_rst_sync_ni;
    wire dst_rst_sync_ni;
    (* ASYNC_REG = "TRUE" *) reg [1:0] src_rst_sync_q;
    (* ASYNC_REG = "TRUE" *) reg [1:0] dst_rst_sync_q;

    always @(posedge src_clk_i or negedge common_rst_ni) begin
        if (!common_rst_ni)
            src_rst_sync_q <= 2'b00;
        else
            src_rst_sync_q <= {src_rst_sync_q[0], 1'b1};
    end

    always @(posedge dst_clk_i or negedge common_rst_ni) begin
        if (!common_rst_ni)
            dst_rst_sync_q <= 2'b00;
        else
            dst_rst_sync_q <= {dst_rst_sync_q[0], 1'b1};
    end

    assign src_rst_sync_ni = src_rst_sync_q[1];
    assign dst_rst_sync_ni = dst_rst_sync_q[1];

    always @(posedge src_clk_i or negedge src_rst_sync_ni) begin
        if (!src_rst_sync_ni)
            src_wptr_q <= {PTRW{1'b0}};
        else if (src_valid_i && src_ready_o)
            src_wptr_q <= src_wptr_q + 1'b1;
    end

    always @(posedge src_clk_i) begin
        if (src_valid_i && src_ready_o)
            fifo_data[src_wptr_q[LOG_DEPTH-1:0]] <= src_data_i;
    end

    // The destination samples the selected memory word once, into
    // dst_data_q, and holds it while valid. A combinational read of
    // fifo_data in dst_clk_i is the CDC_NO_SYNC path. valid falls for
    // one destination clock after an accept even if another word is
    // already stored, so the next sample uses the updated pointer.
    (* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] payload_meta_q, payload_sync_q;
    reg [1:0] payload_wait_q;
    reg [WIDTH-1:0] dst_data_q;
    reg             dst_hold;

    wire dst_more = (dst_rptr_q != dst_wptr);

    always @(posedge dst_clk_i or negedge dst_rst_sync_ni) begin
        if (!dst_rst_sync_ni) begin
            dst_rptr_q <= {PTRW{1'b0}};
            dst_data_q <= {WIDTH{1'b0}};
            dst_hold   <= 1'b0;
        end else if ((!dst_hold && dst_more) && payload_wait_q == 2) begin
            dst_data_q <= payload_sync_q;
            dst_hold   <= 1'b1;
        end else if (dst_hold && dst_ready_i) begin
            dst_hold   <= 1'b0;
            dst_rptr_q <= dst_rptr_q + 1'b1;
        end
    end

    assign src_ready_o = ((src_wptr_q ^ src_rptr) != PTR_FULL);
    assign dst_valid_o = dst_hold;
    assign dst_data_o  = dst_data_q;

    wire wptr_req, wptr_ack;
    wire [PTRW-1:0] wptr_payload;
    cdc_2phase_src #(.WIDTH(PTRW)) i_wptr_src (
        .rst_ni(src_rst_sync_ni), .clk_i(src_clk_i), .data_i(src_wptr_q),
        .valid_i(1'b1), .ready_o(), .async_req_o(wptr_req),
        .async_ack_i(wptr_ack), .async_data_o(wptr_payload)
    );
    cdc_2phase_dst #(.WIDTH(PTRW)) i_wptr_dst (
        .rst_ni(dst_rst_sync_ni), .clk_i(dst_clk_i), .data_o(dst_wptr),
        .valid_o(), .ready_i(1'b1), .async_req_i(wptr_req),
        .async_ack_o(wptr_ack), .async_data_i(wptr_payload)
    );
    wire rptr_req, rptr_ack;
    wire [PTRW-1:0] rptr_payload;
    cdc_2phase_src #(.WIDTH(PTRW)) i_rptr_src (
        .rst_ni(dst_rst_sync_ni), .clk_i(dst_clk_i), .data_i(dst_rptr_q),
        .valid_i(1'b1), .ready_o(), .async_req_o(rptr_req),
        .async_ack_i(rptr_ack), .async_data_o(rptr_payload)
    );
    cdc_2phase_dst #(.WIDTH(PTRW)) i_rptr_dst (
        .rst_ni(src_rst_sync_ni), .clk_i(src_clk_i), .data_o(src_rptr),
        .valid_o(), .ready_i(1'b1), .async_req_i(rptr_req),
        .async_ack_o(rptr_ack), .async_data_i(rptr_payload)
    );
    always @(posedge dst_clk_i or negedge dst_rst_sync_ni) begin
        if (!dst_rst_sync_ni) begin
            payload_meta_q <= {WIDTH{1'b0}};
            payload_sync_q <= {WIDTH{1'b0}};
            payload_wait_q <= 0;
        end else begin
            payload_meta_q <= fifo_data[dst_rptr_q[LOG_DEPTH-1:0]];
            payload_sync_q <= payload_meta_q;
            if (!dst_hold && dst_more) begin
                if (payload_wait_q != 2) payload_wait_q <= payload_wait_q + 1'b1;
            end else payload_wait_q <= 0;
        end
    end
endmodule
