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

    wire [ADDR_WIDTH-1:0] synced_paddr;
    wire [DATA_WIDTH-1:0] synced_pwdata;
    wire [DATA_WIDTH/8-1:0] synced_pstrb;
    wire [2:0]            synced_pprot;
    wire                  synced_pwrite;
    wire                  synced_psel;
    wire                  synced_penable;
    wire                  synced_pready;
    wire [DATA_WIDTH-1:0] synced_prdata;
    wire                  synced_pslverr;

    sync_stage #(.WIDTH(ADDR_WIDTH)) addr_sync (
        .src_clk_i(src_pclk_i),
        .src_rst_ni(src_preset_ni),
        .src_data_i(src_paddr_i),
        .dst_clk_i(dst_pclk_i),
        .dst_rst_ni(dst_preset_ni),
        .dst_data_o(synced_paddr)
    );

    sync_stage #(.WIDTH(DATA_WIDTH)) data_sync (
        .src_clk_i(src_pclk_i),
        .src_rst_ni(src_preset_ni),
        .src_data_i(src_pwdata_i),
        .dst_clk_i(dst_pclk_i),
        .dst_rst_ni(dst_preset_ni),
        .dst_data_o(synced_pwdata)
    );

    sync_stage #(.WIDTH(DATA_WIDTH/8)) strb_sync (
        .src_clk_i(src_pclk_i),
        .src_rst_ni(src_preset_ni),
        .src_data_i(src_pstrb_i),
        .dst_clk_i(dst_pclk_i),
        .dst_rst_ni(dst_preset_ni),
        .dst_data_o(synced_pstrb)
    );

    sync_stage #(.WIDTH(3)) prot_sync (
        .src_clk_i(src_pclk_i),
        .src_rst_ni(src_preset_ni),
        .src_data_i(src_pprot_i),
        .dst_clk_i(dst_pclk_i),
        .dst_rst_ni(dst_preset_ni),
        .dst_data_o(synced_pprot)
    );

    sync_stage #(.WIDTH(1)) write_sync (
        .src_clk_i(src_pclk_i),
        .src_rst_ni(src_preset_ni),
        .src_data_i(src_pwrite_i),
        .dst_clk_i(dst_pclk_i),
        .dst_rst_ni(dst_preset_ni),
        .dst_data_o(synced_pwrite)
    );

    sync_stage #(.WIDTH(1)) sel_sync (
        .src_clk_i(src_pclk_i),
        .src_rst_ni(src_preset_ni),
        .src_data_i(src_psel_i),
        .dst_clk_i(dst_pclk_i),
        .dst_rst_ni(dst_preset_ni),
        .dst_data_o(synced_psel)
    );

    sync_stage #(.WIDTH(1)) enable_sync (
        .src_clk_i(src_pclk_i),
        .src_rst_ni(src_preset_ni),
        .src_data_i(src_penable_i),
        .dst_clk_i(dst_pclk_i),
        .dst_rst_ni(dst_preset_ni),
        .dst_data_o(synced_penable)
    );

    sync_stage #(.WIDTH(1)) ready_sync (
        .src_clk_i(dst_pclk_i),
        .src_rst_ni(dst_preset_ni),
        .src_data_i(dst_pready_i),
        .dst_clk_i(src_pclk_i),
        .dst_rst_ni(src_preset_ni),
        .dst_data_o(synced_pready)
    );

    sync_stage #(.WIDTH(DATA_WIDTH)) rdata_sync (
        .src_clk_i(dst_pclk_i),
        .src_rst_ni(dst_preset_ni),
        .src_data_i(dst_prdata_i),
        .dst_clk_i(src_pclk_i),
        .dst_rst_ni(src_preset_ni),
        .dst_data_o(synced_prdata)
    );

    sync_stage #(.WIDTH(1)) slverr_sync (
        .src_clk_i(dst_pclk_i),
        .src_rst_ni(dst_preset_ni),
        .src_data_i(dst_pslverr_i),
        .dst_clk_i(src_pclk_i),
        .dst_rst_ni(src_preset_ni),
        .dst_data_o(synced_pslverr)
    );

    assign dst_paddr_o    = synced_paddr;
    assign dst_pwdata_o   = synced_pwdata;
    assign dst_pstrb_o    = synced_pstrb;
    assign dst_pprot_o    = synced_pprot;
    assign dst_pwrite_o   = synced_pwrite;
    assign dst_psel_o     = synced_psel;
    assign dst_penable_o  = synced_penable;

    assign src_pready_o   = synced_pready;
    assign src_prdata_o   = synced_prdata;
    assign src_pslverr_o  = synced_pslverr;

endmodule

module sync_stage #(
    parameter WIDTH = 1
)(
    input                       src_clk_i,
    input                       src_rst_ni,
    input  [WIDTH-1:0]          src_data_i,
    input                       dst_clk_i,
    input                       dst_rst_ni,
    output reg [WIDTH-1:0]      dst_data_o
);

    reg [WIDTH-1:0] sync_reg1;
    reg [WIDTH-1:0] sync_reg2;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            sync_reg1 <= {WIDTH{1'b0}};
            sync_reg2 <= {WIDTH{1'b0}};
        end else begin
            sync_reg1 <= src_data_i;
            sync_reg2 <= sync_reg1;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_data_o <= {WIDTH{1'b0}};
        end else begin
            dst_data_o <= sync_reg2;
        end
    end

endmodule
