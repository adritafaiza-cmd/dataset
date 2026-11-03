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

    wire [ADDR_WIDTH:0] wr_addr_gray, wr_addr_gray_sync, rd_addr_gray, rd_addr_gray_sync;
    wire [ADDR_WIDTH:0] wr_ptr, rd_ptr;

    // FIFO Memory
    fifo_mem #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) fifo_memory (
        .wclk     (wclk),
        .wrst_n   (wrst_n),
        .winc     (winc),
        .wdata    (wdata),
        .rclk     (rclk),
        .rrst_n   (rrst_n),
        .rinc     (rinc),
        .wr_addr  (wr_addr_gray),
        .rd_addr  (rd_addr_gray),
        .wr_gray  (wr_addr_gray_sync),
        .rd_gray  (rd_addr_gray_sync),
        .rdata    (rdata),
        .wfull    (wfull),
        .rempty   (rempty)
    );

    // Write Gray Counter
    gray_counter #(
        .WIDTH(ADDR_WIDTH + 1)
    ) w_gray_counter (
        .clk    (wclk),
        .rst_n  (wrst_n),
        .inc    (winc & ~wfull),
        .gray   (wr_addr_gray),
        .bin    (wr_ptr)
    );

    // Read Gray Counter
    gray_counter #(
        .WIDTH(ADDR_WIDTH + 1)
    ) r_gray_counter (
        .clk    (rclk),
        .rst_n  (rrst_n),
        .inc    (rinc & ~rempty),
        .gray   (rd_addr_gray),
        .bin    (rd_ptr)
    );

    // Write Gray Counter Synchronization
    sync_gray_counter #(
        .WIDTH(ADDR_WIDTH + 1),
        .STAGES(SYNC_STAGES)
    ) w_gray_sync (
        .clk     (rclk),
        .rst_n   (rrst_n),
        .data_in (wr_addr_gray),
        .data_out(wr_addr_gray_sync)
    );

    // Read Gray Counter Synchronization
    sync_gray_counter #(
        .WIDTH(ADDR_WIDTH + 1),
        .STAGES(SYNC_STAGES)
    ) r_gray_sync (
        .clk     (wclk),
        .rst_n   (wrst_n),
        .data_in (rd_addr_gray),
        .data_out(rd_addr_gray_sync)
    );

    // Output Addresses
    assign waddr = wr_ptr;
    assign raddr = rd_ptr;

endmodule

// FIFO Memory Module
module fifo_mem #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input  wire                    wclk,
    input  wire                    wrst_n,
    input  wire                    winc,
    input  wire [DATA_WIDTH-1:0]   wdata,
    input  wire                    rclk,
    input  wire                    rrst_n,
    input  wire                    rinc,
    input  wire [ADDR_WIDTH:0]     wr_addr,
    input  wire [ADDR_WIDTH:0]     rd_addr,
    input  wire [ADDR_WIDTH:0]     wr_gray,
    input  wire [ADDR_WIDTH:0]     rd_gray,
    output wire [DATA_WIDTH-1:0]   rdata,
    output wire                    wfull,
    output wire                    rempty
);

    reg [DATA_WIDTH-1:0] mem [0:(1 << ADDR_WIDTH) - 1];
    reg [ADDR_WIDTH:0] wr_ptr, rd_ptr;
    reg [ADDR_WIDTH:0] wr_gray_sync, rd_gray_sync;

    // Write Pointer Logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wr_ptr <= 0;
        end else if (winc & ~wfull) begin
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read Pointer Logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rd_ptr <= 0;
        end else if (rinc & ~rempty) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Memory Write
    always @(posedge wclk) begin
        if (winc & ~wfull) begin
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= wdata;
        end
    end

    // Memory Read
    assign rdata = mem[rd_ptr[ADDR_WIDTH-1:0]];

    // Full and Empty Flags
    assign wfull = (wr_gray_sync[ADDR_WIDTH] != rd_gray[ADDR_WIDTH]) && (wr_gray_sync[ADDR_WIDTH-1:0] == rd_gray[ADDR_WIDTH-1:0]);
    assign rempty = (wr_gray == rd_gray);

endmodule

// Gray Counter Module
module gray_counter #(
    parameter WIDTH = 5
)(
    input  wire clk,
    input  wire rst_n,
    input  wire inc,
    output reg [WIDTH-1:0] gray,
    output wire [WIDTH-1:0] bin
);

    reg [WIDTH-1:0] count;

    // Binary Counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
        end else if (inc) begin
            count <= count + 1;
        end
    end

    // Gray Code Conversion
    assign gray = (count >> 1) ^ count;

    // Output Binary Count
    assign bin = count;

endmodule

// Sync Gray Counter Module
module sync_gray_counter #(
    parameter WIDTH = 5,
    parameter STAGES = 2
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);

    reg [WIDTH-1:0] sync [0:STAGES-1];

    // Synchronization Stages
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync <= 0;
        end else begin
            sync[0] <= data_in;
            for (int i = 1; i < STAGES; i = i + 1) begin
                sync[i] <= sync[i-1];
            end
        end
    end

    // Output Synchronized Data
    assign data_out = sync[STAGES-1];

endmodule
