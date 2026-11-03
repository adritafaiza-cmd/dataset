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
    reg                        src_req_done;

    // Destination side signals
    reg                        dst_req_valid;
    reg                        dst_req_ready;
    reg                        dst_req_accepted;
    reg                        dst_req_done;

    // FIFO instantiation
    fifo_sync #(
        .DATA_WIDTH (ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 3),
        .LOG_DEPTH  (LOG_DEPTH)
    ) fifo_inst (
        .src_clk_i  (src_pclk_i),
        .src_rst_ni (src_preset_ni),
        .src_wr_i   (fifo_write),
        .src_data_i ({src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i}),
        .src_full_o (fifo_full),
        .dst_clk_i  (dst_pclk_i),
        .dst_rst_ni (dst_preset_ni),
        .dst_rd_i   (fifo_read),
        .dst_data_o ({fifo_addr, fifo_wdata, fifo_strb, fifo_prot}),
        .dst_empty_o(fifo_empty)
    );

    // Source side logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_req_valid <= 0;
            src_req_accepted <= 0;
            src_req_done <= 0;
            fifo_write <= 0;
        end else begin
            if (src_psel_i && src_penable_i && !src_req_valid) begin
                src_req_valid <= 1;
            end

            if (src_req_valid && !fifo_full) begin
                fifo_write <= 1;
                src_req_accepted <= 1;
            end else begin
                fifo_write <= 0;
            end

            if (src_req_accepted && fifo_full) begin
                src_req_valid <= 0;
            end

            if (src_req_accepted && dst_req_done) begin
                src_req_accepted <= 0;
                src_req_done <= 1;
            end

            if (src_req_done && src_pready_o) begin
                src_req_done <= 0;
            end
        end
    end

    // Source side ready signal
    assign src_pready_o = src_req_done;

    // Source side data output
    assign src_prdata_o = fifo_rdata;
    assign src_pslverr_o = dst_pslverr_i;

    // Destination side logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_req_valid <= 0;
            dst_req_accepted <= 0;
            dst_req_done <= 0;
            fifo_read <= 0;
        end else begin
            if (!fifo_empty && !dst_req_valid) begin
                fifo_read <= 1;
                dst_req_valid <= 1;
            end else begin
                fifo_read <= 0;
            end

            if (dst_req_valid && dst_pready_i) begin
                dst_req_accepted <= 1;
            end

            if (dst_req_accepted && dst_pready_i) begin
                dst_req_valid <= 0;
                dst_req_accepted <= 0;
                dst_req_done <= 1;
            end

            if (dst_req_done) begin
                dst_req_done <= 0;
            end
        end
    end

    // Destination side control signals
    assign dst_psel_o = dst_req_valid;
    assign dst_penable_o = dst_req_valid;
    assign dst_pwrite_o = fifo_prot[0];
    assign dst_paddr_o = fifo_addr;
    assign dst_pwdata_o = fifo_wdata;
    assign dst_pstrb_o = fifo_strb;
    assign dst_pprot_o = fifo_prot;

endmodule

// FIFO synchronous module
module fifo_sync #(
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      src_clk_i,
    input                      src_rst_ni,
    input                      src_wr_i,
    input  [DATA_WIDTH-1:0]    src_data_i,
    output                     src_full_o,
    input                      dst_clk_i,
    input                      dst_rst_ni,
    input                      dst_rd_i,
    output [DATA_WIDTH-1:0]    dst_data_o,
    output                     dst_empty_o
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam ADDR_WIDTH = LOG_DEPTH;

    reg [DATA_WIDTH-1:0]       mem [0:DEPTH-1];
    reg [ADDR_WIDTH:0]         src_wr_ptr;
    reg [ADDR_WIDTH:0]         dst_rd_ptr;
    reg [ADDR_WIDTH:0]         src_wr_ptr_gray;
    reg [ADDR_WIDTH:0]         dst_rd_ptr_gray;
    reg [ADDR_WIDTH:0]         dst_rd_ptr_gray_sync;

    // Gray code conversion
    function [ADDR_WIDTH:0] bin_to_gray;
        input [ADDR_WIDTH:0] bin;
        bin_to_gray = bin ^ (bin >> 1);
    endfunction

    // Source side write logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= 0;
            src_wr_ptr_gray <= 0;
        end else if (src_wr_i && !src_full_o) begin
            mem[src_wr_ptr[ADDR_WIDTH-1:0]] <= src_data_i;
            src_wr_ptr <= src_wr_ptr + 1;
            src_wr_ptr_gray <= bin_to_gray(src_wr_ptr + 1);
        end
    end

    // Destination side read logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= 0;
            dst_rd_ptr_gray <= 0;
            dst_rd_ptr_gray_sync <= 0;
        end else begin
            if (dst_rd_i && !dst_empty_o) begin
                dst_rd_ptr <= dst_rd_ptr + 1;
                dst_rd_ptr_gray <= bin_to_gray(dst_rd_ptr + 1);
            end
            dst_rd_ptr_gray_sync <= dst_rd_ptr_gray;
        end
    end

    // Full and empty flags
    assign src_full_o = (src_wr_ptr_gray[ADDR_WIDTH:ADDR_WIDTH-1] != dst_rd_ptr_gray_sync[ADDR_WIDTH:ADDR_WIDTH-1]) &&
                        (src_wr_ptr_gray[ADDR_WIDTH-2:0] == {~dst_rd_ptr_gray_sync[ADDR_WIDTH-2:0]});
    assign dst_empty_o = (src_wr_ptr_gray_sync[ADDR_WIDTH:ADDR_WIDTH-1] != dst_rd_ptr_gray[ADDR_WIDTH:ADDR_WIDTH-1]) &&
                         (src_wr_ptr_gray_sync[ADDR_WIDTH-2:0] == {~dst_rd_ptr_gray[ADDR_WIDTH-2:0]});

    // Data output
    assign dst_data_o = mem[dst_rd_ptr[ADDR_WIDTH-1:0]];

endmodule
