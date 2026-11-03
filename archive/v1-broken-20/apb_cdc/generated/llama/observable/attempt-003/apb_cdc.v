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
reg src_pready_r;
reg [DATA_WIDTH-1:0] src_prdata_r;
reg src_pslverr_r;

reg [ADDR_WIDTH-1:0] dst_paddr_r;
reg [DATA_WIDTH-1:0] dst_pwdata_r;
reg [DATA_WIDTH/8-1:0] dst_pstrb_r;
reg [2:0] dst_pprot_r;
reg dst_pwrite_r;
reg dst_penable_r;
reg dst_psel_r;
reg dst_pready_r;
reg [DATA_WIDTH-1:0] dst_prdata_r;
reg dst_pslverr_r;

reg [LOG_DEPTH-1:0] src_fifo_empty_r;
reg [LOG_DEPTH-1:0] src_fifo_full_r;
reg [LOG_DEPTH-1:0] dst_fifo_empty_r;
reg [LOG_DEPTH-1:0] dst_fifo_full_r;

wire src_fifo_write;
wire src_fifo_read;
wire dst_fifo_write;
wire dst_fifo_read;

assign src_fifo_write = src_penable_i && src_psel_i && !src_pready_r;
assign src_fifo_read = src_pready_r && src_penable_r && src_psel_r;
assign dst_fifo_write = dst_penable_r && dst_psel_r && dst_pready_i;
assign dst_fifo_read = dst_pready_i && dst_penable_r && dst_psel_r;

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
    end else if (src_psel_i && src_penable_i) begin
        src_paddr_r <= src_paddr_i;
        src_pwdata_r <= src_pwdata_i;
        src_pstrb_r <= src_pstrb_i;
        src_pprot_r <= src_pprot_i;
        src_pwrite_r <= src_pwrite_i;
        src_penable_r <= src_penable_i;
        src_psel_r <= src_psel_i;
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
    end else if (dst_psel_r && dst_penable_r) begin
        dst_paddr_r <= src_paddr_r;
        dst_pwdata_r <= src_pwdata_r;
        dst_pstrb_r <= src_pstrb_r;
        dst_pprot_r <= src_pprot_r;
        dst_pwrite_r <= src_pwrite_r;
        dst_penable_r <= src_penable_r;
        dst_psel_r <= src_psel_r;
    end
end

always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (!src_preset_ni) begin
        src_pready_o <= 1'b0;
        src_prdata_o <= {DATA_WIDTH{1'b0}};
        src_pslverr_o <= 1'b0;
    end else if (src_penable_i && src_psel_i) begin
        if (src_fifo_empty_r == {LOG_DEPTH{1'b0}}) begin
            src_pready_o <= 1'b1;
        end else begin
            src_pready_o <= 1'b0;
        end
        if (src_fifo_read) begin
            src_prdata_o <= dst_prdata_r;
            src_pslverr_o <= dst_pslverr_r;
        end
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
    end else if (dst_penable_r && dst_psel_r) begin
        dst_psel_o <= dst_psel_r;
        dst_penable_o <= dst_penable_r;
        dst_pwrite_o <= dst_pwrite_r;
        dst_paddr_o <= dst_paddr_r;
        dst_pwdata_o <= dst_pwdata_r;
        dst_pstrb_o <= dst_pstrb_r;
        dst_pprot_o <= dst_pprot_r;
    end
end

always @(posedge src_pclk_i or negedge src_preset_ni) begin
    if (!src_preset_ni) begin
        src_fifo_empty_r <= {LOG_DEPTH{1'b1}};
        src_fifo_full_r <= {LOG_DEPTH{1'b0}};
    end else if (src_fifo_write && !src_fifo_read) begin
        src_fifo_empty_r <= {LOG_DEPTH{1'b0}};
        src_fifo_full_r <= src_fifo_full_r + 1'b1;
    end else if (!src_fifo_write && src_fifo_read) begin
        src_fifo_empty_r <= src_fifo_empty_r + 1'b1;
        src_fifo_full_r <= {LOG_DEPTH{1'b0}};
    end
end

always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
    if (!dst_preset_ni) begin
        dst_fifo_empty_r <= {LOG_DEPTH{1'b1}};
        dst_fifo_full_r <= {LOG_DEPTH{1'b0}};
    end else if (dst_fifo_write && !dst_fifo_read) begin
        dst_fifo_empty_r <= {LOG_DEPTH{1'b0}};
        dst_fifo_full_r <= dst_fifo_full_r + 1'b1;
    end else if (!dst_fifo_write && dst_fifo_read) begin
        dst_fifo_empty_r <= dst_fifo_empty_r + 1'b1;
        dst_fifo_full_r <= {LOG_DEPTH{1'b0}};
    end
end

endmodule
