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

    wire [ADDR_WIDTH-1:0] addr_stage_dout;
    wire [DATA_WIDTH-1:0] wdata_stage_dout;
    wire [DATA_WIDTH/8-1:0] strb_stage_dout;
    wire [2:0] prot_stage_dout;
    wire write_stage_dout;
    wire ready_stage_dout;
    wire [DATA_WIDTH-1:0] rdata_stage_dout;
    wire slverr_stage_dout;
    wire psel_sync_dout;
    wire penable_sync_dout;

    sync_stage #(
        .WIDTH(ADDR_WIDTH)
    ) addr_stage (
        .din(src_paddr_i),
        .clk(src_pclk_i),
        .rst_n(src_preset_ni),
        .dout(addr_stage_dout)
    );

    sync_stage #(
        .WIDTH(DATA_WIDTH)
    ) wdata_stage (
        .din(src_pwdata_i),
        .clk(src_pclk_i),
        .rst_n(src_preset_ni),
        .dout(wdata_stage_dout)
    );

    sync_stage #(
        .WIDTH(DATA_WIDTH/8)
    ) strb_stage (
        .din(src_pstrb_i),
        .clk(src_pclk_i),
        .rst_n(src_preset_ni),
        .dout(strb_stage_dout)
    );

    sync_stage #(
        .WIDTH(3)
    ) prot_stage (
        .din(src_pprot_i),
        .clk(src_pclk_i),
        .rst_n(src_preset_ni),
        .dout(prot_stage_dout)
    );

    sync_stage #(
        .WIDTH(1)
    ) write_stage (
        .din(src_pwrite_i),
        .clk(src_pclk_i),
        .rst_n(src_preset_ni),
        .dout(write_stage_dout)
    );

    sync_stage #(
        .WIDTH(1)
    ) ready_stage (
        .din(dst_pready_i),
        .clk(dst_pclk_i),
        .rst_n(dst_preset_ni),
        .dout(ready_stage_dout)
    );

    sync_stage #(
        .WIDTH(DATA_WIDTH)
    ) rdata_stage (
        .din(dst_prdata_i),
        .clk(dst_pclk_i),
        .rst_n(dst_preset_ni),
        .dout(rdata_stage_dout)
    );

    sync_stage #(
        .WIDTH(1)
    ) slverr_stage (
        .din(dst_pslverr_i),
        .clk(dst_pclk_i),
        .rst_n(dst_preset_ni),
        .dout(slverr_stage_dout)
    );

    sync_flop #(
        .WIDTH(1)
    ) psel_sync (
        .din(src_psel_i),
        .clk(src_pclk_i),
        .rst_n(src_preset_ni),
        .dout(psel_sync_dout)
    );

    sync_flop #(
        .WIDTH(1)
    ) penable_sync (
        .din(src_penable_i),
        .clk(src_pclk_i),
        .rst_n(src_preset_ni),
        .dout(penable_sync_dout)
    );

    assign dst_paddr_o = addr_stage_dout;
    assign dst_pwdata_o = wdata_stage_dout;
    assign dst_pstrb_o = strb_stage_dout;
    assign dst_pprot_o = prot_stage_dout;
    assign dst_pwrite_o = write_stage_dout;
    assign src_pready_o = ready_stage_dout;
    assign src_prdata_o = rdata_stage_dout;
    assign src_pslverr_o = slverr_stage_dout;
    assign dst_psel_o = psel_sync_dout;
    assign dst_penable_o = penable_sync_dout;

endmodule

module sync_stage #(
    parameter WIDTH = 1
)(
    input  [WIDTH-1:0] din,
    input              clk,
    input              rst_n,
    output [WIDTH-1:0] dout
);

    reg [WIDTH-1:0] stage1;
    reg [WIDTH-1:0] stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1 <= {WIDTH{1'b0}};
            stage2 <= {WIDTH{1'b0}};
        end else begin
            stage1 <= din;
            stage2 <= stage1;
        end
    end

    assign dout = stage2;

endmodule

module sync_flop #(
    parameter WIDTH = 1
)(
    input  [WIDTH-1:0] din,
    input              clk,
    input              rst_n,
    output [WIDTH-1:0] dout
);

    reg [WIDTH-1:0] flop;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            flop <= {WIDTH{1'b0}};
        end else begin
            flop <= din;
        end
    end

    assign dout = flop;

endmodule
