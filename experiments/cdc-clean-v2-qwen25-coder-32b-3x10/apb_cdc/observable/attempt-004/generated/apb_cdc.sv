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
    reg                        req_valid_fifo [0:DEPTH-1];
    reg [$clog2(DEPTH):0]      req_wr_ptr;
    reg [$clog2(DEPTH):0]      req_rd_ptr;
    reg [$clog2(DEPTH):0]      req_full_cnt;
    reg [$clog2(DEPTH):0]      req_empty_cnt;

    // FIFO for responses from destination to source
    reg [DATA_WIDTH-1:0]       resp_rdata_fifo [0:DEPTH-1];
    reg                        resp_slverr_fifo [0:DEPTH-1];
    reg                        resp_valid_fifo [0:DEPTH-1];
    reg [$clog2(DEPTH):0]      resp_wr_ptr;
    reg [$clog2(DEPTH):0]      resp_rd_ptr;
    reg [$clog2(DEPTH):0]      resp_full_cnt;
    reg [$clog2(DEPTH):0]      resp_empty_cnt;

    // Source side logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_pready_o <= 1'b0;
            req_wr_ptr <= {$clog2(DEPTH){1'b0}};
            req_full_cnt <= {$clog2(DEPTH){1'b0}};
        end else begin
            if (src_psel_i && src_penable_i && !req_full_cnt[LOG_DEPTH]) begin
                req_addr_fifo[req_wr_ptr[LOG_DEPTH-1:0]] <= src_paddr_i;
                req_wdata_fifo[req_wr_ptr[LOG_DEPTH-1:0]] <= src_pwdata_i;
                req_strb_fifo[req_wr_ptr[LOG_DEPTH-1:0]] <= src_pstrb_i;
                req_prot_fifo[req_wr_ptr[LOG_DEPTH-1:0]] <= src_pprot_i;
                req_write_fifo[req_wr_ptr[LOG_DEPTH-1:0]] <= src_pwrite_i;
                req_valid_fifo[req_wr_ptr[LOG_DEPTH-1:0]] <= 1'b1;
                req_wr_ptr <= req_wr_ptr + 1;
                req_full_cnt <= req_full_cnt + 1;
            end
            if (resp_valid_fifo[resp_rd_ptr[LOG_DEPTH-1:0]] && src_psel_i && src_penable_i) begin
                src_prdata_o <= resp_rdata_fifo[resp_rd_ptr[LOG_DEPTH-1:0]];
                src_pslverr_o <= resp_slverr_fifo[resp_rd_ptr[LOG_DEPTH-1:0]];
                resp_valid_fifo[resp_rd_ptr[LOG_DEPTH-1:0]] <= 1'b0;
                resp_rd_ptr <= resp_rd_ptr + 1;
                resp_empty_cnt <= resp_empty_cnt + 1;
            end
            src_pready_o <= !req_full_cnt[LOG_DEPTH] && !resp_valid_fifo[resp_rd_ptr[LOG_DEPTH-1:0]];
        end
    end

    // Destination side logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_psel_o <= 1'b0;
            dst_penable_o <= 1'b0;
            req_rd_ptr <= {$clog2(DEPTH){1'b0}};
            req_empty_cnt <= {$clog2(DEPTH){1'b0}};
            resp_wr_ptr <= {$clog2(DEPTH){1'b0}};
            resp_full_cnt <= {$clog2(DEPTH){1'b0}};
        end else begin
            if (req_valid_fifo[req_rd_ptr[LOG_DEPTH-1:0]] && dst_pready_i) begin
                dst_psel_o <= 1'b1;
                dst_penable_o <= 1'b1;
                dst_pwrite_o <= req_write_fifo[req_rd_ptr[LOG_DEPTH-1:0]];
                dst_paddr_o <= req_addr_fifo[req_rd_ptr[LOG_DEPTH-1:0]];
                dst_pwdata_o <= req_wdata_fifo[req_rd_ptr[LOG_DEPTH-1:0]];
                dst_pstrb_o <= req_strb_fifo[req_rd_ptr[LOG_DEPTH-1:0]];
                dst_pprot_o <= req_prot_fifo[req_rd_ptr[LOG_DEPTH-1:0]];
                req_valid_fifo[req_rd_ptr[LOG_DEPTH-1:0]] <= 1'b0;
                req_rd_ptr <= req_rd_ptr + 1;
                req_empty_cnt <= req_empty_cnt + 1;
            end else begin
                dst_psel_o <= 1'b0;
                dst_penable_o <= 1'b0;
            end
            if (dst_psel_o && dst_penable_i && dst_pready_i) begin
                resp_rdata_fifo[resp_wr_ptr[LOG_DEPTH-1:0]] <= dst_prdata_i;
                resp_slverr_fifo[resp_wr_ptr[LOG_DEPTH-1:0]] <= dst_pslverr_i;
                resp_valid_fifo[resp_wr_ptr[LOG_DEPTH-1:0]] <= 1'b1;
                resp_wr_ptr <= resp_wr_ptr + 1;
                resp_full_cnt <= resp_full_cnt + 1;
            end
        end
    end

endmodule
