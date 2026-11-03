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

reg [ADDR_WIDTH-1:0] fifo_addr;
reg [DATA_WIDTH-1:0] fifo_wdata;
reg [DATA_WIDTH/8-1:0] fifo_wstrb;
reg [2:0] fifo_wprot;
reg fifo_write;
reg fifo_read;
reg [DATA_WIDTH-1:0] fifo_rdata;
reg fifo_empty;
reg fifo_full;
reg [LOG_DEPTH-1:0] fifo_count;

reg src_pready_reg;
reg [DATA_WIDTH-1:0] src_prdata_reg;
reg src_pslverr_reg;
reg dst_psel_reg;
reg dst_penable_reg;
reg dst_pwrite_reg;
reg [ADDR_WIDTH-1:0] dst_paddr_reg;
reg [DATA_WIDTH-1:0] dst_pwdata_reg;
reg [DATA_WIDTH/8-1:0] dst_pstrb_reg;
reg [2:0] dst_pprot_reg;

always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (!src_preset_ni) begin
        src_pready_reg <= 1'b0;
        src_prdata_reg <= {DATA_WIDTH{1'b0}};
        src_pslverr_reg <= 1'b0;
    end else if (src_psel_i && src_penable_i) begin
        if (fifo_empty) begin
            fifo_addr <= src_paddr_i;
            fifo_wdata <= src_pwdata_i;
            fifo_wstrb <= src_pstrb_i;
            fifo_wprot <= src_pprot_i;
            fifo_write <= 1'b1;
        end else begin
            src_pready_reg <= 1'b0;
        end
    end else begin
        src_pready_reg <= 1'b0;
    end
end

always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (!dst_preset_ni) begin
        dst_psel_reg <= 1'b0;
        dst_penable_reg <= 1'b0;
        dst_pwrite_reg <= 1'b0;
        dst_paddr_reg <= {ADDR_WIDTH{1'b0}};
        dst_pwdata_reg <= {DATA_WIDTH{1'b0}};
        dst_pstrb_reg <= {DATA_WIDTH/8{1'b0}};
        dst_pprot_reg <= {3{1'b0}};
    end else if (fifo_read) begin
        dst_psel_reg <= 1'b1;
        dst_penable_reg <= 1'b1;
        dst_pwrite_reg <= fifo_write;
        dst_paddr_reg <= fifo_addr;
        dst_pwdata_reg <= fifo_wdata;
        dst_pstrb_reg <= fifo_wstrb;
        dst_pprot_reg <= fifo_wprot;
    end else begin
        dst_psel_reg <= 1'b0;
        dst_penable_reg <= 1'b0;
    end
end

always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (!dst_preset_ni) begin
        fifo_read <= 1'b0;
    end else if (dst_pready_i && dst_psel_reg && dst_penable_reg) begin
        fifo_read <= 1'b1;
    end else begin
        fifo_read <= 1'b0;
    end
end

always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (!src_preset_ni) begin
        src_prdata_reg <= {DATA_WIDTH{1'b0}};
        src_pslverr_reg <= 1'b0;
    end else if (fifo_empty && fifo_read) begin
        src_prdata_reg <= dst_prdata_i;
        src_pslverr_reg <= dst_pslverr_i;
        src_pready_reg <= 1'b1;
    end else begin
        src_pready_reg <= 1'b0;
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

// FIFO implementation
reg [ADDR_WIDTH-1:0] fifo_mem_addr [2**LOG_DEPTH-1:0];
reg [DATA_WIDTH-1:0] fifo_mem_wdata [2**LOG_DEPTH-1:0];
reg [DATA_WIDTH/8-1:0] fifo_mem_wstrb [2**LOG_DEPTH-1:0];
reg [2:0] fifo_mem_wprot [2**LOG_DEPTH-1:0];
reg [LOG_DEPTH-1:0] fifo_wr_ptr;
reg [LOG_DEPTH-1:0] fifo_rd_ptr;

always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (!src_preset_ni) begin
        fifo_wr_ptr <= {LOG_DEPTH{1'b0}};
        fifo_rd_ptr <= {LOG_DEPTH{1'b0}};
        fifo_empty <= 1'b1;
        fifo_full <= 1'b0;
    end else if (fifo_write) begin
        fifo_mem_addr[fifo_wr_ptr] <= fifo_addr;
        fifo_mem_wdata[fifo_wr_ptr] <= fifo_wdata;
        fifo_mem_wstrb[fifo_wr_ptr] <= fifo_wstrb;
        fifo_mem_wprot[fifo_wr_ptr] <= fifo_wprot;
        if (fifo_wr_ptr == (2**LOG_DEPTH)-1) begin
            fifo_wr_ptr <= {LOG_DEPTH{1'b0}};
        end else begin
            fifo_wr_ptr <= fifo_wr_ptr + 1'b1;
        end
        if (fifo_full) begin
            fifo_full <= 1'b0;
        end else begin
            fifo_empty <= 1'b0;
        end
    end else if (fifo_read) begin
        fifo_addr <= fifo_mem_addr[fifo_rd_ptr];
        fifo_wdata <= fifo_mem_wdata[fifo_rd_ptr];
        fifo_wstrb <= fifo_mem_wstrb[fifo_rd_ptr];
        fifo_wprot <= fifo_mem_wprot[fifo_rd_ptr];
        if (fifo_rd_ptr == (2**LOG_DEPTH)-1) begin
            fifo_rd_ptr <= {LOG_DEPTH{1'b0}};
        end else begin
            fifo_rd_ptr <= fifo_rd_ptr + 1'b1;
        end
        if (fifo_empty) begin
            fifo_empty <= 1'b1;
        end else begin
            fifo_full <= 1'b0;
        end
    end
end

assign fifo_empty = (fifo_wr_ptr == fifo_rd_ptr) &&!fifo_full;
assign fifo_full = (fifo_wr_ptr == (fifo_rd_ptr + 1'b1)) || ((fifo_wr_ptr == {LOG_DEPTH{1'b0}}) && (fifo_rd_ptr == (2**LOG_DEPTH)-1));

endmodule
