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

    wire [DATA_WIDTH-1:0] src_prdata_reg;
    wire src_pslverr_reg;
    wire src_pready_reg;

    wire [DATA_WIDTH-1:0] dst_pwdata_reg;
    wire [DATA_WIDTH/8-1:0] dst_pstrb_reg;
    wire [2:0] dst_pprot_reg;
    wire [ADDR_WIDTH-1:0] dst_paddr_reg;
    wire dst_pwrite_reg;
    wire dst_psel_reg;
    wire dst_penable_reg;

    wire src_pready_out;
    wire src_prdata_out;
    wire src_pslverr_out;

    wire dst_psel_out;
    wire dst_penable_out;
    wire dst_pwrite_out;
    wire [ADDR_WIDTH-1:0] dst_paddr_out;
    wire [DATA_WIDTH-1:0] dst_pwdata_out;
    wire [DATA_WIDTH/8-1:0] dst_pstrb_out;
    wire [2:0] dst_pprot_out;

    reg [DATA_WIDTH-1:0] src_prdata_ff;
    reg src_pslverr_ff;
    reg src_pready_ff;

    reg [DATA_WIDTH-1:0] dst_pwdata_ff;
    reg [DATA_WIDTH/8-1:0] dst_pstrb_ff;
    reg [2:0] dst_pprot_ff;
    reg [ADDR_WIDTH-1:0] dst_paddr_ff;
    reg dst_pwrite_ff;
    reg dst_psel_ff;
    reg dst_penable_ff;

    reg src_pready_reg_ff;
    reg src_prdata_reg_ff;
    reg src_pslverr_reg_ff;

    reg dst_psel_reg_ff;
    reg dst_penable_reg_ff;
    reg dst_pwrite_reg_ff;
    reg [ADDR_WIDTH-1:0] dst_paddr_reg_ff;
    reg [DATA_WIDTH-1:0] dst_pwdata_reg_ff;
    reg [DATA_WIDTH/8-1:0] dst_pstrb_reg_ff;
    reg [2:0] dst_pprot_reg_ff;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_prdata_reg_ff <= 0;
            src_pslverr_reg_ff <= 0;
            src_pready_reg_ff <= 0;
        end else begin
            src_prdata_reg_ff <= src_prdata_out;
            src_pslverr_reg_ff <= src_pslverr_out;
            src_pready_reg_ff <= src_pready_out;
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_pwdata_reg_ff <= 0;
            dst_pstrb_reg_ff <= 0;
            dst_pprot_reg_ff <= 0;
            dst_paddr_reg_ff <= 0;
            dst_pwrite_reg_ff <= 0;
            dst_psel_reg_ff <= 0;
            dst_penable_reg_ff <= 0;
        end else begin
            dst_pwdata_reg_ff <= dst_pwdata_out;
            dst_pstrb_reg_ff <= dst_pstrb_out;
            dst_pprot_reg_ff <= dst_pprot_out;
            dst_paddr_reg_ff <= dst_paddr_out;
            dst_pwrite_reg_ff <= dst_pwrite_out;
            dst_psel_reg_ff <= dst_psel_out;
            dst_penable_reg_ff <= dst_penable_out;
        end
    end

    assign src_prdata_o = src_prdata_reg_ff;
    assign src_pslverr_o = src_pslverr_reg_ff;
    assign src_pready_o = src_pready_reg_ff;

    assign dst_psel_o = dst_psel_reg_ff;
    assign dst_penable_o = dst_penable_reg_ff;
    assign dst_pwrite_o = dst_pwrite_reg_ff;
    assign dst_paddr_o = dst_paddr_reg_ff;
    assign dst_pwdata_o = dst_pwdata_reg_ff;
    assign dst_pstrb_o = dst_pstrb_reg_ff;
    assign dst_pprot_o = dst_pprot_reg_ff;

    apb_cdc_src src_bridge (
        .clk(src_pclk_i),
        .reset_n(src_preset_ni),
        .psel(src_psel_i),
        .penable(src_penable_i),
        .pwrite(src_pwrite_i),
        .paddr(src_paddr_i),
        .pwdata(src_pwdata_i),
        .pstrb(src_pstrb_i),
        .pprot(src_pprot_i),
        .pready(src_pready_out),
        .prdata(src_prdata_out),
        .pslverr(src_pslverr_out),
        .dst_pready_i(dst_pready_i),
        .dst_prdata_i(dst_prdata_i),
        .dst_pslverr_i(dst_pslverr_i)
    );

    apb_cdc_dst dst_bridge (
        .clk(dst_pclk_i),
        .reset_n(dst_preset_ni),
        .psel(dst_psel_reg_ff),
        .penable(dst_penable_reg_ff),
        .pwrite(dst_pwrite_reg_ff),
        .paddr(dst_paddr_reg_ff),
        .pwdata(dst_pwdata_reg_ff),
        .pstrb(dst_pstrb_reg_ff),
        .pprot(dst_pprot_reg_ff),
        .pready(src_pready_reg_ff),
        .prdata(src_prdata_reg_ff),
        .pslverr(src_pslverr_reg_ff),
        .src_pclk_i(src_pclk_i),
        .src_preset_ni(src_preset_ni)
    );

endmodule
