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
    localparam AW    = LOG_DEPTH;

    // Request FIFO (src -> dst)
    reg [ADDR_WIDTH-1:0] req_addr [0:DEPTH-1];
    reg [DATA_WIDTH-1:0] req_wdata [0:DEPTH-1];
    reg [DATA_WIDTH/8-1:0] req_strb [0:DEPTH-1];
    reg [2:0] req_prot [0:DEPTH-1];
    reg req_write [0:DEPTH-1];

    reg [AW:0] req_wr_ptr;
    reg [AW:0] req_rd_ptr;

    wire req_full  = (req_wr_ptr[AW] != req_rd_ptr[AW]) && (req_wr_ptr[AW-1:0] == req_rd_ptr[AW-1:0]);
    wire req_empty = (req_wr_ptr == req_rd_ptr);

    // Response FIFO (dst -> src)
    reg [DATA_WIDTH-1:0] rsp_data [0:DEPTH-1];
    reg rsp_err [0:DEPTH-1];

    reg [AW:0] rsp_wr_ptr;
    reg [AW:0] rsp_rd_ptr;

    wire rsp_full  = (rsp_wr_ptr[AW] != rsp_rd_ptr[AW]) && (rsp_wr_ptr[AW-1:0] == rsp_rd_ptr[AW-1:0]);
    wire rsp_empty = (rsp_wr_ptr == rsp_rd_ptr);

    // Gray code pointers for CDC
    wire [AW:0] req_wr_ptr_gray  = req_wr_ptr ^ {1'b0, req_wr_ptr[AW-1:0]};
    wire [AW:0] req_rd_ptr_gray  = req_rd_ptr ^ {1'b0, req_rd_ptr[AW-1:0]};
    wire [AW:0] rsp_wr_ptr_gray  = rsp_wr_ptr ^ {1'b0, rsp_wr_ptr[AW-1:0]};
    wire [AW:0] rsp_rd_ptr_gray  = rsp_rd_ptr ^ {1'b0, rsp_rd_ptr[AW-1:0]};

    // Synchronizers: src side sees dst's request read pointer
    reg [AW:0] req_rd_ptr_gray_sync0;
    reg [AW:0] req_rd_ptr_gray_sync1;
    reg [AW:0] req_rd_ptr_gray_sync2;

    // Synchronizers: dst side sees src's request write pointer
    reg [AW:0] req_wr_ptr_gray_sync0;
    reg [AW:0] req_wr_ptr_gray_sync1;
    reg [AW:0] req_wr_ptr_gray_sync2;

    // Synchronizers: dst side sees src's response read pointer
    reg [AW:0] rsp_rd_ptr_gray_sync0;
    reg [AW:0] rsp_rd_ptr_gray_sync1;
    reg [AW:0] rsp_rd_ptr_gray_sync2;

    // Synchronizers: src side sees dst's response write pointer
    reg [AW:0] rsp_wr_ptr_gray_sync0;
    reg [AW:0] rsp_wr_ptr_gray_sync1;
    reg [AW:0] rsp_wr_ptr_gray_sync2;

    // Convert gray to binary
    function [AW:0] gray2bin;
        input [AW:0] g;
        reg [AW:0] b;
        integer i;
        begin
            b[AW] = g[AW];
            for (i = AW-1; i >= 0; i = i - 1)
                b[i] = b[i+1] ^ g[i];
            gray2bin = b;
        end
    endfunction

    wire [AW:0] req_rd_ptr_sync = gray2bin(req_rd_ptr_gray_sync2);
    wire [AW:0] req_wr_ptr_sync = gray2bin(req_wr_ptr_gray_sync2);
    wire [AW:0] rsp_rd_ptr_sync = gray2bin(rsp_rd_ptr_gray_sync2);
    wire [AW:0] rsp_wr_ptr_sync = gray2bin(rsp_wr_ptr_gray_sync2);

    // Synchronizer logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            req_rd_ptr_gray_sync0 <= {1'b0, {AW{1'b0}}};
            req_rd_ptr_gray_sync1 <= {1'b0, {AW{1'b0}}};
            req_rd_ptr_gray_sync2 <= {1'b0, {AW{1'b0}}};
            rsp_wr_ptr_gray_sync0 <= {1'b0, {AW{1'b0}}};
            rsp_wr_ptr_gray_sync1 <= {1'b0, {AW{1'b0}}};
            rsp_wr_ptr_gray_sync2 <= {1'b0, {AW{1'b0}}};
        end else begin
            req_rd_ptr_gray_sync0 <= req_rd_ptr_gray;
            req_rd_ptr_gray_sync1 <= req_rd_ptr_gray_sync0;
            req_rd_ptr_gray_sync2 <= req_rd_ptr_gray_sync1;
            rsp_wr_ptr_gray_sync0 <= rsp_wr_ptr_gray;
            rsp_wr_ptr_gray_sync1 <= rsp_wr_ptr_gray_sync0;
            rsp_wr_ptr_gray_sync2 <= rsp_wr_ptr_gray_sync1;
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            req_wr_ptr_gray_sync0 <= {1'b0, {AW{1'b0}}};
            req_wr_ptr_gray_sync1 <= {1'b0, {AW{1'b0}}};
            req_wr_ptr_gray_sync2 <= {1'b0, {AW{1'b0}}};
            rsp_rd_ptr_gray_sync0 <= {1'b0, {AW{1'b0}}};
            rsp_rd_ptr_gray_sync1 <= {1'b0, {AW{1'b0}}};
            rsp_rd_ptr_gray_sync2 <= {1'b0, {AW{1'b0}}};
        end else begin
            req_wr_ptr_gray_sync0 <= req_wr_ptr_gray;
            req_wr_ptr_gray_sync1 <= req_wr_ptr_gray_sync0;
            req_wr_ptr_gray_sync2 <= req_wr_ptr_gray_sync1;
            rsp_rd_ptr_gray_sync0 <= rsp_rd_ptr_gray;
            rsp_rd_ptr_gray_sync1 <= rsp_rd_ptr_gray_sync0;
            rsp_rd_ptr_gray_sync2 <= rsp_rd_ptr_gray_sync1;
        end
    end

    // Source-side: request FIFO write
    wire src_req_can_write = !req_full;
    wire src_req_write = src_psel_i && src_penable_i && src_pready_o && src_req_can_write;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            req_wr_ptr <= {1'b0, {AW{1'b0}}};
        end else if (src_req_write) begin
            req_addr[req_wr_ptr[AW-1:0]] <= src_paddr_i;
            req_wdata[req_wr_ptr[AW-1:0]] <= src_pwdata_i;
            req_strb[req_wr_ptr[AW-1:0]] <= src_pstrb_i;
            req_prot[req_wr_ptr[AW-1:0]] <= src_pprot_i;
            req_write[req_wr_ptr[AW-1:0]] <= src_pwrite_i;
            req_wr_ptr <= req_wr_ptr + 1'b1;
        end
    end

    // Source-side: response FIFO read
    wire src_rsp_can_read = !rsp_empty;
    wire src_rsp_read = src_psel_i && src_penable_i && src_pready_o && src_rsp_can_read;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            rsp_rd_ptr <= {1'b0, {AW{1'b0}}};
        end else if (src_rsp_read) begin
            rsp_rd_ptr <= rsp_rd_ptr + 1'b1;
        end
    end

    // Source-side outputs
    assign src_pready_o  = src_rsp_can_read;
    assign src_prdata_o  = rsp_data[rsp_rd_ptr[AW-1:0]];
    assign src_pslverr_o = rsp_err[rsp_rd_ptr[AW-1:0]];

    // Destination-side: request FIFO read
    wire dst_req_can_read = !req_empty && !rsp_full;
    wire dst_req_read = dst_req_can_read;

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            req_rd_ptr <= {1'b0, {AW{1'b0}}};
        end else if (dst_req_read) begin
            req_rd_ptr <= req_rd_ptr + 1'b1;
        end
    end

    // Destination-side: response FIFO write
    wire dst_rsp_write = dst_psel_o && dst_penable_o && dst_pready_i;

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            rsp_wr_ptr <= {1'b0, {AW{1'b0}}};
        end else if (dst_rsp_write) begin
            rsp_data[rsp_wr_ptr[AW-1:0]] <= dst_prdata_i;
            rsp_err[rsp_wr_ptr[AW-1:0]]  <= dst_pslverr_i;
            rsp_wr_ptr <= rsp_wr_ptr + 1'b1;
        end
    end

    // Destination-side outputs
    assign dst_psel_o    = dst_req_can_read;
    assign dst_penable_o = dst_psel_o;
    assign dst_pwrite_o  = req_write[req_rd_ptr[AW-1:0]];
    assign dst_paddr_o   = req_addr[req_rd_ptr[AW-1:0]];
    assign dst_pwdata_o  = req_wdata[req_rd_ptr[AW-1:0]];
    assign dst_pstrb_o   = req_strb[req_rd_ptr[AW-1:0]];
    assign dst_pprot_o   = req_prot[req_rd_ptr[AW-1:0]];

endmodule
