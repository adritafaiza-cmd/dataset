module apb_cdc #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      src_pclk_i,
    input                      src_preset_ni,
    input                      src_psel_i,
    input                      src_penable_i,
    input                      src_pwrite_i,
    input  [ADDR_WIDTH-1:0]    src_paddr_i,
    input  [DATA_WIDTH-1:0]    src_pwdata_i,
    input  [DATA_WIDTH/8-1:0]  src_pstrb_i,
    input  [2:0]               src_pprot_i,
    output                     src_pready_o,
    output [DATA_WIDTH-1:0]    src_prdata_o,
    output                     src_pslverr_o,
    input                      dst_pclk_i,
    input                      dst_preset_ni,
    output                     dst_psel_o,
    output                     dst_penable_o,
    output                     dst_pwrite_o,
    output [ADDR_WIDTH-1:0]    dst_paddr_o,
    output [DATA_WIDTH-1:0]    dst_pwdata_o,
    output [DATA_WIDTH/8-1:0]  dst_pstrb_o,
    output [2:0]               dst_pprot_o,
    input                      dst_pready_i,
    input  [DATA_WIDTH-1:0]    dst_prdata_i,
    input                      dst_pslverr_i
);

    // Internal signals for request FIFO
    wire [ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+2:0] req_fifo_wr_data;
    wire                                          req_fifo_wr_en;
    wire [ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+2:0] req_fifo_rd_data;
    wire                                          req_fifo_rd_en;
    wire                                          req_fifo_full;
    wire                                          req_fifo_empty;

    // Internal signals for response FIFO
    wire [DATA_WIDTH:0]                             resp_fifo_wr_data;
    wire                                          resp_fifo_wr_en;
    wire [DATA_WIDTH:0]                             resp_fifo_rd_data;
    wire                                          resp_fifo_rd_en;
    wire                                          resp_fifo_full;
    wire                                          resp_fifo_empty;

    // Assign request FIFO write data
    assign req_fifo_wr_data = {src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i, src_pwrite_i};

    // Assign request FIFO write enable
    assign req_fifo_wr_en = src_psel_i && src_penable_i && !req_fifo_full;

    // Assign destination APB control signals
    assign dst_psel_o     = !req_fifo_empty;
    assign dst_penable_o  = dst_pready_i && !req_fifo_empty;
    assign dst_pwrite_o   = req_fifo_rd_data[ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+2];
    assign dst_paddr_o    = req_fifo_rd_data[ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+1:ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+1-ADDR_WIDTH];
    assign dst_pwdata_o   = req_fifo_rd_data[ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8:ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+1-ADDR_WIDTH-DATA_WIDTH];
    assign dst_pstrb_o    = req_fifo_rd_data[ADDR_WIDTH+DATA_WIDTH/8-1:ADDR_WIDTH+DATA_WIDTH/8+1-ADDR_WIDTH-DATA_WIDTH-DATA_WIDTH/8];
    assign dst_pprot_o    = req_fifo_rd_data[2:0];

    // Assign request FIFO read enable
    assign req_fifo_rd_en = dst_pready_i && !req_fifo_empty;

    // Assign response FIFO write data
    assign resp_fifo_wr_data = {dst_prdata_i, dst_pslverr_i};

    // Assign response FIFO write enable
    assign resp_fifo_wr_en = dst_pready_i && !req_fifo_empty;

    // Assign source APB response signals
    assign src_prdata_o   = resp_fifo_rd_data[DATA_WIDTH:1];
    assign src_pslverr_o  = resp_fifo_rd_data[0];
    assign src_pready_o   = !resp_fifo_empty;

    // Assign response FIFO read enable
    assign resp_fifo_rd_en = src_pready_o && !resp_fifo_empty;

    // Instantiate request FIFO
    async_fifo #(
        .DATA_WIDTH(ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+3),
        .LOG_DEPTH(LOG_DEPTH)
    ) req_fifo_inst (
        .wclk   (src_pclk_i),
        .wrst_n (src_preset_ni),
        .din    (req_fifo_wr_data),
        .wr_en  (req_fifo_wr_en),
        .rclk   (dst_pclk_i),
        .rrst_n (dst_preset_ni),
        .dout   (req_fifo_rd_data),
        .rd_en  (req_fifo_rd_en),
        .full   (req_fifo_full),
        .empty  (req_fifo_empty)
    );

    // Instantiate response FIFO
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH+1),
        .LOG_DEPTH(LOG_DEPTH)
    ) resp_fifo_inst (
        .wclk   (dst_pclk_i),
        .wrst_n (dst_preset_ni),
        .din    (resp_fifo_wr_data),
        .wr_en  (resp_fifo_wr_en),
        .rclk   (src_pclk_i),
        .rrst_n (src_preset_ni),
        .dout   (resp_fifo_rd_data),
        .rd_en  (resp_fifo_rd_en),
        .full   (resp_fifo_full),
        .empty  (resp_fifo_empty)
    );

