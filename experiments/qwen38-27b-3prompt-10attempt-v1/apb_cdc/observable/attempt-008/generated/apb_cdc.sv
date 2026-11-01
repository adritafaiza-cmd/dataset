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
    localparam PTR_W = LOG_DEPTH;

    // Request FIFO (src -> dst)
    reg [ADDR_WIDTH-1:0] req_addr [0:DEPTH-1];
    reg [DATA_WIDTH-1:0] req_wdata [0:DEPTH-1];
    reg [DATA_WIDTH/8-1:0] req_strb [0:DEPTH-1];
    reg [2:0] req_prot [0:DEPTH-1];
    reg req_write [0:DEPTH-1];
    reg [PTR_W-1:0] req_wr_ptr;
    reg [PTR_W-1:0] req_rd_ptr;
    reg req_wr_valid;
    reg req_rd_valid;

    // Response FIFO (dst -> src)
    reg [DATA_WIDTH-1:0] rsp_rdata [0:DEPTH-1];
    reg rsp_err [0:DEPTH-1];
    reg [PTR_W-1:0] rsp_wr_ptr;
    reg [PTR_W-1:0] rsp_rd_ptr;
    reg rsp_wr_valid;
    reg rsp_rd_valid;

    // Gray code pointers for CDC
    reg [PTR_W:0] req_wr_ptr_gray;
    reg [PTR_W:0] req_rd_ptr_gray;
    reg [PTR_W:0] rsp_wr_ptr_gray;
    reg [PTR_W:0] rsp_rd_ptr_gray;

    // Synchronizers
    reg [PTR_W:0] req_wr_ptr_gray_s1, req_wr_ptr_gray_s2;
    reg [PTR_W:0] req_rd_ptr_gray_s1, req_rd_ptr_gray_s2;
    reg [PTR_W:0] rsp_wr_ptr_gray_s1, rsp_wr_ptr_gray_s2;
    reg [PTR_W:0] rsp_rd_ptr_gray_s1, rsp_rd_ptr_gray_s2;

    // Derived signals
    wire req_full;
    wire req_empty;
    wire rsp_full;
    wire rsp_empty;

    // APB state machines
    reg src_state;
    reg dst_state;
    localparam SRC_IDLE = 1'b0;
    localparam SRC_SETUP = 1'b1;
    localparam DST_IDLE = 1'b0;
    localparam DST_SETUP = 1'b1;

    // Gray code conversion
    function [PTR_W:0] bin2gray;
        input [PTR_W:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // Request FIFO full/empty
    assign req_full = (req_wr_ptr_gray_s2 == req_rd_ptr_gray) && 
                      (req_wr_ptr_gray[PTR_W] != req_rd_ptr_gray[PTR_W]);
    assign req_empty = (req_wr_ptr_gray == req_rd_ptr_gray);

    // Response FIFO full/empty
    assign rsp_full = (rsp_wr_ptr_gray_s2 == rsp_rd_ptr_gray) && 
                      (rsp_wr_ptr_gray[PTR_W] != rsp_rd_ptr_gray[PTR_W]);
    assign rsp_empty = (rsp_wr_ptr_gray == rsp_rd_ptr_gray);

    // Source side: APB master to FIFO writer
    // Detect setup phase completion (psel && !penable)
    wire src_setup_done = src_psel_i && !src_penable_i;
    wire src_access_done = src_psel_i && src_penable_i && src_pready_o;

    // Write request to FIFO when setup is done and FIFO is not full
    wire src_req_write_en = src_setup_done && !req_full && (src_state == SRC_IDLE);

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            req_wr_ptr <= {PTR_W{1'b0}};
            req_wr_ptr_gray <= {PTR_W+1{1'b0}};
            req_wr_valid <= 1'b0;
            src_state <= SRC_IDLE;
            src_pready_o <= 1'b0;
            src_prdata_o <= {DATA_WIDTH{1'b0}};
            src_pslverr_o <= 1'b0;
        end else begin
            // Update gray code pointer
            req_wr_ptr_gray <= bin2gray(req_wr_ptr);

            // Write to FIFO
            if (src_req_write_en) begin
                req_addr[req_wr_ptr] <= src_paddr_i;
                req_wdata[req_wr_ptr] <= src_pwdata_i;
                req_strb[req_wr_ptr] <= src_pstrb_i;
                req_prot[req_wr_ptr] <= src_pprot_i;
                req_write[req_wr_ptr] <= src_pwrite_i;
                req_wr_ptr <= req_wr_ptr + 1'b1;
                req_wr_valid <= 1'b1;
                src_state <= SRC_SETUP;
            end

            // Read response from FIFO
            if (rsp_rd_valid && !rsp_empty) begin
                src_prdata_o <= rsp_rdata[rsp_rd_ptr];
                src_pslverr_o <= rsp_err[rsp_rd_ptr];
                rsp_rd_ptr <= rsp_rd_ptr + 1'b1;
                rsp_rd_valid <= 1'b0;
            end

            // APB ready logic
            if (src_state == SRC_IDLE) begin
                src_pready_o <= 1'b0;
            end else if (src_state == SRC_SETUP) begin
                if (src_penable_i) begin
                    src_pready_o <= 1'b1;
                end else begin
                    src_pready_o <= 1'b0;
                end
            end

            // Complete transaction when response is available and in access phase
            if (src_state == SRC_SETUP && src_penable_i && src_pready_o && rsp_rd_valid && !rsp_empty) begin
                src_state <= SRC_IDLE;
                src_pready_o <= 1'b0;
            end
        end
    end

    // Synchronize request write pointer to dst domain
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            req_wr_ptr_gray_s1 <= {PTR_W+1{1'b0}};
            req_wr_ptr_gray_s2 <= {PTR_W+1{1'b0}};
        end else begin
            req_wr_ptr_gray_s1 <= req_wr_ptr_gray;
            req_wr_ptr_gray_s2 <= req_wr_ptr_gray_s1;
        end
    end

    // Synchronize request read pointer to src domain
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            req_rd_ptr_gray_s1 <= {PTR_W+1{1'b0}};
            req_rd_ptr_gray_s2 <= {PTR_W+1{1'b0}};
        end else begin
            req_rd_ptr_gray_s1 <= req_rd_ptr_gray;
            req_rd_ptr_gray_s2 <= req_rd_ptr_gray_s1;
        end
    end

    // Synchronize response write pointer to src domain
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            rsp_wr_ptr_gray_s1 <= {PTR_W+1{1'b0}};
            rsp_wr_ptr_gray_s2 <= {PTR_W+1{1'b0}};
        end else begin
            rsp_wr_ptr_gray_s1 <= rsp_wr_ptr_gray;
            rsp_wr_ptr_gray_s2 <= rsp_wr_ptr_gray_s1;
        end
    end

    // Synchronize response read pointer to dst domain
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            rsp_rd_ptr_gray_s1 <= {PTR_W+1{1'b0}};
            rsp_rd_ptr_gray_s2 <= {PTR_W+1{1'b0}};
        end else begin
            rsp_rd_ptr_gray_s1 <= rsp_rd_ptr_gray;
            rsp_rd_ptr_gray_s2 <= rsp_rd_ptr_gray_s1;
        end
    end

    // Destination side: FIFO reader to APB slave
    wire dst_req_read_en = req_rd_valid && !req_empty && (dst_state == DST_IDLE);

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            req_rd_ptr <= {PTR_W{1'b0}};
            req_rd_ptr_gray <= {PTR_W+1{1'b0}};
            req_rd_valid <= 1'b0;
            dst_state <= DST_IDLE;
            dst_psel_o <= 1'b0;
            dst_penable_o <= 1'b0;
            dst_pwrite_o <= 1'b0;
            dst_paddr_o <= {ADDR_WIDTH{1'b0}};
            dst_pwdata_o <= {DATA_WIDTH{1'b0}};
            dst_pstrb_o <= {DATA_WIDTH/8{1'b0}};
            dst_pprot_o <= 3'b0;
        end else begin
            // Update gray code pointer
            req_rd_ptr_gray <= bin2gray(req_rd_ptr);

            // Read from FIFO and drive APB
            if (dst_req_read_en) begin
                dst_paddr_o <= req_addr[req_rd_ptr];
                dst_pwdata_o <= req_wdata[req_rd_ptr];
                dst_pstrb_o <= req_strb[req_rd_ptr];
                dst_pprot_o <= req_prot[req_rd_ptr];
                dst_pwrite_o <= req_write[req_rd_ptr];
                dst_psel_o <= 1'b1;
                dst_penable_o <= 1'b0;
                req_rd_ptr <= req_rd_ptr + 1'b1;
                req_rd_valid <= 1'b0;
                dst_state <= DST_SETUP;
            end

            // APB state machine
            if (dst_state == DST_IDLE) begin
                dst_psel_o <= 1'b0;
                dst_penable_o <= 1'b0;
            end else if (dst_state == DST_SETUP) begin
                dst_penable_o <= 1'b1;
                if (dst_pready_i) begin
                    dst_state <= DST_IDLE;
                    dst_psel_o <= 1'b0;
                    dst_penable_o <= 1'b0;
                end
            end

            // Write response to FIFO when access completes
            if (dst_state == DST_SETUP && dst_penable_o && dst_pready_i) begin
                rsp_rdata[rsp_wr_ptr] <= dst_prdata_i;
                rsp_err[rsp_wr_ptr] <= dst_pslverr_i;
                rsp_wr_ptr <= rsp_wr_ptr + 1'b1;
                rsp_wr_valid <= 1'b1;
            end
        end
    end

    // Response FIFO write pointer gray code update
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            rsp_wr_ptr_gray <= {PTR_W+1{1'b0}};
        end else begin
            rsp_wr_ptr_gray <= bin2gray(rsp_wr_ptr);
        end
    end

    // Response FIFO read pointer gray code update
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            rsp_rd_ptr_gray <= {PTR_W+1{1'b0}};
        end else begin
            rsp_rd_ptr_gray <= bin2gray(rsp_rd_ptr);
        end
    end

endmodule
