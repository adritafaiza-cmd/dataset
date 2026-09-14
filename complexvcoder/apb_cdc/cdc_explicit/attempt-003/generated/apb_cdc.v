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

    // Internal signals
    logic [ADDR_WIDTH-1:0] src_addr_reg;
    logic [DATA_WIDTH-1:0] src_data_reg;
    logic [DATA_WIDTH/8-1:0] src_strb_reg;
    logic [2:0] src_prot_reg;
    logic src_write_reg;
    logic src_valid_reg;
    logic dst_ready_reg;

    // FIFO for transferring APB transactions
    apb_fifo #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) src_to_dst_fifo (
        .clk(src_pclk_i),
        .rst_ni(src_preset_ni),
        .src_psel_i(src_psel_i),
        .src_penable_i(src_penable_i),
        .src_pwrite_i(src_pwrite_i),
        .src_paddr_i(src_paddr_i),
        .src_pwdata_i(src_pwdata_i),
        .src_pstrb_i(src_pstrb_i),
        .src_pprot_i(src_pprot_i),
        .dst_clk_i(dst_pclk_i),
        .dst_rst_ni(dst_preset_ni),
        .dst_pready_i(dst_pready_i),
        .dst_prdata_i(dst_prdata_i),
        .dst_pslverr_i(dst_pslverr_i)
    );

    // Synchronizer for source signals
    always_ff @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_addr_reg <= 0;
            src_data_reg <= 0;
            src_strb_reg <= 0;
            src_prot_reg <= 0;
            src_write_reg <= 0;
            src_valid_reg <= 0;
        end else begin
            src_addr_reg <= src_paddr_i;
            src_data_reg <= src_pwdata_i;
            src_strb_reg <= src_pstrb_i;
            src_prot_reg <= src_pprot_i;
            src_write_reg <= src_pwrite_i;
            src_valid_reg <= src_penable_i;
        end
    end

    // Synchronizer for destination signals
    always_ff @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_ready_reg <= 0;
        end else begin
            dst_ready_reg <= dst_pready_i;
        end
    end

    // Output logic
    assign src_pready_o = dst_ready_reg;
    assign src_prdata_o = src_to_dst_fifo.src_prdata_o;
    assign src_pslverr_o = src_to_dst_fifo.src_pslverr_o;
    assign dst_psel_o = src_valid_reg;
    assign dst_penable_o = src_valid_reg;
    assign dst_pwrite_o = src_write_reg;
    assign dst_paddr_o = src_addr_reg;
    assign dst_pwdata_o = src_data_reg;
    assign dst_pstrb_o = src_strb_reg;
    assign dst_pprot_o = src_prot_reg;

endmodule
