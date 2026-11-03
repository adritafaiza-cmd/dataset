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

    // FIFO for request signals
    async_fifo #(
        .WIDTH(3 + ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 3),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_req (
        .src_clk(src_pclk_i),
        .src_rst(~src_preset_ni),
        .src_data({src_psel_i, src_penable_i, src_pwrite_i, src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i}),
        .src_valid(src_psel_i & src_penable_i),
        .src_ready(),
        .dst_clk(dst_pclk_i),
        .dst_rst(~dst_preset_ni),
        .dst_data({dst_psel_o, dst_penable_o, dst_pwrite_o, dst_paddr_o, dst_pwdata_o, dst_pstrb_o, dst_pprot_o}),
        .dst_valid(),
        .dst_ready(dst_pready_i)
    );

    // FIFO for response signals
    async_fifo #(
        .WIDTH(DATA_WIDTH + 1),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_resp (
        .src_clk(dst_pclk_i),
        .src_rst(~dst_preset_ni),
        .src_data({dst_prdata_i, dst_pslverr_i}),
        .src_valid(dst_pready_i),
        .src_ready(),
        .dst_clk(src_pclk_i),
        .dst_rst(~src_preset_ni),
        .dst_data({src_prdata_o, src_pslverr_o}),
        .dst_valid(src_pready_o),
        .dst_ready(1'b1)
    );

endmodule

module async_fifo #(
    parameter WIDTH = 32,
    parameter LOG_DEPTH = 2
)(
    input                      src_clk,
    input                      src_rst,
    input  [WIDTH-1:0]         src_data,
    input                      src_valid,
    output                     src_ready,
    input                      dst_clk,
    input                      dst_rst,
    output [WIDTH-1:0]         dst_data,
    output                     dst_valid,
    input                      dst_ready
);

    localparam DEPTH = 1 << LOG_DEPTH;

    reg [WIDTH-1:0] mem [DEPTH-1:0];
    reg [$clog2(DEPTH):0] wr_ptr, rd_ptr;
    reg [$clog2(DEPTH):0] wr_ptr_gray, rd_ptr_gray;
    reg [$clog2(DEPTH):0] wr_ptr_gray_sync, rd_ptr_gray_sync;

    wire [$clog2(DEPTH):0] wr_ptr_bin, rd_ptr_bin;
    wire full, empty;

    // Gray code conversion
    assign wr_ptr_gray = wr_ptr ^ (wr_ptr >> 1);
    assign rd_ptr_gray = rd_ptr ^ (rd_ptr >> 1);

    // Binary conversion
    always @(posedge dst_clk or posedge dst_rst) begin
        if (dst_rst) begin
            wr_ptr_gray_sync <= 0;
            rd_ptr_gray_sync <= 0;
        end else begin
            wr_ptr_gray_sync <= wr_ptr_gray;
            rd_ptr_gray_sync <= rd_ptr_gray;
        end
    end

    gray_to_bin #(.WIDTH($clog2(DEPTH) + 1)) g2b_wr (
        .gray(wr_ptr_gray_sync),
        .bin(wr_ptr_bin)
    );

    gray_to_bin #(.WIDTH($clog2(DEPTH) + 1)) g2b_rd (
        .gray(rd_ptr_gray_sync),
        .bin(rd_ptr_bin)
    );

    // Full and empty flags
    assign full = (wr_ptr_bin[$clog2(DEPTH):1] == rd_ptr_bin[$clog2(DEPTH):1]) & (wr_ptr_bin[0] != rd_ptr_bin[0]);
    assign empty = (wr_ptr_bin == rd_ptr_bin);

    // Write pointer
    always @(posedge src_clk or posedge src_rst) begin
        if (src_rst)
            wr_ptr <= 0;
        else if (src_valid & ~full)
            wr_ptr <= wr_ptr + 1;
    end

    // Read pointer
    always @(posedge dst_clk or posedge dst_rst) begin
        if (dst_rst)
            rd_ptr <= 0;
        else if (dst_valid & dst_ready & ~empty)
            rd_ptr <= rd_ptr + 1;
    end

    // Memory write
    always @(posedge src_clk) begin
        if (src_valid & ~full)
            mem[wr_ptr[$clog2(DEPTH)-1:0]] <= src_data;
    end

    // Memory read
    always @(posedge dst_clk) begin
        if (dst_valid & dst_ready & ~empty)
            dst_data <= mem[rd_ptr[$clog2(DEPTH)-1:0]];
    end

    // Ready signals
    assign src_ready = ~full;
    assign dst_valid = ~empty;

endmodule

module gray_to_bin #(
    parameter WIDTH = 4
)(
    input  [WIDTH-1:0] gray,
    output [WIDTH-1:0] bin
);

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: g_gray_to_bin
            if (i == 0) begin: g_first
                assign bin[i] = gray[i];
            end else begin: g_others
                assign bin[i] = bin[i-1] ^ gray[i];
            end
        end
    endgenerate

endmodule
