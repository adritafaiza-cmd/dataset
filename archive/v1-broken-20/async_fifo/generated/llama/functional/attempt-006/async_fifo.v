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
    reg [DSIZE-1:0] mem [2**ASIZE-1:0];
    reg [ASIZE-1:0] count;
    reg [ASIZE-1:0] count_gray;
    reg [ASIZE-1:0] count_bin;
    reg [ASIZE-1:0] count_next;
    reg [ASIZE-1:0] count_next_gray;
    reg [ASIZE-1:0] count_next_bin;
    reg [ASIZE-1:0] wptr_next;
    reg [ASIZE-1:0] rptr_next;
    reg [ASIZE-1:0] wptr_next_gray;
    reg [ASIZE-1:0] rptr_next_gray;
    reg [ASIZE-1:0] wptr_next_bin;
    reg [ASIZE-1:0] rptr_next_bin;
    reg [DSIZE-1:0] rdata_reg;
    reg wfull_reg;
    reg awfull_reg;
    reg rempty_reg;
    reg arempty_reg;

    assign wfull = wfull_reg;
    assign awfull = awfull_reg;
    assign rdata = rdata_reg;
    assign rempty = rempty_reg;
    assign arempty = arempty_reg;

    always @(posedge wclk or negedge wrst_n) begin
        if (~wrst_n) begin
            wptr <= 0;
            wptr_gray <= 0;
            wptr_bin <= 0;
            count <= 0;
            count_gray <= 0;
            count_bin <= 0;
            wfull_reg <= 1'b0;
            awfull_reg <= 1'b0;
        end else if (winc && ~wfull_reg) begin
            wptr <= wptr + 1;
            wptr_gray <= wptr_gray + 1;
            wptr_bin <= wptr_bin + 1;
            count <= count + 1;
            count_gray <= count_gray + 1;
            count_bin <= count_bin + 1;
            mem[wptr_bin] <= wdata;
            if (count == (2**ASIZE - 2)) begin
                awfull_reg <= 1'b1;
            end else if (count == (2**ASIZE - 1)) begin
                wfull_reg <= 1'b1;
            end
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (~rrst_n) begin
            rptr <= 0;
            rptr_gray <= 0;
            rptr_bin <= 0;
            rempty_reg <= 1'b1;
            arempty_reg <= 1'b1;
            rdata_reg <= 0;
        end else if (rinc && ~rempty_reg) begin
            rptr <= rptr + 1;
            rptr_gray <= rptr_gray + 1;
            rptr_bin <= rptr_bin + 1;
            if (FALLTHROUGH == "TRUE") begin
                rdata_reg <= mem[rptr_bin];
            end
            if (count == 1) begin
                rempty_reg <= 1'b1;
            end else if (count == 2) begin
                arempty_reg <= 1'b0;
            end
        end else if (FALLTHROUGH == "TRUE" && ~rempty_reg) begin
            rdata_reg <= mem[rptr_bin];
        end
    end

    always @(posedge wclk) begin
        wptr_next <= wptr;
        wptr_next_gray <= wptr_gray;
        wptr_next_bin <= wptr_bin;
    end

    always @(posedge rclk) begin
        rptr_next <= rptr;
        rptr_next_gray <= rptr_gray;
        rptr_next_bin <= rptr_bin;
    end

    always @(posedge wclk) begin
        count_next <= count;
        count_next_gray <= count_gray;
        count_next_bin <= count_bin;
    end

    always @(posedge rclk) begin
        if (count_next == 0) begin
            rempty_reg <= 1'b1;
        end else if (count_next == 1) begin
            arempty_reg <= 1'b0;
        end else if (count_next == (2**ASIZE - 1)) begin
            wfull_reg <= 1'b1;
        end else if (count_next == (2**ASIZE - 2)) begin
            awfull_reg <= 1'b1;
        end
    end

endmodule
