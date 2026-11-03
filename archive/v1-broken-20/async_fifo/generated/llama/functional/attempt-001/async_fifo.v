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
        if (!wrst_n) begin
            wptr <= 0;
            wcnt <= 0;
            wptr_gray <= 0;
            wptr_bin <= 0;
        end else if (winc && !wfull) begin
            wptr <= wptr + 1;
            wcnt <= wcnt + 1;
            wptr_gray <= gray_encode(wptr + 1);
            wptr_bin <= bin_encode(wptr + 1);
            fifo[wptr_bin] <= wdata;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rcnt <= 0;
            rptr_gray <= 0;
            rptr_bin <= 0;
            rdata_reg <= 0;
        end else if (rinc && !rempty) begin
            rptr <= rptr + 1;
            rcnt <= rcnt - 1;
            rptr_gray <= gray_encode(rptr + 1);
            rptr_bin <= bin_encode(rptr + 1);
            if (FALLTHROUGH == "TRUE") begin
                rdata_reg <= fifo[rptr_bin];
            end
        end
    end

    always @(posedge rclk) begin
        if (FALLTHROUGH == "TRUE" && !rempty) begin
            rdata <= fifo[rptr_bin];
        end else begin
            rdata <= rdata_reg;
        end
    end

    function [ASIZE-1:0] gray_encode;
        input [ASIZE-1:0] bin;
        begin
            gray_encode = bin ^ (bin >> 1);
        end
    endfunction

    function [ASIZE-1:0] bin_encode;
        input [ASIZE-1:0] gray;
        reg [ASIZE-1:0] bin;
        begin
            bin = gray;
            for (bin_encode = 1; bin_encode < ASIZE; bin_encode = bin_encode + 1) begin
                bin[ASIZE-1-bin_encode] = gray[ASIZE-1-bin_encode] ^ bin[ASIZE-bin_encode];
            end
            bin_encode = bin;
        end
    endfunction

endmodule
