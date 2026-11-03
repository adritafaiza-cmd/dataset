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

    reg [ADDR_WIDTH-1:0]       fifo_addr;
    reg [DATA_WIDTH-1:0]       fifo_wdata;
    reg [DATA_WIDTH/8-1:0]     fifo_wstrb;
    reg [2:0]                  fifo_pprot;
    reg                        fifo_write;
    reg                        fifo_valid;
    reg                        fifo_empty;
    reg                        dst_valid;
    reg                        dst_write;
    reg [DATA_WIDTH-1:0]       dst_rdata;
    reg                        dst_error;

    assign src_pready_o = fifo_empty &&!fifo_valid;
    assign src_prdata_o = dst_rdata;
    assign src_pslverr_o = dst_error;

    assign dst_psel_o = dst_valid;
    assign dst_penable_o = dst_valid && dst_pready_i;
    assign dst_pwrite_o = dst_write;
    assign dst_paddr_o = fifo_addr;
    assign dst_pwdata_o = fifo_wdata;
    assign dst_pstrb_o = fifo_wstrb;
    assign dst_pprot_o = fifo_pprot;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            fifo_valid <= 1'b0;
            fifo_empty <= 1'b1;
        end else if (src_psel_i && src_penable_i) begin
            if (fifo_empty) begin
                fifo_addr <= src_paddr_i;
                fifo_wdata <= src_pwdata_i;
                fifo_wstrb <= src_pstrb_i;
                fifo_pprot <= src_pprot_i;
                fifo_write <= src_pwrite_i;
                fifo_valid <= 1'b1;
                fifo_empty <= 1'b0;
            end
        end else if (dst_pready_i && dst_valid) begin
            fifo_valid <= 1'b0;
            fifo_empty <= 1'b1;
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_valid <= 1'b0;
            dst_write <= 1'b0;
            dst_rdata <= {DATA_WIDTH{1'b0}};
            dst_error <= 1'b0;
        end else if (fifo_valid &&!dst_valid) begin
            dst_valid <= 1'b1;
            dst_write <= fifo_write;
        end else if (dst_pready_i && dst_valid) begin
            dst_valid <= 1'b0;
            dst_rdata <= dst_prdata_i;
            dst_error <= dst_pslverr_i;
        end
    end

endmodule
