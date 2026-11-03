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

    localparam STRB_WIDTH = DATA_WIDTH/8;
    localparam FIFO_DEPTH = 1 << LOG_DEPTH;
    localparam FIFO_ADDR_WIDTH = LOG_DEPTH;

    // Source-side state
    reg src_idle;
    reg src_setup;
    reg src_access;

    // Destination-side state
    reg dst_idle;
    reg dst_setup;
    reg dst_access;

    // FIFO control signals
    reg src_wr_en;
    reg dst_rd_en;
    reg [FIFO_ADDR_WIDTH-1:0] src_wr_ptr;
    reg [FIFO_ADDR_WIDTH-1:0] dst_rd_ptr;
    reg [FIFO_ADDR_WIDTH-1:0] dst_rd_ptr_src;
    reg [FIFO_ADDR_WIDTH-1:0] src_wr_ptr_dst;

    // FIFO data
    reg [DATA_WIDTH-1:0] fifo_data [0:FIFO_DEPTH-1];
    reg [ADDR_WIDTH-1:0] fifo_addr [0:FIFO_DEPTH-1];
    reg [STRB_WIDTH-1:0] fifo_strb [0:FIFO_DEPTH-1];
    reg [2:0] fifo_prot [0:FIFO_DEPTH-1];
    reg fifo_write [0:FIFO_DEPTH-1];

    // Destination output registers
    reg dst_psel_r;
    reg dst_penable_r;
    reg dst_pwrite_r;
    reg [ADDR_WIDTH-1:0] dst_paddr_r;
    reg [DATA_WIDTH-1:0] dst_pwdata_r;
    reg [STRB_WIDTH-1:0] dst_pstrb_r;
    reg [2:0] dst_pprot_r;

    // Source output registers
    reg src_pready_r;
    reg [DATA_WIDTH-1:0] src_prdata_r;
    reg src_pslverr_r;

    // CDC synchronizers
    reg [1:0] dst_rd_ptr_sync;
    reg [1:0] src_wr_ptr_sync;
    reg [1:0] dst_done_sync;
    reg [1:0] src_req_sync;

    // Internal signals
    wire dst_rd_ptr_sync_q;
    wire src_wr_ptr_sync_q;
    wire dst_done_sync_q;
    wire src_req_sync_q;

    // FIFO full/empty
    wire fifo_full;
    wire fifo_empty;

    assign fifo_full = (src_wr_ptr == dst_rd_ptr_src) && (src_wr_ptr[FIFO_ADDR_WIDTH-1] != dst_rd_ptr_src[FIFO_ADDR_WIDTH-1]);
    assign fifo_empty = (dst_rd_ptr == src_wr_ptr_dst);

    // Source clock domain
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_idle <= 1'b1;
            src_setup <= 1'b0;
            src_access <= 1'b0;
            src_wr_en <= 1'b0;
            src_wr_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
            src_pready_r <= 1'b0;
            src_prdata_r <= {DATA_WIDTH{1'b0}};
            src_pslverr_r <= 1'b0;
        end else begin
            src_wr_en <= 1'b0;

            case ({src_idle, src_setup, src_access})
                3'b100: begin // IDLE
                    if (src_psel_i && !fifo_full) begin
                        src_idle <= 1'b0;
                        src_setup <= 1'b1;
                        src_wr_en <= 1'b1;
                        src_wr_ptr <= src_wr_ptr + 1'b1;
                    end
                end
                3'b010: begin // SETUP
                    src_setup <= 1'b0;
                    src_access <= 1'b1;
                end
                3'b001: begin // ACCESS
                    if (dst_done_sync_q[1]) begin
                        src_access <= 1'b0;
                        src_idle <= 1'b1;
                        src_pready_r <= 1'b1;
                    end
                end
                default: begin
                    src_idle <= 1'b1;
                    src_setup <= 1'b0;
                    src_access <= 1'b0;
                end
            endcase

            // Update src_pready_r
            if (src_idle) begin
                src_pready_r <= 1'b1;
            end else if (src_access && dst_done_sync_q[1]) begin
                src_pready_r <= 1'b1;
            end else begin
                src_pready_r <= 1'b0;
            end

            // Capture read data and error when done
            if (src_access && dst_done_sync_q[1]) begin
                src_prdata_r <= dst_prdata_i;
                src_pslverr_r <= dst_pslverr_i;
            end
        end
    end

    // Write to FIFO in source clock domain
    always @(posedge src_pclk_i) begin
        if (src_wr_en) begin
            fifo_data[src_wr_ptr] <= src_pwdata_i;
            fifo_addr[src_wr_ptr] <= src_paddr_i;
            fifo_strb[src_wr_ptr] <= src_pstrb_i;
            fifo_prot[src_wr_ptr] <= src_pprot_i;
            fifo_write[src_wr_ptr] <= src_pwrite_i;
        end
    end

    // Synchronize src_wr_ptr to destination clock domain
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            src_wr_ptr_sync <= 2'b00;
        end else begin
            src_wr_ptr_sync <= {src_wr_ptr_sync[0], src_wr_ptr[FIFO_ADDR_WIDTH-1]};
        end
    end

    assign src_wr_ptr_sync_q = src_wr_ptr_sync[1];

    // Synchronize dst_rd_ptr to source clock domain
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            dst_rd_ptr_sync <= 2'b00;
        end else begin
            dst_rd_ptr_sync <= {dst_rd_ptr_sync[0], dst_rd_ptr[FIFO_ADDR_WIDTH-1]};
        end
    end

    assign dst_rd_ptr_sync_q = dst_rd_ptr_sync[1];

    // Synchronize dst_done to source clock domain
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            dst_done_sync <= 2'b00;
        end else begin
            dst_done_sync <= {dst_done_sync[0], dst_pready_i && dst_penable_i};
        end
    end

    assign dst_done_sync_q = dst_done_sync[1];

    // Synchronize src_req to destination clock domain
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            src_req_sync <= 2'b00;
        end else begin
            src_req_sync <= {src_req_sync[0], src_psel_i && src_pready_o};
        end
    end

    assign src_req_sync_q = src_req_sync[1];

    // Destination clock domain
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_idle <= 1'b1;
            dst_setup <= 1'b0;
            dst_access <= 1'b0;
            dst_rd_en <= 1'b0;
            dst_rd_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
            dst_psel_r <= 1'b0;
            dst_penable_r <= 1'b0;
            dst_pwrite_r <= 1'b0;
            dst_paddr_r <= {ADDR_WIDTH{1'b0}};
            dst_pwdata_r <= {DATA_WIDTH{1'b0}};
            dst_pstrb_r <= {STRB_WIDTH{1'b0}};
            dst_pprot_r <= 3'b000;
        end else begin
            dst_rd_en <= 1'b0;

            case ({dst_idle, dst_setup, dst_access})
                3'b100: begin // IDLE
                    if (!fifo_empty) begin
                        dst_idle <= 1'b0;
                        dst_setup <= 1'b1;
                        dst_rd_en <= 1'b1;
                        dst_rd_ptr <= dst_rd_ptr + 1'b1;
                        dst_psel_r <= 1'b1;
                        dst_penable_r <= 1'b0;
                        dst_pwrite_r <= fifo_write[dst_rd_ptr];
                        dst_paddr_r <= fifo_addr[dst_rd_ptr];
                        dst_pwdata_r <= fifo_data[dst_rd_ptr];
                        dst_pstrb_r <= fifo_strb[dst_rd_ptr];
                        dst_pprot_r <= fifo_prot[dst_rd_ptr];
                    end
                end
                3'b010: begin // SETUP
                    dst_setup <= 1'b0;
                    dst_access <= 1'b1;
                    dst_penable_r <= 1'b1;
                end
                3'b001: begin // ACCESS
                    if (dst_pready_i) begin
                        dst_access <= 1'b0;
                        dst_idle <= 1'b1;
                        dst_psel_r <= 1'b0;
                        dst_penable_r <= 1'b0;
                    end
                end
                default: begin
                    dst_idle <= 1'b1;
                    dst_setup <= 1'b0;
                    dst_access <= 1'b0;
                    dst_psel_r <= 1'b0;
                    dst_penable_r <= 1'b0;
                end
            endcase
        end
    end

    // Update dst_rd_ptr_src in source clock domain
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            dst_rd_ptr_src <= {FIFO_ADDR_WIDTH{1'b0}};
        end else begin
            dst_rd_ptr_src <= dst_rd_ptr_sync_q;
        end
    end

    // Update src_wr_ptr_dst in destination clock domain
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            src_wr_ptr_dst <= {FIFO_ADDR_WIDTH{1'b0}};
        end else begin
            src_wr_ptr_dst <= src_wr_ptr_sync_q;
        end
    end

    // Output assignments
    assign src_pready_o = src_pready_r;
    assign src_prdata_o = src_prdata_r;
    assign src_pslverr_o = src_pslverr_r;
    assign dst_psel_o = dst_psel_r;
    assign dst_penable_o = dst_penable_r;
    assign dst_pwrite_o = dst_pwrite_r;
    assign dst_paddr_o = dst_paddr_r;
    assign dst_pwdata_o = dst_pwdata_r;
    assign dst_pstrb_o = dst_pstrb_r;
    assign dst_pprot_o = dst_pprot_r;

endmodule
