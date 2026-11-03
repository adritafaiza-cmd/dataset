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
    reg [DATA_WIDTH-1:0] req_fifo [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] req_addr [0:DEPTH-1];
    reg [DATA_WIDTH/8-1:0] req_strb [0:DEPTH-1];
    reg [2:0] req_prot [0:DEPTH-1];
    reg req_write [0:DEPTH-1];

    reg [AW:0] req_wr_ptr;
    reg [AW:0] req_rd_ptr;

    // Response FIFO (dst -> src)
    reg [DATA_WIDTH-1:0] rsp_fifo [0:DEPTH-1];
    reg rsp_err [0:DEPTH-1];

    reg [AW:0] rsp_wr_ptr;
    reg [AW:0] rsp_rd_ptr;

    // Gray code pointers for CDC
    wire [AW:0] req_wr_ptr_gray  = req_wr_ptr ^ {1'b0, req_wr_ptr[AW-1:0]};
    wire [AW:0] req_rd_ptr_gray  = req_rd_ptr ^ {1'b0, req_rd_ptr[AW-1:0]};
    wire [AW:0] rsp_wr_ptr_gray  = rsp_wr_ptr ^ {1'b0, rsp_wr_ptr[AW-1:0]};
    wire [AW:0] rsp_rd_ptr_gray  = rsp_rd_ptr ^ {1'b0, rsp_rd_ptr[AW-1:0]};

    // Synchronizers: req_rd_ptr_gray (src -> dst)
    reg [AW:0] req_rd_ptr_gray_s1, req_rd_ptr_gray_s2;
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            req_rd_ptr_gray_s1 <= {(AW+1){1'b0}};
            req_rd_ptr_gray_s2 <= {(AW+1){1'b0}};
        end else begin
            req_rd_ptr_gray_s1 <= req_rd_ptr_gray;
            req_rd_ptr_gray_s2 <= req_rd_ptr_gray_s1;
        end
    end

    // Synchronizers: rsp_wr_ptr_gray (dst -> src)
    reg [AW:0] rsp_wr_ptr_gray_s1, rsp_wr_ptr_gray_s2;
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            rsp_wr_ptr_gray_s1 <= {(AW+1){1'b0}};
            rsp_wr_ptr_gray_s2 <= {(AW+1){1'b0}};
        end else begin
            rsp_wr_ptr_gray_s1 <= rsp_wr_ptr_gray;
            rsp_wr_ptr_gray_s2 <= rsp_wr_ptr_gray_s1;
        end
    end

    // Synchronizers: rsp_rd_ptr_gray (src -> dst)
    reg [AW:0] rsp_rd_ptr_gray_s1, rsp_rd_ptr_gray_s2;
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            rsp_rd_ptr_gray_s1 <= {(AW+1){1'b0}};
            rsp_rd_ptr_gray_s2 <= {(AW+1){1'b0}};
        end else begin
            rsp_rd_ptr_gray_s1 <= rsp_rd_ptr_gray;
            rsp_rd_ptr_gray_s2 <= rsp_rd_ptr_gray_s1;
        end
    end

    // Synchronizers: req_wr_ptr_gray (src -> dst)
    reg [AW:0] req_wr_ptr_gray_s1, req_wr_ptr_gray_s2;
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            req_wr_ptr_gray_s1 <= {(AW+1){1'b0}};
            req_wr_ptr_gray_s2 <= {(AW+1){1'b0}};
        end else begin
            req_wr_ptr_gray_s1 <= req_wr_ptr_gray;
            req_wr_ptr_gray_s2 <= req_wr_ptr_gray_s1;
        end
    end

    // Convert gray to binary
    function [AW:0] gray2bin;
        input [AW:0] gray;
        reg [AW:0] mask;
        begin
            mask = gray[AW] << 1;
            gray2bin = gray ^ mask;
            mask = mask >> 1;
            while (mask != 0) begin
                gray2bin = gray2bin ^ mask;
                mask = mask >> 1;
            end
        end
    endfunction

    wire [AW:0] req_wr_ptr_gray_dst  = req_wr_ptr_gray_s2;
    wire [AW:0] req_rd_ptr_gray_dst  = req_rd_ptr_gray_s2;
    wire [AW:0] rsp_wr_ptr_gray_src  = rsp_wr_ptr_gray_s2;
    wire [AW:0] rsp_rd_ptr_gray_dst  = rsp_rd_ptr_gray_s2;

    wire [AW:0] req_wr_ptr_bin_dst = gray2bin(req_wr_ptr_gray_dst);
    wire [AW:0] req_rd_ptr_bin_dst = gray2bin(req_rd_ptr_gray_dst);
    wire [AW:0] rsp_wr_ptr_bin_src = gray2bin(rsp_wr_ptr_gray_src);
    wire [AW:0] rsp_rd_ptr_bin_dst = gray2bin(rsp_rd_ptr_gray_dst);

    // FIFO full/empty conditions
    wire req_full = (req_wr_ptr == req_rd_ptr) && (req_wr_ptr[AW] != req_rd_ptr[AW]);
    wire req_empty = (req_wr_ptr == req_rd_ptr);

    wire rsp_full = (rsp_wr_ptr == rsp_rd_ptr) && (rsp_wr_ptr[AW] != rsp_rd_ptr[AW]);
    wire rsp_empty = (rsp_wr_ptr == rsp_rd_ptr);

    // Source side: APB slave interface
    reg src_pready_r;
    reg [DATA_WIDTH-1:0] src_prdata_r;
    reg src_pslverr_r;

    // Detect APB setup phase: PSEL high, PENABLE low
    wire src_setup = src_psel_i && !src_penable_i;
    // Detect APB access phase: PSEL high, PENABLE high
    wire src_access = src_psel_i && src_penable_i;

    // Write request to FIFO during setup phase if not full
    wire src_can_write = src_setup && !req_full;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            req_wr_ptr <= {(AW+1){1'b0}};
            src_pready_r <= 1'b0;
            src_prdata_r <= {DATA_WIDTH{1'b0}};
            src_pslverr_r <= 1'b0;
        end else begin
            // Write request to FIFO
            if (src_can_write) begin
                req_fifo[req_wr_ptr[AW-1:0]] <= src_pwdata_i;
                req_addr[req_wr_ptr[AW-1:0]] <= src_paddr_i;
                req_strb[req_wr_ptr[AW-1:0]] <= src_pstrb_i;
                req_prot[req_wr_ptr[AW-1:0]] <= src_pprot_i;
                req_write[req_wr_ptr[AW-1:0]] <= src_pwrite_i;
                req_wr_ptr <= req_wr_ptr + 1'b1;
            end

            // Read response from FIFO
            if (!rsp_empty) begin
                src_prdata_r <= rsp_fifo[rsp_rd_ptr[AW-1:0]];
                src_pslverr_r <= rsp_err[rsp_rd_ptr[AW-1:0]];
                rsp_rd_ptr <= rsp_rd_ptr + 1'b1;
            end

            // Pready: high when no pending requests in FIFO
            // We can complete the current APB transaction when the response is available
            // For simplicity, pready is high when the FIFO is empty (no pending requests)
            // But we need to handle the case where a request is in flight
            // Actually, we should assert pready when the response for the current
            // transaction is available. Since we process one at a time, we can
            // assert pready when rsp is not empty and we're in access phase.
            
            // Let's use a simpler approach: track if we have a pending request
            // Pready is high when there are no more requests to send and the
            // current response is ready.
            
            // For a single outstanding transaction model:
            // - During setup: if FIFO not full, we can accept (pready can be low to stall)
            // - During access: pready high when response is available
            
            // Let's track the number of outstanding requests
            // Actually, with the FIFO approach, we can have multiple outstanding.
            // But APB only allows one outstanding transaction.
            
            // So we should only write to FIFO if there are no outstanding requests.
            // Outstanding = req_wr_ptr - req_rd_ptr (in binary)
            
            // Let's simplify: only allow one request in flight at a time.
            // Pready is high when:
            // 1. We're in access phase AND the response is available (rsp not empty)
            // 2. OR we're not in a transaction
            
            // Actually, the standard APB behavior:
            // - Pready can be low to extend the access phase
            // - When Pready is high, the transaction completes
            
            // For our CDC bridge:
            // - We can only start a new transaction when the previous one is complete
            // - A transaction is complete when the response has been read back
            
            // Let's use a state machine approach for the source side
        end
    end

    // Let's redo the source side with a proper state machine
    // States: IDLE, SETUP, ACCESS, WAIT_RSP
    localparam S_IDLE   = 2'd0;
    localparam S_SETUP  = 2'd1;
    localparam S_ACCESS = 2'd2;
    localparam S_WAIT   = 2'd3;

    reg [1:0] src_state;
    reg [1:0] src_state_nxt;

    // Track if we have a pending request that hasn't been responded to
    wire src_has_pending = !req_empty;

    always @(*) begin
        src_state_nxt = src_state;
        case (src_state)
            S_IDLE: begin
                if (src_psel_i && !src_penable_i) begin
                    src_state_nxt = S_SETUP;
                end
            end
            S_SETUP: begin
                if (src_psel_i && src_penable_i) begin
                    src_state_nxt = S_ACCESS;
                end else if (!src_psel_i) begin
                    src_state_nxt = S_IDLE;
                end
            end
            S_ACCESS: begin
                if (src_psel_i && src_penable_i && !rsp_empty) begin
                    src_state_nxt = S_IDLE;
                end else if (!src_psel_i) begin
                    src_state_nxt = S_IDLE;
                end
            end
            default: src_state_nxt = S_IDLE;
        endcase
    end

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_state <= S_IDLE;
        end else begin
            src_state <= src_state_nxt;
        end
    end

    // Pready: high when we can complete the transaction
    // In ACCESS state, pready is high when response is available
    assign src_pready_o = (src_state == S_ACCESS) && !rsp_empty;

    // Write to request FIFO only when in SETUP state and FIFO not full
    wire src_write_req = (src_state == S_SETUP) && !req_full;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            req_wr_ptr <= {(AW+1){1'b0}};
            src_prdata_r <= {DATA_WIDTH{1'b0}};
            src_pslverr_r <= 1'b0;
        end else begin
            if (src_write_req) begin
                req_fifo[req_wr_ptr[AW-1:0]] <= src_pwdata_i;
                req_addr[req_wr_ptr[AW-1:0]] <= src_paddr_i;
                req_strb[req_wr_ptr[AW-1:0]] <= src_pstrb_i;
                req_prot[req_wr_ptr[AW-1:0]] <= src_pprot_i;
                req_write[req_wr_ptr[AW-1:0]] <= src_pwrite_i;
                req_wr_ptr <= req_wr_ptr + 1'b1;
            end

            if (!rsp_empty) begin
                src_prdata_r <= rsp_fifo[rsp_rd_ptr[AW-1:0]];
                src_pslverr_r <= rsp_err[rsp_rd_ptr[AW-1:0]];
                rsp_rd_ptr <= rsp_rd_ptr + 1'b1;
            end
        end
    end

    assign src_prdata_o  = src_prdata_r;
    assign src_pslverr_o = src_pslverr_r;

    // Destination side: APB master interface
    reg dst_psel_r;
    reg dst_penable_r;
    reg dst_pwrite_r;
    reg [ADDR_WIDTH-1:0] dst_paddr_r;
    reg [DATA_WIDTH-1:0] dst_pwdata_r;
    reg [DATA_WIDTH/8-1:0] dst_pstrb_r;
    reg [2:0] dst_pprot_r;

    // States for destination: IDLE, SETUP, ACCESS
    localparam D_IDLE   = 2'd0;
    localparam D_SETUP  = 2'd1;
    localparam D_ACCESS = 2'd2;

    reg [1:0] dst_state;
    reg [1:0] dst_state_nxt;

    wire dst_req_available = !req_empty;
    wire dst_rsp_space = !rsp_full;

    always @(*) begin
        dst_state_nxt = dst_state;
        case (dst_state)
            D_IDLE: begin
                if (dst_req_available && dst_rsp_space) begin
                    dst_state_nxt = D_SETUP;
                end
            end
            D_SETUP: begin
                dst_state_nxt = D_ACCESS;
            end
            D_ACCESS: begin
                if (dst_pready_i) begin
                    dst_state_nxt = D_IDLE;
                end
            end
            default: dst_state_nxt = D_IDLE;
        endcase
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_state <= D_IDLE;
            dst_psel_r <= 1'b0;
            dst_penable_r <= 1'b0;
            dst_pwrite_r <= 1'b0;
            dst_paddr_r <= {ADDR_WIDTH{1'b0}};
            dst_pwdata_r <= {DATA_WIDTH{1'b0}};
            dst_pstrb_r <= {(DATA_WIDTH/8){1'b0}};
            dst_pprot_r <= 3'b0;
            req_rd_ptr <= {(AW+1){1'b0}};
            rsp_wr_ptr <= {(AW+1){1'b0}};
        end else begin
            dst_state <= dst_state_nxt;

            case (dst_state)
                D_IDLE: begin
                    dst_psel_r <= 1'b0;
                    dst_penable_r <= 1'b0;
                    if (dst_req_available && dst_rsp_space) begin
                        // Load request from FIFO
                        dst_pwrite_r <= req_write[req_rd_ptr[AW-1:0]];
                        dst_paddr_r <= req_addr[req_rd_ptr[AW-1:0]];
                        dst_pwdata_r <= req_fifo[req_rd_ptr[AW-1:0]];
                        dst_pstrb_r <= req_strb[req_rd_ptr[AW-1:0]];
                        dst_pprot_r <= req_prot[req_rd_ptr[AW-1:0]];
                    end
                end
                D_SETUP: begin
                    dst_psel_r <= 1'b1;
                    dst_penable_r <= 1'b0;
                    // Read from request FIFO
                    req_rd_ptr <= req_rd_ptr + 1'b1;
                end
                D_ACCESS: begin
                    dst_psel_r <= 1'b1;
                    dst_penable_r <= 1'b1;
                    if (dst_pready_i) begin
                        // Write response to FIFO
                        rsp_fifo[rsp_wr_ptr[AW-1:0]] <= dst_prdata_i;
                        rsp_err[rsp_wr_ptr[AW-1:0]] <= dst_pslverr_i;
                        rsp_wr_ptr <= rsp_wr_ptr + 1'b1;
                    end
                end
                default: begin
                    dst_psel_r <= 1'b0;
                    dst_penable_r <= 1'b0;
                end
            endcase
        end
    end

    assign dst_psel_o   = dst_psel_r;
    assign dst_penable_o = dst_penable_r;
    assign dst_pwrite_o = dst_pwrite_r;
    assign dst_paddr_o  = dst_paddr_r;
    assign dst_pwdata_o = dst_pwdata_r;
    assign dst_pstrb_o  = dst_pstrb_r;
    assign dst_pprot_o  = dst_pprot_r;

endmodule
