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

    reg [ASIZE-1:0] wptr, rptr;
    reg [ASIZE-1:0] wptr_sync, rptr_sync;
    reg [DSIZE-1:0] mem [2**ASIZE-1:0];
    reg [ASIZE-1:0] wcnt, rcnt;
    reg wfull_reg, awfull_reg;
    reg rempty_reg, arempty_reg;

    assign wfull = wfull_reg;
    assign awfull = awfull_reg;
    assign rempty = rempty_reg;
    assign arempty = arempty_reg;

    always @(posedge wclk or negedge wrst_n) begin
        if (~wrst_n) begin
            wptr <= 0;
            wcnt <= 0;
            wfull_reg <= 0;
            awfull_reg <= 0;
        end else if (winc && ~wfull_reg) begin
            mem[wptr] <= wdata;
            wptr <= wptr + 1;
            wcnt <= wcnt + 1;
            if (wcnt == 2**ASIZE - 2) begin
                awfull_reg <= 1;
            end else if (wcnt == 2**ASIZE - 1) begin
                wfull_reg <= 1;
            end else begin
                wfull_reg <= 0;
                awfull_reg <= 0;
            end
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (~rrst_n) begin
            rptr <= 0;
            rcnt <= 0;
            rempty_reg <= 1;
            arempty_reg <= 1;
            rdata <= 0;
        end else if (rinc && ~rempty_reg) begin
            rdata <= mem[rptr];
            rptr <= rptr + 1;
            rcnt <= rcnt + 1;
            if (rcnt == 2**ASIZE - 1) begin
                rempty_reg <= 1;
            end else if (rcnt == 2**ASIZE) begin
                rcnt <= 0;
                rempty_reg <= 1;
            end else begin
                rempty_reg <= 0;
            end
        end else if (~rinc && rempty_reg) begin
            rdata <= 0;
        end
    end

    always @(posedge wclk) begin
        wptr_sync <= wptr;
    end

    always @(posedge rclk) begin
        rptr_sync <= rptr;
    end

    always @(posedge rclk) begin
        if (rptr_sync == wptr_sync) begin
            arempty_reg <= 1;
        end else begin
            arempty_reg <= 0;
        end
    end

    always @(posedge wclk) begin
        if (wptr_sync == rptr_sync + 2**ASIZE - 1) begin
            awfull_reg <= 1;
        end else begin
            awfull_reg <= 0;
        end
    end

endmodule
