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

    reg [ADDR_WIDTH-1:0] src_paddr_reg;
    reg [DATA_WIDTH-1:0] src_pwdata_reg;
    reg [DATA_WIDTH/8-1:0] src_pstrb_reg;
    reg [2:0] src_pprot_reg;
    reg src_psel_reg;
    reg src_penable_reg;
    reg src_pwrite_reg;

    reg [DATA_WIDTH-1:0] dst_prdata_reg;
    reg dst_pslverr_reg;

    reg src_pready_reg;
    reg [DATA_WIDTH-1:0] src_prdata_reg;
    reg src_pslverr_reg;

    reg [ADDR_WIDTH-1:0] dst_paddr_reg;
    reg [DATA_WIDTH-1:0] dst_pwdata_reg;
    reg [DATA_WIDTH/8-1:0] dst_pstrb_reg;
    reg [2:0] dst_pprot_reg;
    reg dst_psel_reg;
    reg dst_penable_reg;
    reg dst_pwrite_reg;

    wire src_pready_next;
    wire src_prdata_next;
    wire src_pslverr_next;

    wire dst_psel_next;
    wire dst_penable_next;
    wire dst_pwrite_next;
    wire dst_paddr_next;
    wire dst_pwdata_next;
    wire dst_pstrb_next;
    wire dst_pprot_next;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_paddr_reg <= 0;
            src_pwdata_reg <= 0;
            src_pstrb_reg <= 0;
            src_pprot_reg <= 0;
            src_psel_reg <= 0;
            src_penable_reg <= 0;
            src_pwrite_reg <= 0;
        end else begin
            src_paddr_reg <= src_paddr_i;
            src_pwdata_reg <= src_pwdata_i;
            src_pstrb_reg <= src_pstrb_i;
            src_pprot_reg <= src_pprot_i;
            src_psel_reg <= src_psel_i;
            src_penable_reg <= src_penable_i;
            src_pwrite_reg <= src_pwrite_i;
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_prdata_reg <= 0;
            dst_pslverr_reg <= 0;
            src_pready_reg <= 0;
            src_prdata_reg <= 0;
            src_pslverr_reg <= 0;
            dst_paddr_reg <= 0;
            dst_pwdata_reg <= 0;
            dst_pstrb_reg <= 0;
            dst_pprot_reg <= 0;
            dst_psel_reg <= 0;
            dst_penable_reg <= 0;
            dst_pwrite_reg <= 0;
        end else begin
            dst_prdata_reg <= dst_prdata_i;
            dst_pslverr_reg <= dst_pslverr_i;
            src_pready_reg <= dst_pready_i;
            src_prdata_reg <= dst_prdata_i;
            src_pslverr_reg <= dst_pslverr_i;
            dst_paddr_reg <= src_paddr_reg;
            dst_pwdata_reg <= src_pwdata_reg;
            dst_pstrb_reg <= src_pstrb_reg;
            dst_pprot_reg <= src_pprot_reg;
            dst_psel_reg <= src_psel_reg;
            dst_penable_reg <= src_penable_reg;
            dst_pwrite_reg <= src_pwrite_reg;
        end
    end

    assign src_pready_o = src_pready_reg;
    assign src_prdata_o = src_prdata_reg;
    assign src_pslverr_o = src_pslverr_reg;

    assign dst_psel_o = dst_psel_reg;
    assign dst_penable_o = dst_penable_reg;
    assign dst_pwrite_o = dst_pwrite_reg;
    assign dst_paddr_o = dst_paddr_reg;
    assign dst_pwdata_o = dst_pwdata_reg;
    assign dst_pstrb_o = dst_pstrb_reg;
    assign dst_pprot_o = dst_pprot_reg;

endmodule
