// Copyright 2018-2019 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51.
// Verilog-2001 flattening of pulp-platform/common_cells cdc_fifo_gray.

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

    localparam PTRW = LOG_DEPTH + 1;
    localparam NST = (SYNC_STAGES < 2) ? 2 : SYNC_STAGES;
    localparam [PTRW-1:0] PTR_FULL = {1'b1, {LOG_DEPTH{1'b0}}};

    reg [WIDTH-1:0] mem [0:(1<<LOG_DEPTH)-1];
    reg [PTRW-1:0] wptr_bin, rptr_bin;
    reg [PTRW-1:0] wsnap_q, rsnap_q;
    reg [PTRW-1:0] wptr_dst, rptr_src;
    reg wreq_q, rreq_q, wack_q, rack_q;
    (* ASYNC_REG = "TRUE" *) reg [NST-1:0] wreq_sync, rreq_sync;
    (* ASYNC_REG = "TRUE" *) reg [NST-1:0] wack_sync, rack_sync;
    (* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] payload_meta_q, payload_sync_q;
    reg [1:0] payload_wait_q;
    reg [WIDTH-1:0] dst_data_q;
    reg dst_hold;

    // Binary pointers advance only on an accepted beat. Each side sends
    // a snapshot on one request bit. The other side captures that
    // register when the request changes, so ready and valid do not
    // reconverge a synchronized Gray bus.
    assign src_ready_o = ((wptr_bin ^ rptr_src) != PTR_FULL);
    assign dst_valid_o = dst_hold;
    assign dst_data_o  = dst_data_q;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wptr_bin  <= {PTRW{1'b0}};
            wsnap_q   <= {PTRW{1'b0}};
            wreq_q    <= 1'b0;
            rack_sync <= {NST{1'b0}};
            rptr_src  <= {PTRW{1'b0}};
            rreq_sync <= {NST{1'b0}};
            wack_q    <= 1'b0;
        end else begin
            rack_sync <= {rack_sync[NST-2:0], rack_q};
            rreq_sync <= {rreq_sync[NST-2:0], rreq_q};
            if (rreq_sync[NST-1] != wack_q) begin
                rptr_src <= rsnap_q;
                wack_q   <= rreq_sync[NST-1];
            end
            if (src_valid_i && src_ready_o)
                wptr_bin <= wptr_bin + 1'b1;
            if ((wreq_q == rack_sync[NST-1]) && (wptr_bin != wsnap_q)) begin
                wsnap_q <= wptr_bin;
                wreq_q  <= ~wreq_q;
            end
        end
    end

    always @(posedge src_clk_i) begin
        if (src_valid_i && src_ready_o)
            mem[wptr_bin[LOG_DEPTH-1:0]] <= src_data_i;
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rptr_bin  <= {PTRW{1'b0}};
            rsnap_q   <= {PTRW{1'b0}};
            rreq_q    <= 1'b0;
            wack_sync <= {NST{1'b0}};
            wptr_dst  <= {PTRW{1'b0}};
            wreq_sync <= {NST{1'b0}};
            rack_q    <= 1'b0;
            dst_data_q <= {WIDTH{1'b0}};
            dst_hold  <= 1'b0;
        end else begin
            wack_sync <= {wack_sync[NST-2:0], wack_q};
            wreq_sync <= {wreq_sync[NST-2:0], wreq_q};
            if (wreq_sync[NST-1] != rack_q) begin
                wptr_dst <= wsnap_q;
                rack_q   <= wreq_sync[NST-1];
            end
            if (!dst_hold && (wptr_dst != rptr_bin) && payload_wait_q == 2) begin
                dst_data_q <= payload_sync_q;
                dst_hold   <= 1'b1;
            end else if (dst_hold && dst_ready_i) begin
                dst_hold <= 1'b0;
                rptr_bin <= rptr_bin + 1'b1;
            end
            if ((rreq_q == wack_sync[NST-1]) && (rptr_bin != rsnap_q)) begin
                rsnap_q <= rptr_bin;
                rreq_q  <= ~rreq_q;
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            payload_meta_q <= {WIDTH{1'b0}};
            payload_sync_q <= {WIDTH{1'b0}};
            payload_wait_q <= 0;
        end else begin
            payload_meta_q <= mem[rptr_bin[LOG_DEPTH-1:0]];
            payload_sync_q <= payload_meta_q;
            if (!dst_hold && (wptr_dst != rptr_bin)) begin
                if (payload_wait_q != 2) payload_wait_q <= payload_wait_q + 1'b1;
            end else payload_wait_q <= 0;
        end
    end
endmodule
