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
    reg [DSIZE-1:0] mem [2**ASIZE-1:0];
    reg [ASIZE-1:0] wcount;
    reg [ASIZE-1:0] wcount_sync;
    reg [ASIZE-1:0] rcount;
    reg [ASIZE-1:0] rcount_sync;

    assign wfull = (wcount == (2**ASIZE - 1));
    assign awfull = (wcount >= (2**ASIZE - 2));
    assign rempty = (rcount == 0);
    assign arempty = (rcount <= 1);

    always @(posedge wclk or negedge wrst_n) begin
        if (~wrst_n) begin
            wptr <= 0;
            wcount <= 0;
        end else if (winc && ~wfull) begin
            mem[wptr] <= wdata;
            wptr <= wptr + 1;
            wcount <= wcount + 1;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (~rrst_n) begin
            rptr <= 0;
            rcount <= 0;
        end else if (rinc && ~rempty) begin
            rdata <= mem[rptr];
            rptr <= rptr + 1;
            rcount <= rcount - 1;
        end
    end

    always @(posedge wclk) begin
        wptr_sync <= wptr;
    end

    always @(posedge rclk) begin
        rptr_sync <= rptr;
        wcount_sync <= wcount;
        rcount_sync <= rcount;
    end

    always @(posedge rclk) begin
        if (wcount_sync > rcount_sync) begin
            rcount <= wcount_sync - rcount_sync;
        end
    end

    always @(posedge wclk) begin
        if (rcount_sync < wcount) begin
            wcount <= wcount - rcount_sync;
        end
    end

endmodule
