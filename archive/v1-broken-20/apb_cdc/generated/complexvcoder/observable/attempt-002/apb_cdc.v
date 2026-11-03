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

    // FIFOs for request and response
    apb_fifo #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH + DATA_WIDTH/8 + 3),
        .LOG_DEPTH(LOG_DEPTH)
    ) src_to_dst_fifo (
        .clk_i(src_pclk_i),
        .rst_ni(src_preset_ni),
        .w_en_i(src_psel_i & src_penable_i & src_pwrite_i),
        .w_data_i({src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i}),
        .w_ready_o(src_pready_o),
        .clk_o(dst_pclk_i),
        .rst_ni(dst_preset_ni),
        .r_en_i(dst_pready_i),
        .r_data_o({dst_psel_o, dst_penable_o, dst_pwrite_o, dst_paddr_o, dst_pwdata_o, dst_pstrb_o, dst_pprot_o}),
        .r_valid_o()
    );

    apb_fifo #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) dst_to_src_fifo (
        .clk_i(dst_pclk_i),
        .rst_ni(dst_preset_ni),
        .w_en_i(dst_psel_o & dst_penable_o & dst_pwrite_o),
        .w_data_i(dst_prdata_i),
        .w_ready_o(dst_pready_i),
        .clk_o(src_pclk_i),
        .rst_ni(src_preset_ni),
        .r_en_i(src_pready_o),
        .r_data_o(src_prdata_o),
        .r_valid_o(src_pslverr_o)
    );

endmodule

module apb_fifo #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      clk_i,
    input                      rst_ni,
    input                      w_en_i,
    input  [DATA_WIDTH-1:0]    w_data_i,
    output                     w_ready_o,
    input                      clk_o,
    input                      rst_ni,
    input                      r_en_i,
    input  [DATA_WIDTH-1:0]    r_data_o,
    output                     r_valid_o
);

    reg [DATA_WIDTH-1:0] mem [0:2**LOG_DEPTH-1];
    reg [ADDR_WIDTH-1:0] w_ptr, r_ptr;
    reg [LOG_DEPTH:0] count;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            w_ptr <= 0;
            r_ptr <= 0;
            count <= 0;
            w_ready_o <= 1;
        end else begin
            if (w_en_i && r_ptr != w_ptr && count < 2**LOG_DEPTH) begin
                mem[w_ptr] <= w_data_i;
                w_ptr <= w_ptr + 1;
                count <= count + 1;
                w_ready_o <= 0;
            end else begin
                w_ready_o <= 1;
            end
        end
    end

    always @(posedge clk_o or negedge rst_ni) begin
        if (!rst_ni) begin
            r_ptr <= 0;
            count <= 0;
            r_valid_o <= 0;
        end else begin
            if (r_en_i && count > 0) begin
                r_data_o <= mem[r_ptr];
                r_ptr <= r_ptr + 1;
                count <= count - 1;
                r_valid_o <= 1;
            end else begin
                r_valid_o <= 0;
            end
        end
    end

endmodule
