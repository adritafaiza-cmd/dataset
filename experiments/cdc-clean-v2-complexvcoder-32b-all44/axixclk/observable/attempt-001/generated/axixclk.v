module axixclk #(
        parameter integer C_S_AXI_ID_WIDTH    = 2,
        parameter integer C_S_AXI_DATA_WIDTH  = 32,
        parameter integer C_S_AXI_ADDR_WIDTH  = 6,
        parameter [0:0] OPT_WRITE_ONLY      = 1'b0,
        parameter [0:0] OPT_READ_ONLY       = 1'b0,
        parameter       XCLOCK_FFS          = 2,
        parameter       LGFIFO              = 5
    ) (
        input  wire                           S_AXI_ACLK,
        input  wire                           S_AXI_ARESETN,
        input  wire [C_S_AXI_ID_WIDTH-1 : 0]  S_AXI_AWID,
        input  wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
        input  wire [7 : 0]                   S_AXI_AWLEN,
        input  wire [2 : 0]                   S_AXI_AWSIZE,
        input  wire [1 : 0]                   S_AXI_AWBURST,
        input  wire                           S_AXI_AWLOCK,
        input  wire [3 : 0]                   S_AXI_AWCACHE,
        input  wire [2 : 0]                   S_AXI_AWPROT,
        input  wire [3 : 0]                   S_AXI_AWQOS,
        input  wire                           S_AXI_AWVALID,
        output wire                           S_AXI_AWREADY,
        input  wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
        input  wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
        input  wire                           S_AXI_WLAST,
        input  wire                           S_AXI_WVALID,
        output wire                           S_AXI_WREADY,
        output wire [C_S_AXI_ID_WIDTH-1 : 0]  S_AXI_BID,
        output wire [1 : 0]                   S_AXI_BRESP,
        output wire                           S_AXI_BVALID,
        input  wire                           S_AXI_BREADY,
        input  wire [C_S_AXI_ID_WIDTH-1 : 0]  S_AXI_ARID,
        input  wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
        input  wire [7 : 0]                   S_AXI_ARLEN,
        input  wire [2 : 0]                   S_AXI_ARSIZE,
        input  wire [1 : 0]                   S_AXI_ARBURST,
        input  wire                           S_AXI_ARLOCK,
        input  wire [3 : 0]                   S_AXI_ARCACHE,
        input  wire [2 : 0]                   S_AXI_ARPROT,
        input  wire [3 : 0]                   S_AXI_ARQOS,
        input  wire                           S_AXI_ARVALID,
        output wire                           S_AXI_ARREADY,
        output wire [C_S_AXI_ID_WIDTH-1 : 0]  S_AXI_RID,
        output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
        output wire [1 : 0]                   S_AXI_RRESP,
        output wire                           S_AXI_RLAST,
        output wire                           S_AXI_RVALID,
        input  wire                           S_AXI_RREADY,
        input  wire                           M_AXI_ACLK,
        output wire                           M_AXI_ARESETN,
        output wire [C_S_AXI_ID_WIDTH-1 : 0]  M_AXI_AWID,
        output wire [C_S_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,
        output wire [7 : 0]                   M_AXI_AWLEN,
        output wire [2 : 0]                   M_AXI_AWSIZE,
        output wire [1 : 0]                   M_AXI_AWBURST,
        output wire                           M_AXI_AWLOCK,
        output wire [3 : 0]                   M_AXI_AWCACHE,
        output wire [2 : 0]                   M_AXI_AWPROT,
        output wire [3 : 0]                   M_AXI_AWQOS,
        output wire                           M_AXI_AWVALID,
        input  wire                           M_AXI_AWREADY,
        output wire [C_S_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA,
        output wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] M_AXI_WSTRB,
        output wire                           M_AXI_WLAST,
        output wire                           M_AXI_WVALID,
        input  wire                           M_AXI_WREADY,
        input  wire [C_S_AXI_ID_WIDTH-1 : 0]  M_AXI_BID,
        input  wire [1 : 0]                   M_AXI_BRESP,
        input  wire                           M_AXI_BVALID,
        output wire                           M_AXI_BREADY,
        output wire [C_S_AXI_ID_WIDTH-1 : 0]  M_AXI_ARID,
        output wire [C_S_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR,
        output wire [7 : 0]                   M_AXI_ARLEN,
        output wire [2 : 0]                   M_AXI_ARSIZE,
        output wire [1 : 0]                   M_AXI_ARBURST,
        output wire                           M_AXI_ARLOCK,
        output wire [3 : 0]                   M_AXI_ARCACHE,
        output wire [2 : 0]                   M_AXI_ARPROT,
        output wire [3 : 0]                   M_AXI_ARQOS,
        output wire                           M_AXI_ARVALID,
        input  wire                           M_AXI_ARREADY,
        input  wire [C_S_AXI_ID_WIDTH-1 : 0]  M_AXI_RID,
        input  wire [C_S_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA,
        input  wire [1 : 0]                   M_AXI_RRESP,
        input  wire                           M_AXI_RLAST,
        input  wire                           M_AXI_RVALID,
        output wire                           M_AXI_RREADY
    );

    // Internal FIFOs for AW, W, AR channels
    wire [C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4 - 1 : 0] s_awfifo_wdata;
    wire s_awfifo_wvalid;
    wire s_awfifo_wready;
    wire [C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4 - 1 : 0] s_awfifo_rdata;
    wire s_awfifo_rvalid;
    wire s_awfifo_rready;

    wire [C_S_AXI_DATA_WIDTH + C_S_AXI_DATA_WIDTH/8 + 1 - 1 : 0] s_wfifo_wdata;
    wire s_wfifo_wvalid;
    wire s_wfifo_wready;
    wire [C_S_AXI_DATA_WIDTH + C_S_AXI_DATA_WIDTH/8 + 1 - 1 : 0] s_wfifo_rdata;
    wire s_wfifo_rvalid;
    wire s_wfifo_rready;

    wire [C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4 - 1 : 0] s_arfifo_wdata;
    wire s_arfifo_wvalid;
    wire s_arfifo_wready;
    wire [C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4 - 1 : 0] s_arfifo_rdata;
    wire s_arfifo_rvalid;
    wire s_arfifo_rready;

    wire [C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4 - 1 : 0] m_awfifo_wdata;
    wire m_awfifo_wvalid;
    wire m_awfifo_wready;
    wire [C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4 - 1 : 0] m_awfifo_rdata;
    wire m_awfifo_rvalid;
    wire m_awfifo_rready;

    wire [C_S_AXI_DATA_WIDTH + C_S_AXI_DATA_WIDTH/8 + 1 - 1 : 0] m_wfifo_wdata;
    wire m_wfifo_wvalid;
    wire m_wfifo_wready;
    wire [C_S_AXI_DATA_WIDTH + C_S_AXI_DATA_WIDTH/8 + 1 - 1 : 0] m_wfifo_rdata;
    wire m_wfifo_rvalid;
    wire m_wfifo_rready;

    wire [C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4 - 1 : 0] m_arfifo_wdata;
    wire m_arfifo_wvalid;
    wire m_arfifo_wready;
    wire [C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4 - 1 : 0] m_arfifo_rdata;
    wire m_arfifo_rvalid;
    wire m_arfifo_rready;

    // FIFOs instantiation
    sync_fifo #(.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4), .DEPTH(2**LGFIFO))
    s_awfifo_inst (
        .clk_wr(S_AXI_ACLK),
        .rst_wr(!S_AXI_ARESETN),
        .din(s_awfifo_wdata),
        .wr_en(s_awfifo_wvalid),
        .full(~s_awfifo_wready),
        .clk_rd(M_AXI_ACLK),
        .rst_rd(!M_AXI_ARESETN),
        .dout(m_awfifo_wdata),
        .rd_en(m_awfifo_rready),
        .empty(~m_awfifo_rvalid)
    );

    sync_fifo #(.WIDTH(C_S_AXI_DATA_WIDTH + C_S_AXI_DATA_WIDTH/8 + 1), .DEPTH(2**LGFIFO))
    s_wfifo_inst (
        .clk_wr(S_AXI_ACLK),
        .rst_wr(!S_AXI_ARESETN),
        .din(s_wfifo_wdata),
        .wr_en(s_wfifo_wvalid),
        .full(~s_wfifo_wready),
        .clk_rd(M_AXI_ACLK),
        .rst_rd(!M_AXI_ARESETN),
        .dout(m_wfifo_wdata),
        .rd_en(m_wfifo_rready),
        .empty(~m_wfifo_rvalid)
    );

    sync_fifo #(.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4), .DEPTH(2**LGFIFO))
    s_arfifo_inst (
        .clk_wr(S_AXI_ACLK),
        .rst_wr(!S_AXI_ARESETN),
        .din(s_arfifo_wdata),
        .wr_en(s_arfifo_wvalid),
        .full(~s_arfifo_wready),
        .clk_rd(M_AXI_ACLK),
        .rst_rd(!M_AXI_ARESETN),
        .dout(m_arfifo_wdata),
        .rd_en(m_arfifo_rready),
        .empty(~m_arfifo_rvalid)
    );

    sync_fifo #(.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4), .DEPTH(2**LGFIFO))
    m_awfifo_inst (
        .clk_wr(M_AXI_ACLK),
        .rst_wr(!M_AXI_ARESETN),
        .din(m_awfifo_wdata),
        .wr_en(m_awfifo_wvalid),
        .full(~m_awfifo_wready),
        .clk_rd(S_AXI_ACLK),
        .rst_rd(!S_AXI_ARESETN),
        .dout(s_awfifo_rdata),
        .rd_en(s_awfifo_rready),
        .empty(~s_awfifo_rvalid)
    );

    sync_fifo #(.WIDTH(C_S_AXI_DATA_WIDTH + C_S_AXI_DATA_WIDTH/8 + 1), .DEPTH(2**LGFIFO))
    m_wfifo_inst (
        .clk_wr(M_AXI_ACLK),
        .rst_wr(!M_AXI_ARESETN),
        .din(m_wfifo_wdata),
        .wr_en(m_wfifo_wvalid),
        .full(~m_wfifo_wready),
        .clk_rd(S_AXI_ACLK),
        .rst_rd(!S_AXI_ARESETN),
        .dout(s_wfifo_rdata),
        .rd_en(s_wfifo_rready),
        .empty(~s_wfifo_rvalid)
    );

    sync_fifo #(.WIDTH(C_S_AXI_ID_WIDTH + C_S_AXI_ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4), .DEPTH(2**LGFIFO))
    m_arfifo_inst (
        .clk_wr(M_AXI_ACLK),
        .rst_wr(!M_AXI_ARESETN),
        .din(m_arfifo_wdata),
        .wr_en(m_arfifo_wvalid),
        .full(~m_arfifo_wready),
        .clk_rd(S_AXI_ACLK),
        .rst_rd(!S_AXI_ARESETN),
        .dout(s_arfifo_rdata),
        .rd_en(s_arfifo_rready),
        .empty(~s_arfifo_rvalid)
    );

    // AW Channel
    assign s_awfifo_wdata = {S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST, S_AXI_AWLOCK, S_AXI_AWCACHE, S_AXI_AWPROT, S_AXI_AWQOS};
    assign s_awfifo_wvalid = S_AXI_AWVALID;
    assign S_AXI_AWREADY = s_awfifo_wready;
    assign {M_AXI_AWID, M_AXI_AWADDR, M_AXI_AWLEN, M_AXI_AWSIZE, M_AXI_AWBURST, M_AXI_AWLOCK, M_AXI_AWCACHE, M_AXI_AWPROT, M_AXI_AWQOS} = m_awfifo_rdata;
    assign m_awfifo_rready = M_AXI_AWREADY;

    // W Channel
    assign s_wfifo_wdata = {S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST};
    assign s_wfifo_wvalid = S_AXI_WVALID;
    assign S_AXI_WREADY = s_wfifo_wready;
    reg [C_S_AXI_DATA_WIDTH-1 : 0] m_wdata_reg;
    reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0] m_wstrb_reg;
    reg m_wlast_reg;
    reg m_wvalid_reg;

    always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
        if (!M_AXI_ARESETN) begin
            m_wdata_reg <= 0;
            m_wstrb_reg <= 0;
            m_wlast_reg <= 0;
            m_wvalid_reg <= 0;
        end else if (m_wfifo_rvalid && !m_wvalid_reg) begin
            m_wdata_reg <= m_wfifo_rdata[C_S_AXI_DATA_WIDTH-1 : 0];
            m_wstrb_reg <= m_wfifo_rdata[C_S_AXI_DATA_WIDTH + C_S_AXI_DATA_WIDTH/8 - 1 : C_S_AXI_DATA_WIDTH];
            m_wlast_reg <= m_wfifo_rdata[C_S_AXI_DATA_WIDTH + C_S_AXI_DATA_WIDTH/8];
            m_wvalid_reg <= 1;
        end else if (M_AXI_WREADY) begin
            m_wvalid_reg <= 0;
        end
    end

    assign M_AXI_WDATA = m_wdata_reg;
    assign M_AXI_WSTRB = m_wstrb_reg;
    assign M_AXI_WLAST = m_wlast_reg;
    assign M_AXI_WVALID = m_wvalid_reg;
    assign m_wfifo_rready = M_AXI_WREADY;

    // B Channel
    reg [C_S_AXI_ID_WIDTH-1 : 0] s_bid_reg;
    reg [1 : 0] s_bresp_reg;
    reg s_bvalid_reg;

    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            s_bid_reg <= 0;
            s_bresp_reg <= 0;
            s_bvalid_reg <= 0;
        end else if (s_awfifo_rvalid && !s_bvalid_reg) begin
            s_bid_reg <= s_awfifo_rdata[C_S_AXI_ID_WIDTH-1 : 0];
            s_bvalid_reg <= 1;
        end else if (S_AXI_BREADY) begin
            s_bvalid_reg <= 0;
        end
    end

    assign S_AXI_BID = s_bid_reg;
    assign S_AXI_BRESP = s_bresp_reg;
    assign S_AXI_BVALID = s_bvalid_reg;
    assign M_AXI_BREADY = s_bvalid_reg;

    always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
        if (!M_AXI_ARESETN) begin
            s_bresp_reg <= 0;
        end else if (M_AXI_BVALID) begin
            s_bresp_reg <= M_AXI_BRESP;
        end
    end

    // AR Channel
    assign s_arfifo_wdata = {S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN, S_AXI_ARSIZE, S_AXI_ARBURST, S_AXI_ARLOCK, S_AXI_ARCACHE, S_AXI_ARPROT, S_AXI_ARQOS};
    assign s_arfifo_wvalid = S_AXI_ARVALID;
    assign S_AXI_ARREADY = s_arfifo_wready;
    assign {M_AXI_ARID, M_AXI_ARADDR, M_AXI_ARLEN, M_AXI_ARSIZE, M_AXI_ARBURST, M_AXI_ARLOCK, M_AXI_ARCACHE, M_AXI_ARPROT, M_AXI_ARQOS} = m_arfifo_rdata;
    assign m_arfifo_rready = M_AXI_ARREADY;

    // R Channel
    reg [C_S_AXI_ID_WIDTH-1 : 0] s_rid_reg;
    reg [C_S_AXI_DATA_WIDTH-1 : 0] s_rdata_reg;
    reg [1 : 0] s_rresp_reg;
    reg s_rlast_reg;
    reg s_rvalid_reg;

    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            s_rid_reg <= 0;
            s_rdata_reg <= 0;
            s_rresp_reg <= 0;
            s_rlast_reg <= 0;
            s_rvalid_reg <= 0;
        end else if (s_arfifo_rvalid && !s_rvalid_reg) begin
            s_rid_reg <= s_arfifo_rdata[C_S_AXI_ID_WIDTH-1 : 0];
            s_rvalid_reg <= 1;
        end else if (S_AXI_RREADY) begin
            s_rvalid_reg <= 0;
        end
    end

    assign S_AXI_RID = s_rid_reg;
    assign S_AXI_RDATA = s_rdata_reg;
    assign S_AXI_RRESP = s_rresp_reg;
    assign S_AXI_RLAST = s_rlast_reg;
    assign S_AXI_RVALID = s_rvalid_reg;
    assign M_AXI_RREADY = s_rvalid_reg;

    always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
        if (!M_AXI_ARESETN) begin
            s_rdata_reg <= 0;
            s_rresp_reg <= 0;
            s_rlast_reg <= 0;
        end else if (M_AXI_RVALID) begin
            s_rdata_reg <= M_AXI_RDATA;
            s_rresp_reg <= M_AXI_RRESP;
            s_rlast_reg <= M_AXI_RLAST;
        end
    end

    // Reset handling
    assign M_AXI_ARESETN = S_AXI_ARESETN;

endmodule

module sync_fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
) (
    input wire clk_wr,
    input wire rst_wr,
    input wire [WIDTH-1 : 0] din,
    input wire wr_en,
    input wire full,
    input wire clk_rd,
    input wire rst_rd,
    output wire [WIDTH-1 : 0] dout,
    input wire rd_en,
    input wire empty
);

    reg [WIDTH-1 : 0] mem [0 : DEPTH-1];
    reg [$clog2(DEPTH)-1 : 0] wr_ptr;
    reg [$clog2(DEPTH)-1 : 0] rd_ptr;
    reg [$clog2(DEPTH)-1 : 0] wr_ptr_gray;
    reg [$clog2(DEPTH)-1 : 0] rd_ptr_gray;
    reg [$clog2(DEPTH)-1 : 0] wr_ptr_gray_sync;
    reg [$clog2(DEPTH)-1 : 0] rd_ptr_gray_sync;

    assign full = (wr_ptr_gray_sync == (rd_ptr_gray + 1'b1));
    assign empty = (wr_ptr_gray_sync == rd_ptr_gray);

    always @(posedge clk_wr or negedge rst_wr) begin
        if (!rst_wr) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr] <= din;
            wr_ptr <= wr_ptr + 1'b1;
            wr_ptr_gray <= wr_ptr ^ (wr_ptr >> 1);
        end
    end

    always @(posedge clk_rd or negedge rst_rd) begin
        if (!rst_rd) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1'b1;
            rd_ptr_gray <= rd_ptr ^ (rd_ptr >> 1);
        end
    end

    // Gray code synchronization
    always @(posedge clk_wr or negedge rst_wr) begin
        if (!rst_wr) begin
            rd_ptr_gray_sync <= 0;
        end else begin
            rd_ptr_gray_sync <= rd_ptr_gray;
        end
    end

    always @(posedge clk_rd or negedge rst_rd) begin
        if (!rst_rd) begin
            wr_ptr_gray_sync <= 0;
        end else begin
            wr_ptr_gray_sync <= wr_ptr_gray;
        end
    end

    // Output data
    always @(posedge clk_rd or negedge rst_rd) begin
        if (!rst_rd) begin
            dout <= 0;
        end else begin
            dout <= mem[rd_ptr];
        end
    end

endmodule
