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

reg [ADDR_WIDTH-1:0] addr;
reg [DATA_WIDTH-1:0] wdata;
reg [DATA_WIDTH/8-1:0] wstrb;
reg [2:0] pro;
reg write;
reg valid;
reg ready;
reg [DATA_WIDTH-1:0] rdata;
reg slverr;

reg [LOG_DEPTH-1:0] cnt;
reg [LOG_DEPTH:0] full;

always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (~src_preset_ni) begin
        valid <= 1'b0;
        cnt <= 'b0;
    end else if (src_psel_i && src_penable_i && ~valid) begin
        addr <= src_paddr_i;
        wdata <= src_pwdata_i;
        wstrb <= src_pstrb_i;
        pro <= src_pprot_i;
        write <= src_pwrite_i;
        valid <= 1'b1;
        cnt <= cnt + 1'b1;
    end else if (valid && ready) begin
        valid <= 1'b0;
        cnt <= cnt - 1'b1;
    end
end

always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (~dst_preset_ni) begin
        dst_psel_o <= 1'b0;
        dst_penable_o <= 1'b0;
        dst_pwrite_o <= 1'b0;
        dst_paddr_o <= 'b0;
        dst_pwdata_o <= 'b0;
        dst_pstrb_o <= 'b0;
        dst_pprot_o <= 'b0;
        ready <= 1'b0;
        rdata <= 'b0;
        slverr <= 1'b0;
    end else if (valid && ~dst_psel_o) begin
        dst_psel_o <= 1'b1;
        dst_penable_o <= 1'b0;
        dst_pwrite_o <= write;
        dst_paddr_o <= addr;
        dst_pwdata_o <= wdata;
        dst_pstrb_o <= wstrb;
        dst_pprot_o <= pro;
    end else if (dst_psel_o && ~dst_penable_o) begin
        dst_penable_o <= 1'b1;
    end else if (dst_penable_o && dst_pready_i) begin
        dst_psel_o <= 1'b0;
        dst_penable_o <= 1'b0;
        ready <= 1'b1;
        rdata <= dst_prdata_i;
        slverr <= dst_pslverr_i;
    end else if (ready && ~dst_pready_i) begin
        ready <= 1'b0;
    end
end

assign src_pready_o = ready;
assign src_prdata_o = rdata;
assign src_pslverr_o = slverr;

endmodule
