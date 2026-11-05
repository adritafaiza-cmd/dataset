// Copyright 2018-2019 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51.
// Verilog-2001 flattening of pulp-platform cdc_fifo_gray_clearable.
// A clear on either side isolates both ports, then resets the pointers.

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
    // Registered on the same edge as the binary pointer, including the
    // clear edge that writes both back to zero. The synchronizer input
    // is this register, not the combinational Gray encode.
    reg [PTRW-1:0] wptr_gray_q, rptr_gray_q;
    (* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] payload_meta_q, payload_sync_q;
    reg [1:0] payload_wait_q;
    reg [WIDTH-1:0] dst_data_q;
    reg dst_word;

    (* ASYNC_REG = "TRUE" *) reg [PTRW-1:0] rptr_sync [0:SYNC_STAGES-1];
    (* ASYNC_REG = "TRUE" *) reg [PTRW-1:0] wptr_sync [0:SYNC_STAGES-1];
    (* ASYNC_REG = "TRUE" *) reg [SYNC_STAGES-1:0] src_clr_sync;
    (* ASYNC_REG = "TRUE" *) reg [SYNC_STAGES-1:0] dst_clr_sync;

    reg src_clr_level, dst_clr_level;
    reg src_remote_q, dst_remote_q;
    reg [4:0] src_hold, dst_hold;
    integer s;
    wire src_remote_rise = dst_clr_sync[SYNC_STAGES-1] & ~src_remote_q;
    wire dst_remote_rise = src_clr_sync[SYNC_STAGES-1] & ~dst_remote_q;

    // Coordinated async assertion; deassert is synchronized per domain.
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
        if (!src_rst_sync_ni) begin
            for (s = 0; s < SYNC_STAGES; s = s + 1)
                rptr_sync[s] <= {PTRW{1'b0}};
            dst_clr_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            rptr_sync[0] <= rptr_gray_q;
            for (s = 1; s < SYNC_STAGES; s = s + 1)
                rptr_sync[s] <= rptr_sync[s-1];
            dst_clr_sync <= {dst_clr_sync[SYNC_STAGES-2:0], dst_clr_level};
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_sync_ni) begin
        if (!dst_rst_sync_ni) begin
            for (s = 0; s < SYNC_STAGES; s = s + 1)
                wptr_sync[s] <= {PTRW{1'b0}};
            src_clr_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            wptr_sync[0] <= wptr_gray_q;
            for (s = 1; s < SYNC_STAGES; s = s + 1)
                wptr_sync[s] <= wptr_sync[s-1];
            src_clr_sync <= {src_clr_sync[SYNC_STAGES-2:0], src_clr_level};
        end
    end

    wire [PTRW-1:0] rptr_bin_src = gray2bin(rptr_sync[SYNC_STAGES-1]);
    wire [PTRW-1:0] wptr_bin_dst = gray2bin(wptr_sync[SYNC_STAGES-1]);
    wire fifo_ready = ((wptr_bin ^ rptr_bin_src) != PTR_FULL);
    wire fifo_valid = (wptr_bin_dst != rptr_bin);

    assign src_clear_pending_o = (src_hold != 5'd0);
    assign dst_clear_pending_o = (dst_hold != 5'd0);
    assign src_ready_o = fifo_ready & (src_hold == 5'd0);
    // A stored word is sampled once. valid falls for one destination
    // clock after an accept, and it stays low for the whole clear hold
    // so a pre-clear word is not presented again.
    assign dst_valid_o = dst_word & (dst_hold == 5'd0);
    assign dst_data_o  = dst_data_q;

    always @(posedge src_clk_i or negedge src_rst_sync_ni) begin
        if (!src_rst_sync_ni) begin
            wptr_bin <= {PTRW{1'b0}};
            wptr_gray_q <= {PTRW{1'b0}};
            src_clr_level <= 1'b0;
            src_remote_q <= 1'b0;
            src_hold <= 5'd0;
        end else begin
            src_remote_q <= dst_clr_sync[SYNC_STAGES-1];
            if (src_hold != 5'd0)
                src_hold <= src_hold - 5'd1;
            else if (src_clear_i || src_remote_rise)
                src_hold <= 5'd16;

            if (src_clear_i)
                src_clr_level <= 1'b1;
            else if (src_hold == 5'd1)
                src_clr_level <= 1'b0;

            if (src_hold == 5'd1) begin
                wptr_bin <= {PTRW{1'b0}};
                wptr_gray_q <= {PTRW{1'b0}};
            end else if (src_valid_i && src_ready_o) begin
                wptr_bin <= wptr_bin + 1'b1;
                wptr_gray_q <= bin2gray(wptr_bin + 1'b1);
            end
        end
    end

    always @(posedge src_clk_i) begin
        if (src_valid_i && src_ready_o)
            mem[wptr_bin[LOG_DEPTH-1:0]] <= src_data_i;
    end

    always @(posedge dst_clk_i or negedge dst_rst_sync_ni) begin
        if (!dst_rst_sync_ni) begin
            rptr_bin <= {PTRW{1'b0}};
            rptr_gray_q <= {PTRW{1'b0}};
            dst_data_q <= {WIDTH{1'b0}};
            dst_word <= 1'b0;
            dst_clr_level <= 1'b0;
            dst_remote_q <= 1'b0;
            dst_hold <= 5'd0;
        end else begin
            dst_remote_q <= src_clr_sync[SYNC_STAGES-1];
            if (dst_hold != 5'd0)
                dst_hold <= dst_hold - 5'd1;
            else if (dst_clear_i || dst_remote_rise)
                dst_hold <= 5'd16;

            if (dst_clear_i)
                dst_clr_level <= 1'b1;
            else if (dst_hold == 5'd1)
                dst_clr_level <= 1'b0;

            if (dst_hold != 5'd0)
                dst_word <= 1'b0;
            else if ((!dst_word && fifo_valid) && payload_wait_q == 2) begin
                dst_data_q <= payload_sync_q;
                dst_word <= 1'b1;
            end else if (dst_word && dst_ready_i)
                dst_word <= 1'b0;

            if (dst_hold == 5'd1) begin
                rptr_bin <= {PTRW{1'b0}};
                rptr_gray_q <= {PTRW{1'b0}};
            end else if ((dst_hold == 5'd0) && dst_word && dst_ready_i) begin
                rptr_bin <= rptr_bin + 1'b1;
                rptr_gray_q <= bin2gray(rptr_bin + 1'b1);
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_sync_ni) begin
        if (!dst_rst_sync_ni) begin
            payload_meta_q <= {WIDTH{1'b0}};
            payload_sync_q <= {WIDTH{1'b0}};
            payload_wait_q <= 0;
        end else begin
            payload_meta_q <= mem[rptr_bin[LOG_DEPTH-1:0]];
            payload_sync_q <= payload_meta_q;
            if (!dst_word && fifo_valid) begin
                if (payload_wait_q != 2) payload_wait_q <= payload_wait_q + 1'b1;
            end else payload_wait_q <= 0;
        end
    end
endmodule
