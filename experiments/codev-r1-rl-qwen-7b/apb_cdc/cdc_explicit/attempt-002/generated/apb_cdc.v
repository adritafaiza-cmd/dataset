module apb_cdc #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    // Source side (APB Slave)
    input                      src_pclk_i,
    input                      src_preset_ni,
    input                      src_psel_i,
    input                      src_penable_i,
    input                      src_pwrite_i,
    input  [ADDR_WIDTH-1:0]    src_paddr_i,
    input  [DATA_WIDTH-1:0]    src_pwdata_i,
    input  [(DATA_WIDTH/8)-1:0] src_pstrb_i,
    input  [2:0]               src_pprot_i,
    output                     src_pready_o,
    output [DATA_WIDTH-1:0]    src_prdata_o,
    output                     src_pslverr_o,

    // Destination side (APB Master)
    input                      dst_pclk_i,
    input                      dst_preset_ni,
    output reg                 dst_psel_o,
    output reg                 dst_penable_o,
    output reg                 dst_pwrite_o,
    output reg [ADDR_WIDTH-1:0] dst_paddr_o,
    output reg [DATA_WIDTH-1:0] dst_pwdata_o,
    output reg [(DATA_WIDTH/8)-1:0] dst_pstrb_o,
    output reg [2:0]            dst_pprot_o,
    input                      dst_pready_i,
    input  [DATA_WIDTH-1:0]    dst_prdata_i,
    input                      dst_pslverr_i
);

// Request FIFO parameters
localparam REQ_FIFO_DATA_WIDTH = 1 + ADDR_WIDTH + DATA_WIDTH + (DATA_WIDTH/8) + 3;
localparam FIFO_DEPTH = 2**LOG_DEPTH;

// Request FIFO
reg [REQ_FIFO_DATA_WIDTH-1:0] req_fifo [0:FIFO_DEPTH-1];
reg [LOG_DEPTH:0] req_wr_ptr = 0;
reg [LOG_DEPTH:0] req_rd_ptr = 0;
reg [LOG_DEPTH:0] req_wr_ptr_gray = 0;
reg [LOG_DEPTH:0] req_rd_ptr_gray = 0;
reg [LOG_DEPTH:0] req_wr_ptr_gray_sync1 = 0;
reg [LOG_DEPTH:0] req_wr_ptr_gray_sync2 = 0;
reg [LOG_DEPTH:0] req_rd_ptr_gray_sync1 = 0;
reg [LOG_DEPTH:0] req_rd_ptr_gray_sync2 = 0;

// Response FIFO
localparam RESP_FIFO_DATA_WIDTH = DATA_WIDTH + 1;
reg [RESP_FIFO_DATA_WIDTH-1:0] resp_fifo [0:FIFO_DEPTH-1];
reg [LOG_DEPTH:0] resp_wr_ptr = 0;
reg [LOG_DEPTH:0] resp_rd_ptr = 0;
reg [LOG_DEPTH:0] resp_wr_ptr_gray = 0;
reg [LOG_DEPTH:0] resp_rd_ptr_gray = 0;
reg [LOG_DEPTH:0] resp_wr_ptr_gray_sync1 = 0;
reg [LOG_DEPTH:0] resp_wr_ptr_gray_sync2 = 0;
reg [LOG_DEPTH:0] resp_rd_ptr_gray_sync1 = 0;
reg [LOG_DEPTH:0] resp_rd_ptr_gray_sync2 = 0;

// Source side registers
reg src_pready;
reg [ADDR_WIDTH-1:0] src_paddr_reg;
reg [DATA_WIDTH-1:0] src_pwdata_reg;
reg [(DATA_WIDTH/8)-1:0] src_pstrb_reg;
reg [2:0] src_pprot_reg;
reg src_pwrite_reg;

// Destination side registers
reg dst_pready_sync1, dst_pready_sync2;

