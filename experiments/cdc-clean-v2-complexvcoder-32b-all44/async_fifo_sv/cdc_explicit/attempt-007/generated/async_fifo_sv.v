module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter SYNC_STAGES = 2
)(
    input  wire                    wclk,
    input  wire                    wrst_n,
    input  wire                    winc,
    input  wire [DATA_WIDTH-1:0]   wdata,
    output wire                    wfull,
    output wire [ADDR_WIDTH:0]     waddr,
    input  wire                    rclk,
    input  wire                    rrst_n,
    input  wire                    rinc,
    output wire [DATA_WIDTH-1:0]   rdata,
    output wire                    rempty,
    output wire [ADDR_WIDTH:0]     raddr
);

    // Internal signals
    wire [ADDR_WIDTH:0] gray_wr;
    wire [ADDR_WIDTH:0] gray_rr;
    wire [ADDR_WIDTH:0] gray_wr_sync;
    wire [ADDR_WIDTH:0] gray_rr_sync;

    // Write domain gray counter
    gray_counter #(.WIDTH(ADDR_WIDTH+1))
    gray_counter_wr (
        .clk     (wclk),
        .rst_n   (wrst_n),
        .inc     (winc),
        .count   (gray_wr)
    );

    // Read domain gray counter
    gray_counter #(.WIDTH(ADDR_WIDTH+1))
    gray_counter_rr (
        .clk     (rclk),
        .rst_n   (rrst_n),
        .inc     (rinc),
        .count   (gray_rr)
    );

    // Write to Read domain synchronizer
    sync_gray #(.WIDTH(ADDR_WIDTH+1), .STAGES(SYNC_STAGES))
    sync_gray_wr_to_r (
        .async_in (gray_wr),
        .clk      (rclk),
        .rst_n    (rrst_n),
        .sync_out (gray_wr_sync)
    );

    // Read to Write domain synchronizer
    sync_gray #(.WIDTH(ADDR_WIDTH+1), .STAGES(SYNC_STAGES))
    sync_gray_rr_to_w (
        .async_in (gray_rr),
        .clk      (wclk),
        .rst_n    (wrst_n),
        .sync_out (gray_rr_sync)
    );

    // Memory array
    memory_array #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH+1))
    memory (
        .clk    (wclk),
        .rst_n  (wrst_n),
        .we     (winc),
        .din    (wdata),
        .waddr  (gray_wr),
        .raddr  (gray_rr_sync),
        .dout   (rdata)
    );

    // Full and empty flags
    assign wfull = (gray_wr_sync == {~gray_wr[ADDR_WIDTH], gray_wr[ADDR_WIDTH-1:0]});
    assign rempty = (gray_wr_sync == gray_rr_sync);

    // Debug addresses
    assign waddr = gray_wr;
    assign raddr = gray_rr;

endmodule

// Gray code counter module
module gray_counter #(
    parameter WIDTH = 5
)(
    input  wire clk,
    input  wire rst_n,
    input  wire inc,
    output wire [WIDTH-1:0] count
);

    reg [WIDTH-1:0] count_reg;
    reg [WIDTH-1:0] count_next;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count_reg <= 0;
        else if (inc)
            count_reg <= count_next;
    end

    assign count_next = (count_reg + 1) ^ (count_reg + 2);
    assign count = count_reg;

endmodule

// Gray code synchronizer module
module sync_gray #(
    parameter WIDTH = 5,
    parameter STAGES = 2
)(
    input  wire [WIDTH-1:0] async_in,
    input  wire clk,
    input  wire rst_n,
    output wire [WIDTH-1:0] sync_out
);

    reg [WIDTH-1:0] sync_reg [0:STAGES-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < STAGES; i = i + 1)
                sync_reg[i] <= 0;
        end else begin
            sync_reg[0] <= async_in;
            for (int i = 1; i < STAGES; i = i + 1)
                sync_reg[i] <= sync_reg[i-1];
        end
    end

    assign sync_out = sync_reg[STAGES-1];

endmodule

// Memory array module
module memory_array #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 5
)(
    input  wire clk,
    input  wire rst_n,
    input  wire we,
    input  wire [DATA_WIDTH-1:0] din,
    input  wire [ADDR_WIDTH-1:0] waddr,
    input  wire [ADDR_WIDTH-1:0] raddr,
    output wire [DATA_WIDTH-1:0] dout
);

    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < (1<<ADDR_WIDTH); i = i + 1)
                mem[i] <= 0;
        end else if (we) begin
            mem[waddr] <= din;
        end
    end

    assign dout = mem[raddr];

endmodule
