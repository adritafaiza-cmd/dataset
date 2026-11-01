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
    reg [DATA_WIDTH-1:0] req_fifo [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] req_addr_fifo [0:DEPTH-1];
    reg [DATA_WIDTH/8-1:0] req_strb_fifo [0:DEPTH-1];
    reg [2:0] req_prot_fifo [0:DEPTH-1];
    reg req_write_fifo [0:DEPTH-1];

    reg [PTR_W-1:0] req_wr_ptr;
    reg [PTR_W-1:0] req_rd_ptr;
    reg [PTR_W-1:0] req_rd_ptr_sync1;
    reg [PTR_W-1:0] req_rd_ptr_sync2;

    // Response FIFO (dst -> src)
    reg [DATA_WIDTH-1:0] rsp_data_fifo [0:DEPTH-1];
    reg rsp_err_fifo [0:DEPTH-1];

    reg [PTR_W-1:0] rsp_wr_ptr;
    reg [PTR_W-1:0] rsp_rd_ptr;
    reg [PTR_W-1:0] rsp_rd_ptr_sync1;
    reg [PTR_W-1:0] rsp_rd_ptr_sync2;

    // Source side state
    reg src_busy;
    reg [DATA_WIDTH-1:0] src_rdata_reg;
    reg src_rerr_reg;

    // Destination side state
    reg dst_busy;
    reg dst_penable_reg;

    // Request FIFO full/empty
    wire req_full = (req_wr_ptr == req_rd_ptr_sync2) && (req_wr_ptr[PTR_W-1] != req_rd_ptr_sync2[PTR_W-1]);
    wire req_empty = (req_wr_ptr == req_rd_ptr_sync2);

    // Response FIFO full/empty
    wire rsp_full = (rsp_wr_ptr == rsp_rd_ptr_sync2) && (rsp_wr_ptr[PTR_W-1] != rsp_rd_ptr_sync2[PTR_W-1]);
    wire rsp_empty = (rsp_wr_ptr == rsp_rd_ptr_sync2);

    // Source side logic
    wire src_setup_phase = src_psel_i && !src_penable_i;
    wire src_access_phase = src_psel_i && src_penable_i;

    // Write to request FIFO during setup phase if not busy and FIFO not full
    wire req_wr_en = src_setup_phase && !src_busy && !req_full;

    // Read from response FIFO when busy and FIFO not empty
    wire rsp_rd_en = src_busy && !rsp_empty;

    // Source pready: high when not busy, or when busy and response available
    assign src_pready_o = !src_busy || rsp_rd_en;

    // Source response outputs
    assign src_prdata_o = src_rdata_reg;
    assign src_pslverr_o = src_rerr_reg;

    // Destination side logic
    // dst_psel is high when there is a request in the FIFO and we are not in the middle of an access
    // Actually, dst_psel should be high when we have a valid request to send
    // dst_penable is high during the access phase

    // We can start a new access when dst is not busy and request FIFO is not empty
    wire dst_start = !dst_busy && !req_empty;

    // dst_psel is high when we have started an access (dst_busy) or are about to start
    // In APB, PSEL is asserted in setup phase, PENABLE in access phase
    // We need to hold PSEL high for at least 2 cycles: setup and access
    // Let's use a state machine for the destination side

    // dst_psel_o: high when we have a request to process
    // dst_penable_o: high during the access phase (second cycle of the transfer)

    // When dst_start is true, we read from the request FIFO and present the data
    // dst_psel_o should be high for the setup phase
    // dst_penable_o should be high for the access phase

    // Let's define:
    // - When dst_start is true, we are in setup phase: dst_psel_o=1, dst_penable_o=0
    // - Next cycle, we are in access phase: dst_psel_o=1, dst_penable_o=1
    // - When dst_pready_i is high during access phase, the transfer completes

    // We need to track whether we are in setup or access phase
    // dst_busy indicates we are in the middle of a transfer
    // dst_penable_reg indicates we are in the access phase

    assign dst_psel_o = dst_busy;
    assign dst_penable_o = dst_penable_reg;

    // Destination outputs from FIFO
    assign dst_pwrite_o = req_write_fifo[req_rd_ptr];
    assign dst_paddr_o = req_addr_fifo[req_rd_ptr];
    assign dst_pwdata_o = req_fifo[req_rd_ptr];
    assign dst_pstrb_o = req_strb_fifo[req_rd_ptr];
    assign dst_pprot_o = req_prot_fifo[req_rd_ptr];

    // Destination side: write to response FIFO when access completes
    wire rsp_wr_en = dst_busy && dst_penable_reg && dst_pready_i;

    // Source side: write to request FIFO
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            req_wr_ptr <= {PTR_W{1'b0}};
            src_busy <= 1'b0;
            src_rdata_reg <= {DATA_WIDTH{1'b0}};
            src_rerr_reg <= 1'b0;
        end else begin
            if (req_wr_en) begin
                req_fifo[req_wr_ptr] <= src_pwdata_i;
                req_addr_fifo[req_wr_ptr] <= src_paddr_i;
                req_strb_fifo[req_wr_ptr] <= src_pstrb_i;
                req_prot_fifo[req_wr_ptr] <= src_pprot_i;
                req_write_fifo[req_wr_ptr] <= src_pwrite_i;
                req_wr_ptr <= req_wr_ptr + 1'b1;
                src_busy <= 1'b1;
            end
            if (rsp_rd_en) begin
                src_rdata_reg <= rsp_data_fifo[rsp_rd_ptr];
                src_rerr_reg <= rsp_err_fifo[rsp_rd_ptr];
                rsp_rd_ptr <= rsp_rd_ptr + 1'b1;
                src_busy <= 1'b0;
            end
        end
    end

    // Destination side: read from request FIFO and write to response FIFO
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            req_rd_ptr <= {PTR_W{1'b0}};
            rsp_wr_ptr <= {PTR_W{1'b0}};
            dst_busy <= 1'b0;
            dst_penable_reg <= 1'b0;
        end else begin
            if (dst_start) begin
                dst_busy <= 1'b1;
                dst_penable_reg <= 1'b0;
            end else if (dst_busy && !dst_penable_reg) begin
                dst_penable_reg <= 1'b1;
            end else if (rsp_wr_en) begin
                rsp_data_fifo[rsp_wr_ptr] <= dst_prdata_i;
                rsp_err_fifo[rsp_wr_ptr] <= dst_pslverr_i;
                rsp_wr_ptr <= rsp_wr_ptr + 1'b1;
                req_rd_ptr <= req_rd_ptr + 1'b1;
                dst_busy <= 1'b0;
                dst_penable_reg <= 1'b0;
            end
        end
    end

    // Synchronize request FIFO read pointer to source clock domain
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            req_rd_ptr_sync1 <= {PTR_W{1'b0}};
            req_rd_ptr_sync2 <= {PTR_W{1'b0}};
        end else begin
            req_rd_ptr_sync1 <= req_rd_ptr;
            req_rd_ptr_sync2 <= req_rd_ptr_sync1;
        end
    end

    // Synchronize response FIFO read pointer to destination clock domain
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            rsp_rd_ptr_sync1 <= {PTR_W{1'b0}};
            rsp_rd_ptr_sync2 <= {PTR_W{1'b0}};
        end else begin
            rsp_rd_ptr_sync1 <= rsp_rd_ptr;
            rsp_rd_ptr_sync2 <= rsp_rd_ptr_sync1;
        end
    end

endmodule
