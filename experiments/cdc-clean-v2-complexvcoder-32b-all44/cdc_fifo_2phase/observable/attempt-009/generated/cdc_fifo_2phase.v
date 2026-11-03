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
    reg [LOG_DEPTH-1:0]    src_wptr, src_wptr_gray, src_wptr_gray_sync;
    reg [LOG_DEPTH-1:0]    src_rptr, src_rptr_gray, src_rptr_gray_sync;
    reg [LOG_DEPTH-1:0]    dst_wptr, dst_wptr_gray, dst_wptr_gray_sync;
    reg [LOG_DEPTH-1:0]    dst_rptr, dst_rptr_gray, dst_rptr_gray_sync;
    reg [WIDTH-1:0]        fifo_mem [0:(2**LOG_DEPTH)-1];
    reg                    src_full, dst_empty;

    // Gray code conversion
    function [LOG_DEPTH-1:0] bin2gray;
        input [LOG_DEPTH-1:0] bin;
        bin2gray = bin ^ (bin >> 1);
    endfunction

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wptr <= 0;
            src_wptr_gray <= 0;
            src_rptr <= 0;
            src_rptr_gray <= 0;
        end else begin
            src_wptr_gray <= bin2gray(src_wptr);
            src_rptr_gray <= bin2gray(src_rptr);
            if (src_valid_i && src_ready_o) begin
                fifo_mem[src_wptr] <= src_data_i;
                src_wptr <= src_wptr + 1;
            end
        end
    end

    // Calculate src_full
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_full <= 0;
        end else begin
            src_full <= (src_wptr_gray_sync == bin2gray(src_rptr + 1));
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_wptr <= 0;
            dst_wptr_gray <= 0;
            dst_rptr <= 0;
            dst_rptr_gray <= 0;
        end else begin
            dst_wptr_gray <= bin2gray(dst_wptr);
            dst_rptr_gray <= bin2gray(dst_rptr);
            if (dst_valid_o && dst_ready_i) begin
                dst_rptr <= dst_rptr + 1;
            end
        end
    end

    // Calculate dst_empty
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_empty <= 1;
        end else begin
            dst_empty <= (dst_wptr_gray_sync == bin2gray(dst_rptr));
        end
    end

    // Synchronize pointers
    sync_ff #(.WIDTH(LOG_DEPTH)) sync_src_wptr_gray (
        .din(src_wptr_gray),
        .clk(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .dout(dst_wptr_gray_sync)
    );

    sync_ff #(.WIDTH(LOG_DEPTH)) sync_src_rptr_gray (
        .din(src_rptr_gray),
        .clk(dst_clk_i),
        .rst_ni(dst_rst_ni),
        .dout(src_rptr_gray_sync)
    );

    sync_ff #(.WIDTH(LOG_DEPTH)) sync_dst_wptr_gray (
        .din(dst_wptr_gray),
        .clk(src_clk_i),
        .rst_ni(src_rst_ni),
        .dout(src_wptr_gray_sync)
    );

    sync_ff #(.WIDTH(LOG_DEPTH)) sync_dst_rptr_gray (
        .din(dst_rptr_gray),
        .clk(src_clk_i),
        .rst_ni(src_rst_ni),
        .dout(dst_rptr_gray_sync)
    );

    // Ready and valid signals
    assign src_ready_o = !src_full;
    assign dst_valid_o = !dst_empty;
    assign dst_data_o = fifo_mem[dst_rptr];

endmodule

module sync_ff #(
    parameter WIDTH = 1
)(
    input  [WIDTH-1:0]     din,
    input                  clk,
    input                  rst_ni,
    output [WIDTH-1:0]     dout
);

    reg [WIDTH-1:0] ff1, ff2;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            ff1 <= 0;
            ff2 <= 0;
        end else begin
            ff1 <= din;
            ff2 <= ff1;
        end
    end

    assign dout = ff2;

endmodule
