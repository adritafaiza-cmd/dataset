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

    reg src_pready_r;
    reg [DATA_WIDTH-1:0] src_prdata_r;
    reg src_pslverr_r;

    reg dst_psel_r;
    reg dst_penable_r;
    reg dst_pwrite_r;
    reg [ADDR_WIDTH-1:0] dst_paddr_r;
    reg [DATA_WIDTH-1:0] dst_pwdata_r;
    reg [DATA_WIDTH/8-1:0] dst_pstrb_r;
    reg [2:0] dst_pprot_r;

    reg [LOG_DEPTH:0] src_cnt;
    reg [LOG_DEPTH:0] dst_cnt;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_pready_r <= 0;
            src_prdata_r <= 0;
            src_pslverr_r <= 0;
        end else begin
            if (src_psel_i && src_penable_i) begin
                src_pready_r <= 1;
                dst_psel_r <= 1;
                dst_paddr_r <= src_paddr_i;
                dst_pwdata_r <= src_pwdata_i;
                dst_pstrb_r <= src_pstrb_i;
                dst_pprot_r <= src_pprot_i;
                dst_pwrite_r <= src_pwrite_i;
                if (src_pwrite_i) begin
                    dst_penable_r <= 1;
                end else begin
                    dst_penable_r <= 0;
                end
            end else begin
                src_pready_r <= 0;
                dst_psel_r <= 0;
                dst_penable_r <= 0;
            end
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            src_pready_o <= 0;
            src_prdata_o <= 0;
            src_pslverr_o <= 0;
        end else begin
            if (dst_pready_i) begin
                src_pready_o <= 1;
                src_prdata_o <= dst_prdata_i;
                src_pslverr_o <= dst_pslverr_i;
                dst_penable_r <= 0;
            end else begin
                src_pready_o <= 0;
                src_prdata_o <= 0;
                src_pslverr_o <= 0;
            end
        end
    end

endmodule
