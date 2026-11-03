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

reg [ADDR_WIDTH-1:0] src_paddr_r;
reg [DATA_WIDTH-1:0] src_pwdata_r;
reg [DATA_WIDTH/8-1:0] src_pstrb_r;
reg [2:0] src_pprot_r;
reg src_pwrite_r;
reg src_penable_r;
reg src_psel_r;

reg [ADDR_WIDTH-1:0] dst_paddr_r;
reg [DATA_WIDTH-1:0] dst_pwdata_r;
reg [DATA_WIDTH/8-1:0] dst_pstrb_r;
reg [2:0] dst_pprot_r;
reg dst_pwrite_r;
reg dst_penable_r;
reg dst_psel_r;

reg [DATA_WIDTH-1:0] src_prdata_r;
reg src_pslverr_r;

reg [DATA_WIDTH-1:0] dst_prdata_r;
reg dst_pslverr_r;

reg src_pready_r;
reg dst_pready_r;

reg src_valid_r;
reg dst_valid_r;

reg src_almost_full_r;
reg dst_almost_full_r;

reg src_empty_r;
reg dst_empty_r;

wire src_valid_w = src_psel_i && src_penable_i;
wire dst_valid_w = dst_penable_r && dst_pready_i;

wire src_ready_w = !src_almost_full_r;
wire dst_ready_w = !dst_almost_full_r;

wire src_empty_w = src_empty_r;
wire dst_empty_w = dst_empty_r;

always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (!src_preset_ni) begin
        src_paddr_r <= '0;
        src_pwdata_r <= '0;
        src_pstrb_r <= '0;
        src_pprot_r <= '0;
        src_pwrite_r <= 1'b0;
        src_penable_r <= 1'b0;
        src_psel_r <= 1'b0;
        src_valid_r <= 1'b0;
        src_prdata_r <= '0;
        src_pslverr_r <= 1'b0;
        src_pready_r <= 1'b0;
        src_empty_r <= 1'b1;
        src_almost_full_r <= 1'b0;
    end else if (src_valid_w && src_ready_w) begin
        src_paddr_r <= src_paddr_i;
        src_pwdata_r <= src_pwdata_i;
        src_pstrb_r <= src_pstrb_i;
        src_pprot_r <= src_pprot_i;
        src_pwrite_r <= src_pwrite_i;
        src_penable_r <= src_penable_i;
        src_psel_r <= src_psel_i;
        src_valid_r <= 1'b1;
        src_empty_r <= 1'b0;
    end else if (src_valid_r && !src_ready_w) begin
        src_pready_r <= 1'b0;
    end else if (src_valid_r && src_ready_w) begin
        src_pready_r <= 1'b1;
    end else if (!src_valid_w && src_ready_w) begin
        src_pready_r <= 1'b1;
    end
end

always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (!dst_preset_ni) begin
        dst_paddr_r <= '0;
        dst_pwdata_r <= '0;
        dst_pstrb_r <= '0;
        dst_pprot_r <= '0;
        dst_pwrite_r <= 1'b0;
        dst_penable_r <= 1'b0;
        dst_psel_r <= 1'b0;
        dst_valid_r <= 1'b0;
        dst_prdata_r <= '0;
        dst_pslverr_r <= 1'b0;
        dst_pready_r <= 1'b0;
        dst_empty_r <= 1'b1;
        dst_almost_full_r <= 1'b0;
    end else if (dst_valid_w && dst_ready_w) begin
        dst_paddr_r <= src_paddr_r;
        dst_pwdata_r <= src_pwdata_r;
        dst_pstrb_r <= src_pstrb_r;
        dst_pprot_r <= src_pprot_r;
        dst_pwrite_r <= src_pwrite_r;
        dst_penable_r <= src_penable_r;
        dst_psel_r <= src_psel_r;
        dst_valid_r <= 1'b1;
        dst_empty_r <= 1'b0;
    end else if (dst_valid_r && !dst_ready_w) begin
        dst_pready_r <= 1'b0;
    end else if (dst_valid_r && dst_ready_w) begin
        dst_pready_r <= 1'b1;
    end else if (!dst_valid_w && dst_ready_w) begin
        dst_pready_r <= 1'b1;
    end
end

always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (!src_preset_ni) begin
        src_prdata_o <= '0;
        src_pslverr_o <= 1'b0;
    end else if (src_valid_r && src_psel_i && src_penable_i) begin
        src_prdata_o <= dst_prdata_r;
        src_pslverr_o <= dst_pslverr_r;
    end
end

always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (!dst_preset_ni) begin
        dst_psel_o <= 1'b0;
        dst_penable_o <= 1'b0;
        dst_pwrite_o <= 1'b0;
        dst_paddr_o <= '0;
        dst_pwdata_o <= '0;
        dst_pstrb_o <= '0;
        dst_pprot_o <= '0;
    end else if (dst_valid_r && dst_pready_i) begin
        dst_psel_o <= dst_psel_r;
        dst_penable_o <= dst_penable_r;
        dst_pwrite_o <= dst_pwrite_r;
        dst_paddr_o <= dst_paddr_r;
        dst_pwdata_o <= dst_pwdata_r;
        dst_pstrb_o <= dst_pstrb_r;
        dst_pprot_o <= dst_pprot_r;
    end
end

assign src_pready_o = src_pready_r;
assign dst_pready_r = dst_pready_i;

endmodule
