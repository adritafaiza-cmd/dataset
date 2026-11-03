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
reg fifo_write;
reg fifo_read;
reg fifo_empty;
reg fifo_full;
reg [DATA_WIDTH-1:0] fifo_rdata;
reg fifo_rvalid;

// Gray-coded handshake signals
reg [LOG_DEPTH:0] src_gray;
reg [LOG_DEPTH:0] dst_gray;
reg [LOG_DEPTH:0] src_bin;
reg [LOG_DEPTH:0] dst_bin;

// APB signals
reg src_psel_reg;
reg src_penable_reg;
reg src_pwrite_reg;
reg [ADDR_WIDTH-1:0] src_paddr_reg;
reg [DATA_WIDTH-1:0] src_pwdata_reg;
reg [DATA_WIDTH/8-1:0] src_pstrb_reg;
reg [2:0] src_pprot_reg;
reg dst_psel_reg;
reg dst_penable_reg;
reg dst_pwrite_reg;
reg [ADDR_WIDTH-1:0] dst_paddr_reg;
reg [DATA_WIDTH-1:0] dst_pwdata_reg;
reg [DATA_WIDTH/8-1:0] dst_pstrb_reg;
reg [2:0] dst_pprot_reg;

// CDC handshake
always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (!src_preset_ni) begin
        src_gray <= 0;
        src_bin <= 0;
    end else begin
        src_gray <= src_gray + 1;
        src_bin <= src_gray[LOG_DEPTH];
    end
end

always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (!dst_preset_ni) begin
        dst_gray <= 0;
        dst_bin <= 0;
    end else begin
        dst_gray <= dst_gray + 1;
        dst_bin <= dst_gray[LOG_DEPTH];
    end
end

// FIFO
always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (!src_preset_ni) begin
        fifo_empty <= 1;
        fifo_full <= 0;
    end else if (fifo_write &&!fifo_read) begin
        fifo_empty <= 0;
        if (fifo_full) begin
            fifo_full <= 1;
        end else begin
            fifo_full <= 0;
        end
    end else if (!fifo_write && fifo_read) begin
        fifo_full <= 0;
        if (fifo_empty) begin
            fifo_empty <= 1;
        end else begin
            fifo_empty <= 0;
        end
    end
end

always @(posedge src_pclk_i) begin
    if (fifo_write) begin
        fifo_addr <= src_paddr_i;
        fifo_wdata <= src_pwdata_i;
        fifo_wstrb <= src_pstrb_i;
        fifo_wprot <= src_pprot_i;
    end
end

always @(posedge dst_pclk_i) begin
    if (fifo_read) begin
        dst_paddr_o <= fifo_addr;
        dst_pwdata_o <= fifo_wdata;
        dst_pstrb_o <= fifo_wstrb;
        dst_pprot_o <= fifo_wprot;
    end
end

// APB
always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (!src_preset_ni) begin
        src_psel_reg <= 0;
        src_penable_reg <= 0;
        src_pwrite_reg <= 0;
        src_paddr_reg <= 0;
        src_pwdata_reg <= 0;
        src_pstrb_reg <= 0;
        src_pprot_reg <= 0;
    end else if (src_psel_i && src_penable_i) begin
        src_psel_reg <= src_psel_i;
        src_penable_reg <= src_penable_i;
        src_pwrite_reg <= src_pwrite_i;
        src_paddr_reg <= src_paddr_i;
        src_pwdata_reg <= src_pwdata_i;
        src_pstrb_reg <= src_pstrb_i;
        src_pprot_reg <= src_pprot_i;
    end
end

always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (!dst_preset_ni) begin
        dst_psel_reg <= 0;
        dst_penable_reg <= 0;
        dst_pwrite_reg <= 0;
        dst_paddr_reg <= 0;
        dst_pwdata_reg <= 0;
        dst_pstrb_reg <= 0;
        dst_pprot_reg <= 0;
    end else if (dst_pready_i) begin
        dst_psel_reg <= 0;
        dst_penable_reg <= 0;
        dst_pwrite_reg <= 0;
        dst_paddr_reg <= 0;
        dst_pwdata_reg <= 0;
        dst_pstrb_reg <= 0;
        dst_pprot_reg <= 0;
    end
end

// Output assignments
assign src_pready_o = (dst_pready_i &&!fifo_empty);
assign src_prdata_o = dst_prdata_i;
assign src_pslverr_o = dst_pslverr_i;
assign dst_psel_o = dst_psel_reg;
assign dst_penable_o = dst_penable_reg;
assign dst_pwrite_o = dst_pwrite_reg;
assign dst_paddr_o = dst_paddr_reg;
assign dst_pwdata_o = dst_pwdata_reg;
assign dst_pstrb_o = dst_pstrb_reg;
assign dst_pprot_o = dst_pprot_reg;

// Control logic
always @(posedge src_pclk_i) begin
    if (src_psel_i && src_penable_i &&!fifo_full) begin
        fifo_write <= 1;
    end else begin
        fifo_write <= 0;
    end
end

always @(posedge dst_pclk_i) begin
    if (dst_pready_i &&!fifo_empty) begin
        fifo_read <= 1;
    end else begin
        fifo_read <= 0;
    end
end

endmodule
