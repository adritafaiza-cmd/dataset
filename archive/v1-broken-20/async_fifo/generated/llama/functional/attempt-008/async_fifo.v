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

    reg [DSIZE-1:0] fifo [2**ASIZE-1:0];
    reg [ASIZE-1:0] wptr, rptr;
    reg [ASIZE-1:0] wptr_gray, rptr_gray;
    reg [ASIZE-1:0] wptr_bin, rptr_bin;
    reg [ASIZE-1:0] wptr_sync, rptr_sync;
    reg [ASIZE:0] count;
    reg [ASIZE:0] count_sync;
    reg wfull_reg, awfull_reg;
    reg rempty_reg, arempty_reg;

    assign wfull = wfull_reg;
    assign awfull = awfull_reg;
    assign rempty = rempty_reg;
    assign arempty = arempty_reg;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wptr_gray <= 0;
            wptr_bin <= 0;
            wfull_reg <= 0;
            awfull_reg <= 0;
            count <= 0;
        end else if (winc && !wfull_reg) begin
            fifo[wptr] <= wdata;
            wptr <= wptr + 1;
            wptr_gray <= (wptr + 1) ^ ((wptr + 1) >> 1);
            wptr_bin <= wptr_bin + 1;
            count <= count + 1;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rptr_gray <= 0;
            rptr_bin <= 0;
            rempty_reg <= 1;
            arempty_reg <= 1;
            count_sync <= 0;
        end else if (rinc && !rempty_reg) begin
            if (FALLTHROUGH == "TRUE") begin
                rdata <= fifo[rptr];
            end
            rptr <= rptr + 1;
            rptr_gray <= (rptr + 1) ^ ((rptr + 1) >> 1);
            rptr_bin <= rptr_bin + 1;
            count_sync <= count_sync - 1;
        end
    end

    always @(posedge wclk) begin
        wptr_sync <= wptr_bin;
    end

    always @(posedge rclk) begin
        rptr_sync <= rptr_bin;
    end

    always @(posedge wclk) begin
        if (count >= (2**ASIZE - 2)) begin
            awfull_reg <= 1;
        end else begin
            awfull_reg <= 0;
        end
        if (count >= (2**ASIZE - 1)) begin
            wfull_reg <= 1;
        end else begin
            wfull_reg <= 0;
        end
    end

    always @(posedge rclk) begin
        if (count_sync <= 2) begin
            arempty_reg <= 1;
        end else begin
            arempty_reg <= 0;
        end
        if (count_sync <= 1) begin
            rempty_reg <= 1;
        end else begin
            rempty_reg <= 0;
        end
    end

    always @(posedge rclk) begin
        if (FALLTHROUGH == "TRUE" && !rempty_reg) begin
            rdata <= fifo[rptr];
        end
    end

endmodule
