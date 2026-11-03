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
    localparam AW = LOG_DEPTH;

    // Request FIFO (src -> dst)
    reg [ADDR_WIDTH-1:0] req_addr [0:DEPTH-1];
    reg [DATA_WIDTH-1:0] req_wdata [0:DEPTH-1];
    reg [DATA_WIDTH/8-1:0] req_strb [0:DEPTH-1];
    reg [2:0] req_prot [0:DEPTH-1];
    reg req_write [0:DEPTH-1];

    reg [AW-1:0] req_wr_ptr;
    reg [AW-1:0] req_rd_ptr;
    reg [AW:0] req_count;

    // Response FIFO (dst -> src)
    reg [DATA_WIDTH-1:0] rsp_data [0:DEPTH-1];
    reg rsp_err [0:DEPTH-1];

    reg [AW-1:0] rsp_wr_ptr;
    reg [AW-1:0] rsp_rd_ptr;
    reg [AW:0] rsp_count;

    // Gray code pointers for CDC
    wire [AW-1:0] req_wr_ptr_gray = req_wr_ptr ^ {req_wr_ptr[AW-2:0], 1'b0};
    wire [AW-1:0] req_rd_ptr_gray = req_rd_ptr ^ {req_rd_ptr[AW-2:0], 1'b0};
    wire [AW-1:0] rsp_wr_ptr_gray = rsp_wr_ptr ^ {rsp_wr_ptr[AW-2:0], 1'b0};
    wire [AW-1:0] rsp_rd_ptr_gray = rsp_rd_ptr ^ {rsp_rd_ptr[AW-2:0], 1'b0};

    // Synchronizers: req_wr_ptr_gray -> dst domain
    reg [AW-1:0] req_wr_ptr_gray_dst;
    reg [AW-1:0] req_wr_ptr_gray_dst_sync1;
    reg [AW-1:0] req_wr_ptr_gray_dst_sync2;

    // Synchronizers: req_rd_ptr_gray -> src domain
    reg [AW-1:0] req_rd_ptr_gray_src;
    reg [AW-1:0] req_rd_ptr_gray_src_sync1;
    reg [AW-1:0] req_rd_ptr_gray_src_sync2;

    // Synchronizers: rsp_wr_ptr_gray -> src domain
    reg [AW-1:0] rsp_wr_ptr_gray_src;
    reg [AW-1:0] rsp_wr_ptr_gray_src_sync1;
    reg [AW-1:0] rsp_wr_ptr_gray_src_sync2;

    // Synchronizers: rsp_rd_ptr_gray -> dst domain
    reg [AW-1:0] rsp_rd_ptr_gray_dst;
    reg [AW-1:0] rsp_rd_ptr_gray_dst_sync1;
    reg [AW-1:0] rsp_rd_ptr_gray_dst_sync2;

    // Convert gray to binary
    function [AW-1:0] gray2bin;
        input [AW-1:0] gray;
        integer i;
        begin
            gray2bin[AW-1] = gray[AW-1];
            for (i = AW-2; i >= 0; i = i - 1)
                gray2bin[i] = gray2bin[i+1] ^ gray[i];
        end
    endfunction

    // Src domain: detect when request FIFO is not full
    wire [AW-1:0] req_wr_ptr_gray_dst_sync2_q = req_wr_ptr_gray_dst_sync2;
    wire [AW-1:0] req_rd_ptr_gray_src_sync2_q = req_rd_ptr_gray_src_sync2;
    wire [AW-1:0] req_wr_ptr_bin_dst = gray2bin(req_wr_ptr_gray_dst_sync2_q);
    wire [AW-1:0] req_rd_ptr_bin_src = gray2bin(req_rd_ptr_gray_src_sync2_q);

    // Compute req_count in src domain
    wire [AW:0] req_count_src = {1'b0, req_wr_ptr_bin_dst} - {1'b0, req_rd_ptr_bin_src};
    wire req_not_full = (req_count_src < DEPTH);

    // Dst domain: detect when request FIFO is not empty
    wire [AW-1:0] req_wr_ptr_bin_dst2 = gray2bin(req_wr_ptr_gray_dst_sync2);
    wire [AW-1:0] req_rd_ptr_bin_dst = gray2bin(req_rd_ptr_gray_dst_sync2);
    wire [AW:0] req_count_dst = {1'b0, req_wr_ptr_bin_dst2} - {1'b0, req_rd_ptr_bin_dst};
    wire req_not_empty = (req_count_dst > 0);

    // Src domain: detect when response FIFO is not empty
    wire [AW-1:0] rsp_wr_ptr_bin_src = gray2bin(rsp_wr_ptr_gray_src_sync2);
    wire [AW-1:0] rsp_rd_ptr_bin_src = gray2bin(rsp_rd_ptr_gray_src_sync2);
    wire [AW:0] rsp_count_src = {1'b0, rsp_wr_ptr_bin_src} - {1'b0, rsp_rd_ptr_bin_src};
    wire rsp_not_empty = (rsp_count_src > 0);

    // Dst domain: detect when response FIFO is not full
    wire [AW-1:0] rsp_wr_ptr_bin_dst = gray2bin(rsp_wr_ptr_gray_dst_sync2);
    wire [AW-1:0] rsp_rd_ptr_bin_dst = gray2bin(rsp_rd_ptr_gray_dst_sync2);
    wire [AW:0] rsp_count_dst = {1'b0, rsp_wr_ptr_bin_dst} - {1'b0, rsp_rd_ptr_bin_dst};
    wire rsp_not_full = (rsp_count_dst < DEPTH);

    // APB state machines
    // Src side: wait for request to be accepted into FIFO
    reg src_phase;
    localparam SRC_IDLE = 1'b0;
    localparam SRC_WAIT = 1'b1;

    // Dst side: APB transfer
    reg dst_phase;
    localparam DST_IDLE = 1'b0;
    localparam DST_SETUP = 1'b1;
    localparam DST_ACCESS = 1'b2;

    // Src side logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_phase <= SRC_IDLE;
            src_pready_o <= 1'b0;
            src_prdata_o <= {DATA_WIDTH{1'b0}};
            src_pslverr_o <= 1'b0;
            req_wr_ptr <= {AW{1'b0}};
            rsp_rd_ptr <= {AW{1'b0}};
        end else begin
            // Synchronizer updates
            req_rd_ptr_gray_src_sync1 <= req_rd_ptr_gray;
            req_rd_ptr_gray_src_sync2 <= req_rd_ptr_gray_src_sync1;
            rsp_wr_ptr_gray_src_sync1 <= rsp_wr_ptr_gray;
            rsp_wr_ptr_gray_src_sync2 <= rsp_wr_ptr_gray_src_sync1;

            case (src_phase)
                SRC_IDLE: begin
                    src_pready_o <= 1'b0;
                    if (src_psel_i && req_not_full) begin
                        src_phase <= SRC_WAIT;
                        // Write request into FIFO
                        req_addr[req_wr_ptr] <= src_paddr_i;
                        req_wdata[req_wr_ptr] <= src_pwdata_i;
                        req_strb[req_wr_ptr] <= src_pstrb_i;
                        req_prot[req_wr_ptr] <= src_pprot_i;
                        req_write[req_wr_ptr] <= src_pwrite_i;
                        req_wr_ptr <= req_wr_ptr + 1'b1;
                    end
                end
                SRC_WAIT: begin
                    src_pready_o <= 1'b0;
                    if (rsp_not_empty) begin
                        src_phase <= SRC_IDLE;
                        src_pready_o <= 1'b1;
                        src_prdata_o <= rsp_data[rsp_rd_ptr];
                        src_pslverr_o <= rsp_err[rsp_rd_ptr];
                        rsp_rd_ptr <= rsp_rd_ptr + 1'b1;
                    end
                end
                default: begin
                    src_phase <= SRC_IDLE;
                end
            endcase
        end
    end

    // Dst side logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_phase <= DST_IDLE;
            dst_psel_o <= 1'b0;
            dst_penable_o <= 1'b0;
            dst_pwrite_o <= 1'b0;
            dst_paddr_o <= {ADDR_WIDTH{1'b0}};
            dst_pwdata_o <= {DATA_WIDTH{1'b0}};
            dst_pstrb_o <= {(DATA_WIDTH/8){1'b0}};
            dst_pprot_o <= 3'b0;
            req_rd_ptr <= {AW{1'b0}};
            rsp_wr_ptr <= {AW{1'b0}};
        end else begin
            // Synchronizer updates
            req_wr_ptr_gray_dst_sync1 <= req_wr_ptr_gray;
            req_wr_ptr_gray_dst_sync2 <= req_wr_ptr_gray_dst_sync1;
            rsp_rd_ptr_gray_dst_sync1 <= rsp_rd_ptr_gray;
            rsp_rd_ptr_gray_dst_sync2 <= rsp_rd_ptr_gray_dst_sync1;

            case (dst_phase)
                DST_IDLE: begin
                    dst_psel_o <= 1'b0;
                    dst_penable_o <= 1'b0;
                    if (req_not_empty) begin
                        dst_phase <= DST_SETUP;
                        dst_psel_o <= 1'b1;
                        dst_penable_o <= 1'b0;
                        dst_pwrite_o <= req_write[req_rd_ptr];
                        dst_paddr_o <= req_addr[req_rd_ptr];
                        dst_pwdata_o <= req_wdata[req_rd_ptr];
                        dst_pstrb_o <= req_strb[req_rd_ptr];
                        dst_pprot_o <= req_prot[req_rd_ptr];
                        req_rd_ptr <= req_rd_ptr + 1'b1;
                    end
                end
                DST_SETUP: begin
                    dst_psel_o <= 1'b1;
                    dst_penable_o <= 1'b1;
                    dst_phase <= DST_ACCESS;
                end
                DST_ACCESS: begin
                    dst_psel_o <= 1'b1;
                    dst_penable_o <= 1'b1;
                    if (dst_pready_i) begin
                        dst_phase <= DST_IDLE;
                        dst_psel_o <= 1'b0;
                        dst_penable_o <= 1'b0;
                        // Write response into FIFO
                        rsp_data[rsp_wr_ptr] <= dst_prdata_i;
                        rsp_err[rsp_wr_ptr] <= dst_pslverr_i;
                        rsp_wr_ptr <= rsp_wr_ptr + 1'b1;
                    end
                end
                default: begin
                    dst_phase <= DST_IDLE;
                    dst_psel_o <= 1'b0;
                    dst_penable_o <= 1'b0;
                end
            endcase
        end
    end

endmodule
