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

    // FIFO for requests
    reg [ADDR_WIDTH-1:0] req_addr_fifo [DEPTH-1:0];
    reg [DATA_WIDTH-1:0] req_wdata_fifo [DEPTH-1:0];
    reg [DATA_WIDTH/8-1:0] req_strb_fifo [DEPTH-1:0];
    reg [2:0] req_prot_fifo [DEPTH-1:0];
    reg req_write_fifo [DEPTH-1:0];
    reg [LOG_DEPTH:0] req_wr_ptr, req_rd_ptr;
    reg req_full, req_empty;

    // FIFO for responses
    reg [DATA_WIDTH-1:0] resp_rdata_fifo [DEPTH-1:0];
    reg resp_slverr_fifo [DEPTH-1:0];
    reg [LOG_DEPTH:0] resp_wr_ptr, resp_rd_ptr;
    reg resp_full, resp_empty;

    // Source side logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            req_wr_ptr <= 0;
            req_rd_ptr <= 0;
            src_pready_o <= 0;
        end else begin
            if (src_psel_i && src_penable_i && !req_full) begin
                req_addr_fifo[req_wr_ptr[LOG_DEPTH-1:0]] <= src_paddr_i;
                req_wdata_fifo[req_wr_ptr[LOG_DEPTH-1:0]] <= src_pwdata_i;
                req_strb_fifo[req_wr_ptr[LOG_DEPTH-1:0]] <= src_pstrb_i;
                req_prot_fifo[req_wr_ptr[LOG_DEPTH-1:0]] <= src_pprot_i;
                req_write_fifo[req_wr_ptr[LOG_DEPTH-1:0]] <= src_pwrite_i;
                req_wr_ptr <= req_wr_ptr + 1;
                src_pready_o <= 1;
            end else if (src_pready_o && !req_empty) begin
                src_pready_o <= 0;
            end
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            req_rd_ptr <= 0;
            dst_psel_o <= 0;
            dst_penable_o <= 0;
        end else begin
            if (!req_empty && !dst_psel_o) begin
                dst_psel_o <= 1;
                dst_penable_o <= 1;
                dst_pwrite_o <= req_write_fifo[req_rd_ptr[LOG_DEPTH-1:0]];
                dst_paddr_o <= req_addr_fifo[req_rd_ptr[LOG_DEPTH-1:0]];
                dst_pwdata_o <= req_wdata_fifo[req_rd_ptr[LOG_DEPTH-1:0]];
                dst_pstrb_o <= req_strb_fifo[req_rd_ptr[LOG_DEPTH-1:0]];
                dst_pprot_o <= req_prot_fifo[req_rd_ptr[LOG_DEPTH-1:0]];
            end else if (dst_psel_o && dst_penable_o && dst_pready_i) begin
                req_rd_ptr <= req_rd_ptr + 1;
                dst_psel_o <= 0;
                dst_penable_o <= 0;
            end
        end
    end

    // Response FIFO logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            resp_wr_ptr <= 0;
            resp_rd_ptr <= 0;
        end else begin
            if (dst_psel_o && dst_penable_o && dst_pready_i && !resp_full) begin
                resp_rdata_fifo[resp_wr_ptr[LOG_DEPTH-1:0]] <= dst_prdata_i;
                resp_slverr_fifo[resp_wr_ptr[LOG_DEPTH-1:0]] <= dst_pslverr_i;
                resp_wr_ptr <= resp_wr_ptr + 1;
            end
        end
    end

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            resp_rd_ptr <= 0;
            src_prdata_o <= 0;
            src_pslverr_o <= 0;
        end else begin
            if (!resp_empty) begin
                src_prdata_o <= resp_rdata_fifo[resp_rd_ptr[LOG_DEPTH-1:0]];
                src_pslverr_o <= resp_slverr_fifo[resp_rd_ptr[LOG_DEPTH-1:0]];
                resp_rd_ptr <= resp_rd_ptr + 1;
            end
        end
    end

    // FIFO status logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            req_full <= 0;
            req_empty <= 1;
        end else begin
            req_full <= (req_wr_ptr[LOG_DEPTH:0] == {1'b1, req_rd_ptr[LOG_DEPTH-1:0]});
            req_empty <= (req_wr_ptr[LOG_DEPTH:0] == req_rd_ptr[LOG_DEPTH:0]);
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            resp_full <= 0;
            resp_empty <= 1;
        end else begin
            resp_full <= (resp_wr_ptr[LOG_DEPTH:0] == {1'b1, resp_rd_ptr[LOG_DEPTH-1:0]});
            resp_empty <= (resp_wr_ptr[LOG_DEPTH:0] == resp_rd_ptr[LOG_DEPTH:0]);
        end
    end

endmodule
