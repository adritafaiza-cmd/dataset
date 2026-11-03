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
    reg                        fifo_wren;
    reg                        fifo_rden;
    reg [DATA_WIDTH-1:0]       fifo_rdata;
    reg                        fifo_empty;
    reg                        fifo_full;

    // Source side signals
    reg                        src_req_valid;
    reg                        src_req_ready;
    reg                        src_req_accepted;
    reg                        src_req_done;

    // Destination side signals
    reg                        dst_req_valid;
    reg                        dst_req_ready;
    reg                        dst_req_accepted;
    reg                        dst_req_done;

    // FIFO instantiation
    sync_fifo #(
        .DATA_WIDTH(ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 3),
        .LOG_DEPTH(LOG_DEPTH)
    ) u_sync_fifo (
        .clk_wr(src_pclk_i),
        .rst_wr_n(src_preset_ni),
        .clk_rd(dst_pclk_i),
        .rst_rd_n(dst_preset_ni),
        .din({src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i}),
        .wr_en(fifo_wren),
        .rd_en(fifo_rden),
        .dout({fifo_addr, fifo_wdata, fifo_strb, fifo_prot}),
        .empty(fifo_empty),
        .full(fifo_full)
    );

    // Source side logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_req_valid <= 0;
            src_req_accepted <= 0;
            src_req_done <= 0;
            fifo_wren <= 0;
        end else begin
            if (src_psel_i && src_penable_i && !src_req_valid) begin
                src_req_valid <= 1;
            end

            if (src_req_valid && !fifo_full) begin
                fifo_wren <= 1;
                src_req_accepted <= 1;
            end else begin
                fifo_wren <= 0;
            end

            if (src_req_accepted && dst_req_done) begin
                src_req_valid <= 0;
                src_req_accepted <= 0;
                src_req_done <= 0;
            end

            if (dst_req_done) begin
                src_req_done <= 1;
            end
        end
    end

    assign src_pready_o = !src_req_valid || (src_req_valid && src_req_accepted && dst_req_done);

    // Destination side logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_req_valid <= 0;
            dst_req_accepted <= 0;
            dst_req_done <= 0;
            fifo_rden <= 0;
            dst_psel_o <= 0;
            dst_penable_o <= 0;
            dst_pwrite_o <= 0;
            dst_paddr_o <= 0;
            dst_pwdata_o <= 0;
            dst_pstrb_o <= 0;
            dst_pprot_o <= 0;
        end else begin
            if (!fifo_empty && !dst_req_valid) begin
                fifo_rden <= 1;
                dst_req_valid <= 1;
            end else begin
                fifo_rden <= 0;
            end

            if (dst_req_valid && !dst_req_accepted) begin
                dst_psel_o <= 1;
                dst_penable_o <= 1;
                dst_pwrite_o <= fifo_prot[0];
                dst_paddr_o <= fifo_addr;
                dst_pwdata_o <= fifo_wdata;
                dst_pstrb_o <= fifo_strb;
                dst_pprot_o <= fifo_prot;
                dst_req_accepted <= 1;
            end

            if (dst_req_accepted && dst_pready_i) begin
                dst_psel_o <= 0;
                dst_penable_o <= 0;
                dst_req_valid <= 0;
                dst_req_accepted <= 0;
                dst_req_done <= 1;
            end

            if (dst_req_done) begin
                dst_req_done <= 0;
            end
        end
    end

    // Data and error return path
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_prdata_o <= 0;
            src_pslverr_o <= 0;
        end else begin
            if (dst_req_done) begin
                src_prdata_o <= dst_prdata_i;
                src_pslverr_o <= dst_pslverr_i;
            end
        end
    end

endmodule

// Synchronous FIFO module
module sync_fifo #(
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      clk_wr,
    input                      rst_wr_n,
    input                      clk_rd,
    input                      rst_rd_n,
    input  [DATA_WIDTH-1:0]    din,
    input                      wr_en,
    input                      rd_en,
    output [DATA_WIDTH-1:0]    dout,
    output                     empty,
    output                     full
);

    localparam DEPTH = 1 << LOG_DEPTH;
    reg [DATA_WIDTH-1:0]       mem [0:DEPTH-1];
    reg [$clog2(DEPTH):0]      wr_ptr, rd_ptr;
    reg [$clog2(DEPTH):0]      wr_ptr_gray, rd_ptr_gray;
    reg [$clog2(DEPTH):0]      wr_ptr_gray_sync, rd_ptr_gray_sync;

    // Write pointer logic
    always @(posedge clk_wr or negedge rst_wr_n) begin
        if (!rst_wr_n) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read pointer logic
    always @(posedge clk_rd or negedge rst_rd_n) begin
        if (!rst_rd_n) begin
            rd_ptr <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Gray code conversion
    assign wr_ptr_gray = wr_ptr ^ (wr_ptr >> 1);
    assign rd_ptr_gray = rd_ptr ^ (rd_ptr >> 1);

    // Gray code synchronization
    always @(posedge clk_wr or negedge rst_wr_n) begin
        if (!rst_wr_n) begin
            rd_ptr_gray_sync <= 0;
        end else begin
            rd_ptr_gray_sync <= rd_ptr_gray;
        end
    end

    always @(posedge clk_rd or negedge rst_rd_n) begin
        if (!rst_rd_n) begin
            wr_ptr_gray_sync <= 0;
        end else begin
            wr_ptr_gray_sync <= wr_ptr_gray;
        end
    end

    // FIFO memory write
    always @(posedge clk_wr) begin
        if (wr_en && !full) begin
            mem[wr_ptr[LOG_DEPTH-1:0]] <= din;
        end
    end

    // FIFO memory read
    always @(posedge clk_rd) begin
        dout <= mem[rd_ptr[LOG_DEPTH-1:0]];
    end

    // FIFO status
    assign full = (wr_ptr_gray_sync[LOG_DEPTH] != rd_ptr_gray_sync[LOG_DEPTH]) && (wr_ptr_gray_sync[LOG_DEPTH-1:0] == rd_ptr_gray_sync[LOG_DEPTH-1:0]);
    assign empty = (wr_ptr_gray_sync == rd_ptr_gray_sync);

endmodule
