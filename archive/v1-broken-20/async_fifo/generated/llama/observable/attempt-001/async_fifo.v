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
    reg full, empty;

    assign wfull = full;
    assign awfull = (wcnt == (2**ASIZE - 2));
    assign rempty = empty;
    assign arempty = (rcnt == 0);

    always @(posedge wclk or negedge wrst_n) begin
        if (~wrst_n) begin
            wptr <= 0;
            wcnt <= 0;
            full <= 0;
        end else if (winc && !full) begin
            mem[wptr] <= wdata;
            wptr <= wptr + 1;
            wcnt <= wcnt + 1;
            if (wcnt == (2**ASIZE - 1)) begin
                full <= 1;
            end
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (~rrst_n) begin
            rptr <= 0;
            rcnt <= 0;
            empty <= 1;
        end else if (rinc && !empty) begin
            rdata <= mem[rptr];
            rptr <= rptr + 1;
            rcnt <= rcnt - 1;
            if (rcnt == 1) begin
                empty <= 1;
            end
        end
    end

    always @(posedge wclk) begin
        wptr_sync <= wptr;
    end

    always @(posedge rclk) begin
        rptr_sync <= rptr;
    end

    always @(posedge rclk) begin
        if (rptr_sync != wptr_sync) begin
            if (rptr_sync < wptr_sync) begin
                rcnt <= wptr_sync - rptr_sync;
            end else begin
                rcnt <= (2**ASIZE) + wptr_sync - rptr_sync;
            end
            empty <= (rcnt == 0);
        end
    end

    always @(posedge wclk) begin
        if (rptr_sync != wptr_sync) begin
            if (rptr_sync < wptr_sync) begin
                wcnt <= wptr_sync - rptr_sync;
            end else begin
                wcnt <= (2**ASIZE) + wptr_sync - rptr_sync;
            end
            full <= (wcnt == (2**ASIZE - 1));
        end
    end

endmodule
