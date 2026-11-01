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
    reg req_wr_en;
    reg req_rd_en;

    // Response FIFO (dst -> src)
    reg [DATA_WIDTH-1:0] rsp_fifo [0:DEPTH-1];
    reg rsp_err_fifo [0:DEPTH-1];
    reg [PTR_W-1:0] rsp_wr_ptr;
    reg [PTR_W-1:0] rsp_rd_ptr;
    reg rsp_wr_en;
    reg rsp_rd_en;

    // Synchronizers
    reg [PTR_W:0] req_wr_ptr_sync1, req_wr_ptr_sync2;
    reg [PTR_W:0] req_rd_ptr_sync1, req_rd_ptr_sync2;
    reg [PTR_W:0] rsp_wr_ptr_sync1, rsp_wr_ptr_sync2;
    reg [PTR_W:0] rsp_rd_ptr_sync1, rsp_rd_ptr_sync2;

    // Extended pointers for full/empty detection
    wire [PTR_W:0] req_wr_ptr_ext = {req_wr_ptr, 1'b0};
    wire [PTR_W:0] req_rd_ptr_ext = {req_rd_ptr, 1'b0};
    wire [PTR_W:0] rsp_wr_ptr_ext = {rsp_wr_ptr, 1'b0};
    wire [PTR_W:0] rsp_rd_ptr_ext = {rsp_rd_ptr, 1'b0};

    // Full/Empty signals
    wire req_full = (req_wr_ptr_ext == req_rd_ptr_sync2) && (req_wr_ptr_ext[PTR_W] != req_rd_ptr_sync2[PTR_W]);
    wire req_empty = (req_wr_ptr_sync2 == req_rd_ptr_ext);
    wire rsp_full = (rsp_wr_ptr_ext == rsp_rd_ptr_sync2) && (rsp_wr_ptr_ext[PTR_W] != rsp_rd_ptr_sync2[PTR_W]);
    wire rsp_empty = (rsp_wr_ptr_sync2 == rsp_rd_ptr_ext);

    // Source side state
    reg src_busy;
    reg src_pready_r;
    reg [DATA_WIDTH-1:0] src_prdata_r;
    reg src_pslverr_r;

    // Destination side state
    reg dst_psel_r;
    reg dst_penable_r;
    reg dst_pwrite_r;
    reg [ADDR_WIDTH-1:0] dst_paddr_r;
    reg [DATA_WIDTH-1:0] dst_pwdata_r;
    reg [DATA_WIDTH/8-1:0] dst_pstrb_r;
    reg [2:0] dst_pprot_r;

    // Source clock domain logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            req_wr_ptr <= {PTR_W{1'b0}};
            rsp_rd_ptr <= {PTR_W{1'b0}};
            src_busy <= 1'b0;
            src_pready_r <= 1'b1;
            src_prdata_r <= {DATA_WIDTH{1'b0}};
            src_pslverr_r <= 1'b0;
            req_wr_en <= 1'b0;
            rsp_rd_en <= 1'b0;
        end else begin
            req_wr_en <= 1'b0;
            rsp_rd_en <= 1'b0;

            if (src_psel_i && src_penable_i && src_pready_r) begin
                // Complete the current transaction
                src_busy <= 1'b0;
                src_pready_r <= 1'b1;
            end else if (src_psel_i && !src_penable_i && !src_busy && !req_full) begin
                // Start a new transaction
                src_busy <= 1'b1;
                src_pready_r <= 1'b0;
                req_wr_en <= 1'b1;
                req_fifo[req_wr_ptr] <= src_pwdata_i;
                req_addr_fifo[req_wr_ptr] <= src_paddr_i;
                req_strb_fifo[req_wr_ptr] <= src_pstrb_i;
                req_prot_fifo[req_wr_ptr] <= src_pprot_i;
                req_write_fifo[req_wr_ptr] <= src_pwrite_i;
                req_wr_ptr <= req_wr_ptr + 1'b1;
            end else if (src_busy && !rsp_empty) begin
                // Response available
                rsp_rd_en <= 1'b1;
                src_prdata_r <= rsp_fifo[rsp_rd_ptr];
                src_pslverr_r <= rsp_err_fifo[rsp_rd_ptr];
                rsp_rd_ptr <= rsp_rd_ptr + 1'b1;
            end
        end
    end

    // Destination clock domain logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            req_rd_ptr <= {PTR_W{1'b0}};
            rsp_wr_ptr <= {PTR_W{1'b0}};
            dst_psel_r <= 1'b0;
            dst_penable_r <= 1'b0;
            dst_pwrite_r <= 1'b0;
            dst_paddr_r <= {ADDR_WIDTH{1'b0}};
            dst_pwdata_r <= {DATA_WIDTH{1'b0}};
            dst_pstrb_r <= {DATA_WIDTH/8{1'b0}};
            dst_pprot_r <= 3'b0;
            req_rd_en <= 1'b0;
            rsp_wr_en <= 1'b0;
        end else begin
            req_rd_en <= 1'b0;
            rsp_wr_en <= 1'b0;

            if (!dst_psel_r && !req_empty) begin
                // Start a new APB transaction on the destination side
                req_rd_en <= 1'b1;
                dst_psel_r <= 1'b1;
                dst_penable_r <= 1'b0;
                dst_pwrite_r <= req_write_fifo[req_rd_ptr];
                dst_paddr_r <= req_addr_fifo[req_rd_ptr];
                dst_pwdata_r <= req_fifo[req_rd_ptr];
                dst_pstrb_r <= req_strb_fifo[req_rd_ptr];
                dst_pprot_r <= req_prot_fifo[req_rd_ptr];
                req_rd_ptr <= req_rd_ptr + 1'b1;
            end else if (dst_psel_r && !dst_penable_r) begin
                // Setup phase to access phase
                dst_penable_r <= 1'b1;
            end else if (dst_psel_r && dst_penable_r && dst_pready_i) begin
                // Complete the transaction
                dst_psel_r <= 1'b0;
                dst_penable_r <= 1'b0;
                rsp_wr_en <= 1'b1;
                rsp_fifo[rsp_wr_ptr] <= dst_prdata_i;
                rsp_err_fifo[rsp_wr_ptr] <= dst_pslverr_i;
                rsp_wr_ptr <= rsp_wr_ptr + 1'b1;
            end
        end
    end

    // Synchronizers
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            req_wr_ptr_sync1 <= {PTR_W+1{1'b0}};
            req_wr_ptr_sync2 <= {PTR_W+1{1'b0}};
        end else begin
            req_wr_ptr_sync1 <= req_wr_ptr_ext;
            req_wr_ptr_sync2 <= req_wr_ptr_sync1;
        end
    end

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            req_rd_ptr_sync1 <= {PTR_W+1{1'b0}};
            req_rd_ptr_sync2 <= {PTR_W+1{1'b0}};
        end else begin
            req_rd_ptr_sync1 <= req_rd_ptr_ext;
            req_rd_ptr_sync2 <= req_rd_ptr_sync1;
        end
    end

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            rsp_wr_ptr_sync1 <= {PTR_W+1{1'b0}};
            rsp_wr_ptr_sync2 <= {PTR_W+1{1'b0}};
        end else begin
            rsp_wr_ptr_sync1 <= rsp_wr_ptr_ext;
            rsp_wr_ptr_sync2 <= rsp_wr_ptr_sync1;
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            rsp_rd_ptr_sync1 <= {PTR_W+1{1'b0}};
            rsp_rd_ptr_sync2 <= {PTR_W+1{1'b0}};
        end else begin
            rsp_rd_ptr_sync1 <= rsp_rd_ptr_ext;
            rsp_rd_ptr_sync2 <= rsp_rd_ptr_sync1;
        end
    end

    // Outputs
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
