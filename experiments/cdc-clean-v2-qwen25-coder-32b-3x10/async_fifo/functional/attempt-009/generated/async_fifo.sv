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
    reg [ASIZE:0] rptr_gray_synced, wptr_gray_synced;

    // Write domain logic
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

    // Read domain logic
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
        if (!wrst_n)
            rptr_gray_synced <= 0;
        else
            rptr_gray_synced <= rptr_gray;
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            wptr_gray_synced <= 0;
        else
            wptr_gray_synced <= wptr_gray;
    end

    // Binary conversion
    reg [ASIZE:0] rptr_bin_synced;
    reg [ASIZE:0] wptr_bin_synced;

    integer i;
    always @(*) begin
        rptr_bin_synced = 0;
        for (i = 0; i <= ASIZE; i = i + 1)
            rptr_bin_synced[i] = rptr_gray_synced[i] ^ rptr_bin_synced[i-1];

        wptr_bin_synced = 0;
        for (i = 0; i <= ASIZE; i = i + 1)
            wptr_bin_synced[i] = wptr_gray_synced[i] ^ wptr_bin_synced[i-1];
    end

    // FIFO status flags
    assign wfull = (wptr_bin_synced == {1'b1, rptr[ASIZE-1:0]});
    assign awfull = (wptr_bin_synced == {1'b0, {ASIZE{1'b1}}} & rptr[ASIZE-1:0]);
    assign rempty = (rptr_bin_synced == wptr_gray_synced);
    assign arempty = (rptr_bin_synced == (wptr_gray_synced + 1) & {ASIZE{1'b1}});

    // Read data output
    reg [DSIZE-1:0] rdata_reg;
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rdata_reg <= 0;
        else if (rinc && !rempty)
            rdata_reg <= mem[rptr[ASIZE-1:0]];
        else if (FALLTHROUGH && !rempty)
            rdata_reg <= mem[rptr[ASIZE-1:0]];
    end

    assign rdata = rdata_reg;

endmodule
