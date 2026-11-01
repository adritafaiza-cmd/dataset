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
    localparam PTR_WIDTH = LOG_DEPTH;

    // Request FIFO (src -> dst)
    reg [DATA_WIDTH-1:0] req_fifo_data [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] req_fifo_addr [0:DEPTH-1];
    reg [DATA_WIDTH/8-1:0] req_fifo_strb [0:DEPTH-1];
    reg [2:0] req_fifo_prot [0:DEPTH-1];
    reg req_fifo_write [0:DEPTH-1];
    reg [PTR_WIDTH-1:0] req_wr_ptr;
    reg [PTR_WIDTH-1:0] req_rd_ptr;

    // Response FIFO (dst -> src)
    reg [DATA_WIDTH-1:0] rsp_fifo_data [0:DEPTH-1];
    reg rsp_fifo_err [0:DEPTH-1];
    reg [PTR_WIDTH-1:0] rsp_wr_ptr;
    reg [PTR_WIDTH-1:0] rsp_rd_ptr;

    // Request FIFO full/empty
    wire req_full = (req_wr_ptr == req_rd_ptr) && (req_wr_ptr[PTR_WIDTH-1] != req_rd_ptr[PTR_WIDTH-1]);
    wire req_empty = (req_wr_ptr == req_rd_ptr) && (req_wr_ptr[PTR_WIDTH-1] == req_rd_ptr[PTR_WIDTH-1]);

    // Response FIFO full/empty
    wire rsp_full = (rsp_wr_ptr == rsp_rd_ptr) && (rsp_wr_ptr[PTR_WIDTH-1] != rsp_rd_ptr[PTR_WIDTH-1]);
    wire rsp_empty = (rsp_wr_ptr == rsp_rd_ptr) && (rsp_wr_ptr[PTR_WIDTH-1] == rsp_rd_ptr[PTR_WIDTH-1]);

    // Source side: APB setup phase detection
    wire src_setup = src_psel_i && !src_penable_i;
    wire src_access = src_psel_i && src_penable_i;

    // Write to request FIFO during setup phase
    wire req_wr_en = src_setup && !req_full;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            req_wr_ptr <= {PTR_WIDTH{1'b0}};
        end else if (req_wr_en) begin
            req_fifo_data[req_wr_ptr[PTR_WIDTH-1:$clog2(DEPTH)-1]] <= src_pwdata_i;
            req_fifo_addr[req_wr_ptr[PTR_WIDTH-1:$clog2(DEPTH)-1]] <= src_paddr_i;
            req_fifo_strb[req_wr_ptr[PTR_WIDTH-1:$clog2(DEPTH)-1]] <= src_pstrb_i;
            req_fifo_prot[req_wr_ptr[PTR_WIDTH-1:$clog2(DEPTH)-1]] <= src_pprot_i;
            req_fifo_write[req_wr_ptr[PTR_WIDTH-1:$clog2(DEPTH)-1]] <= src_pwrite_i;
            req_wr_ptr <= req_wr_ptr + 1'b1;
        end
    end

    // Source side: read from response FIFO
    wire rsp_rd_en = !rsp_empty;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            rsp_rd_ptr <= {PTR_WIDTH{1'b0}};
        end else if (rsp_rd_en) begin
            rsp_rd_ptr <= rsp_rd_ptr + 1'b1;
        end
    end

    // Source side outputs
    assign src_pready_o = !rsp_empty;
    assign src_prdata_o = rsp_fifo_data[rsp_rd_ptr[PTR_WIDTH-1:$clog2(DEPTH)-1]];
    assign src_pslverr_o = rsp_fifo_err[rsp_rd_ptr[PTR_WIDTH-1:$clog2(DEPTH)-1]];

    // Destination side: read from request FIFO
    wire req_rd_en = !req_empty;

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            req_rd_ptr <= {PTR_WIDTH{1'b0}};
        end else if (req_rd_en) begin
            req_rd_ptr <= req_rd_ptr + 1'b1;
        end
    end

    // Destination side: APB signals
    assign dst_psel_o = !req_empty;
    assign dst_penable_o = !req_empty && dst_pready_i;
    assign dst_pwrite_o = req_fifo_write[req_rd_ptr[PTR_WIDTH-1:$clog2(DEPTH)-1]];
    assign dst_paddr_o = req_fifo_addr[req_rd_ptr[PTR_WIDTH-1:$clog2(DEPTH)-1]];
    assign dst_pwdata_o = req_fifo_data[req_rd_ptr[PTR_WIDTH-1:$clog2(DEPTH)-1]];
    assign dst_pstrb_o = req_fifo_strb[req_rd_ptr[PTR_WIDTH-1:$clog2(DEPTH)-1]];
    assign dst_pprot_o = req_fifo_prot[req_rd_ptr[PTR_WIDTH-1:$clog2(DEPTH)-1]];

    // Destination side: write to response FIFO
    wire rsp_wr_en = dst_psel_o && dst_penable_o && dst_pready_i && !rsp_full;

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            rsp_wr_ptr <= {PTR_WIDTH{1'b0}};
        end else if (rsp_wr_en) begin
            rsp_fifo_data[rsp_wr_ptr[PTR_WIDTH-1:$clog2(DEPTH)-1]] <= dst_prdata_i;
            rsp_fifo_err[rsp_wr_ptr[PTR_WIDTH-1:$clog2(DEPTH)-1]] <= dst_pslverr_i;
            rsp_wr_ptr <= rsp_wr_ptr + 1'b1;
        end
    end

endmodule
