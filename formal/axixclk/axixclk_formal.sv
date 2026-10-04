module axixclk_formal;
  localparam IW=1, AW=6, DW=8;
  (* gclk *) reg gclk;
  reg [5:0] tick = 0;
  always @(posedge gclk) tick <= tick + 1'b1;
  wire S_AXI_ACLK = tick[0];
  wire M_AXI_ACLK = tick[1];
  wire S_AXI_ARESETN = (tick >= 8);
  wire M_AXI_ARESETN;
  (* anyseq *) reg [IW-1:0] S_AXI_AWID, S_AXI_ARID;
  (* anyseq *) reg [AW-1:0] S_AXI_AWADDR, S_AXI_ARADDR;
  (* anyseq *) reg [7:0] S_AXI_AWLEN, S_AXI_ARLEN;
  (* anyseq *) reg [2:0] S_AXI_AWSIZE, S_AXI_ARSIZE;
  (* anyseq *) reg [1:0] S_AXI_AWBURST, S_AXI_ARBURST;
  (* anyseq *) reg S_AXI_AWLOCK, S_AXI_ARLOCK;
  (* anyseq *) reg [3:0] S_AXI_AWCACHE, S_AXI_ARCACHE, S_AXI_AWQOS, S_AXI_ARQOS;
  (* anyseq *) reg [2:0] S_AXI_AWPROT, S_AXI_ARPROT;
  (* anyseq *) reg S_AXI_AWVALID, S_AXI_WVALID, S_AXI_BREADY, S_AXI_ARVALID, S_AXI_RREADY;
  (* anyseq *) reg [DW-1:0] S_AXI_WDATA;
  (* anyseq *) reg [DW/8-1:0] S_AXI_WSTRB;
  (* anyseq *) reg S_AXI_WLAST;
  (* anyseq *) reg M_AXI_AWREADY, M_AXI_WREADY, M_AXI_BVALID, M_AXI_ARREADY, M_AXI_RVALID;
  (* anyseq *) reg [IW-1:0] M_AXI_BID, M_AXI_RID;
  (* anyseq *) reg [1:0] M_AXI_BRESP, M_AXI_RRESP;
  (* anyseq *) reg [DW-1:0] M_AXI_RDATA;
  (* anyseq *) reg M_AXI_RLAST;
  wire S_AXI_AWREADY, S_AXI_WREADY, S_AXI_BVALID, S_AXI_ARREADY, S_AXI_RVALID, S_AXI_RLAST;
  wire [IW-1:0] S_AXI_BID, S_AXI_RID;
  wire [1:0] S_AXI_BRESP, S_AXI_RRESP;
  wire [DW-1:0] S_AXI_RDATA;
  wire [IW-1:0] M_AXI_AWID, M_AXI_ARID;
  wire [AW-1:0] M_AXI_AWADDR, M_AXI_ARADDR;
  wire [7:0] M_AXI_AWLEN, M_AXI_ARLEN;
  wire [2:0] M_AXI_AWSIZE, M_AXI_ARSIZE;
  wire [1:0] M_AXI_AWBURST, M_AXI_ARBURST;
  wire M_AXI_AWLOCK, M_AXI_ARLOCK;
  wire [3:0] M_AXI_AWCACHE, M_AXI_ARCACHE, M_AXI_AWQOS, M_AXI_ARQOS;
  wire [2:0] M_AXI_AWPROT, M_AXI_ARPROT;
  wire M_AXI_AWVALID, M_AXI_WVALID, M_AXI_BREADY, M_AXI_ARVALID, M_AXI_RREADY, M_AXI_WLAST;
  wire [DW-1:0] M_AXI_WDATA;
  wire [DW/8-1:0] M_AXI_WSTRB;
  axixclk #(.C_S_AXI_ID_WIDTH(IW), .C_S_AXI_ADDR_WIDTH(AW),
            .C_S_AXI_DATA_WIDTH(DW), .LGFIFO(2)) dut(.*);

  always @* begin
    if (tick < 10) begin
      assume(!S_AXI_AWVALID);
      assume(!S_AXI_WVALID);
      assume(!S_AXI_ARVALID);
    end
  end

  always @(posedge S_AXI_ACLK) begin
    if (S_AXI_ARESETN && $past(S_AXI_ARESETN && S_AXI_AWVALID && !S_AXI_AWREADY))
      assume(S_AXI_AWVALID && $stable({S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN}));
    if (S_AXI_ARESETN && $past(S_AXI_ARESETN && S_AXI_WVALID && !S_AXI_WREADY))
      assume(S_AXI_WVALID && $stable({S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST}));
    if (S_AXI_ARESETN && $past(S_AXI_ARESETN && S_AXI_ARVALID && !S_AXI_ARREADY))
      assume(S_AXI_ARVALID && $stable({S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN}));
    if ($past(!S_AXI_ARESETN))
      assert(!S_AXI_BVALID && !S_AXI_RVALID);
    if (S_AXI_ARESETN && $past(S_AXI_ARESETN && S_AXI_BVALID && !S_AXI_BREADY))
      assert(S_AXI_BVALID && $stable({S_AXI_BID, S_AXI_BRESP}));
    if (S_AXI_ARESETN && $past(S_AXI_ARESETN && S_AXI_RVALID && !S_AXI_RREADY))
      assert(S_AXI_RVALID && $stable({S_AXI_RID, S_AXI_RDATA, S_AXI_RRESP, S_AXI_RLAST}));
  end

  always @(posedge M_AXI_ACLK) begin
    if (M_AXI_ARESETN && $past(M_AXI_ARESETN && M_AXI_AWVALID && !M_AXI_AWREADY))
      assert(M_AXI_AWVALID && $stable({M_AXI_AWID, M_AXI_AWADDR, M_AXI_AWLEN}));
    if (M_AXI_ARESETN && $past(M_AXI_ARESETN && M_AXI_WVALID && !M_AXI_WREADY))
      assert(M_AXI_WVALID && $stable({M_AXI_WDATA, M_AXI_WSTRB, M_AXI_WLAST}));
    if (M_AXI_ARESETN && $past(M_AXI_ARESETN && M_AXI_ARVALID && !M_AXI_ARREADY))
      assert(M_AXI_ARVALID && $stable({M_AXI_ARID, M_AXI_ARADDR, M_AXI_ARLEN}));
  end

  always @(posedge gclk) begin
    cover(S_AXI_ARESETN && S_AXI_AWVALID && S_AXI_AWREADY);
    cover(M_AXI_ARESETN && M_AXI_AWVALID);
  end
endmodule
