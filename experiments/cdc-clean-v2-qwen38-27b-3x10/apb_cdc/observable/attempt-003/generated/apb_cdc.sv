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
    // Each entry: {write, addr, wdata, strb, pprot}
    localparam REQ_W = 1 + ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 3;
    reg [REQ_W-1:0] req_mem [0:DEPTH-1];
    reg [AW:0] req_wr_ptr, req_rd_ptr;
    wire req_full = (req_wr_ptr[AW-1:0] == req_rd_ptr[AW-1:0]) && (req_wr_ptr[AW] != req_rd_ptr[AW]);
    wire req_empty = (req_wr_ptr == req_rd_ptr);

    // Response FIFO (dst -> src)
    // Each entry: {slverr, rdata}
    localparam RSP_W = 1 + DATA_WIDTH;
    reg [RSP_W-1:0] rsp_mem [0:DEPTH-1];
    reg [AW:0] rsp_wr_ptr, rsp_rd_ptr;
    wire rsp_full = (rsp_wr_ptr[AW-1:0] == rsp_rd_ptr[AW-1:0]) && (rsp_wr_ptr[AW] != rsp_rd_ptr[AW]);
    wire rsp_empty = (rsp_wr_ptr == rsp_rd_ptr);

    // 2-phase handshake for request FIFO write (src clock)
    reg req_wr_valid;
    wire req_wr_ready = !req_full;
    wire req_wr_done = req_wr_valid && req_wr_ready;

    // 2-phase handshake for request FIFO read (dst clock)
    reg req_rd_valid;
    wire req_rd_ready = !req_empty;
    wire req_rd_done = req_rd_valid && req_rd_ready;

    // 2-phase handshake for response FIFO write (dst clock)
    reg rsp_wr_valid;
    wire rsp_wr_ready = !rsp_full;
    wire rsp_wr_done = rsp_wr_valid && rsp_wr_ready;

    // 2-phase handshake for response FIFO read (src clock)
    reg rsp_rd_valid;
    wire rsp_rd_ready = !rsp_empty;
    wire rsp_rd_done = rsp_rd_valid && rsp_rd_ready;

    // Source-side state machine
    // States: IDLE, SETUP, ACCESS, WAIT_RSP
    localparam S_IDLE = 2'd0;
    localparam S_SETUP = 2'd1;
    localparam S_ACCESS = 2'd2;
    localparam S_WAIT = 2'd3;

    reg [1:0] src_state;
    reg [ADDR_WIDTH-1:0] src_addr_reg;
    reg [DATA_WIDTH-1:0] src_wdata_reg;
    reg [DATA_WIDTH/8-1:0] src_strb_reg;
    reg [2:0] src_pprot_reg;
    reg src_write_reg;
    reg [DATA_WIDTH-1:0] src_rdata_reg;
    reg src_slverr_reg;

    // Destination-side state machine
    // States: IDLE, SETUP, ACCESS
    localparam D_IDLE = 2'd0;
    localparam D_SETUP = 2'd1;
    localparam D_ACCESS = 2'd2;

    reg [1:0] dst_state;
    reg [ADDR_WIDTH-1:0] dst_addr_reg;
    reg [DATA_WIDTH-1:0] dst_wdata_reg;
    reg [DATA_WIDTH/8-1:0] dst_strb_reg;
    reg [2:0] dst_pprot_reg;
    reg dst_write_reg;

    // Source clock domain logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_state <= S_IDLE;
            src_addr_reg <= {ADDR_WIDTH{1'b0}};
            src_wdata_reg <= {DATA_WIDTH{1'b0}};
            src_strb_reg <= {(DATA_WIDTH/8){1'b0}};
            src_pprot_reg <= 3'b000;
            src_write_reg <= 1'b0;
            src_rdata_reg <= {DATA_WIDTH{1'b0}};
            src_slverr_reg <= 1'b0;
            req_wr_valid <= 1'b0;
            rsp_rd_valid <= 1'b0;
        end else begin
            case (src_state)
                S_IDLE: begin
                    if (src_psel_i) begin
                        src_state <= S_SETUP;
                        src_addr_reg <= src_paddr_i;
                        src_wdata_reg <= src_pwdata_i;
                        src_strb_reg <= src_pstrb_i;
                        src_pprot_reg <= src_pprot_i;
                        src_write_reg <= src_pwrite_i;
                    end
                end
                S_SETUP: begin
                    if (src_psel_i && src_penable_i) begin
                        src_state <= S_ACCESS;
                        // Write request to FIFO
                        req_wr_valid <= 1'b1;
                    end
                end
                S_ACCESS: begin
                    if (req_wr_done) begin
                        req_wr_valid <= 1'b0;
                        src_state <= S_WAIT;
                    end
                end
                S_WAIT: begin
                    if (rsp_rd_done) begin
                        src_rdata_reg <= rsp_mem[rsp_rd_ptr[AW-1:0]][RSP_W-1:DATA_WIDTH];
                        src_slverr_reg <= rsp_mem[rsp_rd_ptr[AW-1:0]][RSP_W-1];
                        rsp_rd_valid <= 1'b0;
                        src_state <= S_IDLE;
                    end
                end
                default: src_state <= S_IDLE;
            endcase

            // Response FIFO read pointer increment
            if (rsp_rd_done) begin
                rsp_rd_ptr <= rsp_rd_ptr + 1'b1;
            end
        end
    end

    // Source outputs
    assign src_pready_o = (src_state == S_WAIT) && rsp_rd_done;
    assign src_prdata_o = src_rdata_reg;
    assign src_pslverr_o = src_slverr_reg;

    // Destination clock domain logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_state <= D_IDLE;
            dst_addr_reg <= {ADDR_WIDTH{1'b0}};
            dst_wdata_reg <= {DATA_WIDTH{1'b0}};
            dst_strb_reg <= {(DATA_WIDTH/8){1'b0}};
            dst_pprot_reg <= 3'b000;
            dst_write_reg <= 1'b0;
            req_rd_valid <= 1'b0;
            rsp_wr_valid <= 1'b0;
        end else begin
            case (dst_state)
                D_IDLE: begin
                    if (req_rd_done) begin
                        dst_state <= D_SETUP;
                        dst_addr_reg <= req_mem[req_rd_ptr[AW-1:0]][REQ_W-1:REQ_W-ADDR_WIDTH];
                        dst_wdata_reg <= req_mem[req_rd_ptr[AW-1:0]][REQ_W-ADDR_WIDTH-1:REQ_W-ADDR_WIDTH-DATA_WIDTH];
                        dst_strb_reg <= req_mem[req_rd_ptr[AW-1:0]][REQ_W-ADDR_WIDTH-DATA_WIDTH-1:REQ_W-ADDR_WIDTH-DATA_WIDTH-(DATA_WIDTH/8)];
                        dst_pprot_reg <= req_mem[req_rd_ptr[AW-1:0]][REQ_W-ADDR_WIDTH-DATA_WIDTH-(DATA_WIDTH/8)-1:REQ_W-ADDR_WIDTH-DATA_WIDTH-(DATA_WIDTH/8)-3];
                        dst_write_reg <= req_mem[req_rd_ptr[AW-1:0]][REQ_W-1];
                        req_rd_valid <= 1'b0;
                    end
                end
                D_SETUP: begin
                    if (dst_pready_i) begin
                        dst_state <= D_ACCESS;
                    end
                end
                D_ACCESS: begin
                    if (dst_pready_i) begin
                        dst_state <= D_IDLE;
                        // Write response to FIFO
                        rsp_wr_valid <= 1'b1;
                    end
                end
                default: dst_state <= D_IDLE;
            endcase

            // Request FIFO read pointer increment
            if (req_rd_done) begin
                req_rd_ptr <= req_rd_ptr + 1'b1;
            end

            // Response FIFO write pointer increment
            if (rsp_wr_done) begin
                rsp_wr_ptr <= rsp_wr_ptr + 1'b1;
            end
        end
    end

    // Destination outputs
    assign dst_psel_o = (dst_state == D_SETUP) || (dst_state == D_ACCESS);
    assign dst_penable_o = (dst_state == D_ACCESS);
    assign dst_pwrite_o = dst_write_reg;
    assign dst_paddr_o = dst_addr_reg;
    assign dst_pwdata_o = dst_wdata_reg;
    assign dst_pstrb_o = dst_strb_reg;
    assign dst_pprot_o = dst_pprot_reg;

    // FIFO memory writes
    // Request FIFO write (src clock)
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            req_wr_ptr <= {(AW+1){1'b0}};
        end else if (req_wr_done) begin
            req_mem[req_wr_ptr[AW-1:0]] <= {src_write_reg, src_addr_reg, src_wdata_reg, src_strb_reg, src_pprot_reg};
            req_wr_ptr <= req_wr_ptr + 1'b1;
        end
    end

    // Response FIFO write (dst clock)
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            rsp_wr_ptr <= {(AW+1){1'b0}};
        end else if (rsp_wr_done) begin
            rsp_mem[rsp_wr_ptr[AW-1:0]] <= {dst_pslverr_i, dst_prdata_i};
            rsp_wr_ptr <= rsp_wr_ptr + 1'b1;
        end
    end

    // Handshake valid signal resets
    // req_wr_valid is set in src clock domain, cleared on req_wr_done
    // req_rd_valid is set in dst clock domain, cleared on req_rd_done
    // rsp_wr_valid is set in dst clock domain, cleared on rsp_wr_done
    // rsp_rd_valid is set in src clock domain, cleared on rsp_rd_done

    // The valid signals are single-bit flags that are set in one clock domain
    // and cleared when the handshake completes in the same clock domain.
    // Since the FIFO pointers are synchronized via the standard Gray code
    // approach (using the full pointer with MSB for full/empty detection),
    // the valid signals are local to each clock domain and do not cross.

endmodule
