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
    reg [ADDR_WIDTH:0] wptr, rptr;
    reg [ADDR_WIDTH:0] wptr_bin, rptr_bin;
    reg [ADDR_WIDTH:0] wptr_gray, rptr_gray;
    reg [ADDR_WIDTH:0] wptr_gray_sync, rptr_gray_sync;
    reg [ADDR_WIDTH:0] wptr_gray_sync2, rptr_gray_sync2;
    reg [ADDR_WIDTH:0] wptr_bin_sync, rptr_bin_sync;
    wire wfull_logic, rempty_logic;

    // Write domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
        end else if (winc && !wfull_logic) begin
            wptr <= wptr + 1;
        end
    end

    // Read domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
        end else if (rinc && !rempty_logic) begin
            rptr <= rptr + 1;
        end
    end

    // Convert binary to gray
    assign wptr_gray = (wptr >> 1) ^ wptr;
    assign rptr_gray = (rptr >> 1) ^ rptr;

    // Synchronize write pointer to read domain
    sync_ff #(.WIDTH(ADDR_WIDTH+1)) wptr_gray_sync_inst (
        .din(wptr_gray),
        .clk(rclk),
        .rst_n(rrst_n),
        .dout(wptr_gray_sync)
    );

    sync_ff #(.WIDTH(ADDR_WIDTH+1)) wptr_gray_sync2_inst (
        .din(wptr_gray_sync),
        .clk(rclk),
        .rst_n(rrst_n),
        .dout(wptr_gray_sync2)
    );

    // Synchronize read pointer to write domain
    sync_ff #(.WIDTH(ADDR_WIDTH+1)) rptr_gray_sync_inst (
        .din(rptr_gray),
        .clk(wclk),
        .rst_n(wrst_n),
        .dout(rptr_gray_sync)
    );

    sync_ff #(.WIDTH(ADDR_WIDTH+1)) rptr_gray_sync2_inst (
        .din(rptr_gray_sync),
        .clk(wclk),
        .rst_n(wrst_n),
        .dout(rptr_gray_sync2)
    );

    // Convert gray to binary
    gray_to_bin #(.WIDTH(ADDR_WIDTH+1)) wptr_gray_to_bin_inst (
        .din(wptr_gray_sync2),
        .dout(wptr_bin_sync)
    );

    gray_to_bin #(.WIDTH(ADDR_WIDTH+1)) rptr_gray_to_bin_inst (
        .din(rptr_gray_sync2),
        .dout(rptr_bin_sync)
    );

    // FIFO memory
    memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH+1)
    ) fifo_memory_inst (
        .clk(wclk),
        .we(winc && !wfull_logic),
        .addr(wptr_bin),
        .din(wdata),
        .clk_r(rclk),
        .addr_r(rptr_bin_sync),
        .dout(rdata)
    );

    // Output pointers
    assign waddr = wptr_bin;
    assign raddr = rptr_bin;

    // Full and empty logic
    assign wfull_logic = (wptr_bin_sync == {1'b1, rptr_bin[ADDR_WIDTH-1:0]});
    assign rempty_logic = (wptr_bin_sync == rptr_bin_sync);

    // Output full and empty flags
    assign wfull = wfull_logic;
    assign rempty = rempty_logic;

endmodule

module sync_ff #(
    parameter WIDTH = 5
)(
    input  wire [WIDTH-1:0] din,
    input  wire             clk,
    input  wire             rst_n,
    output reg [WIDTH-1:0]  dout
);

    reg [WIDTH-1:0] dout_ff1, dout_ff2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_ff1 <= 0;
            dout_ff2 <= 0;
        end else begin
            dout_ff1 <= din;
            dout_ff2 <= dout_ff1;
        end
    end

    assign dout = dout_ff2;

endmodule

module gray_to_bin #(
    parameter WIDTH = 5
)(
    input  wire [WIDTH-1:0] din,
    output wire [WIDTH-1:0] dout
);

    assign dout = din ^ (din >> 1);

endmodule

module memory #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 5
)(
    input  wire             clk,
    input  wire             we,
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [DATA_WIDTH-1:0] din,
    input  wire             clk_r,
    input  wire [ADDR_WIDTH-1:0] addr_r,
    output reg [DATA_WIDTH-1:0]  dout
);

    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    always @(posedge clk) begin
        if (we) begin
            mem[addr] <= din;
        end
    end

    always @(posedge clk_r) begin
        dout <= mem[addr_r];
    end

endmodule
