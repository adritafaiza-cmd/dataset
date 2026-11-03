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

    localparam FIFO_SIZE = 2**ASIZE;

    reg [ASIZE:0] wptr, rptr;
    reg [ASIZE:0] wcount, rcount;
    reg [DSIZE-1:0] mem [0:FIFO_SIZE-1];

    // Write pointer and count logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wcount <= 0;
        end else begin
            if (winc && !wfull) begin
                mem[wptr] <= wdata;
                wptr <= wptr + 1;
                if (wptr == FIFO_SIZE) wptr <= 0;
                wcount <= wcount + 1;
            end
        end
    end

    // Read pointer and count logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rcount <= 0;
        end else begin
            if (rinc && !rempty) begin
                rptr <= rptr + 1;
                if (rptr == FIFO_SIZE) rptr <= 0;
                rcount <= rcount - 1;
            end
        end
    end

    // FIFO status flags
    assign wfull = (wcount == FIFO_SIZE);
    assign awfull = (wcount + 1 == FIFO_SIZE);
    assign rempty = (wcount == 0);
    assign arempty = (wcount == 1);

    // Read data logic
    assign rdata = mem[rptr];

endmodule
