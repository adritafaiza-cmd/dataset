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

    reg [DATA_WIDTH-1:0] src_prdata_o;
    reg src_pslverr_o;
    reg dst_psel_o;
    reg dst_penable_o;
    reg dst_pwrite_o;
    reg [ADDR_WIDTH-1:0] dst_paddr_o;
    reg [DATA_WIDTH-1:0] dst_pwdata_o;
    reg [DATA_WIDTH/8-1:0] dst_pstrb_o;
    reg [2:0] dst_pprot_o;

    reg [DATA_WIDTH-1:0] dst_prdata_reg;
    reg dst_pslverr_reg;
    reg src_pready_reg;

    reg [ADDR_WIDTH-1:0] src_paddr_reg;
    reg [DATA_WIDTH-1:0] src_pwdata_reg;
    reg [DATA_WIDTH/8-1:0] src_pstrb_reg;
    reg [2:0] src_pprot_reg;

    reg src_psel_reg;
    reg src_penable_reg;
    reg src_pwrite_reg;

    reg dst_pready_reg;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_prdata_o <= 0;
            src_pslverr_o <= 0;
            dst_psel_o <= 0;
            dst_penable_o <= 0;
            dst_pwrite_o <= 0;
            dst_paddr_o <= 0;
            dst_pwdata_o <= 0;
            dst_pstrb_o <= 0;
            dst_pprot_o <= 0;
            dst_prdata_reg <= 0;
            dst_pslverr_reg <= 0;
            src_pready_reg <= 0;
            src_paddr_reg <= 0;
            src_pwdata_reg <= 0;
            src_pstrb_reg <= 0;
            src_pprot_reg <= 0;
            src_psel_reg <= 0;
            src_penable_reg <= 0;
            src_pwrite_reg <= 0;
            dst_pready_reg <= 0;
        end else begin
            dst_prdata_reg <= dst_prdata_i;
            dst_pslverr_reg <= dst_pslverr_i;
            src_pready_reg <= dst_pready_i;

            if (src_psel_i && src_penable_i) begin
                src_paddr_reg <= src_paddr_i;
                src_pwdata_reg <= src_pwdata_i;
                src_pstrb_reg <= src_pstrb_i;
                src_pprot_reg <= src_pprot_i;
                src_psel_reg <= 1;
                src_penable_reg <= 1;
                src_pwrite_reg <= src_pwrite_i;
            end else begin
                src_psel_reg <= 0;
                src_penable_reg <= 0;
            end

            if (dst_pready_i) begin
                dst_psel_o <= src_psel_reg;
                dst_penable_o <= src_penable_reg;
                dst_pwrite_o <= src_pwrite_reg;
                dst_paddr_o <= src_paddr_reg;
                dst_pwdata_o <= src_pwdata_reg;
                dst_pstrb_o <= src_pstrb_reg;
                dst_pprot_o <= src_pprot_reg;
            end else begin
                dst_psel_o <= 0;
                dst_penable_o <= 0;
            end
        end
    end

    assign src_pready_o = src_pready_reg;
    assign src_prdata_o = dst_prdata_reg;
    assign src_pslverr_o = dst_pslverr_reg;

endmodule
