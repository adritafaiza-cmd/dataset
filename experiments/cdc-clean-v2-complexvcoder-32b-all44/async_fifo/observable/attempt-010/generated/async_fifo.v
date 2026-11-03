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

    wire [ASIZE-1:0] wptr_gray;
    wire [ASIZE-1:0] wptr_bin;
    wire [ASIZE-1:0] rptr_gray;
    wire [ASIZE-1:0] rptr_bin;
    wire [ASIZE-1:0] rptr_gray_sync_wclk;
    wire [ASIZE-1:0] wptr_gray_sync_rclk;
    wire             wfull_int;
    wire             wfull_gray;
    wire             arempty_int;
    wire             arempty_gray;

    gray_counter #(.ASIZE(ASIZE)) gray_wptr (
        .clk      (wclk),
        .rst_n    (wrst_n),
        .inc      (winc),
        .gray_out (wptr_gray),
        .bin_out  (wptr_bin)
    );

    gray_counter #(.ASIZE(ASIZE)) gray_rptr (
        .clk      (rclk),
        .rst_n    (rrst_n),
        .inc      (rinc),
        .gray_out (rptr_gray),
        .bin_out  (rptr_bin)
    );

    sync_gray #(.ASIZE(ASIZE)) sync_rptr_gray_wclk (
        .clk      (wclk),
        .rst_n    (wrst_n),
        .din      (rptr_gray),
        .dout     (rptr_gray_sync_wclk)
    );

    sync_gray #(.ASIZE(ASIZE)) sync_wptr_gray_rclk (
        .clk      (rclk),
        .rst_n    (rrst_n),
        .din      (wptr_gray),
        .dout     (wptr_gray_sync_rclk)
    );

    dual_port_ram #(.DSIZE(DSIZE), .ASIZE(ASIZE)) fifo_memory (
        .clk_w    (wclk),
        .clk_r    (rclk),
        .rst_n    (wrst_n),
        .we       (winc),
        .waddr    (wptr_bin),
        .din      (wdata),
        .raddr    (rptr_bin),
        .dout     (rdata)
    );

    assign wfull_int = (wptr_gray_sync_rclk == (wptr_gray ^ (1 << (ASIZE - 1))));
    assign wfull_gray = (wptr_gray == (wptr_gray_sync_rclk ^ (1 << (ASIZE - 1))));
    assign arempty_int = (rptr_gray_sync_wclk == wptr_gray);
    assign arempty_gray = (rptr_gray == wptr_gray_sync_rclk);

    assign wfull = (FALLTHROUGH == "TRUE") ? wfull_int : wfull_gray;
    assign awfull = (FALLTHROUGH == "TRUE") ? wfull_gray : wfull_int;
    assign rempty = (FALLTHROUGH == "TRUE") ? rempty_int : rempty_gray;
    assign arempty = (FALLTHROUGH == "TRUE") ? arempty_gray : arempty_int;

endmodule

module gray_counter
    #(
        parameter ASIZE = 4
    )(
        input  wire            clk,
        input  wire            rst_n,
        input  wire            inc,
        output wire [ASIZE-1:0] gray_out,
        output wire [ASIZE-1:0] bin_out
    );

    reg [ASIZE-1:0] counter;
    reg [ASIZE-1:0] next_counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
        end else begin
            if (inc) begin
                counter <= next_counter;
            end
        end
    end

    assign next_counter = counter + 1;
    assign bin_out = counter;
    assign gray_out = counter ^ (counter >> 1);

endmodule

module sync_gray
    #(
        parameter ASIZE = 4
    )(
        input  wire            clk,
        input  wire            rst_n,
        input  wire [ASIZE-1:0] din,
        output wire [ASIZE-1:0] dout
    );

    reg [ASIZE-1:0] sync_reg1;
    reg [ASIZE-1:0] sync_reg2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_reg1 <= 0;
            sync_reg2 <= 0;
        end else begin
            sync_reg1 <= din;
            sync_reg2 <= sync_reg1;
        end
    end

    assign dout = sync_reg2;

endmodule

module dual_port_ram
    #(
        parameter DSIZE = 8,
        parameter ASIZE = 4
    )(
        input  wire             clk_w,
        input  wire             clk_r,
        input  wire             rst_n,
        input  wire             we,
        input  wire [ASIZE-1:0] waddr,
        input  wire [DSIZE-1:0] din,
        input  wire [ASIZE-1:0] raddr,
        output wire [DSIZE-1:0] dout
    );

    reg [DSIZE-1:0] memory [0:(1 << ASIZE) - 1];

    always @(posedge clk_w or negedge rst_n) begin
        if (!rst_n) begin
            for (integer i = 0; i < (1 << ASIZE); i = i + 1) begin
                memory[i] <= 0;
            end
        end else if (we) begin
            memory[waddr] <= din;
        end
    end

    always @(posedge clk_r) begin
        dout <= memory[raddr];
    end

endmodule
