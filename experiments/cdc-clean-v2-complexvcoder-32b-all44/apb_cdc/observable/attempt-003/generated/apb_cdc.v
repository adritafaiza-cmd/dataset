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

    localparam TOTAL_DATA_WIDTH = DATA_WIDTH + 1 + 3;

    sync_fifo #(
        .DATA_WIDTH(TOTAL_DATA_WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) req_fifo (
        .src_clk(src_pclk_i),
        .src_rst_n(src_preset_ni),
        .src_valid(src_psel_i),
        .src_data({src_penable_i, src_pwrite_i, src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i}),
        .src_ready(),
        .dst_clk(dst_pclk_i),
        .dst_rst_n(dst_preset_ni),
        .dst_valid(dst_psel_o),
        .dst_data({dst_penable_o, dst_pwrite_o, dst_paddr_o, dst_pwdata_o, dst_pstrb_o, dst_pprot_o}),
        .dst_ready(dst_pready_i)
    );

    sync_fifo #(
        .DATA_WIDTH(DATA_WIDTH + 1),
        .LOG_DEPTH(LOG_DEPTH)
    ) resp_fifo (
        .src_clk(dst_pclk_i),
        .src_rst_n(dst_preset_ni),
        .src_valid(dst_pready_i),
        .src_data({dst_prdata_i, dst_pslverr_i}),
        .src_ready(),
        .dst_clk(src_pclk_i),
        .dst_rst_n(src_preset_ni),
        .dst_valid(src_pready_o),
        .dst_data({src_prdata_o, src_pslverr_o}),
        .dst_ready(src_pready_o)
    );

endmodule

module sync_fifo #(
    parameter DATA_WIDTH = 36,
    parameter LOG_DEPTH = 1
)(
    input                      src_clk,
    input                      src_rst_n,
    input                      src_valid,
    input  [DATA_WIDTH-1:0]    src_data,
    output                     src_ready,
    input                      dst_clk,
    input                      dst_rst_n,
    output                     dst_valid,
    output [DATA_WIDTH-1:0]    dst_data,
    input                      dst_ready
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam ADDR_WIDTH = LOG_DEPTH;

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] src_wr_ptr, src_wr_ptr_next;
    reg [ADDR_WIDTH-1:0] dst_rd_ptr, dst_rd_ptr_next;
    reg [ADDR_WIDTH:0] src_count, src_count_next;
    reg [ADDR_WIDTH:0] dst_count, dst_count_next;

    assign src_ready = (src_count < DEPTH);
    assign dst_valid = (dst_count > 0);
    assign dst_data = mem[dst_rd_ptr];

    always @(posedge src_clk or negedge src_rst_n) begin
        if (!src_rst_n) begin
            src_wr_ptr <= 0;
            src_count <= 0;
        end else begin
            src_wr_ptr <= src_wr_ptr_next;
            src_count <= src_count_next;
            if (src_valid && src_ready) begin
                mem[src_wr_ptr] <= src_data;
            end
        end
    end

    always @(*) begin
        src_wr_ptr_next = src_wr_ptr;
        src_count_next = src_count;
        if (src_valid && src_ready) begin
            src_wr_ptr_next = src_wr_ptr + 1;
            src_count_next = src_count + 1;
        end
    end

    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            dst_rd_ptr <= 0;
            dst_count <= 0;
        end else begin
            dst_rd_ptr <= dst_rd_ptr_next;
            dst_count <= dst_count_next;
        end
    end

    always @(*) begin
        dst_rd_ptr_next = dst_rd_ptr;
        dst_count_next = dst_count;
        if (dst_valid && dst_ready) begin
            dst_rd_ptr_next = dst_rd_ptr + 1;
            dst_count_next = dst_count - 1;
        end
    end

endmodule
