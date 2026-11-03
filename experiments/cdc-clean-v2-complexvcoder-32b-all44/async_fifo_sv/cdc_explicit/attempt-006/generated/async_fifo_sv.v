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

    wire [ADDR_WIDTH:0] wptr_bin, wptr_gray, wptr_gray_sync;
    wire [ADDR_WIDTH:0] rptr_bin, rptr_gray, rptr_gray_sync;
    wire [DATA_WIDTH-1:0] fifo_mem [0:(2**(ADDR_WIDTH+1)-1)];
    wire [ADDR_WIDTH:0] wfull_gray, wfull_bin, rempty_gray, rempty_bin;

    // Write Pointer Logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_bin <= 0;
        end else if (winc && !wfull) begin
            wptr_bin <= wptr_bin + 1;
        end
    end

    // Convert write pointer to gray code
    assign wptr_gray = (wptr_bin >> 1) ^ wptr_bin;

    // Read Pointer Logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_bin <= 0;
        end else if (rinc && !rempty) begin
            rptr_bin <= rptr_bin + 1;
        end
    end

    // Convert read pointer to gray code
    assign rptr_gray = (rptr_bin >> 1) ^ rptr_bin;

    // Synchronize write pointer to read domain
    sync_gray #(.WIDTH(ADDR_WIDTH+1)) sync_gray_w2r (
        .din(wptr_gray),
        .clk(rclk),
        .rst_n(rrst_n),
        .dout(wptr_gray_sync)
    );

    // Synchronize read pointer to write domain
    sync_gray #(.WIDTH(ADDR_WIDTH+1)) sync_gray_r2w (
        .din(rptr_gray),
        .clk(wclk),
        .rst_n(wrst_n),
        .dout(rptr_gray_sync)
    );

    // Convert synchronized write pointer back to binary
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_bin_sync <= 0;
        end else begin
            wptr_bin_sync <= wptr_bin_sync + (wptr_gray_sync ^ wptr_bin_sync);
        end
    end

    // Convert synchronized read pointer back to binary
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_bin_sync <= 0;
        end else begin
            rptr_bin_sync <= rptr_bin_sync + (rptr_gray_sync ^ rptr_bin_sync);
        end
    end

    // FIFO memory write operation
    always @(posedge wclk) begin
        if (winc && !wfull) begin
            fifo_mem[wptr_bin] <= wdata;
        end
    end

    // FIFO memory read operation
    always @(posedge rclk) begin
        if (rinc && !rempty) begin
            rdata <= fifo_mem[rptr_bin];
        end
    end

    // Calculate wfull
    assign wfull_gray = (wptr_gray_sync == (rptr_gray + 1));
    assign wfull_bin = (wptr_bin_sync == (rptr_bin + 2**(ADDR_WIDTH+1) - 1));

    // Calculate rempty
    assign rempty_gray = (wptr_gray == rptr_gray);
    assign rempty_bin = (wptr_bin == rptr_bin);

    // Output assignments
    assign wfull = wfull_bin;
    assign waddr = wptr_bin;
    assign rempty = rempty_bin;
    assign raddr = rptr_bin;

endmodule

module sync_gray #(
    parameter WIDTH = 5
)(
    input  wire [WIDTH-1:0] din,
    input  wire             clk,
    input  wire             rst_n,
    output wire [WIDTH-1:0] dout
);

    reg [WIDTH-1:0] sync_reg [0:SYNC_STAGES-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_reg <= 0;
        end else begin
            sync_reg[0] <= din;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_reg[i] <= sync_reg[i-1];
            end
        end
    end

    assign dout = sync_reg[SYNC_STAGES-1];

endmodule
