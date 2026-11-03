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

    reg [DATA_WIDTH-1:0] src_prdata;
    reg src_pslverr;
    reg [DATA_WIDTH-1:0] dst_pwdata;

    reg [ADDR_WIDTH-1:0] src_paddr_reg;
    reg [DATA_WIDTH-1:0] src_pwdata_reg;
    reg [DATA_WIDTH/8-1:0] src_pstrb_reg;
    reg [2:0] src_pprot_reg;
    reg src_psel_reg;
    reg src_penable_reg;
    reg src_pwrite_reg;

    reg dst_psel_reg;
    reg dst_penable_reg;
    reg dst_pwrite_reg;
    reg [ADDR_WIDTH-1:0] dst_paddr_reg;

    reg [DATA_WIDTH-1:0] src_prdata_reg;
    reg src_pslverr_reg;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_prdata <= 0;
            src_pslverr <= 0;
            dst_pwdata <= 0;
            src_pready_o <= 0;
            src_prdata_o <= 0;
            src_pslverr_o <= 0;
            src_psel_reg <= 0;
            src_penable_reg <= 0;
            src_pwrite_reg <= 0;
            dst_psel_reg <= 0;
            dst_penable_reg <= 0;
            dst_pwrite_reg <= 0;
            src_paddr_reg <= 0;
            src_pwdata_reg <= 0;
            src_pstrb_reg <= 0;
            src_pprot_reg <= 0;
        end else begin
            if (src_psel_i && src_penable_i) begin
                src_paddr_reg <= src_paddr_i;
                src_pwdata_reg <= src_pwdata_i;
                src_pstrb_reg <= src_pstrb_i;
                src_pprot_reg <= src_pprot_i;
                src_psel_reg <= src_psel_i;
                src_penable_reg <= src_penable_i;
                src_pwrite_reg <= src_pwrite_i;
                dst_psel_reg <= src_psel_i;
                dst_penable_reg <= src_penable_i;
                dst_pwrite_reg <= src_pwrite_i;
                dst_paddr_reg <= src_paddr_i;
                dst_pwdata <= src_pwdata_i;
                src_pready_o <= 0;
            end else begin
                src_psel_reg <= 0;
                src_penable_reg <= 0;
                src_pwrite_reg <= 0;
                dst_psel_reg <= 0;
                dst_penable_reg <= 0;
                dst_pwrite_reg <= 0;
            end

            if (dst_pready_i) begin
                src_prdata <= dst_prdata_i;
                src_pslverr <= dst_pslverr_i;
                src_pready_o <= 1;
            end
        end
    end

endmodule
