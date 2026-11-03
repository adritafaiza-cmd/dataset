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

    localparam DEPTH = 2**ASIZE;
    localparam AWIDTH = ASIZE + 1;

    reg [DSIZE-1:0] mem [DEPTH-1:0];

    reg [AWIDTH-1:0] wptr, rptr;
    reg [AWIDTH-1:0] wptr_gray, rptr_gray;
    reg [AWIDTH-1:0] wptr_gray_sync, rptr_gray_sync;

    // Binary to Gray conversion
    function [AWIDTH-1:0] bin_to_gray;
        input [AWIDTH-1:0] bin;
        bin_to_gray = bin ^ (bin >> 1);
    endfunction

    // Gray to Binary conversion
    function [AWIDTH-1:0] gray_to_bin;
        input [AWIDTH-1:0] gray;
        integer i;
        reg [AWIDTH-1:0] bin;
        bin = gray;
        for (i = AWIDTH-2; i >= 0; i = i - 1)
            bin[i] = bin[i+1] ^ gray[i];
        gray_to_bin = bin;
    endfunction

    // Write side logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
        end else if (winc && !wfull) begin
            mem[wptr[ASIZE-1:0]] <= wdata;
            wptr <= wptr + 1;
        end
    end

    // Write pointer to Gray code and synchronize to read clock
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            wptr_gray <= 0;
        else
            wptr_gray <= bin_to_gray(wptr);
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            wptr_gray_sync <= 0;
        else
            wptr_gray_sync <= wptr_gray;
    end

    // Read side logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
        end else if (rinc && !rempty) begin
            rptr <= rptr + 1;
        end
    end

    // Read pointer to Gray code and synchronize to write clock
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rptr_gray <= 0;
        else
            rptr_gray <= bin_to_gray(rptr);
    end

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            rptr_gray_sync <= 0;
        else
            rptr_gray_sync <= rptr_gray;
    end

    // Read data output
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rdata <= 0;
        else if (rinc && !rempty)
            rdata <= mem[rptr[ASIZE-1:0]];
    end

    // Full and almost full flags
    wire [AWIDTH-1:0] wptr_gray_sync_bin = gray_to_bin(wptr_gray_sync);
    wire [AWIDTH-1:0] rptr_gray_bin = gray_to_bin(rptr_gray);
    assign wfull = (wptr_gray_sync_bin[AWIDTH-1] != rptr_gray_bin[AWIDTH-1]) && (wptr_gray_sync_bin[AWIDTH-2:0] == rptr_gray_bin[AWIDTH-2:0] + 1);
    assign awfull = (wptr_gray_sync_bin[AWIDTH-1] != rptr_gray_bin[AWIDTH-1]) && (wptr_gray_sync_bin[AWIDTH-2:0] == rptr_gray_bin[AWIDTH-2:0] + 2);

    // Empty and almost empty flags
    wire [AWIDTH-1:0] wptr_gray_bin = gray_to_bin(wptr_gray);
    wire [AWIDTH-1:0] rptr_gray_sync_bin = gray_to_bin(rptr_gray_sync);
    assign rempty = (wptr_gray_bin[AWIDTH-1] == rptr_gray_sync_bin[AWIDTH-1]) && (wptr_gray_bin[AWIDTH-2:0] == rptr_gray_sync_bin[AWIDTH-2:0]);
    assign arempty = (wptr_gray_bin[AWIDTH-1] == rptr_gray_sync_bin[AWIDTH-1]) && (wptr_gray_bin[AWIDTH-2:0] == rptr_gray_sync_bin[AWIDTH-2:0] - 1);

endmodule
