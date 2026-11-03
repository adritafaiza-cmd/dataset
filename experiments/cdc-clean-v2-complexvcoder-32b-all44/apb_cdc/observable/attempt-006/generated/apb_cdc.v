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

    // Internal signals for FIFOs
    wire                     req_fifo_wr_en;
    wire                     req_fifo_full;
    wire [DATA_WIDTH + ADDR_WIDTH + DATA_WIDTH/8 + 3 + 1 - 1:0] req_fifo_wdata;
    wire                     req_fifo_rd_en;
    wire                     req_fifo_empty;
    wire [DATA_WIDTH + ADDR_WIDTH + DATA_WIDTH/8 + 3 + 1 - 1:0] req_fifo_rdata;

    wire                     resp_fifo_wr_en;
    wire                     resp_fifo_full;
    wire [DATA_WIDTH + 1 - 1:0] resp_fifo_wdata;
    wire                     resp_fifo_rd_en;
    wire                     resp_fifo_empty;
    wire [DATA_WIDTH + 1 - 1:0] resp_fifo_rdata;

    // FIFO for request signals
    fifo #(
        .WIDTH(DATA_WIDTH + ADDR_WIDTH + DATA_WIDTH/8 + 3 + 1),
        .LOG_DEPTH(LOG_DEPTH)
    ) req_fifo_inst (
        .write_clk(src_pclk_i),
        .write_rst_ni(src_preset_ni),
        .wr_en(req_fifo_wr_en),
        .full(req_fifo_full),
        .wdata(req_fifo_wdata),
        .read_clk(dst_pclk_i),
        .read_rst_ni(dst_preset_ni),
        .rd_en(req_fifo_rd_en),
        .empty(req_fifo_empty),
        .rdata(req_fifo_rdata)
    );

    // FIFO for response signals
    fifo #(
        .WIDTH(DATA_WIDTH + 1),
        .LOG_DEPTH(LOG_DEPTH)
    ) resp_fifo_inst (
        .write_clk(dst_pclk_i),
        .write_rst_ni(dst_preset_ni),
        .wr_en(resp_fifo_wr_en),
        .full(resp_fifo_full),
        .wdata(resp_fifo_wdata),
        .read_clk(src_pclk_i),
        .read_rst_ni(src_preset_ni),
        .rd_en(resp_fifo_rd_en),
        .empty(resp_fifo_empty),
        .rdata(resp_fifo_rdata)
    );

    // Request FIFO control signals
    assign req_fifo_wr_en = src_psel_i && src_penable_i && !req_fifo_full;
    assign req_fifo_wdata = {src_pwrite_i, src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i};

    // Destination side control signals
    assign req_fifo_rd_en = !req_fifo_empty && !dst_pready_i && !dst_psel_o;
    assign dst_psel_o = !req_fifo_empty;
    assign dst_penable_o = !req_fifo_empty && dst_pready_i;
    assign dst_pwrite_o = req_fifo_rdata[DATA_WIDTH + ADDR_WIDTH + DATA_WIDTH/8 + 3 + 1 - 1];
    assign dst_paddr_o = req_fifo_rdata[DATA_WIDTH + ADDR_WIDTH + DATA_WIDTH/8 + 3 - 1 -: ADDR_WIDTH];
    assign dst_pwdata_o = req_fifo_rdata[DATA_WIDTH + DATA_WIDTH/8 + 3 - 1 -: DATA_WIDTH];
    assign dst_pstrb_o = req_fifo_rdata[DATA_WIDTH/8 + 3 - 1 -: DATA_WIDTH/8];
    assign dst_pprot_o = req_fifo_rdata[3 - 1 -: 3];

    // Response FIFO control signals
    assign resp_fifo_wr_en = dst_pready_i;
    assign resp_fifo_wdata = {dst_prdata_i, dst_pslverr_i};

    // Source side control signals
    assign resp_fifo_rd_en = !resp_fifo_empty && src_pready_o;
    assign src_pready_o = !resp_fifo_full;
    assign src_prdata_o = resp_fifo_rdata[DATA_WIDTH - 1 -: DATA_WIDTH];
    assign src_pslverr_o = resp_fifo_rdata[0];

endmodule

module fifo #(
    parameter WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      write_clk,
    input                      write_rst_ni,
    input                      wr_en,
    output                     full,
    input  [WIDTH-1:0]         wdata,
    input                      read_clk,
    input                      read_rst_ni,
    input                      rd_en,
    output                     empty,
    output [WIDTH-1:0]         rdata
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam AW = LOG_DEPTH;

    reg [WIDTH-1:0] mem [DEPTH-1:0];
    reg [AW:0] wr_ptr, rd_ptr;
    reg [AW:0] wr_ptr_gray, rd_ptr_gray;
    reg [AW:0] wr_ptr_gray_sync, rd_ptr_gray_sync;

    // Write pointer logic
    always @(posedge write_clk or negedge write_rst_ni) begin
        if (!write_rst_ni) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read pointer logic
    always @(posedge read_clk or negedge read_rst_ni) begin
        if (!read_rst_ni) begin
            rd_ptr <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Gray code conversion for write pointer
    always @(wr_ptr) begin
        wr_ptr_gray = (wr_ptr >> 1) ^ wr_ptr;
    end

    // Gray code conversion for read pointer
    always @(rd_ptr) begin
        rd_ptr_gray = (rd_ptr >> 1) ^ rd_ptr;
    end

    // Synchronize read pointer Gray code to write clock domain
    always @(posedge write_clk or negedge write_rst_ni) begin
        if (!write_rst_ni) begin
            rd_ptr_gray_sync <= 0;
        end else begin
            rd_ptr_gray_sync <= rd_ptr_gray;
        end
    end

    // Synchronize write pointer Gray code to read clock domain
    always @(posedge read_clk or negedge read_rst_ni) begin
        if (!read_rst_ni) begin
            wr_ptr_gray_sync <= 0;
        end else begin
            wr_ptr_gray_sync <= wr_ptr_gray;
        end
    end

    // Write data
    always @(posedge write_clk) begin
        if (wr_en && !full) begin
            mem[wr_ptr[AW-1:0]] <= wdata;
        end
    end

    // Read data
    assign rdata = mem[rd_ptr[AW-1:0]];

    // Full flag
    assign full = (wr_ptr_gray[AW] != rd_ptr_gray_sync[AW]) && (wr_ptr_gray[AW-1:0] == rd_ptr_gray_sync[AW-1:0]);

    // Empty flag
    assign empty = (wr_ptr_gray_sync[AW] == rd_ptr_gray[AW]) && (wr_ptr_gray_sync[AW-1:0] == rd_ptr_gray[AW-1:0]);

endmodule
