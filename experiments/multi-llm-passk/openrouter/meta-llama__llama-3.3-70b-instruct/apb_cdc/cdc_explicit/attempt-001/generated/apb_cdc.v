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

    reg [ADDR_WIDTH-1:0]        src_paddr_sync;
    reg [DATA_WIDTH-1:0]        src_pwdata_sync;
    reg [DATA_WIDTH/8-1:0]      src_pstrb_sync;
    reg [2:0]                   src_pprot_sync;
    reg                         src_pwrite_sync;
    reg                         src_psel_sync;
    reg                         src_penable_sync;

    reg [ADDR_WIDTH-1:0]        dst_paddr_sync;
    reg [DATA_WIDTH-1:0]        dst_pwdata_sync;
    reg [DATA_WIDTH/8-1:0]      dst_pstrb_sync;
    reg [2:0]                   dst_pprot_sync;
    reg                         dst_pwrite_sync;
    reg                         dst_psel_sync;
    reg                         dst_penable_sync;

    reg                         src_pready_sync;
    reg [DATA_WIDTH-1:0]        src_prdata_sync;
    reg                         src_pslverr_sync;

    reg [LOG_DEPTH-1:0]         src_fifo_ptr;
    reg [LOG_DEPTH-1:0]         dst_fifo_ptr;

    reg                         src_valid;
    reg                         dst_valid;

    reg                         src_preset_sync;
    reg                         dst_preset_sync;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (~src_preset_ni) begin
            src_paddr_sync <= 0;
            src_pwdata_sync <= 0;
            src_pstrb_sync <= 0;
            src_pprot_sync <= 0;
            src_pwrite_sync <= 0;
            src_psel_sync <= 0;
            src_penable_sync <= 0;
            src_preset_sync <= 0;
            src_valid <= 0;
        end else begin
            src_preset_sync <= src_preset_ni;
            if (src_psel_i && src_penable_i) begin
                src_paddr_sync <= src_paddr_i;
                src_pwdata_sync <= src_pwdata_i;
                src_pstrb_sync <= src_pstrb_i;
                src_pprot_sync <= src_pprot_i;
                src_pwrite_sync <= src_pwrite_i;
                src_psel_sync <= src_psel_i;
                src_penable_sync <= src_penable_i;
                src_valid <= 1;
            end else begin
                src_valid <= 0;
            end
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (~dst_preset_ni) begin
            dst_paddr_sync <= 0;
            dst_pwdata_sync <= 0;
            dst_pstrb_sync <= 0;
            dst_pprot_sync <= 0;
            dst_pwrite_sync <= 0;
            dst_psel_sync <= 0;
            dst_penable_sync <= 0;
            dst_preset_sync <= 0;
            dst_valid <= 0;
        end else begin
            dst_preset_sync <= dst_preset_ni;
            if (dst_pready_i) begin
                dst_valid <= 0;
            end else if (src_valid) begin
                dst_paddr_sync <= src_paddr_sync;
                dst_pwdata_sync <= src_pwdata_sync;
                dst_pstrb_sync <= src_pstrb_sync;
                dst_pprot_sync <= src_pprot_sync;
                dst_pwrite_sync <= src_pwrite_sync;
                dst_psel_sync <= src_psel_sync;
                dst_penable_sync <= src_penable_sync;
                dst_valid <= 1;
            end
        end
    end

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (~src_preset_ni) begin
            src_pready_sync <= 0;
            src_prdata_sync <= 0;
            src_pslverr_sync <= 0;
        end else begin
            if (dst_valid && dst_pready_i) begin
                src_pready_sync <= 1;
                src_prdata_sync <= dst_prdata_i;
                src_pslverr_sync <= dst_pslverr_i;
            end else begin
                src_pready_sync <= 0;
            end
        end
    end

    assign src_pready_o = src_pready_sync;
    assign src_prdata_o = src_prdata_sync;
    assign src_pslverr_o = src_pslverr_sync;

    assign dst_psel_o = dst_psel_sync;
    assign dst_penable_o = dst_penable_sync;
    assign dst_pwrite_o = dst_pwrite_sync;
    assign dst_paddr_o = dst_paddr_sync;
    assign dst_pwdata_o = dst_pwdata_sync;
    assign dst_pstrb_o = dst_pstrb_sync;
    assign dst_pprot_o = dst_pprot_sync;

endmodule
