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

reg src_pready_r;
reg [DATA_WIDTH-1:0] src_prdata_r;
reg src_pslverr_r;

reg dst_pready_r;
reg [DATA_WIDTH-1:0] dst_prdata_r;
reg dst_pslverr_r;

reg [LOG_DEPTH-1:0] src_fifo_empty_r;
reg [LOG_DEPTH-1:0] src_fifo_full_r;
reg [LOG_DEPTH-1:0] dst_fifo_empty_r;
reg [LOG_DEPTH-1:0] dst_fifo_full_r;

reg src_fifo_wr_r;
reg src_fifo_rd_r;
reg dst_fifo_wr_r;
reg dst_fifo_rd_r;

always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (!src_preset_ni) begin
        src_paddr_r <= {ADDR_WIDTH{1'b0}};
        src_pwdata_r <= {DATA_WIDTH{1'b0}};
        src_pstrb_r <= {DATA_WIDTH/8{1'b0}};
        src_pprot_r <= {3{1'b0}};
        src_pwrite_r <= 1'b0;
        src_penable_r <= 1'b0;
        src_psel_r <= 1'b0;
        src_pready_r <= 1'b0;
        src_prdata_r <= {DATA_WIDTH{1'b0}};
        src_pslverr_r <= 1'b0;
        src_fifo_empty_r <= {LOG_DEPTH{1'b1}};
        src_fifo_full_r <= {LOG_DEPTH{1'b0}};
        src_fifo_wr_r <= 1'b0;
        src_fifo_rd_r <= 1'b0;
    end else begin
        if (src_psel_i && src_penable_i) begin
            src_paddr_r <= src_paddr_i;
            src_pwdata_r <= src_pwdata_i;
            src_pstrb_r <= src_pstrb_i;
            src_pprot_r <= src_pprot_i;
            src_pwrite_r <= src_pwrite_i;
            src_penable_r <= src_penable_i;
            src_psel_r <= src_psel_i;
        end
        if (src_psel_i && src_penable_i && src_pready_r) begin
            src_pready_r <= 1'b0;
        end
        if (src_fifo_empty_r == {LOG_DEPTH{1'b0}} && src_psel_i && src_penable_i) begin
            src_fifo_wr_r <= 1'b1;
        end else begin
            src_fifo_wr_r <= 1'b0;
        end
        if (src_fifo_full_r == {LOG_DEPTH{1'b1}} && src_psel_i && src_penable_i) begin
            src_fifo_rd_r <= 1'b1;
        end else begin
            src_fifo_rd_r <= 1'b0;
        end
        if (src_fifo_wr_r) begin
            src_fifo_empty_r <= {LOG_DEPTH{1'b0}};
        end
        if (src_fifo_rd_r) begin
            src_fifo_full_r <= {LOG_DEPTH{1'b0}};
        end
    end
end

always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (!dst_preset_ni) begin
        dst_paddr_r <= {ADDR_WIDTH{1'b0}};
        dst_pwdata_r <= {DATA_WIDTH{1'b0}};
        dst_pstrb_r <= {DATA_WIDTH/8{1'b0}};
        dst_pprot_r <= {3{1'b0}};
        dst_pwrite_r <= 1'b0;
        dst_penable_r <= 1'b0;
        dst_psel_r <= 1'b0;
        dst_pready_r <= 1'b0;
        dst_prdata_r <= {DATA_WIDTH{1'b0}};
        dst_pslverr_r <= 1'b0;
        dst_fifo_empty_r <= {LOG_DEPTH{1'b1}};
        dst_fifo_full_r <= {LOG_DEPTH{1'b0}};
        dst_fifo_wr_r <= 1'b0;
        dst_fifo_rd_r <= 1'b0;
    end else begin
        if (dst_pready_i) begin
            dst_pready_r <= 1'b1;
        end
        if (dst_pready_i && dst_psel_r && dst_penable_r) begin
            dst_pready_r <= 1'b0;
        end
        if (dst_fifo_empty_r == {LOG_DEPTH{1'b0}} && dst_pready_i) begin
            dst_fifo_rd_r <= 1'b1;
        end else begin
            dst_fifo_rd_r <= 1'b0;
        end
        if (dst_fifo_full_r == {LOG_DEPTH{1'b1}} && dst_pready_i) begin
            dst_fifo_wr_r <= 1'b1;
        end else begin
            dst_fifo_wr_r <= 1'b0;
        end
        if (dst_fifo_wr_r) begin
            dst_fifo_empty_r <= {LOG_DEPTH{1'b0}};
        end
        if (dst_fifo_rd_r) begin
            dst_fifo_full_r <= {LOG_DEPTH{1'b0}};
        end
    end
end

always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (!src_preset_ni) begin
        src_psel_o <= 1'b0;
        src_penable_o <= 1'b0;
        src_pwrite_o <= 1'b0;
        src_paddr_o <= {ADDR_WIDTH{1'b0}};
        src_pwdata_o <= {DATA_WIDTH{1'b0}};
        src_pstrb_o <= {DATA_WIDTH/8{1'b0}};
        src_pprot_o <= {3{1'b0}};
    end else begin
        src_psel_o <= src_psel_r;
        src_penable_o <= src_penable_r;
        src_pwrite_o <= src_pwrite_r;
        src_paddr_o <= src_paddr_r;
        src_pwdata_o <= src_pwdata_r;
        src_pstrb_o <= src_pstrb_r;
        src_pprot_o <= src_pprot_r;
    end
end

always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (!dst_preset_ni) begin
        dst_psel_o <= 1'b0;
        dst_penable_o <= 1'b0;
        dst_pwrite_o <= 1'b0;
        dst_paddr_o <= {ADDR_WIDTH{1'b0}};
        dst_pwdata_o <= {DATA_WIDTH{1'b0}};
        dst_pstrb_o <= {DATA_WIDTH/8{1'b0}};
        dst_pprot_o <= {3{1'b0}};
    end else begin
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
assign src_prdata_o = src_prdata_r;
assign src_pslverr_o = src_pslverr_r;

assign dst_psel_o = dst_psel_r;
assign dst_penable_o = dst_penable_r;
assign dst_pwrite_o = dst_pwrite_r;
assign dst_paddr_o = dst_paddr_r;
assign dst_pwdata_o = dst_pwdata_r;
assign dst_pstrb_o = dst_pstrb_r;
assign dst_pprot_o = dst_pprot_r;

endmodule
