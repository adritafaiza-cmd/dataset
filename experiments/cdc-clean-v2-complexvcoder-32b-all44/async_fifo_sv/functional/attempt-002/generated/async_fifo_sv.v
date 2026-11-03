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

    wire [ADDR_WIDTH:0] gray_w;
    wire [ADDR_WIDTH:0] gray_r;
    wire [ADDR_WIDTH:0] waddr_bin;
    wire [ADDR_WIDTH:0] raddr_bin;

    // Gray counter for write pointer
    gray_counter #(.ADDR_WIDTH(ADDR_WIDTH))
    gray_counter_w (
        .clk    (wclk),
        .rst_n  (wrst_n),
        .inc    (winc),
        .gray   (gray_w)
    );

    // Gray counter for read pointer
    gray_counter #(.ADDR_WIDTH(ADDR_WIDTH))
    gray_counter_r (
        .clk    (rclk),
        .rst_n  (rrst_n),
        .inc    (rinc),
        .gray   (gray_r)
    );

    // Convert gray code to binary for write pointer
    gray_to_bin #(.ADDR_WIDTH(ADDR_WIDTH))
    gray_to_bin_w (
        .gray   (gray_w),
        .bin    (waddr_bin)
    );

    // Convert gray code to binary for read pointer
    gray_to_bin #(.ADDR_WIDTH(ADDR_WIDTH))
    gray_to_bin_r (
        .gray   (gray_r),
        .bin    (raddr_bin)
    );

    // Synchronous FIFO for data storage
    sync_fifo #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .SYNC_STAGES(SYNC_STAGES))
    sync_fifo_inst (
        .clk    (wclk),
        .rst_n  (wrst_n),
        .waddr  (waddr_bin),
        .wdata  (wdata),
        .rclk   (rclk),
        .rrst_n (rrst_n),
        .raddr  (raddr_bin),
        .rdata  (rdata),
        .wfull  (wfull),
        .rempty (rempty)
    );

    // Assign debug pointer outputs
    assign waddr = gray_w;
    assign raddr = gray_r;

endmodule

module gray_counter #(
    parameter ADDR_WIDTH = 4
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    inc,
    output wire [ADDR_WIDTH:0]     gray
);

    reg [ADDR_WIDTH:0] bin;
    reg [ADDR_WIDTH:0] next_bin;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin <= 0;
        end else if (inc) begin
            bin <= next_bin;
        end
    end

    assign next_bin = bin + 1;
    assign gray = bin ^ (bin >> 1);

endmodule

module gray_to_bin #(
    parameter ADDR_WIDTH = 4
)(
    input  wire [ADDR_WIDTH:0]     gray,
    output wire [ADDR_WIDTH:0]     bin
);

    reg [ADDR_WIDTH:0] bin_temp;

    always @(*) begin
        bin_temp = gray;
        for (int i = 0; i < ADDR_WIDTH; i = i + 1) begin
            bin_temp[ADDR_WIDTH-i] = bin_temp[ADDR_WIDTH-i] ^ bin_temp[ADDR_WIDTH-i-1];
        end
    end

    assign bin = bin_temp;

endmodule

module sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter SYNC_STAGES = 2
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire [ADDR_WIDTH:0]     waddr,
    input  wire [DATA_WIDTH-1:0]   wdata,
    input  wire                    rclk,
    input  wire                    rrst_n,
    input  wire [ADDR_WIDTH:0]     raddr,
    output wire [DATA_WIDTH-1:0]   rdata,
    output wire                    wfull,
    output wire                    rempty
);

    reg [DATA_WIDTH-1:0] mem [0:(2**(ADDR_WIDTH+1))-1];
    wire [ADDR_WIDTH:0] raddr_sync;

    // Synchronizer for read pointer
    sync_reg #(.ADDR_WIDTH(ADDR_WIDTH))
    sync_reg_inst (
        .clk    (clk),
        .rst_n  (rst_n),
        .async_data (raddr),
        .sync_data  (raddr_sync)
    );

    // Write operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < 2**(ADDR_WIDTH+1); i = i + 1) begin
                mem[i] <= 0;
            end
        end else if (!wfull) begin
            mem[waddr] <= wdata;
        end
    end

    // Read operation
    assign rdata = mem[raddr_sync];

    // Full and empty flags
    reg [ADDR_WIDTH:0] wptr_gray_sync;
    wire [ADDR_WIDTH:0] wptr_gray_sync_next;

    // Synchronize write pointer to read domain
    sync_reg #(.ADDR_WIDTH(ADDR_WIDTH))
    sync_reg_wptr (
        .clk    (rclk),
        .rst_n  (rrst_n),
        .async_data (gray_counter_w.gray),
        .sync_data  (wptr_gray_sync)
    );

    // Calculate next synchronized write pointer
    always @(*) begin
        reg [ADDR_WIDTH:0] wptr_bin_sync;
        wptr_bin_sync = wptr_gray_sync ^ (wptr_gray_sync >> 1);
        wptr_gray_sync_next = wptr_bin_sync + 1;
        wptr_gray_sync_next = wptr_gray_sync_next ^ (wptr_gray_sync_next >> 1);
    end

    // Full and empty flags
    assign wfull = (wptr_gray_sync_next == gray_r);
    assign rempty = (gray_w == gray_r);

endmodule

module sync_reg #(
    parameter ADDR_WIDTH = 4
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire [ADDR_WIDTH:0]     async_data,
    output wire [ADDR_WIDTH:0]     sync_data
);

    reg [ADDR_WIDTH:0] reg1;
    reg [ADDR_WIDTH:0] reg2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg1 <= 0;
            reg2 <= 0;
        end else begin
            reg1 <= async_data;
            reg2 <= reg1;
        end
    end

    assign sync_data = reg2;

endmodule
