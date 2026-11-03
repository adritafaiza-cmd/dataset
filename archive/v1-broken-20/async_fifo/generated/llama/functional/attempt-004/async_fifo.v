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
    reg [ASIZE-1:0] wptr_bin;
    reg [ASIZE-1:0] rptr_bin;
    reg [DSIZE-1:0] fifo [2**ASIZE-1:0];
    reg [ASIZE-1:0] wcnt;
    reg [ASIZE-1:0] rcnt;
    reg [ASIZE-1:0] wcnt_gray;
    reg [ASIZE-1:0] rcnt_gray;
    reg [DSIZE-1:0] rdata_reg;

    assign wfull = (wcnt == (2**ASIZE - 1));
    assign awfull = (wcnt >= (2**ASIZE - 2));
    assign rempty = (rcnt == 0);
    assign arempty = (rcnt <= 2);

    always @(posedge wclk or negedge wrst_n) begin
        if (~wrst_n) begin
            wptr <= 0;
            wcnt <= 0;
            wptr_gray <= 0;
            wcnt_gray <= 0;
        end else if (winc &&!wfull) begin
            fifo[wptr] <= wdata;
            wptr <= wptr + 1;
            wcnt <= wcnt + 1;
            wptr_gray <= wptr_gray + 1;
            wcnt_gray <= wcnt_gray + 1;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (~rrst_n) begin
            rptr <= 0;
            rcnt <= 0;
            rptr_gray <= 0;
            rcnt_gray <= 0;
            rdata_reg <= 0;
        end else if (rinc &&!rempty) begin
            rdata_reg <= fifo[rptr];
            rptr <= rptr + 1;
            rcnt <= rcnt - 1;
            rptr_gray <= rptr_gray + 1;
            rcnt_gray <= rcnt_gray - 1;
        end else if (FALLTHROUGH == "TRUE" &&!rempty) begin
            rdata_reg <= fifo[rptr];
        end
    end

    always @(posedge rclk) begin
        if (FALLTHROUGH == "TRUE") begin
            rdata <= rdata_reg;
        end else begin
            rdata <= (rempty)? 0 : fifo[rptr];
        end
    end

    always @(posedge wclk) begin
        wptr_bin <= wptr;
    end

    always @(posedge rclk) begin
        rptr_bin <= rptr;
    end

    always @(posedge wclk) begin
        wcnt_gray <= gray_encode(wcnt);
    end

    always @(posedge rclk) begin
        rcnt_gray <= gray_encode(rcnt);
    end

    function [ASIZE-1:0] gray_encode;
        input [ASIZE-1:0] bin;
        reg [ASIZE-1:0] gray;
        begin
            gray = bin ^ (bin >> 1);
            gray_encode = gray;
        end
    endfunction

endmodule
