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

    localparam DEPTH = 1 << LOG_DEPTH;

    // FIFO for requests from source to destination
    reg [ADDR_WIDTH-1:0]       req_addr_fifo [0:DEPTH-1];
    reg [DATA_WIDTH-1:0]       req_wdata_fifo [0:DEPTH-1];
    reg [DATA_WIDTH/8-1:0]     req_strb_fifo [0:DEPTH-1];
    reg [2:0]                  req_prot_fifo [0:DEPTH-1];
    reg                        req_write_fifo [0:DEPTH-1];
    reg [$clog2(DEPTH):0]      req_wr_ptr;
    reg [$clog2(DEPTH):0]      req_rd_ptr;
    reg [$clog2(DEPTH):0]      req_count;

    // FIFO for responses from destination to source
    reg [DATA_WIDTH-1:0]       resp_rdata_fifo [0:DEPTH-1];
    reg                        resp_slverr_fifo [0:DEPTH-1];
    reg [$clog2(DEPTH):0]      resp_wr_ptr;
    reg [$clog2(DEPTH):0]      resp_rd_ptr;
    reg [$clog2(DEPTH):0]      resp_count;

    // Source side logic
    reg                        src_req_valid;
    reg                        src_req_ready;
    reg                        src_resp_valid;
    reg                        src_resp_ready;

    // Destination side logic
    reg                        dst_req_valid;
    reg                        dst_req_ready;
    reg                        dst_resp_valid;
    reg                        dst_resp_ready;

    // Source side request FIFO
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            req_wr_ptr <= 0;
            req_count <= 0;
        end else if (src_req_valid && src_req_ready) begin
            req_addr_fifo[req_wr_ptr] <= src_paddr_i;
            req_wdata_fifo[req_wr_ptr] <= src_pwdata_i;
            req_strb_fifo[req_wr_ptr] <= src_pstrb_i;
            req_prot_fifo[req_wr_ptr] <= src_pprot_i;
            req_write_fifo[req_wr_ptr] <= src_pwrite_i;
            req_wr_ptr <= req_wr_ptr + 1;
            req_count <= req_count + 1;
        end
    end

    // Source side response FIFO
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            resp_rd_ptr <= 0;
            resp_count <= 0;
        end else if (src_resp_valid && src_resp_ready) begin
            resp_rd_ptr <= resp_rd_ptr + 1;
            resp_count <= resp_count - 1;
        end
    end

    // Source side request valid and ready
    assign src_req_valid = src_psel_i && src_penable_i && (req_count < DEPTH);
    assign src_req_ready = (req_count < DEPTH);

    // Source side response valid and ready
    assign src_resp_valid = (resp_count > 0);
    assign src_resp_ready = 1;

    // Source side APB signals
    assign src_pready_o = src_req_ready;
    assign src_prdata_o = resp_rdata_fifo[resp_rd_ptr];
    assign src_pslverr_o = resp_slverr_fifo[resp_rd_ptr];

    // Destination side request FIFO
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            req_rd_ptr <= 0;
        end else if (dst_req_valid && dst_req_ready) begin
            req_rd_ptr <= req_rd_ptr + 1;
            req_count <= req_count - 1;
        end
    end

    // Destination side response FIFO
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            resp_wr_ptr <= 0;
            resp_count <= 0;
        end else if (dst_resp_valid && dst_resp_ready) begin
            resp_rdata_fifo[resp_wr_ptr] <= dst_prdata_i;
            resp_slverr_fifo[resp_wr_ptr] <= dst_pslverr_i;
            resp_wr_ptr <= resp_wr_ptr + 1;
            resp_count <= resp_count + 1;
        end
    end

    // Destination side request valid and ready
    assign dst_req_valid = (req_count > 0);
    assign dst_req_ready = dst_pready_i;

    // Destination side response valid and ready
    assign dst_resp_valid = (resp_count < DEPTH);
    assign dst_resp_ready = 1;

    // Destination side APB signals
    assign dst_psel_o = dst_req_valid;
    assign dst_penable_o = dst_req_valid;
    assign dst_pwrite_o = req_write_fifo[req_rd_ptr];
    assign dst_paddr_o = req_addr_fifo[req_rd_ptr];
    assign dst_pwdata_o = req_wdata_fifo[req_rd_ptr];
    assign dst_pstrb_o = req_strb_fifo[req_rd_ptr];
    assign dst_pprot_o = req_prot_fifo[req_rd_ptr];

endmodule
