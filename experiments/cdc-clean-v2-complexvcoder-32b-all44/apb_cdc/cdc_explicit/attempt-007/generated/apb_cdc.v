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

    // Internal signals
    reg                        sync_src_psel_q;
    reg                        sync_src_penable_q;
    reg                        sync_src_pwrite_q;
    reg  [ADDR_WIDTH-1:0]      sync_src_paddr_q;
    reg  [DATA_WIDTH-1:0]      sync_src_pwdata_q;
    reg  [DATA_WIDTH/8-1:0]    sync_src_pstrb_q;
    reg  [2:0]                 sync_src_pprot_q;
    reg                        sync_dst_pready_q;
    reg  [DATA_WIDTH-1:0]      sync_dst_prdata_q;
    reg                        sync_dst_pslverr_q;
    reg                        req_valid;
    reg                        req_ready;
    reg                        resp_valid;
    reg                        resp_ready;
    reg                        req_psel;
    reg                        req_penable;
    reg                        req_pwrite;
    reg  [ADDR_WIDTH-1:0]      req_paddr;
    reg  [DATA_WIDTH-1:0]      req_pwdata;
    reg  [DATA_WIDTH/8-1:0]    req_pstrb;
    reg  [2:0]                 req_pprot;
    reg                        req_fifo_empty;
    reg                        req_fifo_full;
    wire [ADDR_WIDTH+DATA_WIDTH+(DATA_WIDTH/8)+3:0] req_fifo_din;
    wire [ADDR_WIDTH+DATA_WIDTH+(DATA_WIDTH/8)+3:0] req_fifo_dout;
    reg                        resp_fifo_empty;
    reg                        resp_fifo_full;
    wire [DATA_WIDTH:0]        resp_fifo_din;
    wire [DATA_WIDTH:0]        resp_fifo_dout;

    // FIFO for requests
    scfifo #(
        .ADD_RAM_OUTPUT_REGISTER_STAGE("ON"),
        .LPM_NUMWORDS(1 << LOG_DEPTH),
        .LPM_WIDTH(ADDR_WIDTH+DATA_WIDTH+(DATA_WIDTH/8)+3),
        .LPM_WIDTHU(LOG_DEPTH+1),
        .LPM_TYPE("scfifo"),
        .LPM_WIDTHU_REQUEST(LPM_WIDTHU_REQUEST_UNREGISTERED),
        .UNDERFLOW_CHECKING("ON"),
        .USE_EAB("ON"),
        .USE_PACKETS("OFF"),
        .USE_WAITREQUEST("ON")
    ) req_fifo (
        .clock(dst_pclk_i),
        .sclr(~dst_preset_ni),
        .data(req_fifo_din),
        .rdreq(resp_ready),
        .wrreq(req_ready & req_valid),
        .q(req_fifo_dout),
        .empty(req_fifo_empty),
        .full(req_fifo_full)
    );

    // FIFO for responses
    scfifo #(
        .ADD_RAM_OUTPUT_REGISTER_STAGE("ON"),
        .LPM_NUMWORDS(1 << LOG_DEPTH),
        .LPM_WIDTH(DATA_WIDTH+1),
        .LPM_WIDTHU(LOG_DEPTH+1),
        .LPM_TYPE("scfifo"),
        .LPM_WIDTHU_REQUEST(LPM_WIDTHU_REQUEST_UNREGISTERED),
        .UNDERFLOW_CHECKING("ON"),
        .USE_EAB("ON"),
        .USE_PACKETS("OFF"),
        .USE_WAITREQUEST("ON")
    ) resp_fifo (
        .clock(src_pclk_i),
        .sclr(~src_preset_ni),
        .data(resp_fifo_din),
        .rdreq(src_pready_o),
        .wrreq(~req_fifo_empty & sync_dst_pready_q),
        .q(resp_fifo_dout),
        .empty(resp_fifo_empty),
        .full(resp_fifo_full)
    );

    // Synchronizers
    sync_reg sync_src_psel (
        .clk(dst_pclk_i),
        .rst_n(dst_preset_ni),
        .d(src_psel_i),
        .q(sync_src_psel_q)
    );

    sync_reg sync_src_penable (
        .clk(dst_pclk_i),
        .rst_n(dst_preset_ni),
        .d(src_penable_i),
        .q(sync_src_penable_q)
    );

    sync_reg sync_src_pwrite (
        .clk(dst_pclk_i),
        .rst_n(dst_preset_ni),
        .d(src_pwrite_i),
        .q(sync_src_pwrite_q)
    );

    sync_reg sync_src_paddr (
        .clk(dst_pclk_i),
        .rst_n(dst_preset_ni),
        .d(src_paddr_i),
        .q(sync_src_paddr_q)
    );

    sync_reg sync_src_pwdata (
        .clk(dst_pclk_i),
        .rst_n(dst_preset_ni),
        .d(src_pwdata_i),
        .q(sync_src_pwdata_q)
    );

    sync_reg sync_src_pstrb (
        .clk(dst_pclk_i),
        .rst_n(dst_preset_ni),
        .d(src_pstrb_i),
        .q(sync_src_pstrb_q)
    );

    sync_reg sync_src_pprot (
        .clk(dst_pclk_i),
        .rst_n(dst_preset_ni),
        .d(src_pprot_i),
        .q(sync_src_pprot_q)
    );

    sync_reg sync_dst_pready (
        .clk(src_pclk_i),
        .rst_n(src_preset_ni),
        .d(dst_pready_i),
        .q(sync_dst_pready_q)
    );

    sync_reg sync_dst_prdata (
        .clk(src_pclk_i),
        .rst_n(src_preset_ni),
        .d(dst_prdata_i),
        .q(sync_dst_prdata_q)
    );

    sync_reg sync_dst_pslverr (
        .clk(src_pclk_i),
        .rst_n(src_preset_ni),
        .d(dst_pslverr_i),
        .q(sync_dst_pslverr_q)
    );

    // Request FIFO data input
    assign req_fifo_din = {sync_src_psel_q, sync_src_penable_q, sync_src_pwrite_q, sync_src_paddr_q, sync_src_pwdata_q, sync_src_pstrb_q, sync_src_pprot_q};

    // Assign request FIFO data output
    assign req_psel   = req_fifo_dout[ADDR_WIDTH+DATA_WIDTH+(DATA_WIDTH/8)+2];
    assign req_penable = req_fifo_dout[ADDR_WIDTH+DATA_WIDTH+(DATA_WIDTH/8)+1];
    assign req_pwrite  = req_fifo_dout[ADDR_WIDTH+DATA_WIDTH+(DATA_WIDTH/8)+0];
    assign req_paddr   = req_fifo_dout[ADDR_WIDTH+DATA_WIDTH+(DATA_WIDTH/8)-1:DATA_WIDTH+(DATA_WIDTH/8)];
    assign req_pwdata  = req_fifo_dout[ADDR_WIDTH+(DATA_WIDTH/8)-1:DATA_WIDTH/8];
    assign req_pstrb   = req_fifo_dout[DATA_WIDTH/8-1:0];
    assign req_pprot   = req_fifo_dout[DATA_WIDTH+(DATA_WIDTH/8)+2:DATA_WIDTH+(DATA_WIDTH/8)];

    // Response FIFO data input
    assign resp_fifo_din = {sync_dst_prdata_q, sync_dst_pslverr_q};

    // Assign response FIFO data output
    assign src_prdata_o  = resp_fifo_dout[DATA_WIDTH:1];
    assign src_pslverr_o = resp_fifo_dout[0];

    // Request valid and ready
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            req_valid <= 1'b0;
            req_ready <= 1'b0;
        end else begin
            req_valid <= sync_src_psel_q & sync_src_penable_q;
            req_ready <= ~req_fifo_full;
        end
    end

    // Response valid and ready
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            resp_valid <= 1'b0;
            resp_ready <= 1'b0;
        end else begin
            resp_valid <= ~resp_fifo_empty & sync_dst_pready_q;
            resp_ready <= src_pready_o;
        end
    end

    // Destination outputs
    assign dst_psel_o    = req_psel;
    assign dst_penable_o = req_penable;
    assign dst_pwrite_o  = req_pwrite;
    assign dst_paddr_o   = req_paddr;
    assign dst_pwdata_o  = req_pwdata;
    assign dst_pstrb_o   = req_pstrb;
    assign dst_pprot_o   = req_pprot;

    // Source ready
    assign src_pready_o = resp_valid;

endmodule

// Synchronizer module
module sync_reg (
    input clk,
    input rst_n,
    input d,
    output reg q
);

    reg sync_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_stage1 <= 1'b0;
            q <= 1'b0;
        end else begin
            sync_stage1 <= d;
            q <= sync_stage1;
        end
    end

endmodule
