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

    // FIFO signals
    reg [ADDR_WIDTH-1:0]       fifo_addr;
    reg [DATA_WIDTH-1:0]       fifo_wdata;
    reg [DATA_WIDTH/8-1:0]     fifo_strb;
    reg [2:0]                  fifo_prot;
    reg                        fifo_write;
    reg                        fifo_read;
    reg                        fifo_full;
    reg                        fifo_empty;
    reg [DATA_WIDTH-1:0]       fifo_rdata;

    // Source side signals
    reg                        src_req_valid;
    reg                        src_req_ready;
    reg                        src_req_accepted;
    reg [DATA_WIDTH-1:0]       src_rdata_sync1;
    reg [DATA_WIDTH-1:0]       src_rdata_sync2;
    reg                        src_slverr_sync1;
    reg                        src_slverr_sync2;

    // Destination side signals
    reg                        dst_req_valid;
    reg                        dst_req_ready;
    reg                        dst_req_accepted;

    // FIFO instantiation
    fifo_sync #(
        .DATA_WIDTH (ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 3),
        .LOG_DEPTH  (LOG_DEPTH)
    ) fifo_inst (
        .clk_wr_i   (src_pclk_i),
        .rst_wr_ni  (src_preset_ni),
        .clk_rd_i   (dst_pclk_i),
        .rst_rd_ni  (dst_preset_ni),
        .din_i      ({src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i}),
        .wr_en_i    (fifo_write),
        .rd_en_i    (fifo_read),
        .dout_o     ({fifo_addr, fifo_wdata, fifo_strb, fifo_prot}),
        .full_o     (fifo_full),
        .empty_o    (fifo_empty)
    );

    // Source side logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_req_valid <= 0;
            src_req_accepted <= 0;
            src_rdata_sync1 <= 0;
            src_rdata_sync2 <= 0;
            src_slverr_sync1 <= 0;
            src_slverr_sync2 <= 0;
        end else begin
            if (src_psel_i && src_penable_i && !src_req_valid) begin
                src_req_valid <= 1;
            end else if (src_req_accepted) begin
                src_req_valid <= 0;
            end

            if (src_req_accepted) begin
                src_req_accepted <= 0;
            end

            if (dst_pready_i && dst_req_accepted) begin
                src_rdata_sync1 <= dst_prdata_i;
                src_slverr_sync1 <= dst_pslverr_i;
            end

            src_rdata_sync2 <= src_rdata_sync1;
            src_slverr_sync2 <= src_slverr_sync1;
        end
    end

    assign src_pready_o = !src_req_valid || src_req_accepted;
    assign src_prdata_o = src_rdata_sync2;
    assign src_pslverr_o = src_slverr_sync2;

    // Destination side logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_req_valid <= 0;
            dst_req_accepted <= 0;
        end else begin
            if (!fifo_empty && !dst_req_valid) begin
                dst_req_valid <= 1;
            end else if (dst_pready_i && dst_req_accepted) begin
                dst_req_valid <= 0;
            end

            if (dst_pready_i && dst_req_accepted) begin
                dst_req_accepted <= 0;
            end
        end
    end

    assign dst_psel_o = dst_req_valid;
    assign dst_penable_o = dst_req_valid;
    assign dst_pwrite_o = fifo_prot[0];
    assign dst_paddr_o = fifo_addr;
    assign dst_pwdata_o = fifo_wdata;
    assign dst_pstrb_o = fifo_strb;
    assign dst_pprot_o = fifo_prot;

    // FIFO control
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            fifo_write <= 0;
        end else begin
            fifo_write <= src_psel_i && src_penable_i && !fifo_full;
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            fifo_read <= 0;
        end else begin
            fifo_read <= dst_pready_i && dst_req_valid;
        end
    end

    // Accept request
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_req_accepted <= 0;
        end else begin
            if (src_psel_i && src_penable_i && !fifo_full) begin
                src_req_accepted <= 1;
            end
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_req_accepted <= 0;
        end else begin
            if (dst_pready_i && dst_req_valid) begin
                dst_req_accepted <= 1;
            end
        end
    end

endmodule

// FIFO with synchronization
module fifo_sync #(
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      clk_wr_i,
    input                      rst_wr_ni,
    input                      clk_rd_i,
    input                      rst_rd_ni,
    input  [DATA_WIDTH-1:0]    din_i,
    input                      wr_en_i,
    input                      rd_en_i,
    output [DATA_WIDTH-1:0]    dout_o,
    output                     full_o,
    output                     empty_o
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam ADDR_WIDTH = LOG_DEPTH;

    reg [DATA_WIDTH-1:0]       mem [0:DEPTH-1];
    reg [ADDR_WIDTH:0]         wr_ptr;
    reg [ADDR_WIDTH:0]         rd_ptr;
    reg [ADDR_WIDTH:0]         wr_ptr_gray;
    reg [ADDR_WIDTH:0]         rd_ptr_gray;
    reg [ADDR_WIDTH:0]         wr_ptr_gray_sync1;
    reg [ADDR_WIDTH:0]         wr_ptr_gray_sync2;
    reg [ADDR_WIDTH:0]         rd_ptr_gray_sync1;
    reg [ADDR_WIDTH:0]         rd_ptr_gray_sync2;

    // Write pointer logic
    always @(posedge clk_wr_i or negedge rst_wr_ni) begin
        if (!rst_wr_ni) begin
            wr_ptr <= 0;
        end else if (wr_en_i && !full_o) begin
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read pointer logic
    always @(posedge clk_rd_i or negedge rst_rd_ni) begin
        if (!rst_rd_ni) begin
            rd_ptr <= 0;
        end else if (rd_en_i && !empty_o) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Gray code conversion
    assign wr_ptr_gray = wr_ptr ^ (wr_ptr >> 1);
    assign rd_ptr_gray = rd_ptr ^ (rd_ptr >> 1);

    // Synchronization
    always @(posedge clk_wr_i or negedge rst_wr_ni) begin
        if (!rst_wr_ni) begin
            wr_ptr_gray_sync1 <= 0;
            wr_ptr_gray_sync2 <= 0;
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end

    always @(posedge clk_rd_i or negedge rst_rd_ni) begin
        if (!rst_rd_ni) begin
            rd_ptr_gray_sync1 <= 0;
            rd_ptr_gray_sync2 <= 0;
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end

    // Full and empty flags
    assign full_o = (wr_ptr_gray_sync2 == {~rd_ptr_gray[ADDR_WIDTH], rd_ptr_gray[ADDR_WIDTH-1:0]});
    assign empty_o = (wr_ptr_gray_sync2 == rd_ptr_gray_sync2);

    // Memory write
    always @(posedge clk_wr_i) begin
        if (wr_en_i && !full_o) begin
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= din_i;
        end
    end

    // Memory read
    always @(posedge clk_rd_i) begin
        if (rd_en_i && !empty_o) begin
            dout_o <= mem[rd_ptr[ADDR_WIDTH-1:0]];
        end
    end

endmodule
