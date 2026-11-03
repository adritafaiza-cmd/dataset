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
    reg [ASIZE-1:0] wptr_gray;
    reg [ASIZE-1:0] rptr_gray;
    reg [ASIZE-1:0] wptr_gray_sync;
    reg [ASIZE-1:0] rptr_gray_sync;
    reg [DSIZE-1:0] fifo [2**ASIZE-1:0];
    reg [DSIZE-1:0] rdata_reg;
    reg             wfull_reg;
    reg             awfull_reg;
    reg             rempty_reg;
    reg             arempty_reg;

    // Write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wptr_gray <= 0;
            wfull_reg <= 0;
            awfull_reg <= 0;
        end else if (winc && !wfull_reg) begin
            wptr <= wptr + 1;
            wptr_gray <= wptr_gray + 1;
            fifo[wptr[ASIZE-1:0]] <= wdata;
        end
    end

    always @(wptr) begin
        wptr_gray <= {wptr[ASIZE-1], wptr[ASIZE-2:0]} + wptr[ASIZE-1:0];
    end

    always @(posedge wclk) begin
        if (wptr[ASIZE-1:0] == (2**ASIZE - 1)) begin
            wfull_reg <= 1;
        end else if (wptr[ASIZE-1:0] == (2**ASIZE - 2)) begin
            awfull_reg <= 1;
        end else begin
            wfull_reg <= 0;
            awfull_reg <= 0;
        end
    end

    // Read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rptr_gray <= 0;
            rptr_gray_sync <= 0;
            rempty_reg <= 1;
            arempty_reg <= 1;
            rdata_reg <= 0;
        end else if (rinc && !rempty_reg) begin
            rptr <= rptr + 1;
            rptr_gray <= rptr_gray + 1;
            rdata_reg <= fifo[rptr[ASIZE-1:0]];
        end
    end

    always @(rptr) begin
        rptr_gray <= {rptr[ASIZE-1], rptr[ASIZE-2:0]} + rptr[ASIZE-1:0];
    end

    always @(posedge rclk) begin
        if (rptr[ASIZE-1:0] == 0) begin
            rempty_reg <= 1;
        end else begin
            rempty_reg <= 0;
        end
        if (rptr[ASIZE-1:0] == (2**(ASIZE-1) - 1)) begin
            arempty_reg <= 1;
        end else begin
            arempty_reg <= 0;
        end
    end

    // CDC
    always @(posedge wclk) begin
        wptr_gray_sync <= wptr_gray;
    end

    always @(posedge rclk) begin
        rptr_gray_sync <= rptr_gray_sync + 1;
        if (rptr_gray_sync == (2**ASIZE - 1)) begin
            rptr_gray_sync <= 0;
        end
    end

    assign wfull = wfull_reg;
    assign awfull = awfull_reg;
    assign rdata = (FALLTHROUGH == "TRUE") ? (rempty_reg ? fifo[rptr[ASIZE-1:0]] : rdata_reg) : rdata_reg;
    assign rempty = rempty_reg;
    assign arempty = arempty_reg;

endmodule
