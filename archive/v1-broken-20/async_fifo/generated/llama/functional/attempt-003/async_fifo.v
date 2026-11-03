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

    reg [DSIZE-1:0] mem [0:2**ASIZE-1];
    reg [ASIZE-1:0] wptr, rptr;
    reg [ASIZE-1:0] wptr_gray, rptr_gray;
    reg [ASIZE-1:0] wptr_bin, rptr_bin;
    reg [ASIZE-1:0] wptr_sync, rptr_sync;
    reg [ASIZE:0] wcount, rcount;
    reg wfull_reg, awfull_reg, rempty_reg, arempty_reg;
    reg [DSIZE-1:0] rdata_reg;

    assign wfull = wfull_reg;
    assign awfull = awfull_reg;
    assign rempty = rempty_reg;
    assign arempty = arempty_reg;
    assign rdata = rdata_reg;

    always @(posedge wclk or negedge wrst_n)
    begin
        if (~wrst_n)
        begin
            wptr <= 0;
            wptr_gray <= 0;
            wptr_bin <= 0;
            wcount <= 0;
            wfull_reg <= 0;
            awfull_reg <= 0;
        end
        else if (winc && ~wfull_reg)
        begin
            mem[wptr] <= wdata;
            wptr <= wptr + 1;
            wptr_gray <= {wptr[ASIZE-2:0], wptr[ASIZE-1]};
            wptr_bin <= wptr;
            wcount <= wcount + 1;
            if (wcount == 2**ASIZE - 2)
                awfull_reg <= 1;
            if (wcount == 2**ASIZE - 1)
                wfull_reg <= 1;
        end
    end

    always @(posedge rclk or negedge rrst_n)
    begin
        if (~rrst_n)
        begin
            rptr <= 0;
            rptr_gray <= 0;
            rptr_bin <= 0;
            rcount <= 0;
            rempty_reg <= 1;
            arempty_reg <= 1;
            rdata_reg <= 0;
        end
        else if (rinc && ~rempty_reg)
        begin
            rdata_reg <= mem[rptr];
            rptr <= rptr + 1;
            rptr_gray <= {rptr[ASIZE-2:0], rptr[ASIZE-1]};
            rptr_bin <= rptr;
            rcount <= rcount + 1;
            if (rcount == 1)
                arempty_reg <= 0;
            if (rcount == 2)
                rempty_reg <= 0;
        end
        else if (FALLTHROUGH == "TRUE" && ~rempty_reg && rptr_bin == wptr_bin)
        begin
            rdata_reg <= mem[rptr];
        end
    end

    always @(posedge wclk)
    begin
        wptr_sync <= wptr_gray;
    end

    always @(posedge rclk)
    begin
        rptr_sync <= rptr_gray;
    end

    always @(posedge wclk)
    begin
        if (wptr_sync == rptr_sync)
        begin
            if (wcount > rcount)
                rempty_reg <= 0;
            else
                rempty_reg <= 1;
            if (wcount > rcount + 1)
                arempty_reg <= 0;
            else
                arempty_reg <= 1;
        end
    end

endmodule
