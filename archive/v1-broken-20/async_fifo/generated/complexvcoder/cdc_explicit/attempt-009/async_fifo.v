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

    localparam FIFO_SIZE = 1 << ASIZE;
    localparam FIFO_HALF_SIZE = FIFO_SIZE >> 1;

    reg [ASIZE-1:0] wptr_reg, rptr_reg;
    reg [ASIZE-1:0] wptr_next, rptr_next;
    reg [FIFO_SIZE-1:0] fifo;
    reg wfull_reg, awfull_reg, rempty_reg, arempty_reg;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_reg <= 0;
            wfull_reg <= 0;
            awfull_reg <= 0;
        end else begin
            wptr_reg <= wptr_next;
            wfull_reg <= (wptr_reg == rptr_reg + FIFO_SIZE - 1);
            awfull_reg <= (wptr_reg == rptr_reg + FIFO_HALF_SIZE - 1);
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_reg <= 0;
            rempty_reg <= 1;
            arempty_reg <= 1;
        end else begin
            rptr_reg <= rptr_next;
            rempty_reg <= (wptr_reg == rptr_reg);
            arempty_reg <= (wptr_reg == rptr_reg + FIFO_HALF_SIZE);
        end
    end

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_next <= 0;
        end else if (winc && !wfull_reg) begin
            wptr_next <= wptr_reg + 1;
        end else begin
            wptr_next <= wptr_reg;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_next <= 0;
        end else if (rinc && !rempty_reg) begin
            rptr_next <= rptr_reg + 1;
        end else begin
            rptr_next <= rptr_reg;
        end
    end

    assign wfull = wfull_reg;
    assign awfull = awfull_reg;
    assign rempty = rempty_reg;
    assign arempty = arempty_reg;

    assign rdata = (FALLTHROUGH == "TRUE") ? fifo[rptr_reg] : fifo[rptr_next];

endmodule
