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
    localparam [PTRW-1:0] PTR_FULL = {1'b1, {LOG_DEPTH{1'b0}}};

    function [PTRW-1:0] bin2gray;
        input [PTRW-1:0] b;
        begin
            bin2gray = b ^ (b >> 1);
        end
    endfunction

    function [PTRW-1:0] gray2bin;
        input [PTRW-1:0] g;
        integer k;
        begin
            gray2bin[PTRW-1] = g[PTRW-1];
            for (k = PTRW-2; k >= 0; k = k - 1)
                gray2bin[k] = gray2bin[k+1] ^ g[k];
        end
    endfunction

    reg [WIDTH-1:0] mem [0:(1<<LOG_DEPTH)-1];
    reg [PTRW-1:0] wptr_bin, rptr_bin;
    wire [PTRW-1:0] wptr_gray = bin2gray(wptr_bin);
    wire [PTRW-1:0] rptr_gray = bin2gray(rptr_bin);

    (* ASYNC_REG = "TRUE" *) reg [PTRW-1:0] rptr_sync [0:SYNC_STAGES-1];
    (* ASYNC_REG = "TRUE" *) reg [PTRW-1:0] wptr_sync [0:SYNC_STAGES-1];

    integer s;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            for (s = 0; s < SYNC_STAGES; s = s + 1)
                rptr_sync[s] <= {PTRW{1'b0}};
        end else begin
            rptr_sync[0] <= rptr_gray;
            for (s = 1; s < SYNC_STAGES; s = s + 1)
                rptr_sync[s] <= rptr_sync[s-1];
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            for (s = 0; s < SYNC_STAGES; s = s + 1)
                wptr_sync[s] <= {PTRW{1'b0}};
        end else begin
            wptr_sync[0] <= wptr_gray;
            for (s = 1; s < SYNC_STAGES; s = s + 1)
                wptr_sync[s] <= wptr_sync[s-1];
        end
    end

    wire [PTRW-1:0] rptr_bin_src = gray2bin(rptr_sync[SYNC_STAGES-1]);
    wire [PTRW-1:0] wptr_bin_dst = gray2bin(wptr_sync[SYNC_STAGES-1]);

    assign src_ready_o = ((wptr_bin ^ rptr_bin_src) != PTR_FULL);
    assign dst_valid_o = (wptr_bin_dst != rptr_bin);
    assign dst_data_o  = mem[rptr_bin[LOG_DEPTH-1:0]];

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            wptr_bin <= {PTRW{1'b0}};
        else if (src_valid_i && src_ready_o)
            wptr_bin <= wptr_bin + 1'b1;
    end

    // FIFO storage is not reset; keep it off the async-reset always block
    // so the write data pin is not a reset-in-data-path.
    always @(posedge src_clk_i) begin
        if (src_valid_i && src_ready_o)
            mem[wptr_bin[LOG_DEPTH-1:0]] <= src_data_i;
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            rptr_bin <= {PTRW{1'b0}};
        else if (dst_valid_o && dst_ready_i)
            rptr_bin <= rptr_bin + 1'b1;
    end

endmodule
