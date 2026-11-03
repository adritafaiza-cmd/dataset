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

    localparam FIFO_DEPTH = 2**ASIZE;

    reg [ASIZE-1:0] wptr;
    reg [ASIZE-1:0] rptr;
    reg [FIFO_DEPTH-1:0][DSIZE-1:0] fifo;

    reg wfull_reg;
    reg awfull_reg;
    reg rempty_reg;
    reg arempty_reg;

    wire wclk_to_rclk_wptr;
    wire rclk_to_wclk_rptr;

    assign wfull = wfull_reg;
    assign awfull = awfull_reg;
    assign rempty = rempty_reg;
    assign arempty = arempty_reg;

    // Clock-domain crossing logic for write pointer
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
        end else begin
            if (winc && !wfull_reg) begin
                wptr <= wptr + 1;
            end
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wclk_to_rclk_wptr <= 0;
        end else begin
            wclk_to_rclk_wptr <= wptr;
        end
    end

    // Clock-domain crossing logic for read pointer
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
        end else begin
            if (rinc && !arempty_reg) begin
                rptr <= rptr + 1;
            end
        end
    end

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rclk_to_wclk_rptr <= 0;
        end else begin
            rclk_to_wclk_rptr <= rptr;
        end
    end

    // FIFO core logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wfull_reg <= 0;
            awfull_reg <= 0;
            fifo <= 0;
        end else begin
            if (winc && !wfull_reg && rclk_to_wclk_rptr != wptr) begin
                fifo[wptr] <= wdata;
            end
            wfull_reg <= (wptr == rclk_to_wclk_rptr);
            awfull_reg <= (wptr == (rclk_to_wclk_rptr + 1) % FIFO_DEPTH);
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rempty_reg <= 1;
            arempty_reg <= 1;
        end else begin
            rempty_reg <= (rptr == wclk_to_rclk_wptr);
            arempty_reg <= (rptr == ((wclk_to_rclk_wptr + 1) % FIFO_DEPTH));
        end
    end

    assign rdata = fifo[rclk_to_wclk_rptr];

endmodule