// Source side logic
always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (!src_preset_ni) begin
        src_pready <= 1'b1;
        req_wr_ptr <= 0;
        req_wr_ptr_gray <= 0;
        req_rd_ptr <= 0;
        req_rd_ptr_gray <= 0;
        resp_rd_ptr <= 0;
        resp_rd_ptr_gray <= 0;
    end else begin
        // Synchronize destination ready
        dst_pready_sync1 <= dst_pready_i;
        dst_pready_sync2 <= dst_pready_sync1;

        // Capture request
        if (src_pready && src_psel_i && src_penable_i) begin
            src_paddr_reg <= src_paddr_i;
            src_pwdata_reg <= src_pwdata_i;
            src_pstrb_reg <= src_pstrb_i;
            src_pprot_reg <= src_pprot_i;
            src_pwrite_reg <= src_pwrite_i;
            // Write to request FIFO
            req_fifo[req_wr_ptr] <= {src_pwrite_i, src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i};
            req_wr_ptr <= req_wr_ptr + 1;
            req_wr_ptr_gray <= req_wr_ptr + 1;
            src_pready <= 1'b0;
        end

        // Read response FIFO
        if (resp_rd_ptr_gray != resp_wr_ptr_gray_sync2) begin
            {src_prdata_o, src_pslverr_o} <= resp_fifo[resp_rd_ptr];
            resp_rd_ptr <= resp_rd_ptr + 1;
            resp_rd_ptr_gray <= resp_rd_ptr + 1;
        end

        // Update response FIFO read pointer synchronization
        resp_rd_ptr_gray_sync1 <= resp_rd_ptr_gray;
        resp_rd_ptr_gray_sync2 <= resp_rd_ptr_gray_sync1;
    end
end

// Destination side logic
always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (!dst_preset_ni) begin
        dst_psel_o <= 0;
        dst_penable_o <= 0;
        dst_paddr_o <= 0;
        dst_pwdata_o <= 0;
        dst_pstrb_o <= 0;
        dst_pwrite_o <= 0;
        dst_pprot_o <= 0;
        req_rd_ptr <= 0;
        req_rd_ptr_gray <= 0;
        req_wr_ptr_gray_sync1 <= 0;
        req_wr_ptr_gray_sync2 <= 0;
        resp_wr_ptr <= 0;
        resp_wr_ptr_gray <= 0;
        resp_wr_ptr_gray_sync1 <= 0;
        resp_wr_ptr_gray_sync2 <= 0;
    end else begin
        // Synchronize request FIFO write pointer
        req_wr_ptr_gray_sync1 <= req_wr_ptr_gray;
        req_wr_ptr_gray_sync2 <= req_wr_ptr_gray_sync1;

        // Read request FIFO
        if (req_rd_ptr_gray != req_wr_ptr_gray_sync2) begin
            {dst_pwrite_o, dst_paddr_o, dst_pwdata_o, dst_pstrb_o, dst_pprot_o} <= req_fifo[req_rd_ptr];
            dst_psel_o <= 1;
            dst_penable_o <= 0;
            req_rd_ptr <= req_rd_ptr + 1;
            req_rd_ptr_gray <= req_rd_ptr + 1;
        end

        // Complete transfer
        if (dst_psel_o && dst_penable_o && dst_pready_i) begin
            dst_psel_o <= 0;
            dst_penable_o <= 0;
            // Write response to FIFO
            resp_fifo[resp_wr_ptr] <= {dst_prdata_i, dst_pslverr_i};
            resp_wr_ptr <= resp_wr_ptr + 1;
            resp_wr_ptr_gray <= resp_wr_ptr + 1;
        end

        // Update request FIFO read pointer synchronization
        req_rd_ptr_gray_sync1 <= req_rd_ptr_gray;
        req_rd_ptr_gray_sync2 <= req_rd_ptr_gray_sync1;

        // Synchronize response FIFO write pointer
        resp_wr_ptr_gray_sync1 <= resp_wr_ptr_gray;
        resp_wr_ptr_gray_sync2 <= resp_wr_ptr_gray_sync1;
    end
end

assign src_pready_o = src_pready;

endmodule
