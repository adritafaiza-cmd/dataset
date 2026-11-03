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

    wire [ASIZE:0] gray_w, gray_r;
    wire [ASIZE:0] gray_w_sync, gray_r_sync;
    wire [ASIZE:0] wptr, rptr;
    wire rempty_sync, wfull_sync;

    gray_counter gray_counter_w (
        .clk  (wclk),
        .rst_n(wrst_n),
        .inc  (winc),
        .gray (gray_w)
    );

    gray_counter gray_counter_r (
        .clk  (rclk),
        .rst_n(rrst_n),
        .inc  (rinc),
        .gray (gray_r)
    );

    gray_to_bin gray_to_bin_w (
        .gray (gray_w),
        .bin  (wptr)
    );

    gray_to_bin gray_to_bin_r (
        .gray (gray_r),
        .bin  (rptr)
    );

    fifo_memory fifo_mem (
        .wclk    (wclk),
        .wdata   (wdata),
        .wptr    (wptr),
        .rclk    (rclk),
        .rdata   (rdata),
        .rptr    (rptr),
        .wfull   (wfull),
        .awfull  (awfull),
        .remp    (rempty),
        .arempty (arempty)
    );

    sync_flop sync_w_gray_r (
        .clk (rclk),
        .din (gray_w),
        .out (gray_w_sync)
    );

    sync_flop sync_r_gray_w (
        .clk (wclk),
        .din (gray_r),
        .out (gray_r_sync)
    );

    sync_flop sync_w_empty (
        .clk (wclk),
        .din (rempty),
        .out (rempty_sync)
    );

    sync_flop sync_r_full (
        .clk (rclk),
        .din (wfull),
        .out (wfull_sync)
    );

endmodule

module gray_counter (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        inc,
    output wire [ASIZE:0] gray
);

    reg [ASIZE:0] gray_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_reg <= 0;
        end else if (inc) begin
            gray_reg <= gray_reg ^ ({gray_reg[ASIZE-1:0], 1'b0} + 1'b1);
        end
    end

    assign gray = gray_reg;

endmodule

module gray_to_bin (
    input  wire [ASIZE:0] gray,
    output wire [ASIZE:0] bin
);

    wire [ASIZE:0] gray_shifted;

    assign gray_shifted = {gray[ASIZE-1:0], 1'b0};

    assign bin = gray ^ gray_shifted;

endmodule

module fifo_memory (
    input  wire             wclk,
    input  wire [DSIZE-1:0] wdata,
    input  wire [ASIZE:0] wptr,
    input  wire             rclk,
    output wire [DSIZE-1:0] rdata,
    input  wire [ASIZE:0] rptr,
    output wire             wfull,
    output wire             awfull,
    output wire             remp,
    output wire             arempty
);

    reg [DSIZE-1:0] mem [0:(2**ASIZE)-1];
    reg [ASIZE:0] wptr_gray, rptr_gray;
    reg [ASIZE:0] wptr_gray_next, rptr_gray_next;
    reg [ASIZE:0] wptr_gray_sync, rptr_gray_sync;

    always @(posedge wclk) begin
        if (winc && !wfull) begin
            mem[wptr[ASIZE-1:0]] <= wdata;
        end
        wptr_gray <= wptr;
    end

    always @(posedge rclk) begin
        rptr_gray <= rptr;
    end

    sync_flop sync_wptr_gray (
        .clk (rclk),
        .din (wptr_gray),
        .out (wptr_gray_sync)
    );

    sync_flop sync_rptr_gray (
        .clk (wclk),
        .din (rptr_gray),
        .out (rptr_gray_sync)
    );

    assign wptr_gray_next = wptr_gray + 1;
    assign rptr_gray_next = rptr_gray + 1;

    assign wfull = (wptr_gray_next == rptr_gray_sync);
    assign awfull = (wptr_gray_next[ASIZE-1:0] == rptr_gray_sync[ASIZE-1:0] && wptr_gray_next[ASIZE] != rptr_gray_sync[ASIZE]);
    assign remp = (wptr_gray == rptr_gray_sync);
    assign arempty = (wptr_gray[ASIZE-1:0] == rptr_gray_sync[ASIZE-1:0] && wptr_gray[ASIZE] != rptr_gray_sync[ASIZE]);

    always @(posedge rclk) begin
        if (rinc && !remp) begin
            rdata <= mem[rptr[ASIZE-1:0]];
        end
    end

endmodule

module sync_flop (
    input  wire         clk,
    input  wire [ASIZE:0] din,
    output reg [ASIZE:0] out
);

    reg [ASIZE:0] reg1, reg2;

    always @(posedge clk) begin
        reg1 <= din;
        reg2 <= reg1;
    end

    assign out = reg2;

endmodule
