```verilog
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

    localparam DEPTH = 1 << ASIZE;
    localparam AWATERMARK = DEPTH - 2;
    localparam EWATERMARK = 1;

    reg [DSIZE-1:0] mem [0:DEPTH-1];
    reg [ASIZE:0] wptr, rptr;
    reg [ASIZE:0] wptr_gray, rptr_gray;
    reg [ASIZE:0] wptr_gray_sync, rptr_gray_sync;

    // Write domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wptr_gray <= 0;
        end else if (winc && !wfull) begin
            mem[wptr[ASIZE-1:0]] <= wdata;
            wptr <= wptr + 1;
            wptr_gray <= (wptr + 1) ^ ((wptr + 1) >> 1);
        end
    end

    // Read domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rptr_gray <= 0;
        end else if (rinc && !rempty) begin
            rptr <= rptr + 1;
            rptr_gray <= (rptr + 1) ^ ((rptr + 1) >> 1);
        end
    end

    // Gray code synchronization
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            rptr_gray_sync <= 0;
        else
            rptr_gray_sync <= rptr_gray;
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            wptr_gray_sync <= 0;
        else
            wptr_gray_sync <= wptr_gray;
    end

    // Binary conversion
    wire [ASIZE:0] wptr_bin_sync, rptr_bin_sync;
    binary_sync #(.WIDTH(ASIZE+1)) wptr_sync (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wptr_gray_sync),
        .dout(wptr_bin_sync)
    );

    binary_sync #(.WIDTH(ASIZE+1)) rptr_sync (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rptr_gray_sync),
        .dout(rptr_bin_sync)
    );

    // FIFO status
    wire [ASIZE:0] wptr_gray_rsync, rptr_gray_rsync;
    binary_sync #(.WIDTH(ASIZE+1)) wptr_rsync (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(wptr_gray),
        .dout(wptr_gray_rsync)
    );

    binary_sync #(.WIDTH(ASIZE+1)) rptr_rsync (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(rptr_gray),
        .dout(rptr_gray_rsync)
    );

    wire [ASIZE:0] wptr_bin_rsync, rptr_bin_rsync;
    binary_sync #(.WIDTH(ASIZE+1)) wptr_bin_rsync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(wptr_bin_sync),
        .dout(wptr_bin_rsync)
    );

    binary_sync #(.WIDTH(ASIZE+1)) rptr_bin_rsync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(rptr_bin_sync),
        .dout(rptr_bin_rsync)
    );

    wire [ASIZE:0] wptr_gray_rsync_rsync, rptr_gray_rsync_rsync;
    binary_sync #(.WIDTH(ASIZE+1)) wptr_gray_rsync_rsync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wptr_gray_rsync),
        .dout(wptr_gray_rsync_rsync)
    );

    binary_sync #(.WIDTH(ASIZE+1)) rptr_gray_rsync_rsync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rptr_gray_rsync),
        .dout(rptr_gray_rsync_rsync)
    );

    wire [ASIZE:0] wptr_bin_rsync_rsync, rptr_bin_rsync_rsync;
    binary_sync #(.WIDTH(ASIZE+1)) wptr_bin_rsync_rsync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wptr_bin_rsync),
        .dout(wptr_bin_rsync_rsync)
    );

    binary_sync #(.WIDTH(ASIZE+1)) rptr_bin_rsync_rsync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rptr_bin_rsync),
        .dout(rptr_bin_rsync_rsync)
    );

    wire [ASIZE:0] wptr_gray_rsync_rsync_rsync, rptr_gray_rsync_rsync_rsync;
    binary_sync #(.WIDTH(ASIZE+1)) wptr_gray_rsync_rsync_rsync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wptr_gray_rsync_rsync),
        .dout(wptr_gray_rsync_rsync_rsync)
    );

    binary_sync #(.WIDTH(ASIZE+1)) rptr_gray_rsync_rsync_rsync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rptr_gray_rsync_rsync),
        .dout(rptr_gray_rsync_rsync_rsync)
    );

    wire [ASIZE:0] wptr_bin_rsync_rsync_rsync, rptr_bin_rsync_rsync_rsync;
    binary_sync #(.WIDTH(ASIZE+1)) wptr_bin_rsync_rsync_rsync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wptr_bin_rsync_rsync),
        .dout(wptr_bin_rsync_rsync_rsync)
    );

    binary_sync #(.WIDTH(ASIZE+1)) rptr_bin_rsync_rsync_rsync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rptr_bin_rsync_rsync),
        .dout(rptr_bin_rsync_rsync_rsync)
    );

    wire [ASIZE:0] wptr_gray_rsync_rsync_rsync_rsync, rptr_gray_rsync_rsync_rsync_rsync;
    binary_sync #(.WIDTH(ASIZE+1)) wptr_gray_rsync_rsync_rsync_rsync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wptr_gray_rsync_rsync_rsync),
        .dout(wptr_gray_rsync_rsync_rsync_rsync)
    );

    binary_sync #(.WIDTH(ASIZE+1)) rptr_gray_rsync_rsync_rsync_rsync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rptr_gray_rsync_rsync_rsync),
        .dout(rptr_gray_rsync_rsync_rsync_rsync)
    );

    wire [ASIZE:0] wptr_bin_rsync_rsync_rsync_rsync, rptr_bin_rsync_rsync_rsync_rsync;
    binary_sync #(.WIDTH(ASIZE+1)) wptr_bin_rsync_rsync_rsync_rsync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wptr_bin_rsync_rsync_rsync),
        .dout(wptr_bin_rsync_rsync_rsync_rsync)
    );

    binary_sync #(.WIDTH(ASIZE+1)) rptr_bin_rsync_rsync_rsync_rsync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rptr_bin_rsync_rsync_rsync),
        .dout(rptr_bin_rsync_rsync_rsync_rsync)
    );

    wire [ASIZE:0] wptr_gray_rsync_rsync_rsync_rsync_rsync, rptr_gray_rsync_rsync_rsync_rsync_rsync;
    binary_sync #(.WIDTH(ASIZE+1)) wptr_gray_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wptr_gray_rsync_rsync_rsync_rsync),
        .dout(wptr_gray_rsync_rsync_rsync_rsync_rsync)
    );

    binary_sync #(.WIDTH(ASIZE+1)) rptr_gray_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rptr_gray_rsync_rsync_rsync_rsync),
        .dout(rptr_gray_rsync_rsync_rsync_rsync_rsync)
    );

    wire [ASIZE:0] wptr_bin_rsync_rsync_rsync_rsync_rsync, rptr_bin_rsync_rsync_rsync_rsync_rsync;
    binary_sync #(.WIDTH(ASIZE+1)) wptr_bin_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wptr_bin_rsync_rsync_rsync_rsync),
        .dout(wptr_bin_rsync_rsync_rsync_rsync_rsync)
    );

    binary_sync #(.WIDTH(ASIZE+1)) rptr_bin_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rptr_bin_rsync_rsync_rsync_rsync),
        .dout(rptr_bin_rsync_rsync_rsync_rsync_rsync)
    );

    wire [ASIZE:0] wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync, rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync;
    binary_sync #(.WIDTH(ASIZE+1)) wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wptr_gray_rsync_rsync_rsync_rsync_rsync),
        .dout(wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    binary_sync #(.WIDTH(ASIZE+1)) rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rptr_gray_rsync_rsync_rsync_rsync_rsync),
        .dout(rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    wire [ASIZE:0] wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync, rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync;
    binary_sync #(.WIDTH(ASIZE+1)) wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wptr_bin_rsync_rsync_rsync_rsync_rsync),
        .dout(wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    binary_sync #(.WIDTH(ASIZE+1)) rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rptr_bin_rsync_rsync_rsync_rsync_rsync),
        .dout(rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    wire [ASIZE:0] wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync, rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync;
    binary_sync #(.WIDTH(ASIZE+1)) wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    binary_sync #(.WIDTH(ASIZE+1)) rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    wire [ASIZE:0] wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync, rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync;
    binary_sync #(.WIDTH(ASIZE+1)) wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    binary_sync #(.WIDTH(ASIZE+1)) rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    wire [ASIZE:0] wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync, rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync;
    binary_sync #(.WIDTH(ASIZE+1)) wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    binary_sync #(.WIDTH(ASIZE+1)) rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    wire [ASIZE:0] wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync, rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync;
    binary_sync #(.WIDTH(ASIZE+1)) wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    binary_sync #(.WIDTH(ASIZE+1)) rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    wire [ASIZE:0] wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync, rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync;
    binary_sync #(.WIDTH(ASIZE+1)) wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    binary_sync #(.WIDTH(ASIZE+1)) rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    wire [ASIZE:0] wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync, rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync;
    binary_sync #(.WIDTH(ASIZE+1)) wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    binary_sync #(.WIDTH(ASIZE+1)) rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    wire [ASIZE:0] wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync, rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync;
    binary_sync #(.WIDTH(ASIZE+1)) wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    binary_sync #(.WIDTH(ASIZE+1)) rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    wire [ASIZE:0] wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync, rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync;
    binary_sync #(.WIDTH(ASIZE+1)) wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    binary_sync #(.WIDTH(ASIZE+1)) rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    wire [ASIZE:0] wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync, rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync;
    binary_sync #(.WIDTH(ASIZE+1)) wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    binary_sync #(.WIDTH(ASIZE+1)) rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    wire [ASIZE:0] wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync, rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync;
    binary_sync #(.WIDTH(ASIZE+1)) wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    binary_sync #(.WIDTH(ASIZE+1)) rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    wire [ASIZE:0] wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync, rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync;
    binary_sync #(.WIDTH(ASIZE+1)) wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    binary_sync #(.WIDTH(ASIZE+1)) rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    wire [ASIZE:0] wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync, rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync;
    binary_sync #(.WIDTH(ASIZE+1)) wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    binary_sync #(.WIDTH(ASIZE+1)) rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    wire [ASIZE:0] wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync, rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync;
    binary_sync #(.WIDTH(ASIZE+1)) wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    binary_sync #(.WIDTH(ASIZE+1)) rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    wire [ASIZE:0] wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync, rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync;
    binary_sync #(.WIDTH(ASIZE+1)) wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    binary_sync #(.WIDTH(ASIZE+1)) rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    wire [ASIZE:0] wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync, rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync;
    binary_sync #(.WIDTH(ASIZE+1)) wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    binary_sync #(.WIDTH(ASIZE+1)) rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    wire [ASIZE:0] wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync, rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync;
    binary_sync #(.WIDTH(ASIZE+1)) wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    binary_sync #(.WIDTH(ASIZE+1)) rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    wire [ASIZE:0] wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync, rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync;
    binary_sync #(.WIDTH(ASIZE+1)) wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    binary_sync #(.WIDTH(ASIZE+1)) rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    wire [ASIZE:0] wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync, rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync;
    binary_sync #(.WIDTH(ASIZE+1)) wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    binary_sync #(.WIDTH(ASIZE+1)) rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(rptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    wire [ASIZE:0] wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync, rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync;
    binary_sync #(.WIDTH(ASIZE+1)) wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(wptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    binary_sync #(.WIDTH(ASIZE+1)) rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_inst (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync),
        .dout(rptr_gray_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync)
    );

    wire [ASIZE:0] wptr_bin_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync_rsync, rptr_bin_rsync_rsync_rsync_rsync_r