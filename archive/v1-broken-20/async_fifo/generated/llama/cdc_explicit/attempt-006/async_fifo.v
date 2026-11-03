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

    reg [ASIZE-1:0] wptr;
    reg [ASIZE-1:0] rptr;
    reg [ASIZE-1:0] wptr_sync;
    reg [ASIZE-1:0] rptr_sync;
    reg [ASIZE-1:0] wptr_gray;
    reg [ASIZE-1:0] rptr_gray;
    reg [ASIZE-1:0] wptr_gray_sync;
    reg [ASIZE-1:0] rptr_gray_sync;
    reg [DSIZE-1:0] fifo [2**ASIZE-1:0];
    reg [ASIZE-1:0] wcount;
    reg [ASIZE-1:0] wcount_sync;
    reg [ASIZE-1:0] rcount;
    reg [ASIZE-1:0] rcount_sync;
    reg [ASIZE-1:0] wcount_gray;
    reg [ASIZE-1:0] wcount_gray_sync;
    reg [ASIZE-1:0] rcount_gray;
    reg [ASIZE-1:0] rcount_gray_sync;
    reg wfull_reg;
    reg awfull_reg;
    reg rempty_reg;
    reg arempty_reg;

    assign wfull = wfull_reg;
    assign awfull = awfull_reg;
    assign rempty = rempty_reg;
    assign arempty = arempty_reg;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wcount <= 0;
            wfull_reg <= 0;
            awfull_reg <= 0;
        end else if (winc && !wfull_reg) begin
            fifo[wptr] <= wdata;
            wptr <= wptr + 1;
            wcount <= wcount + 1;
            if (wcount == (2**ASIZE - 2)) begin
                awfull_reg <= 1;
            end else begin
                awfull_reg <= 0;
            end
            if (wcount == (2**ASIZE - 1)) begin
                wfull_reg <= 1;
            end else begin
                wfull_reg <= 0;
            end
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rcount <= 0;
            rempty_reg <= 1;
            arempty_reg <= 1;
        end else if (rinc && !rempty_reg) begin
            rdata <= fifo[rptr];
            rptr <= rptr + 1;
            rcount <= rcount + 1;
            if (rcount == 2) begin
                arempty_reg <= 0;
            end else begin
                arempty_reg <= 1;
            end
            if (rcount == (2**ASIZE)) begin
                rempty_reg <= 1;
            end else begin
                rempty_reg <= 0;
            end
        end
    end

    // Gray encoding
    always @(wptr) begin
        wptr_gray <= (wptr >> 1) ^ wptr;
    end

    always @(rptr) begin
        rptr_gray <= (rptr >> 1) ^ rptr;
    end

    always @(wcount) begin
        wcount_gray <= (wcount >> 1) ^ wcount;
    end

    always @(rcount) begin
        rcount_gray <= (rcount >> 1) ^ rcount;
    end

    // Synchronization
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_sync <= 0;
            wcount_sync <= 0;
            wptr_gray_sync <= 0;
            wcount_gray_sync <= 0;
        end else begin
            wptr_sync <= wptr;
            wcount_sync <= wcount;
            wptr_gray_sync <= wptr_gray;
            wcount_gray_sync <= wcount_gray;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_sync <= 0;
            rcount_sync <= 0;
            rptr_gray_sync <= 0;
            rcount_gray_sync <= 0;
        end else begin
            rptr_sync <= rptr;
            rcount_sync <= rcount;
            rptr_gray_sync <= rptr_gray;
            rcount_gray_sync <= rcount_gray;
        end
    end

    // Fall-through
    always @(posedge rclk or negedge rrst_n) begin
        if (FALLTHROUGH == "TRUE" && !rempty_reg) begin
            rdata <= fifo[rptr];
        end
    end

endmodule
