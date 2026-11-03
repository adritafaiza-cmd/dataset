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

reg [ADDR_WIDTH-1:0]  fifo_addr;
reg [DATA_WIDTH-1:0]  fifo_wdata;
reg [DATA_WIDTH/8-1:0] fifo_wstrb;
reg [2:0]             fifo_pprot;
reg                   fifo_write;
reg                   fifo_valid;
reg                   fifo_ready;
reg                   dst_valid;
reg                   dst_ready;
reg [DATA_WIDTH-1:0]  dst_rdata;
reg                   dst_error;
reg                   src_valid;
reg                   src_ready;

integer i;

always @(posedge src_pclk_i or negedge src_preset_ni)
begin
    if (~src_preset_ni) begin
        src_valid <= 1'b0;
        fifo_valid <= 1'b0;
    end else if (src_penable_i && src_psel_i && ~fifo_valid) begin
        src_valid <= 1'b1;
        fifo_addr <= src_paddr_i;
        fifo_wdata <= src_pwdata_i;
        fifo_wstrb <= src_pstrb_i;
        fifo_pprot <= src_pprot_i;
        fifo_write <= src_pwrite_i;
        fifo_valid <= 1'b1;
    end else if (fifo_ready) begin
        fifo_valid <= 1'b0;
    end
end

always @(posedge dst_pclk_i or negedge dst_preset_ni)
begin
    if (~dst_preset_ni) begin
        dst_valid <= 1'b0;
        dst_ready <= 1'b0;
        dst_psel_o <= 1'b0;
        dst_penable_o <= 1'b0;
        dst_pwrite_o <= 1'b0;
        dst_paddr_o <= {ADDR_WIDTH{1'b0}};
        dst_pwdata_o <= {DATA_WIDTH{1'b0}};
        dst_pstrb_o <= {DATA_WIDTH/8{1'b0}};
        dst_pprot_o <= {3{1'b0}};
    end else if (fifo_valid && ~dst_valid) begin
        dst_valid <= 1'b1;
        dst_psel_o <= 1'b1;
        dst_penable_o <= 1'b0;
        dst_pwrite_o <= fifo_write;
        dst_paddr_o <= fifo_addr;
        dst_pwdata_o <= fifo_wdata;
        dst_pstrb_o <= fifo_wstrb;
        dst_pprot_o <= fifo_pprot;
    end else if (dst_pready_i) begin
        dst_valid <= 1'b0;
        dst_psel_o <= 1'b0;
        dst_penable_o <= 1'b0;
        dst_ready <= 1'b1;
        dst_rdata <= dst_prdata_i;
        dst_error <= dst_pslverr_i;
    end else if (~dst_pready_i && dst_valid) begin
        dst_penable_o <= 1'b1;
    end else if (~dst_pready_i && ~dst_valid) begin
        dst_penable_o <= 1'b0;
    end
end

always @(posedge src_pclk_i or negedge src_preset_ni)
begin
    if (~src_preset_ni) begin
        src_pready_o <= 1'b0;
        src_prdata_o <= {DATA_WIDTH{1'b0}};
        src_pslverr_o <= 1'b0;
    end else if (dst_ready) begin
        src_pready_o <= 1'b1;
        src_prdata_o <= dst_rdata;
        src_pslverr_o <= dst_error;
        fifo_ready <= 1'b1;
    end else if (~dst_ready && src_valid) begin
        src_pready_o <= 1'b0;
    end else if (~dst_ready && ~src_valid) begin
        src_pready_o <= 1'b0;
        fifo_ready <= 1'b0;
    end
end

endmodule
