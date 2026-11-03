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
    localparam AWATERMARK = DEPTH - 2;
    localparam EWATERMARK = 1;

    reg [DSIZE-1:0] mem [DEPTH-1:0];

    reg [ASIZE:0] wptr, rptr;
    reg [ASIZE:0] wptr_gray, rptr_gray;
    reg [ASIZE:0] rptr_gray_sync1, rptr_gray_sync2;
    reg [ASIZE:0] wptr_gray_sync1, wptr_gray_sync2;

    // Write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wptr_gray <= 0;
        end else if (winc && !wfull) begin
            mem[wptr[ASIZE-1:0]] <= wdata;
            wptr <= wptr + 1;
            wptr_gray <= (wptr + 1) ^ ((wptr + 1) >> 1);
        end
    end

    // Read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rptr_gray <= 0;
        end else if (rinc && !rempty) begin
            rptr <= rptr + 1;
            rptr_gray <= (rptr + 1) ^ ((rptr + 1) >> 1);
        end
    end

    // Gray code synchronization
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_sync1 <= 0;
            rptr_gray_sync2 <= 0;
        end else begin
            rptr_gray_sync1 <= rptr_gray;
            rptr_gray_sync2 <= rptr_gray_sync1;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_sync1 <= 0;
            wptr_gray_sync2 <= 0;
        end else begin
            wptr_gray_sync1 <= wptr_gray;
            wptr_gray_sync2 <= wptr_gray_sync1;
        end
    end

    // Binary conversion
    wire [ASIZE:0] rptr_bin_sync;
    wire [ASIZE:0] wptr_bin_sync;

    integer i;
    always @(*) begin
        rptr_bin_sync = 0;
        for (i = 0; i <= ASIZE; i = i + 1) begin
            rptr_bin_sync[i] = rptr_gray_sync2[i] ^ rptr_bin_sync[i-1];
        end
    end

    always @(*) begin
        wptr_bin_sync = 0;
        for (i = 0; i <= ASIZE; i = i + 1) begin
            wptr_bin_sync[i] = wptr_gray_sync2[i] ^ wptr_bin_sync[i-1];
        end
    end

    // FIFO status
    wire [ASIZE:0] wptr_gray_sync2_bin;
    wire [ASIZE:0] rptr_gray_sync2_bin;

    always @(*) begin
        wptr_gray_sync2_bin = 0;
        for (i = 0; i <= ASIZE; i = i + 1) begin
            wptr_gray_sync2_bin[i] = wptr_gray_sync2[i] ^ wptr_gray_sync2_bin[i-1];
        end
    end

    always @(*) begin
        rptr_gray_sync2_bin = 0;
        for (i = 0; i <= ASIZE; i = i + 1) begin
            rptr_gray_sync2_bin[i] = rptr_gray_sync2[i] ^ rptr_gray_sync2_bin[i-1];
        end
    end

    assign wfull = (wptr_gray_sync2_bin == {1'b1, rptr_gray_sync2[ASIZE-1:0]});
    assign awfull = (wptr_gray_sync2_bin == {1'b0, {ASIZE{1'b1}}} ^ (rptr_gray_sync2 >> 1));
    assign rempty = (rptr_gray_sync2_bin == wptr_gray_sync2);
    assign arempty = (rptr_gray_sync2_bin == (wptr_gray_sync2 ^ (1 << ASIZE)));

    // Read data output
    reg [DSIZE-1:0] rdata_reg;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata_reg <= 0;
        end else if (rinc && !rempty) begin
            rdata_reg <= mem[rptr[ASIZE-1:0]];
        end else if (FALLTHROUGH == "TRUE" && !rempty) begin
            rdata_reg <= mem[rptr[ASIZE-1:0]];
        end
    end

    assign rdata = rdata_reg;

endmodule
