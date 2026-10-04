`default_nettype wire
module axidma_formal;
  localparam AW=8, DW=8, IW=1;
  reg S_AXI_ACLK;
  (* anyseq *) reg S_AXI_ARESETN;
  (* anyseq *) reg S_AXIL_AWVALID, S_AXIL_WVALID, S_AXIL_BREADY, S_AXIL_ARVALID, S_AXIL_RREADY;
  (* anyseq *) reg [4:0] S_AXIL_AWADDR, S_AXIL_ARADDR;
  (* anyseq *) reg [2:0] S_AXIL_AWPROT, S_AXIL_ARPROT;
  (* anyseq *) reg [31:0] S_AXIL_WDATA;
  (* anyseq *) reg [3:0] S_AXIL_WSTRB;
  (* anyseq *) reg M_AXI_AWREADY, M_AXI_WREADY, M_AXI_BVALID, M_AXI_ARREADY, M_AXI_RVALID, M_AXI_RLAST;
  (* anyseq *) reg [IW-1:0] M_AXI_BID, M_AXI_RID;
  (* anyseq *) reg [1:0] M_AXI_BRESP, M_AXI_RRESP;
  (* anyseq *) reg [DW-1:0] M_AXI_RDATA;
  wire S_AXIL_AWREADY, S_AXIL_WREADY, S_AXIL_BVALID, S_AXIL_ARREADY, S_AXIL_RVALID;
  wire [1:0] S_AXIL_BRESP, S_AXIL_RRESP;
  wire [31:0] S_AXIL_RDATA;
  wire M_AXI_AWVALID, M_AXI_WVALID, M_AXI_WLAST, M_AXI_BREADY, M_AXI_ARVALID, M_AXI_RREADY;
  wire [IW-1:0] M_AXI_AWID, M_AXI_ARID;
  wire [AW-1:0] M_AXI_AWADDR, M_AXI_ARADDR;
  wire [7:0] M_AXI_AWLEN, M_AXI_ARLEN;
  wire [2:0] M_AXI_AWSIZE, M_AXI_ARSIZE, M_AXI_AWPROT, M_AXI_ARPROT;
  wire [1:0] M_AXI_AWBURST, M_AXI_ARBURST;
  wire M_AXI_AWLOCK, M_AXI_ARLOCK;
  wire [3:0] M_AXI_AWCACHE, M_AXI_ARCACHE, M_AXI_AWQOS, M_AXI_ARQOS;
  wire [DW-1:0] M_AXI_WDATA;
  wire [DW/8-1:0] M_AXI_WSTRB;
  wire o_int;

  axidma #(.C_AXI_ID_WIDTH(IW), .C_AXI_ADDR_WIDTH(AW), .C_AXI_DATA_WIDTH(DW),
           .OPT_UNALIGNED(0), .LGMAXBURST(2), .LGFIFO(3)) dut (.*);

  reg f_past_valid;
  initial begin
    f_past_valid = 0;
    assume(!S_AXI_ARESETN);
  end

  always @(posedge S_AXI_ACLK) begin
    f_past_valid <= 1;
    if (S_AXI_ARESETN && f_past_valid && $past(S_AXI_ARESETN && S_AXIL_AWVALID && !S_AXIL_AWREADY))
      assume(S_AXIL_AWVALID && $stable({S_AXIL_AWADDR, S_AXIL_AWPROT}));
    if (S_AXI_ARESETN && f_past_valid && $past(S_AXI_ARESETN && S_AXIL_WVALID && !S_AXIL_WREADY))
      assume(S_AXIL_WVALID && $stable({S_AXIL_WDATA, S_AXIL_WSTRB}));
    if (S_AXI_ARESETN && f_past_valid && $past(S_AXI_ARESETN && S_AXIL_ARVALID && !S_AXIL_ARREADY))
      assume(S_AXIL_ARVALID && $stable({S_AXIL_ARADDR, S_AXIL_ARPROT}));
    if (S_AXI_ARESETN && f_past_valid && $past(S_AXI_ARESETN && S_AXIL_BVALID && !S_AXIL_BREADY))
      assert(S_AXIL_BVALID);
    if (S_AXI_ARESETN && f_past_valid && $past(S_AXI_ARESETN && S_AXIL_RVALID && !S_AXIL_RREADY))
      assert(S_AXIL_RVALID);
    if (f_past_valid && $past(!S_AXI_ARESETN))
      assert(!S_AXIL_BVALID && !S_AXIL_RVALID);
    cover(S_AXI_ARESETN && S_AXIL_AWVALID && S_AXIL_AWREADY);
    cover(S_AXI_ARESETN && S_AXIL_BVALID);
  end
endmodule
