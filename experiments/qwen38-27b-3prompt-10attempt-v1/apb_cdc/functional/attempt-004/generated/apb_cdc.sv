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

    // Source side state
    reg src_idle;
    reg src_setup;
    reg src_access;

    // Destination side state
    reg dst_idle;
    reg dst_setup;
    reg dst_access;

    // FIFO for request data
    reg [DATA_WIDTH-1:0] req_data_fifo [0:(1<<LOG_DEPTH)-1];
    reg [ADDR_WIDTH-1:0] req_addr_fifo [0:(1<<LOG_DEPTH)-1];
    reg [DATA_WIDTH/8-1:0] req_strb_fifo [0:(1<<LOG_DEPTH)-1];
    reg [2:0] req_prot_fifo [0:(1<<LOG_DEPTH)-1];
    reg req_write_fifo [0:(1<<LOG_DEPTH)-1];
    reg [LOG_DEPTH-1:0] req_wr_ptr;
    reg [LOG_DEPTH-1:0] req_rd_ptr;
    reg req_valid;

    // FIFO for response data
    reg [DATA_WIDTH-1:0] rsp_data_fifo [0:(1<<LOG_DEPTH)-1];
    reg rsp_err_fifo [0:(1<<LOG_DEPTH)-1];
    reg [LOG_DEPTH-1:0] rsp_wr_ptr;
    reg [LOG_DEPTH-1:0] rsp_rd_ptr;
    reg rsp_valid;

    // Synchronization signals
    reg src_to_dst_req;
    reg [2:0] src_to_dst_req_sync;
    reg dst_to_src_rsp;
    reg [2:0] dst_to_src_rsp_sync;

    // Source side logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_idle <= 1'b1;
            src_setup <= 1'b0;
            src_access <= 1'b0;
            src_pready_o <= 1'b0;
            src_prdata_o <= {DATA_WIDTH{1'b0}};
            src_pslverr_o <= 1'b0;
            req_wr_ptr <= {LOG_DEPTH{1'b0}};
            rsp_rd_ptr <= {LOG_DEPTH{1'b0}};
            src_to_dst_req <= 1'b0;
            dst_to_src_rsp_sync <= 3'b000;
        end else begin
            case ({src_idle, src_setup, src_access})
                3'b100: begin // Idle
                    if (src_psel_i) begin
                        src_idle <= 1'b0;
                        src_setup <= 1'b1;
                        src_access <= 1'b0;
                        src_pready_o <= 1'b0;
                    end else begin
                        src_pready_o <= 1'b1;
                    end
                end
                3'b010: begin // Setup
                    if (src_penable_i) begin
                        src_setup <= 1'b0;
                        src_access <= 1'b1;
                        // Store request in FIFO
                        req_data_fifo[req_wr_ptr] <= src_pwdata_i;
                        req_addr_fifo[req_wr_ptr] <= src_paddr_i;
                        req_strb_fifo[req_wr_ptr] <= src_pstrb_i;
                        req_prot_fifo[req_wr_ptr] <= src_pprot_i;
                        req_write_fifo[req_wr_ptr] <= src_pwrite_i;
                        req_wr_ptr <= req_wr_ptr + 1'b1;
                        req_valid <= 1'b1;
                        src_to_dst_req <= 1'b1;
                    end
                end
                3'b001: begin // Access
                    if (dst_to_src_rsp_sync[2] && !dst_to_src_rsp_sync[1]) begin
                        // Response received
                        src_access <= 1'b0;
                        src_idle <= 1'b1;
                        src_pready_o <= 1'b1;
                        src_prdata_o <= rsp_data_fifo[rsp_rd_ptr];
                        src_pslverr_o <= rsp_err_fifo[rsp_rd_ptr];
                        rsp_rd_ptr <= rsp_rd_ptr + 1'b1;
                        rsp_valid <= 1'b0;
                    end
                end
                default: begin
                    src_idle <= 1'b1;
                    src_setup <= 1'b0;
                    src_access <= 1'b0;
                    src_pready_o <= 1'b1;
                end
            endcase
        end
    end

    // Synchronize src_to_dst_req to destination clock
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            src_to_dst_req_sync <= 3'b000;
        end else begin
            src_to_dst_req_sync <= {src_to_dst_req_sync[1:0], src_to_dst_req};
        end
    end

    // Synchronize dst_to_src_rsp to source clock
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            dst_to_src_rsp_sync <= 3'b000;
        end else begin
            dst_to_src_rsp_sync <= {dst_to_src_rsp_sync[1:0], dst_to_src_rsp};
        end
    end

    // Destination side logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_idle <= 1'b1;
            dst_setup <= 1'b0;
            dst_access <= 1'b0;
            dst_psel_o <= 1'b0;
            dst_penable_o <= 1'b0;
            dst_pwrite_o <= 1'b0;
            dst_paddr_o <= {ADDR_WIDTH{1'b0}};
            dst_pwdata_o <= {DATA_WIDTH{1'b0}};
            dst_pstrb_o <= {(DATA_WIDTH/8){1'b0}};
            dst_pprot_o <= 3'b000;
            req_rd_ptr <= {LOG_DEPTH{1'b0}};
            rsp_wr_ptr <= {LOG_DEPTH{1'b0}};
            dst_to_src_rsp <= 1'b0;
            src_to_dst_req_sync <= 3'b000;
        end else begin
            case ({dst_idle, dst_setup, dst_access})
                3'b100: begin // Idle
                    if (src_to_dst_req_sync[2] && !src_to_dst_req_sync[1]) begin
                        // New request from source
                        dst_idle <= 1'b0;
                        dst_setup <= 1'b1;
                        dst_access <= 1'b0;
                        dst_psel_o <= 1'b1;
                        dst_penable_o <= 1'b0;
                        dst_pwrite_o <= req_write_fifo[req_rd_ptr];
                        dst_paddr_o <= req_addr_fifo[req_rd_ptr];
                        dst_pwdata_o <= req_data_fifo[req_rd_ptr];
                        dst_pstrb_o <= req_strb_fifo[req_rd_ptr];
                        dst_pprot_o <= req_prot_fifo[req_rd_ptr];
                    end else begin
                        dst_psel_o <= 1'b0;
                    end
                end
                3'b010: begin // Setup
                    if (dst_pready_i) begin
                        dst_setup <= 1'b0;
                        dst_access <= 1'b1;
                        dst_penable_o <= 1'b1;
                    end
                end
                3'b001: begin // Access
                    if (dst_pready_i) begin
                        dst_access <= 1'b0;
                        dst_idle <= 1'b1;
                        dst_psel_o <= 1'b0;
                        dst_penable_o <= 1'b0;
                        // Store response
                        rsp_data_fifo[rsp_wr_ptr] <= dst_prdata_i;
                        rsp_err_fifo[rsp_wr_ptr] <= dst_pslverr_i;
                        rsp_wr_ptr <= rsp_wr_ptr + 1'b1;
                        rsp_valid <= 1'b1;
                        dst_to_src_rsp <= 1'b1;
                        req_rd_ptr <= req_rd_ptr + 1'b1;
                    end
                end
                default: begin
                    dst_idle <= 1'b1;
                    dst_setup <= 1'b0;
                    dst_access <= 1'b0;
                    dst_psel_o <= 1'b0;
                    dst_penable_o <= 1'b0;
                end
            endcase
        end
    end

endmodule
