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
    reg [ASIZE-1:0] wptr_bin;
    reg [ASIZE-1:0] rptr_bin;
    reg [ASIZE:0]    wcnt;
    reg [ASIZE:0]    rcnt;
    reg [DSIZE-1:0]  mem [2**ASIZE-1:0];
    reg [DSIZE-1:0]  rdata_reg;

    assign wfull = (wcnt == (1 << ASIZE));
    assign awfull = (wcnt >= (1 << ASIZE) - 2);
    assign rempty = (rcnt == 0);
    assign arempty = (rcnt <= 2);

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wcnt <= 0;
        end else if (winc && !wfull) begin
            wptr <= wptr + 1;
            wcnt <= wcnt + 1;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rcnt <= 0;
        end else if (rinc && !rempty) begin
            rptr <= rptr + 1;
            rcnt <= rcnt - 1;
        end
    end

    always @(posedge wclk) begin
        if (winc && !wfull) begin
            mem[wptr] <= wdata;
        end
    end

    always @(posedge rclk) begin
        if (FALLTHROUGH == "TRUE") begin
            rdata_reg <= mem[rptr];
        end
        if (rinc && !rempty) begin
            rdata_reg <= mem[rptr];
        end
    end

    assign rdata = rdata_reg;

    // Gray code conversion
    always @(wptr) begin
        wptr_gray <= {wptr[ASIZE-1], wptr[ASIZE-2:0]} ^ wptr;
    end

    always @(rptr) begin
        rptr_gray <= {rptr[ASIZE-1], rptr[ASIZE-2:0]} ^ rptr;
    end

    // Binary to gray synchronization
    reg [ASIZE-1:0] wptr_sync;
    reg [ASIZE-1:0] rptr_sync;

    always @(posedge rclk) begin
        wptr_sync <= wptr_gray;
    end

    always @(posedge wclk) begin
        rptr_sync <= rptr_gray;
    end

    // Counters synchronization
    reg [ASIZE:0] wcnt_sync;
    reg [ASIZE:0] rcnt_sync;

    always @(posedge rclk) begin
        wcnt_sync <= wcnt;
    end

    always @(posedge wclk) begin
        rcnt_sync <= rcnt;
    end

    // Empty and full flags synchronization
    reg wfull_sync;
    reg awfull_sync;
    reg rempty_sync;
    reg arempty_sync;

    always @(posedge rclk) begin
        wfull_sync <= wfull;
        awfull_sync <= awfull;
    end

    always @(posedge wclk) begin
        rempty_sync <= rempty;
        arempty_sync <= arempty;
    end

    assign wfull = wfull_sync;
    assign awfull = awfull_sync;
    assign rempty = rempty_sync;
    assign arempty = arempty_sync;

endmodule
