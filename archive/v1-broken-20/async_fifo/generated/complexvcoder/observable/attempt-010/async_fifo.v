`timescale 1ns / 1ps

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

    parameter FIFO_SIZE = 2**ASIZE;
    parameter FIFO_MASK = FIFO_SIZE - 1;

    reg [DSIZE-1:0] mem [0:FIFO_SIZE-1];
    reg [ASIZE-1:0] wptr, rptr;
    reg [ASIZE-1:0] wcnt, rcnt;

    wire [ASIZE-1:0] next_wptr, next_rptr;
    wire [ASIZE-1:0] next_wcnt, next_rcnt;
    wire wready, rready;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wcnt <= 0;
        end else begin
            wptr <= next_wptr;
            wcnt <= next_wcnt;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rcnt <= 0;
        end else begin
            rptr <= next_rptr;
            rcnt <= next_rcnt;
        end
    end

    always @(*) begin
        next_wptr = wptr;
        next_wcnt = wcnt;
        next_rptr = rptr;
        next_rcnt = rcnt;
        wready = 1;
        rready = 1;

        if (winc && !wfull) begin
            mem[wptr] = wdata;
            next_wptr = (wptr + 1) & FIFO_MASK;
            next_wcnt = wcnt + 1;
        end

        if (rinc && !rempty) begin
            next_rptr = (rptr + 1) & FIFO_MASK;
            next_rcnt = rcnt - 1;
        end

        wfull = (wcnt == FIFO_SIZE);
        awfull = (wcnt == FIFO_SIZE - 1);
        rempty = (rcnt == 0);
        arempty = (rcnt == 1);

        if (FALLTHROUGH == "TRUE") begin
            if (wcnt == 0 && rinc) begin
                rdata = mem[rptr];
            end else begin
                rdata = mem[rptr];
            end
        end else begin
            rdata = mem[rptr];
        end
    end

endmodule
