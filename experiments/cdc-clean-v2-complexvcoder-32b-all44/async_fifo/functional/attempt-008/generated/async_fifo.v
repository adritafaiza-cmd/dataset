module async_fifo
    #(
        parameter DSIZE = 8,
        parameter ASIZE = 4,
        parameter FALLTHROUGH = "TRUE"
    )(
        input  wire             wclk,
        input  wire             wrst_n,
        input  wire             winc,
        input  wire [DSIZE-1:0] wdata,
        output wire             wfull,
        output wire             awfull,
        input  wire             rclk,
        input  wire             rrst_n,
        input  wire             rinc,
        output wire [DSIZE-1:0] rdata,
        output wire             rempty,
        output wire             arempty
    );

    // Internal signals
    reg [DSIZE-1:0] mem [0:(1<<ASIZE)-1];
    reg [ASIZE-1:0] wptr, wptr_gray, wptr_gray_r;
    reg [ASIZE-1:0] rptr, rptr_gray, rptr_gray_w;
    reg [ASIZE-1:0] wptr_next, wptr_gray_next;
    reg [ASIZE-1:0] rptr_next, rptr_gray_next;
    reg [ASIZE-1:0] wptr_bin, rptr_bin;
    reg [ASIZE-1:0] wptr_gray_sync, rptr_gray_sync;
    reg             full, almost_full;
    reg             empty, almost_empty;

    // Gray code conversion
    function [ASIZE-1:0] bin_to_gray;
        input [ASIZE-1:0] bin;
        bin_to_gray = (bin >> 1) ^ bin;
    endfunction

    // Binary code conversion
    function [ASIZE-1:0] gray_to_bin;
        input [ASIZE-1:0] gray;
        integer i;
        reg [ASIZE-1:0] bin;
        bin = gray;
        for (i = ASIZE-2; i >= 0; i = i - 1) begin
            bin[i] = bin[i+1] ^ gray[i];
        end
        gray_to_bin = bin;
    endfunction

    // Write domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wptr_gray <= 0;
            wptr_gray_r <= 0;
            full <= 0;
            almost_full <= 0;
        end else begin
            wptr_next = wptr;
            if (winc && !full) begin
                wptr_next = wptr + 1;
                mem[wptr_bin] <= wdata;
            end
            wptr_gray_next = bin_to_gray(wptr_next);
            wptr <= wptr_next;
            wptr_gray <= wptr_gray_next;
            wptr_gray_r <= wptr_gray_sync;
        end
    end

    // Read domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rptr_gray <= 0;
            rptr_gray_w <= 0;
            empty <= 1;
            almost_empty <= 1;
        end else begin
            rptr_next = rptr;
            if (rinc && !empty) begin
                rptr_next = rptr + 1;
            end
            rptr_gray_next = bin_to_gray(rptr_next);
            rptr <= rptr_next;
            rptr_gray <= rptr_gray_next;
            rptr_gray_w <= rptr_gray_sync;
        end
    end

    // Synchronization of pointers
    sync_gray_code sync_gray_code_w (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(rptr_gray),
        .dout(rptr_gray_sync)
    );

    sync_gray_code sync_gray_code_r (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(wptr_gray),
        .dout(wptr_gray_sync)
    );

    // Calculate full and almost_full
    assign wptr_bin = gray_to_bin(wptr_gray);
    assign rptr_bin = gray_to_bin(rptr_gray_w);
    assign full = (wptr_gray_sync == (rptr_gray + 1));
    assign almost_full = (wptr_gray_sync == (rptr_gray + 2));

    // Calculate empty and almost_empty
    assign empty = (wptr_gray == rptr_gray_w);
    assign almost_empty = (wptr_gray == (rptr_gray_w + 1));

    // Outputs
    assign wfull = full;
    assign awfull = almost_full;
    assign rdata = mem[rptr_bin];
    assign rempty = empty;
    assign arempty = almost_empty;

endmodule

// Synchronizer module for gray code
module sync_gray_code (
    input wire clk,
    input wire rst_n,
    input wire [ASIZE-1:0] din,
    output reg [ASIZE-1:0] dout
);

    reg [ASIZE-1:0] stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1 <= 0;
            dout <= 0;
        end else begin
            stage1 <= din;
            dout <= stage1;
        end
    end

endmodule
