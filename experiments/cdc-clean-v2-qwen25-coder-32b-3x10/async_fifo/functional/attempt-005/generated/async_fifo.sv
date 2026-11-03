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

    reg [DSIZE-1:0] mem [0:DEPTH-1];
    reg [ASIZE:0] wptr, rptr;
    reg [ASIZE:0] wptr_gray, rptr_gray;
    reg [ASIZE:0] rptr_gray_sync_w, wptr_gray_sync_r;

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
            rptr_gray_sync_w <= 0;
        else
            rptr_gray_sync_w <= rptr_gray;
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            wptr_gray_sync_r <= 0;
        else
            wptr_gray_sync_r <= wptr_gray;
    end

    // Calculate full and almost full
    wire [ASIZE:0] wptr_bin_sync_r;
    wire [ASIZE:0] rptr_bin_sync_w;

    assign wptr_bin_sync_r = {wptr_gray_sync_r[ASIZE], wptr_gray_sync_r[ASIZE-1:0] ^ (wptr_gray_sync_r >> 1)};
    assign rptr_bin_sync_w = {rptr_gray_sync_w[ASIZE], rptr_gray_sync_w[ASIZE-1:0] ^ (rptr_gray_sync_w >> 1)};

    assign wfull = (wptr_bin_sync_r[ASIZE:0] == {rptr_bin_sync_w[ASIZE:0] + 1});
    assign awfull = (wptr_bin_sync_r[ASIZE:0] == {rptr_bin_sync_w[ASIZE:0] + AWATERMARK});

    // Calculate empty and almost empty
    wire [ASIZE:0] wptr_bin_sync_w;
    wire [ASIZE:0] rptr_bin_sync_r;

    assign wptr_bin_sync_w = {wptr_gray_sync_w[ASIZE], wptr_gray_sync_w[ASIZE-1:0] ^ (wptr_gray_sync_w >> 1)};
    assign rptr_bin_sync_r = {rptr_gray_sync_r[ASIZE], rptr_gray_sync_r[ASIZE-1:0] ^ (rptr_gray_sync_r >> 1)};

    assign rempty = (wptr_bin_sync_w[ASIZE:0] == rptr_bin_sync_r[ASIZE:0]);
    assign arempty = (wptr_bin_sync_w[ASIZE:0] == {rptr_bin_sync_r[ASIZE:0] + EWATERMARK});

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
