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

// FIFO signals
reg [ADDR_WIDTH-1:0] fifo_addr;
reg [DATA_WIDTH-1:0] fifo_wdata;
reg [DATA_WIDTH/8-1:0] fifo_wstrb;
reg [2:0] fifo_wprot;
reg [DATA_WIDTH-1:0] fifo_rdata;
reg fifo_empty;
reg fifo_full;
reg fifo_valid;

// Source side handshake
reg src_handshake;
reg src_handshake_r;

// Destination side handshake
reg dst_handshake;
reg dst_handshake_r;

// FIFO write logic
always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (~src_preset_ni) begin
        fifo_valid <= 1'b0;
        src_handshake <= 1'b0;
    end else if (src_psel_i && src_penable_i && ~src_handshake) begin
        fifo_addr <= src_paddr_i;
        fifo_wdata <= src_pwdata_i;
        fifo_wstrb <= src_pstrb_i;
        fifo_wprot <= src_pprot_i;
        fifo_valid <= 1'b1;
        src_handshake <= 1'b1;
    end else if (src_handshake && ~fifo_full) begin
        src_handshake <= 1'b0;
    end
end

// FIFO read logic
always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (~dst_preset_ni) begin
        dst_handshake <= 1'b0;
    end else if (fifo_valid && ~dst_handshake) begin
        dst_psel_o <= 1'b1;
        dst_penable_o <= 1'b1;
        dst_pwrite_o <= fifo_wprot[0];
        dst_paddr_o <= fifo_addr;
        dst_pwdata_o <= fifo_wdata;
        dst_pstrb_o <= fifo_wstrb;
        dst_pprot_o <= fifo_wprot;
        dst_handshake <= 1'b1;
    end else if (dst_handshake && dst_pready_i) begin
        dst_handshake <= 1'b0;
        fifo_valid <= 1'b0;
    end
end

// Source side ready logic
always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (~src_preset_ni) begin
        src_pready_o <= 1'b0;
    end else if (src_handshake_r && ~fifo_empty) begin
        src_pready_o <= 1'b1;
    end else begin
        src_pready_o <= 1'b0;
    end
end

// Source side data logic
always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (~src_preset_ni) begin
        src_prdata_o <= {DATA_WIDTH{1'b0}};
        src_pslverr_o <= 1'b0;
    end else if (src_handshake_r && ~fifo_empty) begin
        src_prdata_o <= dst_prdata_i;
        src_pslverr_o <= dst_pslverr_i;
    end
end

// FIFO status logic
always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (~src_preset_ni) begin
        fifo_empty <= 1'b1;
        fifo_full <= 1'b0;
    end else if (fifo_valid && ~fifo_full) begin
        fifo_empty <= 1'b0;
    end else if (~fifo_valid && fifo_empty) begin
        fifo_full <= 1'b0;
    end
end

// Handshake registers
always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (~src_preset_ni) begin
        src_handshake_r <= 1'b0;
    end else begin
        src_handshake_r <= src_handshake;
    end
end

always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (~dst_preset_ni) begin
        dst_handshake_r <= 1'b0;
    end else begin
        dst_handshake_r <= dst_handshake;
    end
end

endmodule
