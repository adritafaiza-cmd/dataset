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

    // Internal signals
    reg [ADDR_WIDTH-1:0]    src_paddr_ff;
    reg [DATA_WIDTH-1:0]    src_pwdata_ff;
    reg  [DATA_WIDTH/8-1:0]  src_pstrb_ff;
    reg  [2:0]               src_pprot_ff;
    reg                      src_pwrite_ff;
    reg                      src_psel_ff;
    reg                      src_penable_ff;
    reg                      src_pready_ff;
    reg                      dst_psel_ff;
    reg                      dst_penable_ff;
    reg                      dst_pwrite_ff;
    reg [ADDR_WIDTH-1:0]    dst_paddr_ff;
    reg [DATA_WIDTH-1:0]    dst_pwdata_ff;
    reg  [DATA_WIDTH/8-1:0]  dst_pstrb_ff;
    reg  [2:0]               dst_pprot_ff;
    reg                      dst_pready_ff;
    reg [DATA_WIDTH-1:0]    dst_prdata_ff;
    reg                      dst_pslverr_ff;

    // Synchronizer for source signals
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_paddr_ff <= 0;
            src_pwdata_ff <= 0;
            src_pstrb_ff <= 0;
            src_pprot_ff <= 0;
            src_pwrite_ff <= 0;
            src_psel_ff <= 0;
            src_penable_ff <= 0;
            src_pready_ff <= 0;
        end else begin
            src_paddr_ff <= src_paddr_i;
            src_pwdata_ff <= src_pwdata_i;
            src_pstrb_ff <= src_pstrb_i;
            src_pprot_ff <= src_pprot_i;
            src_pwrite_ff <= src_pwrite_i;
            src_psel_ff <= src_psel_i;
            src_penable_ff <= src_penable_i;
            src_pready_ff <= src_pready_o;
        end
    end

    // Synchronizer for destination signals
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_psel_ff <= 0;
            dst_penable_ff <= 0;
            dst_pwrite_ff <= 0;
            dst_paddr_ff <= 0;
            dst_pwdata_ff <= 0;
            dst_pstrb_ff <= 0;
            dst_pprot_ff <= 0;
            dst_pready_ff <= 0;
            dst_prdata_ff <= 0;
            dst_pslverr_ff <= 0;
        end else begin
            dst_psel_ff <= dst_psel_o;
            dst_penable_ff <= dst_penable_o;
            dst_pwrite_ff <= dst_pwrite_o;
            dst_paddr_ff <= dst_paddr_o;
            dst_pwdata_ff <= dst_pwdata_o;
            dst_pstrb_ff <= dst_pstrb_o;
            dst_pprot_ff <= dst_pprot_o;
            dst_pready_ff <= dst_pready_i;
            dst_prdata_ff <= dst_prdata_i;
            dst_pslverr_ff <= dst_pslverr_i;
        end
    end

    // Drive destination signals
    assign dst_psel_o = src_psel_ff;
    assign dst_penable_o = src_penable_ff;
    assign dst_pwrite_o = src_pwrite_ff;
    assign dst_paddr_o = src_paddr_ff;
    assign dst_pwdata_o = src_pwdata_ff;
    assign dst_pstrb_o = src_pstrb_ff;
    assign dst_pprot_o = src_pprot_ff;

    // Drive source signals
    assign src_pready_o = dst_pready_ff;
    assign src_prdata_o = dst_prdata_ff;
    assign src_pslverr_o = dst_pslverr_ff;

endmodule