endmodule

module async_fifo #(
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      wclk,
    input                      wrst_n,
    input  [DATA_WIDTH-1:0]    din,
    input                      wr_en,
    input                      rclk,
    input                      rrst_n,
    output [DATA_WIDTH-1:0]    dout,
    input                      rd_en,
    output                     full,
    output                     empty
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam ADDR_WIDTH = LOG_DEPTH;

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH:0] wptr, rptr;
    reg [ADDR_WIDTH:0] wptr_gray, rptr_gray;
    reg [ADDR_WIDTH:0] wptr_gray_rsync, rptr_gray_rsync;

    // Write pointer logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
        end else if (wr_en && !full) begin
            wptr <= wptr + 1;
        end
    end

    // Read pointer logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
        end else if (rd_en && !empty) begin
            rptr <= rptr + 1;
        end
    end

    // Gray code conversion for pointers
    assign wptr_gray = (wptr >> 1) ^ wptr;
    assign rptr_gray = (rptr >> 1) ^ rptr;

    // Cross-domain synchronization of gray-coded pointers
    sync_gray_ptr wptr_sync (
        .clk (rclk),
        .rst_n (rrst_n),
        .din (wptr_gray),
        .dout (wptr_gray_rsync)
    );

    sync_gray_ptr rptr_sync (
        .clk (wclk),
        .rst_n (wrst_n),
        .din (rptr_gray),
        .dout (rptr_gray_rsync)
    );

    // Binary conversion of synchronized gray-coded pointers
    reg [ADDR_WIDTH:0] wptr_bin_rsync, rptr_bin_rsync;

    binary_conversion wptr_bin_conv (
        .gray (wptr_gray_rsync),
        .bin  (wptr_bin_rsync)
    );

    binary_conversion rptr_bin_conv (
        .gray (rptr_gray_rsync),
        .bin  (rptr_bin_rsync)
    );

    // Full and empty flags
    assign full = (wptr_gray_rsync == {~rptr_bin_rsync[ADDR_WIDTH], rptr_bin_rsync[ADDR_WIDTH-1:0]});
    assign empty = (wptr_gray_rsync == rptr_gray_rsync);

    // Memory write
    always @(posedge wclk) begin
        if (wr_en && !full) begin
            mem[wptr[ADDR_WIDTH-1:0]] <= din;
        end
    end

    // Memory read
    always @(posedge rclk) begin
        if (rd_en && !empty) begin
            dout <= mem[rptr[ADDR_WIDTH-1:0]];
        end
    end

endmodule

module sync_gray_ptr (
    input clk,
    input rst_n,
    input [3:0] din,
    output [3:0] dout
);

    reg [3:0] sync_reg1, sync_reg2;

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

module binary_conversion (
    input [3:0] gray,
    output [3:0] bin
);

    assign bin[3] = gray[3];
    assign bin[2] = gray[3] ^ gray[2];
    assign bin[1] = gray[2] ^ gray[1];
    assign bin[0] = gray[1] ^ gray[0];

endmodule
