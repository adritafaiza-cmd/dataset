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
    wire [ADDR_WIDTH:0] wgray, rgray;
    wire [ADDR_WIDTH:0] wptr, rptr;
    wire [ADDR_WIDTH:0] rgray_synced_wclk, rptr_synced_wclk;
    wire [ADDR_WIDTH:0] wgray_synced_rclk, wptr_synced_rclk;
    wire wfull_raw, rempty_raw;

    // Write domain gray counter
    gray_counter #(.ADDR_WIDTH(ADDR_WIDTH + 1)) gray_counter_w (
        .clk(wclk),
        .rst_n(wrst_n),
        .inc(winc),
        .gray(wgray)
    );

    // Read domain gray counter
    gray_counter #(.ADDR_WIDTH(ADDR_WIDTH + 1)) gray_counter_r (
        .clk(rclk),
        .rst_n(rrst_n),
        .inc(rinc),
        .gray(rgray)
    );

    // Write pointer conversion
    gray_to_bin #(.ADDR_WIDTH(ADDR_WIDTH + 1)) gray_to_bin_w (
        .gray(wgray),
        .bin(wptr)
    );

    // Read pointer conversion
    gray_to_bin #(.ADDR_WIDTH(ADDR_WIDTH + 1)) gray_to_bin_r (
        .gray(rgray),
        .bin(rptr)
    );

    // Synchronize read pointer to write clock domain
    sync_register #(.ADDR_WIDTH(ADDR_WIDTH + 1), .SYNC_STAGES(SYNC_STAGES)) sync_rptr_wclk (
        .din(rgray),
        .dout(rgray_synced_wclk),
        .clk(wclk),
        .rst_n(wrst_n)
    );

    // Synchronize write pointer to read clock domain
    sync_register #(.ADDR_WIDTH(ADDR_WIDTH + 1), .SYNC_STAGES(SYNC_STAGES)) sync_wptr_rclk (
        .din(wgray),
        .dout(wgray_synced_rclk),
        .clk(rclk),
        .rst_n(rrst_n)
    );

    // Convert synchronized read pointer to binary in write clock domain
    gray_to_bin #(.ADDR_WIDTH(ADDR_WIDTH + 1)) gray_to_bin_sync_rptr_wclk (
        .gray(rgray_synced_wclk),
        .bin(rptr_synced_wclk)
    );

    // Convert synchronized write pointer to binary in read clock domain
    gray_to_bin #(.ADDR_WIDTH(ADDR_WIDTH + 1)) gray_to_bin_sync_wptr_rclk (
        .gray(wgray_synced_rclk),
        .bin(wptr_synced_rclk)
    );

    // Dual-port RAM for FIFO storage
    ram #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH + 1)) fifo_ram (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .waddr(wptr),
        .winc(winc),
        .wdata(wdata),
        .rclk(rclk),
        .rrst_n(rrst_n),
        .raddr(rptr_synced_wclk),
        .rdata(rdata)
    );

    // FIFO full flag
    assign wfull_raw = (wptr_synced_rclk == {~wptr[ADDR_WIDTH], wptr[ADDR_WIDTH-1:0]});
    assign wfull = wfull_raw;

    // FIFO empty flag
    assign rempty_raw = (rptr_synced_wclk == wgray);
    assign rempty = rempty_raw;

    // Debug address outputs
    assign waddr = wptr;
    assign raddr = rptr;

endmodule

// Gray code counter module
module gray_counter #(
    parameter ADDR_WIDTH = 5
)(
    input  wire clk,
    input  wire rst_n,
    input  wire inc,
    output wire [ADDR_WIDTH-1:0] gray
);

    reg [ADDR_WIDTH-1:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= 'b0;
        else if (inc)
            count <= count + 1;
    end

    assign gray = (count >> 1) ^ count;

endmodule

// Gray to binary converter module
module gray_to_bin #(
    parameter ADDR_WIDTH = 5
)(
    input  wire [ADDR_WIDTH-1:0] gray,
    output wire [ADDR_WIDTH-1:0] bin
);

    reg [ADDR_WIDTH-1:0] bin_reg;

    always @(*) begin
        bin_reg[ADDR_WIDTH-1] = gray[ADDR_WIDTH-1];
        for (int i = ADDR_WIDTH - 2; i >= 0; i = i - 1) begin
            bin_reg[i] = gray[i] ^ bin_reg[i+1];
        end
    end

    assign bin = bin_reg;

endmodule

// Synchronizer register module
module sync_register #(
    parameter ADDR_WIDTH = 5,
    parameter SYNC_STAGES = 2
)(
    input  wire [ADDR_WIDTH-1:0] din,
    output wire [ADDR_WIDTH-1:0] dout,
    input  wire clk,
    input  wire rst_n
);

    reg [ADDR_WIDTH-1:0] sync_reg [SYNC_STAGES-1:0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < SYNC_STAGES; i = i + 1) begin
                sync_reg[i] <= 'b0;
            end
        end else begin
            sync_reg[0] <= din;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_reg[i] <= sync_reg[i-1];
            end
        end
    end

    assign dout = sync_reg[SYNC_STAGES-1];

endmodule

// Dual-port RAM module
module ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 5
)(
    input  wire wclk,
    input  wire wrst_n,
    input  wire [ADDR_WIDTH-1:0] waddr,
    input  wire winc,
    input  wire [DATA_WIDTH-1:0] wdata,
    input  wire rclk,
    input  wire rrst_n,
    input  wire [ADDR_WIDTH-1:0] raddr,
    output wire [DATA_WIDTH-1:0] rdata
);

    reg [DATA_WIDTH-1:0] memory [2**ADDR_WIDTH-1:0];

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            for (int i = 0; i < 2**ADDR_WIDTH; i = i + 1) begin
                memory[i] <= 'b0;
            end
        end else if (winc) begin
            memory[waddr] <= wdata;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rdata <= 'b0;
        else
            rdata <= memory[raddr];
    end

endmodule
