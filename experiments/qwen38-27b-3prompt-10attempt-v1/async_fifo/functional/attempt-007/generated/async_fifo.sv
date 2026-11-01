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

    localparam DEPTH = 1 << ASIZE;
    localparam AWFULL_THRESH = DEPTH - 2;
    localparam AEMPTY_THRESH = 1;

    // Write domain
    reg [ASIZE:0] wptr;
    reg [ASIZE:0] rptr_w;
    reg [DSIZE-1:0] mem [0:DEPTH-1];

    wire winc_eff = winc & ~wfull;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            wptr <= 0;
        else if (winc_eff)
            wptr <= wptr + 1;
    end

    always @(posedge wclk) begin
        if (winc_eff)
            mem[wptr[ASIZE-1:0]] <= wdata;
    end

    // Read domain
    reg [ASIZE:0] rptr;
    reg [ASIZE:0] wptr_r;
    reg [DSIZE-1:0] rdata_reg;

    wire rinc_eff = rinc & ~rempty;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rptr <= 0;
        else if (rinc_eff)
            rptr <= rptr + 1;
    end

    // Gray code conversion
    function [ASIZE:0] bin2gray;
        input [ASIZE:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // Write domain gray pointer
    wire [ASIZE:0] wptr_gray = bin2gray(wptr);

    // Read domain gray pointer
    wire [ASIZE:0] rptr_gray = bin2gray(rptr);

    // Synchronizers: wptr_gray to read domain
    reg [ASIZE:0] wptr_gray_r1, wptr_gray_r2;
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_r1 <= 0;
            wptr_gray_r2 <= 0;
        end else begin
            wptr_gray_r1 <= wptr_gray;
            wptr_gray_r2 <= wptr_gray_r1;
        end
    end

    // Synchronizers: rptr_gray to write domain
    reg [ASIZE:0] rptr_gray_w1, rptr_gray_w2;
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_w1 <= 0;
            rptr_gray_w2 <= 0;
        end else begin
            rptr_gray_w1 <= rptr_gray;
            rptr_gray_w2 <= rptr_gray_w1;
        end
    end

    // Gray to binary conversion
    function [ASIZE:0] gray2bin;
        input [ASIZE:0] gray;
        integer i;
        begin
            gray2bin[ASIZE] = gray[ASIZE];
            for (i = ASIZE-1; i >= 0; i = i-1)
                gray2bin[i] = gray[i] ^ gray2bin[i+1];
        end
    endfunction

    // Read domain: wptr in binary
    wire [ASIZE:0] wptr_r = gray2bin(wptr_gray_r2);

    // Write domain: rptr in binary
    wire [ASIZE:0] rptr_w = gray2bin(rptr_gray_w2);

    // Full and empty detection
    // Full: wptr and rptr differ in MSB and match in lower bits
    wire wfull = (wptr[ASIZE] != rptr_w[ASIZE]) && (wptr[ASIZE-1:0] == rptr_w[ASIZE-1:0]);
    wire rempty = (rptr == wptr_r);

    // Almost full: number of entries >= AWFULL_THRESH
    // Number of entries = wptr - rptr (mod 2^(ASIZE+1))
    wire [ASIZE:0] wcount = wptr - rptr_w;
    wire awfull = (wcount >= AWFULL_THRESH);

    // Almost empty: number of entries <= AEMPTY_THRESH
    wire [ASIZE:0] rcount = wptr_r - rptr;
    wire arempty = (rcount <= AEMPTY_THRESH);

    // Read data
    // If FALLTHROUGH, rdata is the current oldest unread word (combinational from memory)
    // Otherwise, rdata is registered
    reg [DSIZE-1:0] rdata_comb;
    wire [ASIZE-1:0] raddr = rptr[ASIZE-1:0];

    assign rdata_comb = mem[raddr];

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rdata_reg <= 0;
        else if (rinc_eff)
            rdata_reg <= mem[rptr[ASIZE-1:0]];
    end

    assign rdata = (FALLTHROUGH == "TRUE") ? rdata_comb : rdata_reg;

endmodule
