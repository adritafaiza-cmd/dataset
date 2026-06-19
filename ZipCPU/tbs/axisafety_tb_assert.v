`timescale 1ns/1ps
// Assertion-enhanced starter testbench generated for simulation + protocol checking.
`default_nettype none
module axisafety_assert;
    localparam IW=1,DW=32,AW=8;
    reg clk=0,rstn=0; always #5 clk=~clk; integer errors=0;
    wire rfault,wfault,m_rstn;
    reg [IW-1:0] s_awid,s_arid; reg [AW-1:0] s_awaddr,s_araddr; reg [7:0] s_awlen,s_arlen; reg [2:0] s_awsize,s_arsize; reg [1:0] s_awburst,s_arburst; reg s_awlock,s_arlock; reg [3:0] s_awcache,s_arcache,s_awqos,s_arqos; reg [2:0] s_awprot,s_arprot; reg s_awvalid,s_wvalid,s_bready,s_arvalid,s_rready; wire s_awready,s_wready,s_bvalid,s_arready,s_rvalid; reg [DW-1:0] s_wdata; reg [DW/8-1:0] s_wstrb; reg s_wlast; wire [IW-1:0] s_bid,s_rid; wire [1:0] s_bresp,s_rresp; wire [DW-1:0] s_rdata; wire s_rlast;
    wire [IW-1:0] m_awid,m_arid; wire [AW-1:0] m_awaddr,m_araddr; wire [7:0] m_awlen,m_arlen; wire [2:0] m_awsize,m_arsize; wire [1:0] m_awburst,m_arburst; wire m_awlock,m_arlock; wire [3:0] m_awcache,m_arcache,m_awqos,m_arqos; wire [2:0] m_awprot,m_arprot; wire m_awvalid,m_wvalid,m_bready,m_arvalid,m_rready; reg m_awready,m_wready,m_bvalid,m_arready,m_rvalid; wire [DW-1:0] m_wdata; wire [DW/8-1:0] m_wstrb; wire m_wlast; reg [IW-1:0] m_bid,m_rid; reg [1:0] m_bresp,m_rresp; reg [DW-1:0] m_rdata; reg m_rlast;
    axisafety #(.C_S_AXI_ID_WIDTH(IW),.C_S_AXI_DATA_WIDTH(DW),.C_S_AXI_ADDR_WIDTH(AW),.OPT_SELF_RESET(1'b0),.OPT_TIMEOUT(8)) dut(
        .o_read_fault(rfault),.o_write_fault(wfault),.S_AXI_ACLK(clk),.S_AXI_ARESETN(rstn),.M_AXI_ARESETN(m_rstn),
        .S_AXI_AWID(s_awid),.S_AXI_AWADDR(s_awaddr),.S_AXI_AWLEN(s_awlen),.S_AXI_AWSIZE(s_awsize),.S_AXI_AWBURST(s_awburst),.S_AXI_AWLOCK(s_awlock),.S_AXI_AWCACHE(s_awcache),.S_AXI_AWPROT(s_awprot),.S_AXI_AWQOS(s_awqos),.S_AXI_AWVALID(s_awvalid),.S_AXI_AWREADY(s_awready),
        .S_AXI_WDATA(s_wdata),.S_AXI_WSTRB(s_wstrb),.S_AXI_WLAST(s_wlast),.S_AXI_WVALID(s_wvalid),.S_AXI_WREADY(s_wready),.S_AXI_BID(s_bid),.S_AXI_BRESP(s_bresp),.S_AXI_BVALID(s_bvalid),.S_AXI_BREADY(s_bready),
        .S_AXI_ARID(s_arid),.S_AXI_ARADDR(s_araddr),.S_AXI_ARLEN(s_arlen),.S_AXI_ARSIZE(s_arsize),.S_AXI_ARBURST(s_arburst),.S_AXI_ARLOCK(s_arlock),.S_AXI_ARCACHE(s_arcache),.S_AXI_ARPROT(s_arprot),.S_AXI_ARQOS(s_arqos),.S_AXI_ARVALID(s_arvalid),.S_AXI_ARREADY(s_arready),
        .S_AXI_RID(s_rid),.S_AXI_RDATA(s_rdata),.S_AXI_RRESP(s_rresp),.S_AXI_RLAST(s_rlast),.S_AXI_RVALID(s_rvalid),.S_AXI_RREADY(s_rready),
        .M_AXI_AWID(m_awid),.M_AXI_AWADDR(m_awaddr),.M_AXI_AWLEN(m_awlen),.M_AXI_AWSIZE(m_awsize),.M_AXI_AWBURST(m_awburst),.M_AXI_AWLOCK(m_awlock),.M_AXI_AWCACHE(m_awcache),.M_AXI_AWPROT(m_awprot),.M_AXI_AWQOS(m_awqos),.M_AXI_AWVALID(m_awvalid),.M_AXI_AWREADY(m_awready),
        .M_AXI_WDATA(m_wdata),.M_AXI_WSTRB(m_wstrb),.M_AXI_WLAST(m_wlast),.M_AXI_WVALID(m_wvalid),.M_AXI_WREADY(m_wready),.M_AXI_BID(m_bid),.M_AXI_BRESP(m_bresp),.M_AXI_BVALID(m_bvalid),.M_AXI_BREADY(m_bready),
        .M_AXI_ARID(m_arid),.M_AXI_ARADDR(m_araddr),.M_AXI_ARLEN(m_arlen),.M_AXI_ARSIZE(m_arsize),.M_AXI_ARBURST(m_arburst),.M_AXI_ARLOCK(m_arlock),.M_AXI_ARCACHE(m_arcache),.M_AXI_ARPROT(m_arprot),.M_AXI_ARQOS(m_arqos),.M_AXI_ARVALID(m_arvalid),.M_AXI_ARREADY(m_arready),.M_AXI_RID(m_rid),.M_AXI_RDATA(m_rdata),.M_AXI_RRESP(m_rresp),.M_AXI_RLAST(m_rlast),.M_AXI_RVALID(m_rvalid),.M_AXI_RREADY(m_rready));
    task check; input cond; input [255:0] msg; begin if(!cond) begin $display("FAIL: %s",msg); errors=errors+1; end else $display("PASS: %s",msg); end endtask
    initial begin
        s_awid=0; s_awaddr=0; s_awlen=0; s_awsize=3'd2; s_awburst=2'b01; s_awlock=0; s_awcache=0; s_awprot=0; s_awqos=0; s_awvalid=0; s_wdata=0; s_wstrb=4'hf; s_wlast=1; s_wvalid=0; s_bready=0; s_arid=0; s_araddr=0; s_arlen=0; s_arsize=3'd2; s_arburst=2'b01; s_arlock=0; s_arcache=0; s_arprot=0; s_arqos=0; s_arvalid=0; s_rready=0; m_awready=0; m_wready=0; m_bvalid=0; m_bid=0; m_bresp=0; m_arready=0; m_rvalid=0; m_rid=0; m_rdata=0; m_rresp=0; m_rlast=1;
        repeat(5) @(posedge clk); rstn=1; repeat(5) @(posedge clk); $display("TEST AXISAFETY");
        @(negedge clk); s_awaddr=8'h20; s_awvalid=1; s_wdata=32'hdeadbeef; s_wvalid=1; s_bready=1; wait(m_awvalid&&m_wvalid); m_awready=1; m_wready=1; @(negedge clk); m_awready=0; m_wready=0; s_awvalid=0; s_wvalid=0; m_bvalid=1; m_bresp=0; wait(m_bready); @(negedge clk); m_bvalid=0; wait(s_bvalid); check(s_bresp==0,"good AXI write"); s_bready=0;
        @(negedge clk); s_araddr=8'h30; s_arvalid=1; s_rready=1; wait(m_arvalid); m_arready=1; @(negedge clk); m_arready=0; s_arvalid=0; m_rvalid=1; m_rdata=32'hcafebabe; m_rresp=0; m_rlast=1; wait(m_rready); @(negedge clk); m_rvalid=0; wait(s_rvalid); check(s_rdata==32'hcafebabe,"good AXI read"); s_rready=0;
        @(negedge clk); s_arvalid=1; s_rready=1; s_araddr=8'h40; repeat(20) @(posedge clk); check(rfault,"read fault asserted on timeout");
        $display(errors?"TESTS FAILED":"ALL TESTS PASSED"); $finish;
    end


  // ---------------- Assertion monitors: AXI firewall handshake stability ----------------
  reg prev_s_aw_wait, prev_s_w_wait, prev_s_ar_wait, prev_m_aw_wait, prev_m_w_wait, prev_m_ar_wait;
  always @(posedge clk) begin
    if (!rstn) begin prev_s_aw_wait<=0; prev_s_w_wait<=0; prev_s_ar_wait<=0; prev_m_aw_wait<=0; prev_m_w_wait<=0; prev_m_ar_wait<=0; end else begin
      if (prev_s_aw_wait) if (!(s_awvalid) else begin $display("ASSERT FAIL: S AWVALID dropped")) begin $display("ASSERT FAIL: s_awvalid) else begin $display("ASSERT FAIL: S AWVALID dropped""); errors = errors + 1; end errors=errors+1; end
      if (prev_s_w_wait)  if (!(s_wvalid)  else begin $display("ASSERT FAIL: S WVALID dropped")) begin $display("ASSERT FAIL: s_wvalid)  else begin $display("ASSERT FAIL: S WVALID dropped""); errors = errors + 1; end errors=errors+1; end
      if (prev_s_ar_wait) if (!(s_arvalid) else begin $display("ASSERT FAIL: S ARVALID dropped")) begin $display("ASSERT FAIL: s_arvalid) else begin $display("ASSERT FAIL: S ARVALID dropped""); errors = errors + 1; end errors=errors+1; end
      if (prev_m_aw_wait) if (!(m_awvalid) else begin $display("ASSERT FAIL: M AWVALID dropped")) begin $display("ASSERT FAIL: m_awvalid) else begin $display("ASSERT FAIL: M AWVALID dropped""); errors = errors + 1; end errors=errors+1; end
      if (prev_m_w_wait)  if (!(m_wvalid)  else begin $display("ASSERT FAIL: M WVALID dropped")) begin $display("ASSERT FAIL: m_wvalid)  else begin $display("ASSERT FAIL: M WVALID dropped""); errors = errors + 1; end errors=errors+1; end
      if (prev_m_ar_wait) if (!(m_arvalid) else begin $display("ASSERT FAIL: M ARVALID dropped")) begin $display("ASSERT FAIL: m_arvalid) else begin $display("ASSERT FAIL: M ARVALID dropped""); errors = errors + 1; end errors=errors+1; end
      prev_s_aw_wait <= s_awvalid && !s_awready; prev_s_w_wait <= s_wvalid && !s_wready; prev_s_ar_wait <= s_arvalid && !s_arready;
      prev_m_aw_wait <= m_awvalid && !m_awready; prev_m_w_wait <= m_wvalid && !m_wready; prev_m_ar_wait <= m_arvalid && !m_arready;
    end
  end

endmodule
`default_nettype wire
