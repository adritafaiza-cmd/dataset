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
    wire [ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 3 + 1 - 1:0] request_fifo_wr_data;
    wire request_fifo_wr_en;
    wire request_fifo_full;
    wire [ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 3 + 1 - 1:0] request_fifo_rd_data;
    wire request_fifo_rd_en;
    wire request_fifo_empty;

    // Internal signals for response FIFO
    wire [DATA_WIDTH + 1 - 1:0] response_fifo_wr_data;
    wire response_fifo_wr_en;
    wire response_fifo_full;
    wire [DATA_WIDTH + 1 - 1:0] response_fifo_rd_data;
    wire response_fifo_rd_en;
    wire response_fifo_empty;

    // Pack request data into a single vector for FIFO
    assign request_fifo_wr_data = {src_pwrite_i, src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i};

    // Request FIFO write enable
    assign request_fifo_wr_en = src_psel_i & src_penable_i & !request_fifo_full;

    // Unpack request data from FIFO
    assign dst_pwrite_o = request_fifo_rd_data[ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 3 + 1 - 1];
    assign dst_paddr_o = request_fifo_rd_data[ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 3 + 1 - 2 -: ADDR_WIDTH];
    assign dst_pwdata_o = request_fifo_rd_data[ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 3 + 1 - 2 - ADDR_WIDTH -: DATA_WIDTH];
    assign dst_pstrb_o = request_fifo_rd_data[ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 3 + 1 - 2 - ADDR_WIDTH - DATA_WIDTH -: DATA_WIDTH/8];
    assign dst_pprot_o = request_fifo_rd_data[ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 3 + 1 - 2 - ADDR_WIDTH - DATA_WIDTH - DATA_WIDTH/8 -: 3];

    // Request FIFO read enable
    assign request_fifo_rd_en = !request_fifo_empty & dst_pready_i;

    // Pack response data into a single vector for FIFO
    assign response_fifo_wr_data = {dst_prdata_i, dst_pslverr_i};

    // Response FIFO write enable
    assign response_fifo_wr_en = !response_fifo_full & dst_pready_i;

    // Unpack response data from FIFO
    assign src_prdata_o = response_fifo_rd_data[DATA_WIDTH + 1 - 1 -: DATA_WIDTH];
    assign src_pslverr_o = response_fifo_rd_data[DATA_WIDTH + 1 - 1 - DATA_WIDTH];

    // Response FIFO read enable
    assign response_fifo_rd_en = !response_fifo_empty & src_psel_i & src_penable_i;

    // Source side ready signal
    assign src_pready_o = request_fifo_full ? 1'b0 : request_fifo_empty ? 1'b0 : 1'b1;

    // Destination side select and enable signals
    assign dst_psel_o = !request_fifo_empty;
    assign dst_penable_o = !request_fifo_empty;

    // Instantiate request FIFO
    async_fifo #(
        .WIDTH(ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 3 + 1),
        .LOG_DEPTH(LOG_DEPTH)
    ) request_fifo_inst (
        .clk_wr(src_pclk_i),
        .rst_wr_ni(src_preset_ni),
        .data_wr(request_fifo_wr_data),
        .wr_en(request_fifo_wr_en),
        .full(request_fifo_full),
        .clk_rd(dst_pclk_i),
        .rst_rd_ni(dst_preset_ni),
        .data_rd(request_fifo_rd_data),
        .rd_en(request_fifo_rd_en),
        .empty(request_fifo_empty)
    );

    // Instantiate response FIFO
    async_fifo #(
        .WIDTH(DATA_WIDTH + 1),
        .LOG_DEPTH(LOG_DEPTH)
    ) response_fifo_inst (
        .clk_wr(dst_pclk_i),
        .rst_wr_ni(dst_preset_ni),
        .data_wr(response_fifo_wr_data),
        .wr_en(response_fifo_wr_en),
        .full(response_fifo_full),
        .clk_rd(src_pclk_i),
        .rst_rd_ni(src_preset_ni),
        .data_rd(response_fifo_rd_data),
        .rd_en(response_fifo_rd_en),
        .empty(response_fifo_empty)
    );

endmodule

// Asynchronous FIFO module
module async_fifo #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 1
)(
    input                      clk_wr,
    input                      rst_wr_ni,
    input  [WIDTH-1:0]         data_wr,
    input                      wr_en,
    output                     full,
    input                      clk_rd,
    input                      rst_rd_ni,
    output [WIDTH-1:0]         data_rd,
    input                      rd_en,
    output                     empty
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam AW = LOG_DEPTH;

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [AW:0] wr_ptr;
    reg [AW:0] rd_ptr;
    reg [AW:0] wr_ptr_gray;
    reg [AW:0] rd_ptr_gray;
    reg [AW:0] rd_ptr_gray_sync1;
    reg [AW:0] rd_ptr_gray_sync2;
    reg [AW:0] wr_ptr_gray_sync1;
    reg [AW:0] wr_ptr_gray_sync2;

    // Write pointer logic
    always @(posedge clk_wr or negedge rst_wr_ni) begin
        if (!rst_wr_ni) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr[AW-1:0]] <= data_wr;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read pointer logic
    always @(posedge clk_rd or negedge rst_rd_ni) begin
        if (!rst_rd_ni) begin
            rd_ptr <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Gray code conversion and synchronization
    assign wr_ptr_gray = wr_ptr ^ (wr_ptr >> 1);
    assign rd_ptr_gray = rd_ptr ^ (rd_ptr >> 1);

    always @(posedge clk_rd or negedge rst_rd_ni) begin
        if (!rst_rd_ni) begin
            rd_ptr_gray_sync1 <= 0;
            rd_ptr_gray_sync2 <= 0;
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end

    always @(posedge clk_wr or negedge rst_wr_ni) begin
        if (!rst_wr_ni) begin
            wr_ptr_gray_sync1 <= 0;
            wr_ptr_gray_sync2 <= 0;
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end

    // Data read
    assign data_rd = mem[rd_ptr[AW-1:0]];

    // Full and empty flags
    assign full = (wr_ptr_gray_sync2 == (rd_ptr_gray + 1));
    assign empty = (wr_ptr_gray_sync2 == rd_ptr_gray);

endmodule
