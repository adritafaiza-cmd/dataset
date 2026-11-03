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

    reg                      src_pready_r;
    reg [DATA_WIDTH-1:0]       src_prdata_r;
    reg                      src_pslverr_r;

    reg                      dst_psel_r;
    reg                      dst_penable_r;
    reg                      dst_pwrite_r;
    reg [ADDR_WIDTH-1:0]       dst_paddr_r;
    reg [DATA_WIDTH-1:0]       dst_pwdata_r;
    reg [DATA_WIDTH/8-1:0]     dst_pstrb_r;
    reg [2:0]                  dst_pprot_r;

    reg                      fifo_valid;
    wire                     fifo_ready;
    wire [DATA_WIDTH-1:0]      fifo_data;

    fifo #(
        .WIDTH(DATA_WIDTH),
        .DEPTH(1 << LOG_DEPTH)
    ) src_to_dst_fifo (
        .clk(src_pclk_i),
        .reset(src_preset_ni),
        .din(src_pwdata_i),
        .we(src_penable_i & src_psel_i),
        .full(fifo_valid),
        .empty(fifo_ready),
        . dout(fifo_data)
    );

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_pready_r <= 1'b0;
            src_prdata_r <= {DATA_WIDTH{1'b0}};
            src_pslverr_r <= 1'b0;
        end else begin
            if (src_psel_i && src_penable_i) begin
                src_pready_r <= 1'b0;
            end else if (dst_pready_i) begin
                src_pready_r <= 1'b1;
            end
            if (src_psel_i && src_penable_i) begin
                src_prdata_r <= dst_prdata_i;
                src_pslverr_r <= dst_pslverr_i;
            end
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_psel_r <= 1'b0;
            dst_penable_r <= 1'b0;
            dst_pwrite_r <= 1'b0;
            dst_paddr_r <= {ADDR_WIDTH{1'b0}};
            dst_pwdata_r <= {DATA_WIDTH{1'b0}};
            dst_pstrb_r <= {DATA_WIDTH/8{1'b0}};
            dst_pprot_r <= 3'b000;
        end else begin
            if (fifo_valid) begin
                dst_psel_r <= 1'b1;
                dst_penable_r <= 1'b1;
                dst_pwrite_r <= src_pwrite_i;
                dst_paddr_r <= src_paddr_i;
                dst_pwdata_r <= src_pwdata_i;
                dst_pstrb_r <= src_pstrb_i;
                dst_pprot_r <= src_pprot_i;
            end else begin
                dst_psel_r <= 1'b0;
                dst_penable_r <= 1'b0;
                dst_pwrite_r <= 1'b0;
                dst_paddr_r <= {ADDR_WIDTH{1'b0}};
                dst_pwdata_r <= {DATA_WIDTH{1'b0}};
                dst_pstrb_r <= {DATA_WIDTH/8{1'b0}};
                dst_pprot_r <= 3'b000;
            end
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
