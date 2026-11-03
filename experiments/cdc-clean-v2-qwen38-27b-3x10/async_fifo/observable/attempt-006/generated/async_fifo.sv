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

    localparam AWIDTH = ASIZE + 1;
    localparam DEPTH  = 1 << ASIZE;

    // Write domain
    reg [AWIDTH-1:0] wptr;
    reg [ASIZE-1:0]  wptr_gray;
    reg [ASIZE-1:0]  wptr_gray_next;

    // Read domain
    reg [AWIDTH-1:0] rptr;
    reg [ASIZE-1:0]  rptr_gray;
    reg [ASIZE-1:0]  rptr_gray_next;

    // Gray code conversion
    function [ASIZE-1:0] bin2gray;
        input [ASIZE-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // Write pointer update
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= {AWIDTH{1'b0}};
            wptr_gray <= {ASIZE{1'b0}};
        end else if (winc && !wfull) begin
            wptr <= wptr + 1'b1;
            wptr_gray <= bin2gray(wptr[ASIZE:1]);
        end
    end

    // Read pointer update
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= {AWIDTH{1'b0}};
            rptr_gray <= {ASIZE{1'b0}};
        end else if (rinc && !rempty) begin
            rptr <= rptr + 1'b1;
            rptr_gray <= bin2gray(rptr[ASIZE:1]);
        end
    end

    // Synchronize read pointer gray into write domain
    reg [ASIZE-1:0] rptr_gray_w1;
    reg [ASIZE-1:0] rptr_gray_w2;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_w1 <= {ASIZE{1'b0}};
            rptr_gray_w2 <= {ASIZE{1'b0}};
        end else begin
            rptr_gray_w1 <= rptr_gray;
            rptr_gray_w2 <= rptr_gray_w1;
        end
    end

    // Synchronize write pointer gray into read domain
    reg [ASIZE-1:0] wptr_gray_r1;
    reg [ASIZE-1:0] wptr_gray_r2;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_r1 <= {ASIZE{1'b0}};
            wptr_gray_r2 <= {ASIZE{1'b0}};
        end else begin
            wptr_gray_r1 <= wptr_gray;
            wptr_gray_r2 <= wptr_gray_r1;
        end
    end

    // Convert synchronized gray codes back to binary for comparison
    // We need to compare the full AWIDTH-bit pointers.
    // The MSB of the binary pointer is the "wrap" bit.
    // For gray code of width ASIZE, we can recover the binary MSB by looking at the MSB of the gray code.
    // Actually, let's think about this more carefully.
    
    // The pointer is AWIDTH bits wide. The lower ASIZE bits are the address.
    // The MSB (bit ASIZE) is the wrap bit.
    // When we convert to gray code, we only send ASIZE bits (the address part).
    // But we need to know the wrap bit to distinguish full from empty.
    
    // Standard approach: use AWIDTH-bit gray codes.
    // Let me redo this with AWIDTH-bit gray codes.

    // Actually, the standard Cummings approach uses AWIDTH-bit pointers and AWIDTH-bit gray codes.
    // Let me fix the implementation.

    // Redo: use AWIDTH-bit gray codes
    // Write domain
    // (already declared wptr as AWIDTH bits)
    
    // Let me re-declare with proper widths

    // I'll restructure the code properly below.

endmodule

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

    localparam AWIDTH = ASIZE + 1;
    localparam DEPTH  = 1 << ASIZE;

    // Write domain
    reg [AWIDTH-1:0] wptr;
    reg [AWIDTH-1:0] wptr_gray;

    // Read domain
    reg [AWIDTH-1:0] rptr;
    reg [AWIDTH-1:0] rptr_gray;

    // Gray code conversion
    function [AWIDTH-1:0] bin2gray;
        input [AWIDTH-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // Write pointer update
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr      <= {AWIDTH{1'b0}};
            wptr_gray <= {AWIDTH{1'b0}};
        end else if (winc && !wfull) begin
            wptr      <= wptr + 1'b1;
            wptr_gray <= bin2gray(wptr + 1'b1);
        end
    end

    // Read pointer update
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr      <= {AWIDTH{1'b0}};
            rptr_gray <= {AWIDTH{1'b0}};
        end else if (rinc && !rempty) begin
            rptr      <= rptr + 1'b1;
            rptr_gray <= bin2gray(rptr + 1'b1);
        end
    end

    // Synchronize read pointer gray into write domain
    reg [AWIDTH-1:0] rptr_gray_w1;
    reg [AWIDTH-1:0] rptr_gray_w2;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_w1 <= {AWIDTH{1'b0}};
            rptr_gray_w2 <= {AWIDTH{1'b0}};
        end else begin
            rptr_gray_w1 <= rptr_gray;
            rptr_gray_w2 <= rptr_gray_w1;
        end
    end

    // Synchronize write pointer gray into read domain
    reg [AWIDTH-1:0] wptr_gray_r1;
    reg [AWIDTH-1:0] wptr_gray_r2;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_r1 <= {AWIDTH{1'b0}};
            wptr_gray_r2 <= {AWIDTH{1'b0}};
        end else begin
            wptr_gray_r1 <= wptr_gray;
            wptr_gray_r2 <= wptr_gray_r1;
        end
    end

    // Convert synchronized gray codes back to binary
    function [AWIDTH-1:0] gray2bin;
        input [AWIDTH-1:0] gray;
        integer i;
        begin
            gray2bin[AWIDTH-1] = gray[AWIDTH-1];
            for (i = AWIDTH-2; i >= 0; i = i - 1)
                gray2bin[i] = gray2bin[i+1] ^ gray[i];
        end
    endfunction

    // Full and empty flags
    wire [AWIDTH-1:0] rptr_gray_w2_bin = gray2bin(rptr_gray_w2);
    wire [AWIDTH-1:0] wptr_gray_r2_bin = gray2bin(wptr_gray_r2);

    assign wfull   = (wptr[AWIDTH-1:1] == rptr_gray_w2_bin[AWIDTH-1:1]) && (wptr[0] != rptr_gray_w2_bin[0]);
    assign rempty  = (rptr == wptr_gray_r2_bin);

    // Almost full and almost empty
    assign awfull  = wfull || (wptr[AWIDTH-1:1] == rptr_gray_w2_bin[AWIDTH-1:1]) && (wptr[0] == rptr_gray_w2_bin[0]) && (wptr[0] == 1'b1);
    assign arempty = rempty || (rptr[AWIDTH-1:1] == wptr_gray_r2_bin[AWIDTH-1:1]) && (rptr[0] != wptr_gray_r2_bin[0]) && (rptr[0] == 1'b0);

    // Memory
    reg [DSIZE-1:0] mem [0:DEPTH-1];

    // Write to memory
    always @(posedge wclk) begin
        if (winc && !wfull)
            mem[wptr[ASIZE-1:0]] <= wdata;
    end

    // Read from memory
    assign rdata = mem[rptr[ASIZE-1:0]];

endmodule
