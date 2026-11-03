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

    reg [DSIZE-1:0] mem [2**ASIZE-1:0];
    reg [ASIZE-1:0] wptr;
    reg [ASIZE-1:0] rptr;
    reg [ASIZE-1:0] wptr_sync;
    reg [ASIZE-1:0] rptr_sync;
    reg [ASIZE-1:0] wptr_gray;
    reg [ASIZE-1:0] rptr_gray;
    reg [ASIZE-1:0] wptr_gray_sync;
    reg [ASIZE-1:0] rptr_gray_sync;
    reg full;
    reg empty;
    reg almost_full;
    reg almost_empty;

    assign wfull = full;
    assign awfull = almost_full;
    assign rempty = empty;
    assign arempty = almost_empty;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wptr_gray <= 0;
        end else if (winc && !full) begin
            wptr <= wptr + 1;
            wptr_gray <= wptr_gray + 1;
            mem[wptr] <= wdata;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rptr_gray <= 0;
        end else if (rinc && !empty) begin
            rptr <= rptr + 1;
            rptr_gray <= rptr_gray + 1;
        end
    end

    always @(posedge wclk) begin
        wptr_sync <= wptr;
        wptr_gray_sync <= wptr_gray;
    end

    always @(posedge rclk) begin
        rptr_sync <= rptr;
        rptr_gray_sync <= rptr_gray;
    end

    always @(posedge wclk) begin
        if (wptr_gray_sync == (2**ASIZE - 1)) begin
            full <= 1;
        end else if (wptr_gray_sync == rptr_gray_sync) begin
            full <= 0;
        end
    end

    always @(posedge rclk) begin
        if (rptr_gray_sync == wptr_gray_sync) begin
            empty <= 1;
        end else if (rptr_gray_sync == (2**ASIZE - 1)) begin
            empty <= 0;
        end
    end

    always @(posedge wclk) begin
        if (wptr_gray_sync == (2**ASIZE - 2)) begin
            almost_full <= 1;
        end else if (wptr_gray_sync == rptr_gray_sync) begin
            almost_full <= 0;
        end
    end

    always @(posedge rclk) begin
        if (rptr_gray_sync == wptr_gray_sync + 1) begin
            almost_empty <= 1;
        end else if (rptr_gray_sync == (2**ASIZE - 1)) begin
            almost_empty <= 0;
        end
    end

    always @(posedge rclk) begin
        if (FALLTHROUGH == "TRUE") begin
            rdata <= mem[rptr];
        end else if (!empty) begin
            rdata <= mem[rptr];
        end
    end

endmodule
