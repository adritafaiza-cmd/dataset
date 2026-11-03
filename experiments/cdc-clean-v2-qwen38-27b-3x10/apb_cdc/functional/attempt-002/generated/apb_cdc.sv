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

    // Source-side state
    reg src_idle;
    reg src_setup;
    reg src_access;
    reg src_done;

    // Source-side data registers
    reg [ADDR_WIDTH-1:0] src_addr_reg;
    reg [DATA_WIDTH-1:0] src_wdata_reg;
    reg [DATA_WIDTH/8-1:0] src_strb_reg;
    reg [2:0] src_prot_reg;
    reg src_write_reg;

    // Source-side response registers
    reg [DATA_WIDTH-1:0] src_rdata_reg;
    reg src_slverr_reg;

    // Destination-side state
    reg dst_idle;
    reg dst_setup;
    reg dst_access;
    reg dst_done;

    // Destination-side data registers
    reg [ADDR_WIDTH-1:0] dst_addr_reg;
    reg [DATA_WIDTH-1:0] dst_wdata_reg;
    reg [DATA_WIDTH/8-1:0] dst_strb_reg;
    reg [2:0] dst_prot_reg;
    reg dst_write_reg;

    // CDC signals
    wire src_req_valid;
    wire dst_req_ready;
    wire dst_resp_valid;
    wire src_resp_ready;

    // Request FIFO (source to destination)
    reg [ADDR_WIDTH-1:0] req_fifo [0:DEPTH-1];
    reg [DATA_WIDTH-1:0] wdata_fifo [0:DEPTH-1];
    reg [DATA_WIDTH/8-1:0] strb_fifo [0:DEPTH-1];
    reg [2:0] prot_fifo [0:DEPTH-1];
    reg write_fifo [0:DEPTH-1];
    reg [PTR_W-1:0] req_wr_ptr;
    reg [PTR_W-1:0] req_rd_ptr;

    // Response FIFO (destination to source)
    reg [DATA_WIDTH-1:0] resp_fifo [0:DEPTH-1];
    reg slverr_fifo [0:DEPTH-1];
    reg [PTR_W-1:0] resp_wr_ptr;
    reg [PTR_W-1:0] resp_rd_ptr;

    // FIFO full/empty
    wire req_full = (req_wr_ptr == req_rd_ptr) && (req_wr_ptr[PTR_W-1] != req_rd_ptr[PTR_W-1]);
    wire req_empty = (req_wr_ptr == req_rd_ptr);
    wire resp_full = (resp_wr_ptr == resp_rd_ptr) && (resp_wr_ptr[PTR_W-1] != resp_rd_ptr[PTR_W-1]);
    wire resp_empty = (resp_wr_ptr == resp_rd_ptr);

    // Source side: accept request when idle and not full
    assign src_pready_o = src_idle && !req_full;
    assign src_prdata_o = src_rdata_reg;
    assign src_pslverr_o = src_slverr_reg;

    // Destination side outputs
    assign dst_psel_o = dst_setup || dst_access;
    assign dst_penable_o = dst_access;
    assign dst_pwrite_o = dst_write_reg;
    assign dst_paddr_o = dst_addr_reg;
    assign dst_pwdata_o = dst_wdata_reg;
    assign dst_pstrb_o = dst_strb_reg;
    assign dst_pprot_o = dst_prot_reg;

    // Source clock domain: request FIFO write
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_idle <= 1'b1;
            src_setup <= 1'b0;
            src_access <= 1'b0;
            src_done <= 1'b0;
            src_addr_reg <= {ADDR_WIDTH{1'b0}};
            src_wdata_reg <= {DATA_WIDTH{1'b0}};
            src_strb_reg <= {(DATA_WIDTH/8){1'b0}};
            src_prot_reg <= 3'b000;
            src_write_reg <= 1'b0;
            src_rdata_reg <= {DATA_WIDTH{1'b0}};
            src_slverr_reg <= 1'b0;
            req_wr_ptr <= {PTR_W{1'b0}};
            resp_rd_ptr <= {PTR_W{1'b0}};
        end else begin
            // State machine
            case (1'b1)
                src_idle: begin
                    if (src_psel_i && !req_full) begin
                        src_idle <= 1'b0;
                        src_setup <= 1'b1;
                        src_addr_reg <= src_paddr_i;
                        src_wdata_reg <= src_pwdata_i;
                        src_strb_reg <= src_pstrb_i;
                        src_prot_reg <= src_pprot_i;
                        src_write_reg <= src_pwrite_i;
                    end
                end
                src_setup: begin
                    if (src_penable_i) begin
                        src_setup <= 1'b0;
                        src_access <= 1'b1;
                        // Write to request FIFO
                        req_fifo[req_wr_ptr] <= src_addr_reg;
                        wdata_fifo[req_wr_ptr] <= src_wdata_reg;
                        strb_fifo[req_wr_ptr] <= src_strb_reg;
                        prot_fifo[req_wr_ptr] <= src_prot_reg;
                        write_fifo[req_wr_ptr] <= src_write_reg;
                        req_wr_ptr <= req_wr_ptr + 1'b1;
                    end
                end
                src_access: begin
                    if (!resp_empty) begin
                        src_access <= 1'b0;
                        src_done <= 1'b1;
                        src_rdata_reg <= resp_fifo[resp_rd_ptr];
                        src_slverr_reg <= slverr_fifo[resp_rd_ptr];
                        resp_rd_ptr <= resp_rd_ptr + 1'b1;
                    end
                end
                src_done: begin
                    src_done <= 1'b0;
                    src_idle <= 1'b1;
                end
                default: begin
                    src_idle <= 1'b1;
                end
            endcase
        end
    end

    // Destination clock domain: request FIFO read and response FIFO write
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_idle <= 1'b1;
            dst_setup <= 1'b0;
            dst_access <= 1'b0;
            dst_done <= 1'b0;
            dst_addr_reg <= {ADDR_WIDTH{1'b0}};
            dst_wdata_reg <= {DATA_WIDTH{1'b0}};
            dst_strb_reg <= {(DATA_WIDTH/8){1'b0}};
            dst_prot_reg <= 3'b000;
            dst_write_reg <= 1'b0;
            req_rd_ptr <= {PTR_W{1'b0}};
            resp_wr_ptr <= {PTR_W{1'b0}};
        end else begin
            case (1'b1)
                dst_idle: begin
                    if (!req_empty) begin
                        dst_idle <= 1'b0;
                        dst_setup <= 1'b1;
                        dst_addr_reg <= req_fifo[req_rd_ptr];
                        dst_wdata_reg <= wdata_fifo[req_rd_ptr];
                        dst_strb_reg <= strb_fifo[req_rd_ptr];
                        dst_prot_reg <= prot_fifo[req_rd_ptr];
                        dst_write_reg <= write_fifo[req_rd_ptr];
                        req_rd_ptr <= req_rd_ptr + 1'b1;
                    end
                end
                dst_setup: begin
                    dst_access <= 1'b1;
                    dst_setup <= 1'b0;
                end
                dst_access: begin
                    if (dst_pready_i) begin
                        dst_access <= 1'b0;
                        dst_done <= 1'b1;
                        resp_fifo[resp_wr_ptr] <= dst_prdata_i;
                        slverr_fifo[resp_wr_ptr] <= dst_pslverr_i;
                        resp_wr_ptr <= resp_wr_ptr + 1'b1;
                    end
                end
                dst_done: begin
                    dst_done <= 1'b0;
                    dst_idle <= 1'b1;
                end
                default: begin
                    dst_idle <= 1'b1;
                end
            endcase
        end
    end

endmodule
