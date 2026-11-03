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

    reg [ADDR_WIDTH-1:0]       addr;
    reg [DATA_WIDTH-1:0]       wdata;
    reg [DATA_WIDTH/8-1:0]     wstrb;
    reg [2:0]                  wprot;
    reg                        write;
    reg                        valid;
    reg                        ready;
    reg                        error;

    reg [DATA_WIDTH-1:0]       rdata;
    reg                        rerror;

    reg                        src_valid;
    reg                        dst_valid;

    reg                        src_psel;
    reg                        src_penable;
    reg                        src_pwrite;
    reg [ADDR_WIDTH-1:0]       src_paddr;
    reg [DATA_WIDTH-1:0]       src_pwdata;
    reg [DATA_WIDTH/8-1:0]     src_pstrb;
    reg [2:0]                  src_pprot;

    reg                        dst_psel;
    reg                        dst_penable;
    reg                        dst_pwrite;
    reg [ADDR_WIDTH-1:0]       dst_paddr;
    reg [DATA_WIDTH-1:0]       dst_pwdata;
    reg [DATA_WIDTH/8-1:0]     dst_pstrb;
    reg [2:0]                  dst_pprot;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_valid <= 1'b0;
            src_psel <= 1'b0;
            src_penable <= 1'b0;
            src_pwrite <= 1'b0;
            src_paddr <= 'h0;
            src_pwdata <= 'h0;
            src_pstrb <= 'h0;
            src_pprot <= 'h0;
        end else if (src_psel_i && src_penable_i) begin
            src_valid <= 1'b1;
            src_psel <= src_psel_i;
            src_penable <= src_penable_i;
            src_pwrite <= src_pwrite_i;
            src_paddr <= src_paddr_i;
            src_pwdata <= src_pwdata_i;
            src_pstrb <= src_pstrb_i;
            src_pprot <= src_pprot_i;
        end else begin
            src_valid <= 1'b0;
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_valid <= 1'b0;
            dst_psel <= 1'b0;
            dst_penable <= 1'b0;
            dst_pwrite <= 1'b0;
            dst_paddr <= 'h0;
            dst_pwdata <= 'h0;
            dst_pstrb <= 'h0;
            dst_pprot <= 'h0;
        end else if (src_valid &&!dst_valid) begin
            dst_valid <= 1'b1;
            dst_psel <= src_psel;
            dst_penable <= src_penable;
            dst_pwrite <= src_pwrite;
            dst_paddr <= src_paddr;
            dst_pwdata <= src_pwdata;
            dst_pstrb <= src_pstrb;
            dst_pprot <= src_pprot;
        end else if (dst_pready_i) begin
            dst_valid <= 1'b0;
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            rdata <= 'h0;
            rerror <= 1'b0;
        end else if (dst_pready_i) begin
            rdata <= dst_prdata_i;
            rerror <= dst_pslverr_i;
        end
    end

    assign src_pready_o = (dst_valid && dst_pready_i);
    assign src_prdata_o = rdata;
    assign src_pslverr_o = rerror;

    assign dst_psel_o = dst_psel;
    assign dst_penable_o = dst_penable;
    assign dst_pwrite_o = dst_pwrite;
    assign dst_paddr_o = dst_paddr;
    assign dst_pwdata_o = dst_pwdata;
    assign dst_pstrb_o = dst_pstrb;
    assign dst_pprot_o = dst_pprot;

endmodule
