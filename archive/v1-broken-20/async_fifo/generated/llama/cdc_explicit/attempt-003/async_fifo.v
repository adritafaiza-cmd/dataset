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
    reg [DSIZE-1:0] fifo [2**ASIZE-1:0];
    reg [DSIZE-1:0] rdata_reg;
    reg             wfull_reg;
    reg             awfull_reg;
    reg             rempty_reg;
    reg             arempty_reg;

    // Write Domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wfull_reg <= 1'b0;
            awfull_reg <= 1'b0;
        end else if (winc && !wfull_reg) begin
            fifo[wptr] <= wdata;
            wptr <= wptr + 1;
            if (wptr == (2**ASIZE - 1)) begin
                wptr <= 0;
            end
            if (wptr == (2**ASIZE - 2)) begin
                awfull_reg <= 1'b1;
            end else begin
                awfull_reg <= 1'b0;
            end
            if (wptr == (2**ASIZE - 1)) begin
                wfull_reg <= 1'b1;
            end else begin
                wfull_reg <= 1'b0;
            end
        end
    end

    // Read Domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rptr_sync <= 0;
            rempty_reg <= 1'b1;
            arempty_reg <= 1'b1;
            rdata_reg <= 0;
        end else begin
            if (rinc && !rempty_reg) begin
                rdata_reg <= fifo[rptr];
                rptr <= rptr + 1;
                if (rptr == (2**ASIZE - 1)) begin
                    rptr <= 0;
                end
                if (rptr == 1) begin
                    arempty_reg <= 1'b1;
                end else begin
                    arempty_reg <= 1'b0;
                end
                if (rptr == 0) begin
                    rempty_reg <= 1'b1;
                end else begin
                    rempty_reg <= 1'b0;
                end
            end
            if (FALLTHROUGH == "TRUE" && !rempty_reg) begin
                rdata_reg <= fifo[rptr];
            end
        end
    end

    // Synchronization
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_sync <= 0;
        end else begin
            wptr_sync <= wptr;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_sync <= 0;
        end else begin
            rptr_sync <= rptr;
        end
    end

    assign wfull = wfull_reg;
    assign awfull = awfull_reg;
    assign rdata = rdata_reg;
    assign rempty = rempty_reg;
    assign arempty = arempty_reg;

endmodule
