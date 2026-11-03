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
    // Each entry: {pwrite, paddr, pwdata, pstrb, pprot}
    localparam REQ_W = 1 + ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 3;
    reg [REQ_W-1:0] req_mem [0:DEPTH-1];
    reg [PTR_W-1:0] req_wr_ptr, req_rd_ptr;
    wire req_full, req_empty;
    wire req_push, req_pop;

    // Response FIFO (dst -> src)
    // Each entry: {prdata, pslverr}
    localparam RSP_W = DATA_WIDTH + 1;
    reg [RSP_W-1:0] rsp_mem [0:DEPTH-1];
    reg [PTR_W-1:0] rsp_wr_ptr, rsp_rd_ptr;
    wire rsp_full, rsp_empty;
    wire rsp_push, rsp_pop;

    // Gray code pointers for CDC
    wire [PTR_W-1:0] req_wr_ptr_gray, req_rd_ptr_gray;
    wire [PTR_W-1:0] rsp_wr_ptr_gray, rsp_rd_ptr_gray;

    // Synchronizers
    reg [PTR_W-1:0] req_rd_ptr_gray_s1, req_rd_ptr_gray_s2;
    reg [PTR_W-1:0] rsp_wr_ptr_gray_s1, rsp_wr_ptr_gray_s2;

    // Binary to Gray
    function [PTR_W-1:0] bin2gray;
        input [PTR_W-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // Gray to Binary
    function [PTR_W-1:0] gray2bin;
        input [PTR_W-1:0] gray;
        reg [PTR_W-1:0] bin;
        integer i;
        begin
            bin[PTR_W-1] = gray[PTR_W-1];
            for (i = PTR_W-2; i >= 0; i = i - 1)
                bin[i] = gray[i] ^ bin[i+1];
            gray2bin = bin;
        end
    endfunction

    assign req_wr_ptr_gray = bin2gray(req_wr_ptr);
    assign rsp_wr_ptr_gray = bin2gray(rsp_wr_ptr);
    assign req_rd_ptr_gray = bin2gray(req_rd_ptr);
    assign rsp_rd_ptr_gray = bin2gray(rsp_rd_ptr);

    // Synchronizer for req_rd_ptr_gray (src -> dst)
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            req_rd_ptr_gray_s1 <= {PTR_W{1'b0}};
            req_rd_ptr_gray_s2 <= {PTR_W{1'b0}};
        end else begin
            req_rd_ptr_gray_s1 <= req_rd_ptr_gray;
            req_rd_ptr_gray_s2 <= req_rd_ptr_gray_s1;
        end
    end

    // Synchronizer for rsp_wr_ptr_gray (dst -> src)
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            rsp_wr_ptr_gray_s1 <= {PTR_W{1'b0}};
            rsp_wr_ptr_gray_s2 <= {PTR_W{1'b0}};
        end else begin
            rsp_wr_ptr_gray_s1 <= rsp_wr_ptr_gray;
            rsp_wr_ptr_gray_s2 <= rsp_wr_ptr_gray_s1;
        end
    end

    // Convert synchronized gray to binary
    wire [PTR_W-1:0] req_rd_ptr_gray_bin = gray2bin(req_rd_ptr_gray_s2);
    wire [PTR_W-1:0] rsp_wr_ptr_gray_bin = gray2bin(rsp_wr_ptr_gray_s2);

    // FIFO full/empty logic
    // For a FIFO of depth DEPTH, full when wr_ptr - rd_ptr == DEPTH
    // We use the standard approach: full when the upper bits differ and lower bits are complement
    wire [PTR_W:0] req_wr_ptr_ext = {1'b0, req_wr_ptr};
    wire [PTR_W:0] req_rd_ptr_ext = {1'b0, req_rd_ptr_gray_bin};
    wire req_full = (req_wr_ptr_ext - req_rd_ptr_ext) == DEPTH;

    wire [PTR_W:0] rsp_wr_ptr_ext = {1'b0, rsp_wr_ptr};
    wire [PTR_W:0] rsp_rd_ptr_ext = {1'b0, rsp_rd_ptr};
    wire rsp_full = (rsp_wr_ptr_ext - rsp_rd_ptr_ext) == DEPTH;

    assign req_empty = (req_wr_ptr == req_rd_ptr);
    assign rsp_empty = (rsp_wr_ptr == rsp_rd_ptr);

    // Source side: APB request handling
    // We accept a request when:
    // 1. src_psel_i && src_penable_i (phase 2 of APB)
    // 2. Request FIFO is not full
    // 3. Response FIFO is not full (to ensure we can get a response back)
    // Actually, we need to be careful. Let's think about this differently.
    
    // The source side presents an APB transaction. We need to:
    // 1. Capture the request when src_psel_i && src_penable_i
    // 2. Push it into the request FIFO
    // 3. Wait for the response to come back
    // 4. Present the response on src_prdata_o and src_pslverr_o
    // 5. Assert src_pready_o when the response is ready
    
    // Let's use a state machine on the source side:
    // IDLE: waiting for src_psel_i
    // WAIT_PHASE2: src_psel_i is high, waiting for src_penable_i
    // WAIT_RSP: request has been pushed, waiting for response
    // DONE: response is ready, assert src_pready_o

    reg src_state;
    localparam SRC_IDLE = 1'b0;
    localparam SRC_WAIT_RSP = 1'b1;

    reg [REQ_W-1:0] src_req_reg;
    reg [RSP_W-1:0] src_rsp_reg;
    reg src_rsp_valid;

    // Push request into FIFO
    assign req_push = (src_state == SRC_IDLE) && src_psel_i && src_penable_i && !req_full;

    // Pop response from FIFO
    assign rsp_pop = (src_state == SRC_WAIT_RSP) && !rsp_empty;

    // Source side registers
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_state <= SRC_IDLE;
            src_req_reg <= {REQ_W{1'b0}};
            src_rsp_reg <= {RSP_W{1'b0}};
            src_rsp_valid <= 1'b0;
            req_wr_ptr <= {PTR_W{1'b0}};
            rsp_rd_ptr <= {PTR_W{1'b0}};
        end else begin
            // Update request write pointer
            if (req_push)
                req_wr_ptr <= req_wr_ptr + 1'b1;

            // Update response read pointer
            if (rsp_pop)
                rsp_rd_ptr <= rsp_rd_ptr + 1'b1;

            // Capture request data
            if (req_push)
                src_req_reg <= {src_pwrite_i, src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i};

            // State machine
            case (src_state)
                SRC_IDLE: begin
                    if (src_psel_i && src_penable_i && !req_full) begin
                        src_state <= SRC_WAIT_RSP;
                        src_rsp_valid <= 1'b0;
                    end
                end
                SRC_WAIT_RSP: begin
                    if (!rsp_empty) begin
                        src_rsp_reg <= rsp_mem[rsp_rd_ptr];
                        src_rsp_valid <= 1'b1;
                        src_state <= SRC_IDLE;
                    end
                end
                default: src_state <= SRC_IDLE;
            endcase
        end
    end

    // Source side outputs
    assign src_pready_o = (src_state == SRC_WAIT_RSP) && src_rsp_valid;
    assign src_prdata_o = src_rsp_reg[RSP_W-1:1];
    assign src_pslverr_o = src_rsp_reg[0];

    // Destination side: APB response handling
    // We pop from the request FIFO and present an APB transaction to the destination.
    // We need to wait for dst_pready_i to complete the transaction.
    // Then we push the response into the response FIFO.

    reg dst_state;
    localparam DST_IDLE = 1'b0;
    localparam DST_PHASE1 = 1'b1;
    localparam DST_PHASE2 = 1'b2;

    reg [REQ_W-1:0] dst_req_reg;

    // Pop request from FIFO
    assign req_pop = (dst_state == DST_IDLE) && !req_empty;

    // Push response into FIFO
    assign rsp_push = (dst_state == DST_PHASE2) && dst_pready_i;

    // Destination side registers
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_state <= DST_IDLE;
            dst_req_reg <= {REQ_W{1'b0}};
            req_rd_ptr <= {PTR_W{1'b0}};
            rsp_wr_ptr <= {PTR_W{1'b0}};
        end else begin
            // Update request read pointer
            if (req_pop)
                req_rd_ptr <= req_rd_ptr + 1'b1;

            // Update response write pointer
            if (rsp_push)
                rsp_wr_ptr <= rsp_wr_ptr + 1'b1;

            // Capture request data
            if (req_pop)
                dst_req_reg <= req_mem[req_rd_ptr];

            // State machine
            case (dst_state)
                DST_IDLE: begin
                    if (!req_empty) begin
                        dst_state <= DST_PHASE1;
                    end
                end
                DST_PHASE1: begin
                    // Present phase 1: psel=1, penable=0
                    // Wait for next clock to go to phase 2
                    dst_state <= DST_PHASE2;
                end
                DST_PHASE2: begin
                    // Present phase 2: psel=1, penable=1
                    // Wait for dst_pready_i
                    if (dst_pready_i) begin
                        // Store response
                        rsp_mem[rsp_wr_ptr] <= {dst_prdata_i, dst_pslverr_i};
                        dst_state <= DST_IDLE;
                    end
                end
                default: dst_state <= DST_IDLE;
            endcase
        end
    end

    // Destination side outputs
    assign dst_psel_o = (dst_state == DST_PHASE1) || (dst_state == DST_PHASE2);
    assign dst_penable_o = (dst_state == DST_PHASE2);
    assign dst_pwrite_o = dst_req_reg[REQ_W-1];
    assign dst_paddr_o = dst_req_reg[REQ_W-2:ADDR_WIDTH-1];
    assign dst_pwdata_o = dst_req_reg[ADDR_WIDTH-1:ADDR_WIDTH-DATA_WIDTH];
    assign dst_pstrb_o = dst_req_reg[ADDR_WIDTH-DATA_WIDTH-1:ADDR_WIDTH-DATA_WIDTH-DATA_WIDTH/8];
    assign dst_pprot_o = dst_req_reg[ADDR_WIDTH-DATA_WIDTH-DATA_WIDTH/8-1:0];

    // Write to FIFOs
    always @(posedge src_pclk_i) begin
        if (req_push)
            req_mem[req_wr_ptr] <= src_req_reg;
    end

    always @(posedge dst_pclk_i) begin
        if (rsp_push)
            rsp_mem[rsp_wr_ptr] <= {dst_prdata_i, dst_pslverr_i};
    end

endmodule
