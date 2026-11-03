// Copyright 2021 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51.
// Verilog-2001 flattening of pulp-platform/apb apb_cdc (no structs).

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

    localparam REQW = ADDR_WIDTH + 3 + 1 + DATA_WIDTH + (DATA_WIDTH/8);
    localparam RSPW = DATA_WIDTH + 1;
    localparam SRC_IDLE = 1'b0;
    localparam SRC_BUSY = 1'b1;
    localparam DST_IDLE = 2'd0;
    localparam DST_ACCESS = 2'd1;
    localparam DST_BUSY = 2'd2;

    wire [REQW-1:0] src_req_data = {src_paddr_i, src_pprot_i, src_pwrite_i, src_pwdata_i, src_pstrb_i};
    wire [REQW-1:0] dst_req_data;
    wire [RSPW-1:0] src_resp_data;
    reg  [RSPW-1:0] dst_resp_data_q, dst_resp_data_d;
    wire src_req_ready, src_resp_valid;
    wire dst_req_valid, dst_resp_ready;

    reg src_state_q, src_state_d;
    reg src_req_valid, src_resp_ready, src_pready_o;
    reg [1:0] dst_state_q, dst_state_d;
    reg dst_req_ready, dst_resp_valid, dst_psel_o, dst_penable_o;

    assign {dst_paddr_o, dst_pprot_o, dst_pwrite_o, dst_pwdata_o, dst_pstrb_o} = dst_req_data;
    assign src_prdata_o  = src_resp_data[DATA_WIDTH:1];
    assign src_pslverr_o = src_resp_data[0];

    always @(*) begin
        src_state_d    = src_state_q;
        src_req_valid  = 1'b0;
        src_resp_ready = 1'b0;
        src_pready_o   = 1'b0;
        case (src_state_q)
            SRC_IDLE: begin
                if (src_psel_i && src_penable_i) begin
                    src_req_valid = 1'b1;
                    if (src_req_ready)
                        src_state_d = SRC_BUSY;
                end
            end
            SRC_BUSY: begin
                src_resp_ready = 1'b1;
                if (src_resp_valid) begin
                    src_pready_o = 1'b1;
                    src_state_d = SRC_IDLE;
                end
            end
            default: src_state_d = SRC_IDLE;
        endcase
    end

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni)
            src_state_q <= SRC_IDLE;
        else
            src_state_q <= src_state_d;
    end

    always @(*) begin
        dst_state_d     = dst_state_q;
        dst_req_ready   = 1'b0;
        dst_resp_valid  = 1'b0;
        dst_psel_o      = 1'b0;
        dst_penable_o   = 1'b0;
        dst_resp_data_d = dst_resp_data_q;
        case (dst_state_q)
            DST_IDLE: begin
                if (dst_req_valid) begin
                    dst_psel_o = 1'b1;
                    dst_state_d = DST_ACCESS;
                end
            end
            DST_ACCESS: begin
                dst_psel_o    = 1'b1;
                dst_penable_o = 1'b1;
                if (dst_pready_i) begin
                    dst_req_ready   = 1'b1;
                    dst_resp_data_d = {dst_prdata_i, dst_pslverr_i};
                    dst_state_d     = DST_BUSY;
                end
            end
            DST_BUSY: begin
                dst_resp_valid = 1'b1;
                if (dst_resp_ready)
                    dst_state_d = DST_IDLE;
            end
            default: dst_state_d = DST_IDLE;
        endcase
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_state_q     <= DST_IDLE;
            dst_resp_data_q <= {RSPW{1'b0}};
        end else begin
            dst_state_q     <= dst_state_d;
            dst_resp_data_q <= dst_resp_data_d;
        end
    end

    cdc_fifo_gray #(.WIDTH(REQW), .LOG_DEPTH(LOG_DEPTH)) i_req (
        .src_rst_ni(src_preset_ni), .src_clk_i(src_pclk_i),
        .src_data_i(src_req_data), .src_valid_i(src_req_valid), .src_ready_o(src_req_ready),
        .dst_rst_ni(dst_preset_ni), .dst_clk_i(dst_pclk_i),
        .dst_data_o(dst_req_data), .dst_valid_o(dst_req_valid), .dst_ready_i(dst_req_ready)
    );

    cdc_fifo_gray #(.WIDTH(RSPW), .LOG_DEPTH(LOG_DEPTH)) i_resp (
        .src_rst_ni(dst_preset_ni), .src_clk_i(dst_pclk_i),
        .src_data_i(dst_resp_data_q), .src_valid_i(dst_resp_valid), .src_ready_o(dst_resp_ready),
        .dst_rst_ni(src_preset_ni), .dst_clk_i(src_pclk_i),
        .dst_data_o(src_resp_data), .dst_valid_o(src_resp_valid), .dst_ready_i(src_resp_ready)
    );

endmodule
