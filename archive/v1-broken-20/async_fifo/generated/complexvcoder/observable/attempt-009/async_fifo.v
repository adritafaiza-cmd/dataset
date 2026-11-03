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

    // FIFO memory
    reg [DSIZE-1:0] mem [0:(2**ASIZE)-1];
    reg [ASIZE:0] wptr, rptr;
    reg [ASIZE:0] wnext, rnext;
    reg wfull_reg, rempty_reg;

    // FIFO control
    reg awfull_reg, arempty_reg;

    // Write logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wfull_reg <= 0;
        end else begin
            if (winc && !wfull_reg) begin
                mem[wptr] <= wdata;
                wptr <= wptr + 1;
                wfull_reg <= (wptr == rptr);
            end
        end
    end

    // Read logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rempty_reg <= 1;
        end else begin
            if (rinc && !rempty_reg) begin
                rptr <= rptr + 1;
                rempty_reg <= (rptr == wptr);
            end
        end
    end

    // Next pointer calculation
    always @(*) begin
        wnext = wptr + 1;
        if (wnext == (2**ASIZE)) wnext = 0;
        rnext = rptr + 1;
        if (rnext == (2**ASIZE)) rnext = 0;
    end

    // Almost full/empty flags
    assign awfull_reg = (wnext == rptr);
    assign arempty_reg = (wptr == rnext);

    // Full/empty flags
    assign wfull = wfull_reg;
    assign rempty = rempty_reg;

    // Almost full/empty outputs
    assign awfull = awfull_reg;
    assign arempty = arempty_reg;

    // Data output
    assign rdata = mem[rptr];

endmodule
