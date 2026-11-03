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

    // Internal signals
    reg  [WIDTH-1:0]     fifo_mem [0:(2**LOG_DEPTH)-1];
    reg  [LOG_DEPTH:0]   fifo_wptr, fifo_rptr;
    reg  [LOG_DEPTH:0]   fifo_wptr_gray, fifo_rptr_gray;
    reg  [LOG_DEPTH:0]   fifo_wptr_gray_sync, fifo_rptr_gray_sync;
    reg  [LOG_DEPTH:0]   fifo_wptr_next, fifo_rptr_next;
    reg  [LOG_DEPTH:0]   fifo_full, fifo_empty;
    reg  [LOG_DEPTH:0]   fifo_count;

    // Binary to Gray Code conversion
    function [LOG_DEPTH:0] bin2gray;
        input [LOG_DEPTH:0] bin;
        bin2gray = bin ^ (bin >> 1);
    endfunction

    // Gray Code to Binary conversion
    function [LOG_DEPTH:0] gray2bin;
        input [LOG_DEPTH:0] gray;
        integer i;
        reg [LOG_DEPTH:0] bin;
        bin = gray;
        for (i = LOG_DEPTH-1; i >= 0; i = i - 1) begin
            bin[i] = bin[i+1] ^ gray[i];
        end
        gray2bin = bin;
    endfunction

    // Source Domain Logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            fifo_wptr <= 0;
            fifo_wptr_gray <= 0;
            fifo_wptr_next <= 0;
            fifo_full <= 0;
            fifo_count <= 0;
        end else begin
            fifo_wptr_next = fifo_wptr + src_valid_i & src_ready_o;
            fifo_wptr_gray = bin2gray(fifo_wptr_next);
            fifo_count = fifo_count + src_valid_i & src_ready_o - dst_valid_o & dst_ready_i;
            fifo_full = (fifo_count == 2**LOG_DEPTH);
            if (!fifo_full) begin
                fifo_mem[fifo_wptr] <= src_data_i;
                fifo_wptr <= fifo_wptr_next;
            end
        end
    end

    // Destination Domain Logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            fifo_rptr <= 0;
            fifo_rptr_gray <= 0;
            fifo_rptr_next <= 0;
            fifo_empty <= 1;
            fifo_count <= 0;
        end else begin
            fifo_rptr_next = fifo_rptr + dst_valid_o & dst_ready_i;
            fifo_count = fifo_count - src_valid_i & src_ready_o + dst_valid_o & dst_ready_i;
            fifo_empty = (fifo_count == 0);
            if (!fifo_empty) begin
                fifo_rptr <= fifo_rptr_next;
            end
        end
    end

    // Cross-domain synchronization of write pointer
    sync_register #(
        .WIDTH(LOG_DEPTH+1)
    ) sync_register_inst_wptr (
        .rst_ni(src_rst_ni),
        .clk_i(dst_clk_i),
        .data_i(fifo_wptr_gray),
        .data_o(fifo_wptr_gray_sync)
    );

    // Cross-domain synchronization of read pointer
    sync_register #(
        .WIDTH(LOG_DEPTH+1)
    ) sync_register_inst_rptr (
        .rst_ni(dst_rst_ni),
        .clk_i(src_clk_i),
        .data_i(fifo_rptr_gray),
        .data_o(fifo_rptr_gray_sync)
    );

    // Source ready signal
    assign src_ready_o = !fifo_full;

    // Destination data and valid signals
    reg [WIDTH-1:0] dst_data_reg1, dst_data_reg2;
    reg dst_valid_reg1, dst_valid_reg2;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_reg1 <= 0;
            dst_data_reg2 <= 0;
            dst_valid_reg1 <= 0;
            dst_valid_reg2 <= 0;
        end else begin
            dst_data_reg1 <= fifo_mem[gray2bin(fifo_rptr_gray_sync)];
            dst_valid_reg1 <= !fifo_empty;
            dst_data_reg2 <= dst_data_reg1;
            dst_valid_reg2 <= dst_valid_reg1;
        end
    end

    assign dst_data_o = dst_data_reg2;
    assign dst_valid_o = dst_valid_reg2;

endmodule

module sync_register #(
    parameter WIDTH = 1
)(
    input                  rst_ni,
    input                  clk_i,
    input  [WIDTH-1:0]     data_i,
    output [WIDTH-1:0]     data_o
);

    reg [WIDTH-1:0] sync_ff1, sync_ff2;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_ff1 <= 0;
            sync_ff2 <= 0;
        end else begin
            sync_ff1 <= data_i;
            sync_ff2 <= sync_ff1;
        end
    end

    assign data_o = sync_ff2;

endmodule
