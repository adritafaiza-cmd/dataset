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
    reg [DATA_WIDTH-1:0]       src_rdata;
    reg                        src_slverr;

    // Destination side signals
    reg                        dst_req_valid;
    reg                        dst_req_ready;
    reg                        dst_req_accepted;

    // FIFO instantiation
    fifo_sync #(
        .DATA_WIDTH(ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 3),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_inst (
        .clk_wr(src_pclk_i),
        .rst_wr(~src_preset_ni),
        .clk_rd(dst_pclk_i),
        .rst_rd(~dst_preset_ni),
        .din({src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i}),
        .wr_en(fifo_write),
        .rd_en(fifo_read),
        .full(fifo_full),
        .empty(fifo_empty),
        .dout({fifo_addr, fifo_wdata, fifo_strb, fifo_prot})
    );

    // Source side logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_req_valid <= 0;
            src_req_accepted <= 0;
            src_pready_o <= 0;
        end else begin
            if (src_psel_i && src_penable_i && !src_req_valid) begin
                src_req_valid <= 1;
            end else if (src_req_accepted) begin
                src_req_valid <= 0;
                src_req_accepted <= 0;
                src_pready_o <= 0;
            end else if (src_pready_o && dst_pready_i) begin
                src_req_accepted <= 1;
                src_pready_o <= 1;
                src_prdata_o <= src_rdata;
                src_pslverr_o <= src_slverr;
            end
        end
    end

    // FIFO write control
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            fifo_write <= 0;
        end else begin
            fifo_write <= src_req_valid && !fifo_full;
        end
    end

    // Destination side logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_req_valid <= 0;
            dst_req_accepted <= 0;
            dst_psel_o <= 0;
            dst_penable_o <= 0;
        end else begin
            if (dst_req_ready && !fifo_empty) begin
                dst_req_valid <= 1;
                dst_psel_o <= 1;
                dst_penable_o <= 1;
                dst_pwrite_o <= fifo_prot[0];
                dst_paddr_o <= fifo_addr;
                dst_pwdata_o <= fifo_wdata;
                dst_pstrb_o <= fifo_strb;
                dst_pprot_o <= fifo_prot;
            end else if (dst_pready_i) begin
                dst_req_valid <= 0;
                dst_req_accepted <= 1;
                dst_psel_o <= 0;
                dst_penable_o <= 0;
                src_rdata <= dst_prdata_i;
                src_slverr <= dst_pslverr_i;
            end else if (dst_req_accepted) begin
                dst_req_accepted <= 0;
            end
        end
    end

    // FIFO read control
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            fifo_read <= 0;
        end else begin
            fifo_read <= dst_req_ready && !fifo_empty;
        end
    end

    // Destination request ready
    assign dst_req_ready = !dst_req_valid && !fifo_empty;

    // Source request ready
    assign src_req_ready = !src_req_valid && !fifo_full;

endmodule

// FIFO synchronous module
module fifo_sync #(
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      clk_wr,
    input                      rst_wr,
    input                      clk_rd,
    input                      rst_rd,
    input  [DATA_WIDTH-1:0]    din,
    input                      wr_en,
    input                      rd_en,
    output                     full,
    output                     empty,
    output [DATA_WIDTH-1:0]    dout
);

    localparam DEPTH = 1 << LOG_DEPTH;
    reg [DATA_WIDTH-1:0]       mem [0:DEPTH-1];
    reg [$clog2(DEPTH):0]      wr_ptr;
    reg [$clog2(DEPTH):0]      rd_ptr;
    reg [$clog2(DEPTH):0]      wr_ptr_gray;
    reg [$clog2(DEPTH):0]      rd_ptr_gray;
    reg [$clog2(DEPTH):0]      wr_ptr_gray_sync;
    reg [$clog2(DEPTH):0]      rd_ptr_gray_sync;

    // Write pointer logic
    always @(posedge clk_wr or negedge rst_wr) begin
        if (!rst_wr) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr] <= din;
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= wr_ptr ^ (wr_ptr >> 1);
        end
    end

    // Read pointer logic
    always @(posedge clk_rd or negedge rst_rd) begin
        if (!rst_rd) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= rd_ptr ^ (rd_ptr >> 1);
        end
    end

    // Gray code synchronization
    always @(posedge clk_wr or negedge rst_wr) begin
        if (!rst_wr) begin
            rd_ptr_gray_sync <= 0;
        end else begin
            rd_ptr_gray_sync <= rd_ptr_gray;
        end
    end

    always @(posedge clk_rd or negedge rst_rd) begin
        if (!rst_rd) begin
            wr_ptr_gray_sync <= 0;
        end else begin
            wr_ptr_gray_sync <= wr_ptr_gray;
        end
    end

    // Full and empty flags
    assign full = (wr_ptr_gray_sync == {~rd_ptr_gray[LOG_DEPTH], rd_ptr_gray[LOG_DEPTH-1:0]});
    assign empty = (wr_ptr_gray_sync == rd_ptr_gray_sync);

    // Output data
    assign dout = mem[rd_ptr];

endmodule
