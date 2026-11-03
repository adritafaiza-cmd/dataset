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
    wire [ADDR_WIDTH:0] gray_wptr_q, gray_rptr_q;
    wire [ADDR_WIDTH:0] wptr_bin, rptr_bin;
    wire [ADDR_WIDTH:0] gray_wptr_sync_rclk, gray_rptr_sync_wclk;
    wire [ADDR_WIDTH:0] wptr_sync_bin_rclk, rptr_sync_bin_wclk;
    wire [ADDR_WIDTH:0] wptr_sync, rptr_sync;
    wire wfull_raw, rempty_raw;

    // Write domain Gray counter
    gray_counter #(.WIDTH(ADDR_WIDTH+1)) gray_wptr (
        .clk(wclk),
        .rst_n(wrst_n),
        .inc(winc),
        .q(gray_wptr_q),
        .bin_q(wptr_bin)
    );

    // Read domain Gray counter
    gray_counter #(.WIDTH(ADDR_WIDTH+1)) gray_rptr (
        .clk(rclk),
        .rst_n(rrst_n),
        .inc(rinc),
        .q(gray_rptr_q),
        .bin_q(rptr_bin)
    );

    // Write pointer to read domain synchronizer
    sync_gray_counter #(.WIDTH(ADDR_WIDTH+1), .STAGES(SYNC_STAGES)) sync_gray_wptr_rclk (
        .clk(rclk),
        .rst_n(rrst_n),
        .d(gray_wptr_q),
        .q(gray_wptr_sync_rclk)
    );

    // Read pointer to write domain synchronizer
    sync_gray_counter #(.WIDTH(ADDR_WIDTH+1), .STAGES(SYNC_STAGES)) sync_gray_rptr_wclk (
        .clk(wclk),
        .rst_n(wrst_n),
        .d(gray_rptr_q),
        .q(gray_rptr_sync_wclk)
    );

    // Convert synchronized write pointer to binary
    gray_to_bin #(.WIDTH(ADDR_WIDTH+1)) gray_to_bin_wptr_sync (
        .gray(gray_wptr_sync_rclk),
        .bin(wptr_sync_bin_rclk)
    );

    // Convert synchronized read pointer to binary
    gray_to_bin #(.WIDTH(ADDR_WIDTH+1)) gray_to_bin_rptr_sync (
        .gray(gray_rptr_sync_wclk),
        .bin(rptr_sync_bin_wclk)
    );

    // Assign synchronized pointers
    assign wptr_sync = wptr_sync_bin_rclk;
    assign rptr_sync = rptr_sync_bin_wclk;

    // FIFO memory array
    memory_array #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH+1)) mem (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .wen(winc),
        .waddr(wptr_bin),
        .wdata(wdata),
        .rclk(rclk),
        .rrst_n(rrst_n),
        .ren(rinc),
        .raddr(rptr_bin),
        .rdata(rdata)
    );

    // Calculate full and empty flags
    assign wfull_raw = (wptr_sync + 1) % (2 ** (ADDR_WIDTH + 1)) == rptr_bin;
    assign rempty_raw = wptr_sync == rptr_bin;

    // Outputs
    assign wfull = wfull_raw;
    assign rempty = rempty_raw;
    assign waddr = wptr_bin;
    assign raddr = rptr_bin;

endmodule

module gray_counter #(
    parameter WIDTH = 5
)(
    input  wire clk,
    input  wire rst_n,
    input  wire inc,
    output reg [WIDTH-1:0] q,
    output wire [WIDTH-1:0] bin_q
);

    reg [WIDTH-1:0] bin_next;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 0;
        end else if (inc) begin
            q <= {bin_next[WIDTH-2:0], ~bin_next[WIDTH-1]};
        end
    end

    assign bin_next = bin_q + 1;
    assign bin_q = q ^ (q >> 1);

endmodule

module sync_gray_counter #(
    parameter WIDTH = 5,
    parameter STAGES = 2
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);

    reg [WIDTH-1:0] sync_stages [0:STAGES-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_stages[0] <= 0;
            if (STAGES > 1) begin
                sync_stages[1:STAGES-1] <= 0;
            end
        end else begin
            sync_stages[0] <= d;
            if (STAGES > 1) begin
                for (int i = 1; i < STAGES; i = i + 1) begin
                    sync_stages[i] <= sync_stages[i-1];
                end
            end
        end
    end

    assign q = sync_stages[STAGES-1];

endmodule

module gray_to_bin #(
    parameter WIDTH = 5
)(
    input  wire [WIDTH-1:0] gray,
    output wire [WIDTH-1:0] bin
);

    wire [WIDTH-1:0] shifted;

    assign shifted = gray >> 1;
    assign bin = gray ^ shifted;

endmodule

module memory_array #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 5
)(
    input  wire wclk,
    input  wire wrst_n,
    input  wire wen,
    input  wire [ADDR_WIDTH-1:0] waddr,
    input  wire [DATA_WIDTH-1:0] wdata,
    input  wire rclk,
    input  wire rrst_n,
    input  wire ren,
    input  wire [ADDR_WIDTH-1:0] raddr,
    output reg [DATA_WIDTH-1:0] rdata
);

    reg [DATA_WIDTH-1:0] mem [0:(2**ADDR_WIDTH)-1];

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            for (int i = 0; i < 2**ADDR_WIDTH; i = i + 1) begin
                mem[i] <= 0;
            end
        end else if (wen) begin
            mem[waddr] <= wdata;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata <= 0;
        end else if (ren) begin
            rdata <= mem[raddr];
        end
    end

endmodule
