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

    // Internal signals
    wire [ASIZE-1:0] gray_wptr_out;
    wire [ASIZE-1:0] gray_rptr_out;
    wire [ASIZE-1:0] gray_wptr_out_sync_rclk;
    wire [ASIZE-1:0] gray_rptr_out_sync_wclk;
    wire [ASIZE-1:0] bin_wptr_rclk;
    wire [ASIZE-1:0] bin_rptr_wclk;

    // Write and Read Gray Counters
    gray_counter gray_wptr (
        .clk   (wclk),
        .rst_n (wrst_n),
        .inc   (winc),
        .gray  (gray_wptr_out)
    );

    gray_counter gray_rptr (
        .clk   (rclk),
        .rst_n (rrst_n),
        .inc   (rinc),
        .gray  (gray_rptr_out)
    );

    // Gray to Binary Conversion
    gray_to_bin bin_wptr (
        .gray (gray_wptr_out_sync_rclk),
        .bin  (bin_wptr_rclk)
    );

    gray_to_bin bin_rptr (
        .gray (gray_rptr_out_sync_wclk),
        .bin  (bin_rptr_wclk)
    );

    // Synchronization Registers
    sync_register sync_wptr (
        .clk   (rclk),
        .rst_n (rrst_n),
        .din   (gray_wptr_out),
        .dout  (gray_wptr_out_sync_rclk)
    );

    sync_register sync_rptr (
        .clk   (wclk),
        .rst_n (wrst_n),
        .din   (gray_rptr_out),
        .dout  (gray_rptr_out_sync_wclk)
    );

    // Memory Module
    memory fifo_memory (
        .wclk   (wclk),
        .wrst_n (wrst_n),
        .winc   (winc),
        .waddr  (bin_wptr_wclk),
        .wdata  (wdata),
        .rclk   (rclk),
        .rrst_n (rrst_n),
        .raddr  (bin_rptr_rclk),
        .rdata  (rdata)
    );

    // Full and Almost Full Conditions
    wire [ASIZE:0] wptr_plus_one;
    wire [ASIZE:0] rptr_plus_one;

    assign wptr_plus_one = bin_wptr_wclk + 1;
    assign rptr_plus_one = bin_rptr_wclk + 1;

    assign wfull   = (wptr_plus_one[ASIZE-1:0] == gray_rptr_out_sync_wclk[ASIZE-1:0]) && (wptr_plus_one[ASIZE] != gray_rptr_out_sync_wclk[ASIZE]);
    assign awfull  = (wptr_plus_one[ASIZE-1:0] == gray_rptr_out_sync_wclk[ASIZE-1:0]) && (wptr_plus_one[ASIZE] == gray_rptr_out_sync_wclk[ASIZE]);

    // Empty and Almost Empty Conditions
    assign rempty  = (bin_rptr_rclk == gray_wptr_out_sync_rclk);
    assign arempty = (bin_rptr_rclk == gray_wptr_out_sync_rclk[ASIZE-1:0]) && (gray_wptr_out_sync_rclk[ASIZE] == 1'b0);

endmodule

module gray_counter (
    input  wire             clk,
    input  wire             rst_n,
    input  wire             inc,
    output wire [ASIZE-1:0] gray
);

    reg [ASIZE-1:0] gray_reg;
    wire [ASIZE-1:0] gray_next;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            gray_reg <= 0;
        else if (inc)
            gray_reg <= gray_next;
    end

    assign gray_next = (gray_reg << 1) ^ {gray_reg[ASIZE-2:0], 1'b1};
    assign gray      = gray_reg;

endmodule

module gray_to_bin (
    input  wire [ASIZE-1:0] gray,
    output wire [ASIZE-1:0] bin
);

    wire [ASIZE-1:0] gray_shifted;

    assign gray_shifted = gray >> 1;
    assign bin          = gray ^ gray_shifted;

endmodule

module sync_register (
    input  wire             clk,
    input  wire             rst_n,
    input  wire [ASIZE-1:0] din,
    output reg  [ASIZE-1:0] dout
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

module memory (
    input  wire             wclk,
    input  wire             wrst_n,
    input  wire             winc,
    input  wire [ASIZE-1:0] waddr,
    input  wire [DSIZE-1:0] wdata,
    input  wire             rclk,
    input  wire             rrst_n,
    input  wire [ASIZE-1:0] raddr,
    output wire [DSIZE-1:0] rdata
);

    reg [DSIZE-1:0] mem [0:(2**ASIZE)-1];

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            mem <= '{default: 0};
        end else if (winc) begin
            mem[waddr] <= wdata;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata <= 0;
        end else begin
            rdata <= mem[raddr];
        end
    end

endmodule
