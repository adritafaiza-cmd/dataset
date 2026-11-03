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

    wire src_master_ready;
    wire [DATA_WIDTH-1:0] src_master_rdata;
    wire src_master_slverr;
    wire dst_slave_ready;
    wire [DATA_WIDTH-1:0] dst_slave_rdata;
    wire dst_slave_slverr;

    apb_master src_master (
        .clk_i(src_pclk_i),
        .reset_ni(src_preset_ni),
        .sel_i(src_psel_i),
        .enable_i(src_penable_i),
        .write_i(src_pwrite_i),
        .addr_i(src_paddr_i),
        .wdata_i(src_pwdata_i),
        .strb_i(src_pstrb_i),
        .prot_i(src_pprot_i),
        .ready_o(src_pready_o),
        .rdata_o(src_prdata_o),
        .slverr_o(src_pslverr_o)
    );

    apb_slave dst_slave (
        .clk_i(dst_pclk_i),
        .reset_ni(dst_preset_ni),
        .sel_o(dst_psel_o),
        .enable_o(dst_penable_o),
        .write_o(dst_pwrite_o),
        .addr_o(dst_paddr_o),
        .wdata_o(dst_pwdata_o),
        .strb_o(dst_pstrb_o),
        .prot_o(dst_pprot_o),
        .ready_i(dst_pready_i),
        .rdata_i(dst_prdata_i),
        .slverr_i(dst_pslverr_i)
    );

    apb_crossbar xbar (
        .clk_i(src_pclk_i),
        .reset_ni(src_preset_ni),
        .slave_0_sel_i(src_master.sel_o),
        .slave_0_enable_i(src_master.enable_o),
        .slave_0_write_i(src_master.write_o),
        .slave_0_addr_i(src_master.addr_o),
        .slave_0_wdata_i(src_master.wdata_o),
        .slave_0_strb_i(src_master.strb_o),
        .slave_0_prot_i(src_master.prot_o),
        .slave_0_ready_i(dst_slave.ready_i),
        .slave_0_rdata_o(src_master_rdata),
        .slave_0_slverr_o(src_master_slverr),
        .master_0_sel_i(dst_slave.sel_o),
        .master_0_enable_i(dst_slave.enable_o),
        .master_0_write_i(dst_slave.write_o),
        .master_0_addr_i(dst_slave.addr_o),
        .master_0_wdata_i(dst_slave.wdata_o),
        .master_0_strb_i(dst_slave.strb_o),
        .master_0_prot_i(dst_slave.prot_o),
        .master_0_ready_i(src_master.ready_i),
        .master_0_rdata_o(dst_slave_rdata),
        .master_0_slverr_o(dst_slave_slverr)
    );

endmodule
