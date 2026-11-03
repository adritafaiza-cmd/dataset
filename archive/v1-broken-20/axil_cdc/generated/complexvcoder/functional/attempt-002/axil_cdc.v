module axil_cdc #
(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = (DATA_WIDTH/8)
)
(
    input  wire                   s_clk,
    input  wire                   s_rst,
    input  wire [ADDR_WIDTH-1:0]  s_axil_awaddr,
    input  wire [2:0]             s_axil_awprot,
    input  wire                   s_axil_awvalid,
    output wire                   s_axil_awready,
    input  wire [DATA_WIDTH-1:0]  s_axil_wdata,
    input  wire [STRB_WIDTH-1:0]  s_axil_wstrb,
    input  wire                   s_axil_wvalid,
    output wire                   s_axil_wready,
    output wire [1:0]             s_axil_bresp,
    output wire                   s_axil_bvalid,
    input  wire                   s_axil_bready,
    input  wire [ADDR_WIDTH-1:0]  s_axil_araddr,
    input  wire [2:0]             s_axil_arprot,
    input  wire                   s_axil_arvalid,
    output wire                   s_axil_arready,
    output wire [DATA_WIDTH-1:0]  s_axil_rdata,
    output wire [1:0]             s_axil_rresp,
    output wire                   s_axil_rvalid,
    input  wire                   s_axil_rready,
    input  wire                   m_clk,
    input  wire                   m_rst,
    output wire [ADDR_WIDTH-1:0]  m_axil_awaddr,
    output wire [2:0]             m_axil_awprot,
    output wire                   m_axil_awvalid,
    input  wire                   m_axil_awready,
    output wire [DATA_WIDTH-1:0]  m_axil_wdata,
    output wire [STRB_WIDTH-1:0]  m_axil_wstrb,
    output wire                   m_axil_wvalid,
    input  wire                   m_axil_wready,
    input  wire [1:0]             m_axil_bresp,
    input  wire                   m_axil_bvalid,
    output wire                   m_axil_bready,
    output wire [ADDR_WIDTH-1:0]  m_axil_araddr,
    output wire [2:0]             m_axil_arprot,
    output wire                   m_axil_arvalid,
    input  wire                   m_axil_arready,
    input  wire [DATA_WIDTH-1:0]  m_axil_rdata,
    input  wire [1:0]             m_axil_rresp,
    input  wire                   m_axil_rvalid,
    output wire                   m_axil_rready
);

    // Internal signals for synchronization
    logic [ADDR_WIDTH-1:0] awaddr_sync;
    logic [2:0] awprot_sync;
    logic awvalid_sync;
    logic awready_sync;
    logic [DATA_WIDTH-1:0] wdata_sync;
    logic [STRB_WIDTH-1:0] wstrb_sync;
    logic wvalid_sync;
    logic wready_sync;
    logic bresp_sync;
    logic bvalid_sync;
    logic bready_sync;
    logic [ADDR_WIDTH-1:0] araddr_sync;
    logic [2:0] arprot_sync;
    logic arvalid_sync;
    logic arready_sync;
    logic [DATA_WIDTH-1:0] rdata_sync;
    logic [1:0] rresp_sync;
    logic rvalid_sync;
    logic rready_sync;

    // Write transaction FIFO
    sync_fifo #(
        .DATA_WIDTH(ADDR_WIDTH + 2*3 + 1),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) write_fifo (
        .clk(s_clk),
        .rst(s_rst),
        .data_in({s_axil_awaddr, s_axil_awprot, s_axil_awvalid}),
        .valid_in(s_axil_awvalid),
        .ready_out(s_axil_awready),
        .data_out({awaddr_sync, awprot_sync, awvalid_sync}),
        .valid_out(awready_sync),
        .ready_in(m_axil_awready)
    );

    // Read transaction FIFO
    sync_fifo #(
        .DATA_WIDTH(ADDR_WIDTH + 2*3 + 1),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) read_fifo (
        .clk(s_clk),
        .rst(s_rst),
        .data_in({s_axil_araddr, s_axil_arprot, s_axil_arvalid}),
        .valid_in(s_axil_arvalid),
        .ready_out(s_axil_arready),
        .data_out({araddr_sync, arprot_sync, arvalid_sync}),
        .valid_out(arready_sync),
        .ready_in(m_axil_arready)
    );

    // Write response FIFO
    sync_fifo #(
        .DATA_WIDTH(2 + 1),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) write_response_fifo (
        .clk(m_clk),
        .rst(m_rst),
        .data_in({m_axil_bresp, m_axil_bvalid}),
        .valid_in(m_axil_bvalid),
        .ready_out(m_axil_bready),
        .data_out({bresp_sync, bvalid_sync}),
        .valid_out(m_axil_bvalid),
        .ready_in(s_axil_bready)
    );

    // Read response FIFO
    sync_fifo #(
        .DATA_WIDTH(DATA_WIDTH + 2 + 1),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) read_response_fifo (
        .clk(m_clk),
        .rst(m_rst),
        .data_in({m_axil_rdata, m_axil_rresp, m_axil_rvalid}),
        .valid_in(m_axil_rvalid),
        .ready_out(m_axil_rready),
        .data_out({rdata_sync, rresp_sync, rvalid_sync}),
        .valid_out(m_axil_rvalid),
        .ready_in(s_axil_rready)
    );

    // Master interface signals
    assign m_axil_awaddr = awaddr_sync;
    assign m_axil_awprot = awprot_sync;
    assign m_axil_awvalid = awvalid_sync;
    assign s_axil_awready = awready_sync;

    assign m_axil_wdata = wdata_sync;
    assign m_axil_wstrb = wstrb_sync;
    assign m_axil_wvalid = wvalid_sync;
    assign s_axil_wready = wready_sync;

    assign m_axil_araddr = araddr_sync;
    assign m_axil_arprot = arprot_sync;
    assign m_axil_arvalid = arvalid_sync;
    assign s_axil_arready = arready_sync;

    assign m_axil_rdata = rdata_sync;
    assign m_axil_rresp = rresp_sync;
    assign m_axil_rvalid = rvalid_sync;
    assign s_axil_rready = rready_sync;

endmodule

module sync_fifo #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
)
(
    input  wire                   clk,
    input  wire                   rst,
    input  wire [DATA_WIDTH-1:0]  data_in,
    input  wire                   valid_in,
    output wire                   ready_out,
    output wire [DATA_WIDTH-1:0]  data_out,
    input  wire                   valid_out,
    output wire                   ready_in
);

    logic [ADDR_WIDTH-1:0] wr_ptr;
    logic [ADDR_WIDTH-1:0] rd_ptr;
    logic [ADDR_WIDTH-1:0] count;
    logic [DATA_WIDTH-1:0] mem [0:(2**ADDR_WIDTH)-1];

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
        end else begin
            if (valid_in && ready_out && count < (2**ADDR_WIDTH)) begin
                mem[wr_ptr] <= data_in;
                wr_ptr <= wr_ptr + 1;
                count <= count + 1;
            end
            if (valid_out && ready_in && count > 0) begin
                rd_ptr <= rd_ptr + 1;
                count <= count - 1;
            end
        end
    end

    assign ready_out = (count < (2**ADDR_WIDTH));
    assign ready_in = (count > 0);
    assign data_out = mem[rd_ptr];

endmodule
