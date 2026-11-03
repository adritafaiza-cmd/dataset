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
    wire fifo_we;
    wire fifo_re;
    wire fifo_full;
    wire fifo_empty;
    wire [ADDR_WIDTH:0] fifo_wr_addr;
    wire [ADDR_WIDTH:0] fifo_rd_addr;
    wire [ADDR_WIDTH:0] fifo_wr_gray;
    wire [ADDR_WIDTH:0] fifo_rd_gray;
    wire [ADDR_WIDTH:0] fifo_wr_gray_synced;
    wire [ADDR_WIDTH:0] fifo_rd_gray_synced;
    wire [ADDR_WIDTH:0] fifo_wr_addr_synced;
    wire [ADDR_WIDTH:0] fifo_rd_addr_synced;
    wire fifo_full_synced;
    wire fifo_empty_synced;
    wire [DATA_WIDTH-1:0] fifo_data;

    // Write address counter in gray code
    gray_counter #(.WIDTH(ADDR_WIDTH+1)) write_gray_counter_inst (
        .clk        (wclk),
        .rst_n      (wrst_n),
        .inc        (fifo_we),
        .gray_count (fifo_wr_gray)
    );

    // Read address counter in gray code
    gray_counter #(.WIDTH(ADDR_WIDTH+1)) read_gray_counter_inst (
        .clk        (rclk),
        .rst_n      (rrst_n),
        .inc        (fifo_re),
        .gray_count (fifo_rd_gray)
    );

    // Convert read binary counter to gray code
    binary_to_gray #(.WIDTH(ADDR_WIDTH+1)) read_bin_to_gray_inst (
        .bin        (fifo_rd_addr),
        .gray       (fifo_rd_gray_synced)
    );

    // Convert write binary counter to gray code
    binary_to_gray #(.WIDTH(ADDR_WIDTH+1)) write_bin_to_gray_inst (
        .bin        (fifo_wr_addr),
        .gray       (fifo_wr_gray_synced)
    );

    // Convert read gray counter to binary code
    gray_to_binary #(.WIDTH(ADDR_WIDTH+1)) read_gray_to_bin_inst (
        .gray       (fifo_wr_gray_synced),
        .bin        (fifo_wr_addr_synced)
    );

    // Convert write gray counter to binary code
    gray_to_binary #(.WIDTH(ADDR_WIDTH+1)) write_gray_to_bin_inst (
        .gray       (fifo_rd_gray_synced),
        .bin        (fifo_rd_addr_synced)
    );

    // Synchronize write flags to read domain
    sync_fifo_flags #(.SYNC_STAGES(SYNC_STAGES)) write_flags_sync_inst (
        .clk_src    (wclk),
        .rst_src_n  (wrst_n),
        .clk_dst    (rclk),
        .rst_dst_n  (rrst_n),
        .flag_src   (fifo_full),
        .flag_dst   (fifo_full_synced)
    );

    // Synchronize read flags to write domain
    sync_fifo_flags #(.SYNC_STAGES(SYNC_STAGES)) read_flags_sync_inst (
        .clk_src    (rclk),
        .rst_src_n  (rrst_n),
        .clk_dst    (wclk),
        .rst_dst_n  (wrst_n),
        .flag_src   (fifo_empty),
        .flag_dst   (fifo_empty_synced)
    );

    // FIFO buffer to store FIFO data
    fifo_buffer #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) fifo_buffer_inst (
        .clk        (wclk),
        .rst_n      (wrst_n),
        .we         (fifo_we),
        .din        (wdata),
        .addr       (fifo_wr_addr),
        .dout       (fifo_data)
    );

    // FIFO full and empty flags
    assign fifo_full  = (fifo_wr_gray == {~fifo_rd_gray_synced[ADDR_WIDTH:ADDR_WIDTH-1], fifo_rd_gray_synced[ADDR_WIDTH-1:0] + 1'b1});
    assign fifo_empty = (fifo_wr_gray == fifo_rd_gray_synced);

    // Write enable and read enable
    assign fifo_we = winc & ~fifo_full_synced;
    assign fifo_re = rinc & ~fifo_empty_synced;

    // FIFO outputs
    assign wfull  = fifo_full_synced;
    assign waddr  = fifo_wr_addr;
    assign rempty = fifo_empty_synced;
    assign raddr  = fifo_rd_addr;
    assign rdata  = fifo_data;

endmodule

module fifo_buffer #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    we,
    input  wire [DATA_WIDTH-1:0]   din,
    input  wire [ADDR_WIDTH:0]     addr,
    output wire [DATA_WIDTH-1:0]   dout
);

    // Memory array
    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    // Write operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (integer i = 0; i < (1<<ADDR_WIDTH); i = i + 1) begin
                mem[i] <= '0;
            end
        end else if (we) begin
            mem[addr[ADDR_WIDTH-1:0]] <= din;
        end
    end

    // Read operation
    assign dout = mem[addr[ADDR_WIDTH-1:0]];

endmodule

module gray_counter #(
    parameter WIDTH = 5
)(
    input  wire          clk,
    input  wire          rst_n,
    input  wire          inc,
    output wire [WIDTH-1:0] gray_count
);

    reg [WIDTH-1:0] bin_count;

    // Binary counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin_count <= '0;
        end else if (inc) begin
            bin_count <= bin_count + 1;
        end
    end

    // Convert binary to gray code
    assign gray_count = bin_count ^ (bin_count >> 1);

endmodule

module binary_to_gray #(
    parameter WIDTH = 5
)(
    input  wire [WIDTH-1:0] bin,
    output wire [WIDTH-1:0] gray
);

    assign gray = bin ^ (bin >> 1);

endmodule

module gray_to_binary #(
    parameter WIDTH = 5
)(
    input  wire [WIDTH-1:0] gray,
    output wire [WIDTH-1:0] bin
);

    wire [WIDTH-1:0] shifted_gray;

    // Shift right gray code
    assign shifted_gray = {1'b0, gray[WIDTH-1:1]};

    // Convert gray code to binary code
    assign bin = gray ^ shifted_gray;

endmodule

module sync_fifo_flags #(
    parameter SYNC_STAGES = 2
)(
    input  wire clk_src,
    input  wire rst_src_n,
    input  wire clk_dst,
    input  wire rst_dst_n,
    input  wire flag_src,
    output wire flag_dst
);

    reg [SYNC_STAGES-1:0] sync_stage;

    // Synchronize flag from source to destination clock domain
    always @(posedge clk_src or negedge rst_src_n) begin
        if (!rst_src_n) begin
            sync_stage <= '0;
        end else begin
            sync_stage[0] <= flag_src;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_stage[i] <= sync_stage[i-1];
            end
        end
    end

    // Output synchronized flag
    always @(posedge clk_dst or negedge rst_dst_n) begin
        if (!rst_dst_n) begin
            flag_dst <= 0;
        end else begin
            flag_dst <= sync_stage[SYNC_STAGES-1];
        end
    end

endmodule
