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
    reg [ASIZE-1:0] wptr_sync;
    reg [ASIZE-1:0] rptr_sync;
    reg [DSIZE-1:0] mem [2**ASIZE-1:0];
    reg [ASIZE-1:0] wcount;
    reg [ASIZE-1:0] wcount_sync;
    reg [ASIZE-1:0] rcount;
    reg [ASIZE-1:0] rcount_sync;

    assign wfull = (wcount == (2**ASIZE)-1);
    assign awfull = (wcount >= (2**ASIZE)-2);
    assign rempty = (rcount == 0);
    assign arempty = (rcount <= 1);
    assign rdata = (FALLTHROUGH == "TRUE" && rempty) ? wdata : mem[rptr];

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wcount <= 0;
            wptr_gray <= 0;
        end else if (winc && !wfull) begin
            wptr <= wptr + 1;
            wcount <= wcount + 1;
            mem[wptr] <= wdata;
        end
    end

    always @(posedge wclk) begin
        wptr_gray <= {wptr[ASIZE-2:0], wptr[ASIZE-1]};
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rcount <= 0;
            rptr_gray <= 0;
        end else if (rinc && !rempty) begin
            rptr <= rptr + 1;
            rcount <= rcount - 1;
        end
    end

    always @(posedge rclk) begin
        rptr_gray <= {rptr[ASIZE-2:0], rptr[ASIZE-1]};
    end

    always @(posedge wclk) begin
        wptr_sync <= wptr_gray;
    end

    always @(posedge rclk) begin
        rptr_sync <= rptr_gray;
    end

    always @(posedge wclk) begin
        wcount_sync <= wcount;
    end

    always @(posedge rclk) begin
        rcount_sync <= rcount;
    end

    always @(posedge rclk) begin
        if (wptr_sync != rptr_sync) begin
            rcount <= wcount_sync - rcount_sync;
        end
    end

endmodule
