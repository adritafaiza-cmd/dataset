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

    reg [ADDR_WIDTH-1:0]        src_paddr;
    reg [DATA_WIDTH-1:0]        src_pwdata;
    reg [DATA_WIDTH/8-1:0]      src_pstrb;
    reg [2:0]                   src_pprot;
    reg                         src_pwrite;
    reg                         src_psel;
    reg                         src_penable;
    reg                         src_pready;
    reg [DATA_WIDTH-1:0]        src_prdata;
    reg                         src_pslverr;

    reg [ADDR_WIDTH-1:0]        dst_paddr;
    reg [DATA_WIDTH-1:0]        dst_pwdata;
    reg [DATA_WIDTH/8-1:0]      dst_pstrb;
    reg [2:0]                   dst_pprot;
    reg                         dst_pwrite;
    reg                         dst_psel;
    reg                         dst_penable;
    reg [DATA_WIDTH-1:0]        dst_prdata;
    reg                         dst_pslverr;

    reg                         src_valid;
    reg                         dst_valid;
    reg                         src_ready;
    reg                         dst_ready;

    reg [LOG_DEPTH-1:0]         src_fifo_ptr;
    reg [LOG_DEPTH-1:0]         dst_fifo_ptr;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_valid <= 1'b0;
            src_fifo_ptr <= '0;
            src_pready <= 1'b0;
            src_prdata <= '0;
            src_pslverr <= 1'b0;
        end else if (src_psel_i && src_penable_i) begin
            src_paddr <= src_paddr_i;
            src_pwdata <= src_pwdata_i;
            src_pstrb <= src_pstrb_i;
            src_pprot <= src_pprot_i;
            src_pwrite <= src_pwrite_i;
            src_psel <= src_psel_i;
            src_penable <= src_penable_i;
            src_valid <= 1'b1;
            src_fifo_ptr <= src_fifo_ptr + 1'b1;
        end else if (src_valid && src_ready) begin
            src_valid <= 1'b0;
            src_fifo_ptr <= '0;
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_valid <= 1'b0;
            dst_fifo_ptr <= '0;
            dst_psel_o <= 1'b0;
            dst_penable_o <= 1'b0;
            dst_pwrite_o <= 1'b0;
            dst_paddr_o <= '0;
            dst_pwdata_o <= '0;
            dst_pstrb_o <= '0;
            dst_pprot_o <= '0;
        end else if (dst_valid && dst_pready_i) begin
            dst_valid <= 1'b0;
            dst_fifo_ptr <= '0;
            dst_psel_o <= 1'b0;
            dst_penable_o <= 1'b0;
            dst_pwrite_o <= 1'b0;
            dst_paddr_o <= '0;
            dst_pwdata_o <= '0;
            dst_pstrb_o <= '0;
            dst_pprot_o <= '0;
        end else if (src_valid && !dst_valid) begin
            dst_psel_o <= src_psel;
            dst_penable_o <= src_penable;
            dst_pwrite_o <= src_pwrite;
            dst_paddr_o <= src_paddr;
            dst_pwdata_o <= src_pwdata;
            dst_pstrb_o <= src_pstrb;
            dst_pprot_o <= src_pprot;
            dst_valid <= 1'b1;
            dst_fifo_ptr <= dst_fifo_ptr + 1'b1;
        end
    end

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_ready <= 1'b0;
        end else if (dst_pready_i && dst_valid) begin
            src_ready <= 1'b1;
        end else if (src_valid && src_ready) begin
            src_ready <= 1'b0;
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_ready <= 1'b0;
        end else if (dst_pready_i && dst_valid) begin
            dst_ready <= 1'b1;
        end else if (dst_valid && dst_ready) begin
            dst_ready <= 1'b0;
        end
    end

    assign src_pready_o = src_pready;
    assign src_prdata_o = dst_prdata_i;
    assign src_pslverr_o = dst_pslverr_i;

endmodule
