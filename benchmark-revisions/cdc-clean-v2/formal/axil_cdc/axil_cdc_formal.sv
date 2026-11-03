module axil_cdc_formal;
  localparam AW=6, DW=8;
  (* gclk *) reg gclk;
  reg [5:0] tick = 0;
  always @(posedge gclk) tick <= tick + 1'b1;
  wire s_clk = tick[0];
  wire m_clk = tick[1];
  wire s_rst = (tick < 8);
  wire m_rst = (tick < 8);
  (* anyseq *) reg [AW-1:0] s_axil_awaddr, s_axil_araddr;
  (* anyseq *) reg [2:0] s_axil_awprot, s_axil_arprot;
  (* anyseq *) reg s_axil_awvalid, s_axil_wvalid, s_axil_bready, s_axil_arvalid, s_axil_rready;
  (* anyseq *) reg [DW-1:0] s_axil_wdata;
  (* anyseq *) reg [DW/8-1:0] s_axil_wstrb;
  (* anyseq *) reg m_axil_awready, m_axil_wready, m_axil_bvalid, m_axil_arready, m_axil_rvalid;
  (* anyseq *) reg [1:0] m_axil_bresp, m_axil_rresp;
  (* anyseq *) reg [DW-1:0] m_axil_rdata;
  wire s_axil_awready, s_axil_wready, s_axil_bvalid, s_axil_arready, s_axil_rvalid;
  wire [1:0] s_axil_bresp, s_axil_rresp;
  wire [DW-1:0] s_axil_rdata;
  wire [AW-1:0] m_axil_awaddr, m_axil_araddr;
  wire [2:0] m_axil_awprot, m_axil_arprot;
  wire m_axil_awvalid, m_axil_wvalid, m_axil_bready, m_axil_arvalid, m_axil_rready;
  wire [DW-1:0] m_axil_wdata;
  wire [DW/8-1:0] m_axil_wstrb;
  axil_cdc #(.ADDR_WIDTH(AW), .DATA_WIDTH(DW)) dut(.*);

  always @* begin
    if (tick < 10) begin
      assume(!s_axil_awvalid);
      assume(!s_axil_wvalid);
      assume(!s_axil_arvalid);
    end
  end

  always @(posedge s_clk) begin
    if (!s_rst && $past(!s_rst && s_axil_awvalid && !s_axil_awready))
      assume(s_axil_awvalid && $stable({s_axil_awaddr, s_axil_awprot}));
    if (!s_rst && $past(!s_rst && s_axil_wvalid && !s_axil_wready))
      assume(s_axil_wvalid && $stable({s_axil_wdata, s_axil_wstrb}));
    if (!s_rst && $past(!s_rst && s_axil_arvalid && !s_axil_arready))
      assume(s_axil_arvalid && $stable({s_axil_araddr, s_axil_arprot}));
    if ($past(s_rst))
      assert(!s_axil_bvalid && !s_axil_rvalid);
    if (!s_rst && $past(!s_rst && s_axil_bvalid && !s_axil_bready))
      assert(s_axil_bvalid && $stable(s_axil_bresp));
    if (!s_rst && $past(!s_rst && s_axil_rvalid && !s_axil_rready))
      assert(s_axil_rvalid && $stable({s_axil_rdata, s_axil_rresp}));
  end

  always @(posedge m_clk) begin
    if (!m_rst && $past(!m_rst && m_axil_awvalid && !m_axil_awready))
      assert(m_axil_awvalid && $stable({m_axil_awaddr, m_axil_awprot}));
    if (!m_rst && $past(!m_rst && m_axil_wvalid && !m_axil_wready))
      assert(m_axil_wvalid && $stable({m_axil_wdata, m_axil_wstrb}));
    if (!m_rst && $past(!m_rst && m_axil_arvalid && !m_axil_arready))
      assert(m_axil_arvalid && $stable({m_axil_araddr, m_axil_arprot}));
  end

  always @(posedge gclk) begin
    cover(!s_rst && s_axil_awvalid && s_axil_awready);
    cover(!m_rst && m_axil_awvalid);
  end
endmodule
