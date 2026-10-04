`timescale 1ns/1ps
module axixclk_tb;
  localparam IDW=2,DW=32,AW=8;
  integer errors,wreq,brsp,rreq,rrsp,mwreq,mrreq,tick,age_b,age_r,i;
  reg s_clk,m_clk,s_rstn;
  reg [IDW-1:0] s_awid,s_arid;
  reg [AW-1:0] s_awaddr,s_araddr;
  reg [7:0] s_awlen,s_arlen;
  reg [2:0] s_awsize,s_arsize;
  reg [1:0] s_awburst,s_arburst;
  reg s_awvalid,s_wvalid,s_wlast,s_bready,s_arvalid,s_rready;
  reg [DW-1:0] s_wdata;
  reg [3:0] s_wstrb;
  wire s_awready,s_wready,s_bvalid,s_arready,s_rvalid,s_rlast;
  wire [IDW-1:0] s_bid,s_rid;
  wire [1:0] s_bresp,s_rresp;
  wire [DW-1:0] s_rdata;
  wire m_rstn,m_awvalid,m_wvalid,m_wlast,m_bready,m_arvalid,m_rready;
  wire [IDW-1:0] m_awid,m_arid;
  wire [AW-1:0] m_awaddr,m_araddr;
  wire [7:0] m_awlen,m_arlen;
  wire [2:0] m_awsize,m_arsize;
  wire [1:0] m_awburst,m_arburst;
  wire [DW-1:0] m_wdata;
  wire [3:0] m_wstrb;
  reg m_awready,m_wready,m_bvalid,m_arready,m_rvalid,m_rlast;
  reg [IDW-1:0] m_bid,m_rid;
  reg [1:0] m_bresp,m_rresp;
  reg [DW-1:0] m_rdata;
  reg [31:0] mem[0:63];
  reg have_aw,have_w;
  reg [AW-1:0] aw_hold;
  reg [IDW-1:0] awid_hold;
  reg [DW-1:0] wd_hold;
  reg paw,pw,par,pb,pr;
  reg [AW-1:0] pawaddr,paraddr;
  reg [DW-1:0] pwdata,prdata;

  always #5 s_clk=~s_clk;
  always #7 m_clk=~m_clk;
  axixclk #(.C_S_AXI_ID_WIDTH(IDW),.C_S_AXI_DATA_WIDTH(DW),
    .C_S_AXI_ADDR_WIDTH(AW),.LGFIFO(4)) dut(
    .S_AXI_ACLK(s_clk),.S_AXI_ARESETN(s_rstn),
    .S_AXI_AWID(s_awid),.S_AXI_AWADDR(s_awaddr),.S_AXI_AWLEN(s_awlen),
    .S_AXI_AWSIZE(s_awsize),.S_AXI_AWBURST(s_awburst),.S_AXI_AWLOCK(1'b0),
    .S_AXI_AWCACHE(4'b0),.S_AXI_AWPROT(3'b0),.S_AXI_AWQOS(4'b0),
    .S_AXI_AWVALID(s_awvalid),.S_AXI_AWREADY(s_awready),
    .S_AXI_WDATA(s_wdata),.S_AXI_WSTRB(s_wstrb),.S_AXI_WLAST(s_wlast),
    .S_AXI_WVALID(s_wvalid),.S_AXI_WREADY(s_wready),
    .S_AXI_BID(s_bid),.S_AXI_BRESP(s_bresp),.S_AXI_BVALID(s_bvalid),.S_AXI_BREADY(s_bready),
    .S_AXI_ARID(s_arid),.S_AXI_ARADDR(s_araddr),.S_AXI_ARLEN(s_arlen),
    .S_AXI_ARSIZE(s_arsize),.S_AXI_ARBURST(s_arburst),.S_AXI_ARLOCK(1'b0),
    .S_AXI_ARCACHE(4'b0),.S_AXI_ARPROT(3'b0),.S_AXI_ARQOS(4'b0),
    .S_AXI_ARVALID(s_arvalid),.S_AXI_ARREADY(s_arready),
    .S_AXI_RID(s_rid),.S_AXI_RDATA(s_rdata),.S_AXI_RRESP(s_rresp),
    .S_AXI_RLAST(s_rlast),.S_AXI_RVALID(s_rvalid),.S_AXI_RREADY(s_rready),
    .M_AXI_ACLK(m_clk),.M_AXI_ARESETN(m_rstn),
    .M_AXI_AWID(m_awid),.M_AXI_AWADDR(m_awaddr),.M_AXI_AWLEN(m_awlen),
    .M_AXI_AWSIZE(m_awsize),.M_AXI_AWBURST(m_awburst),.M_AXI_AWLOCK(),
    .M_AXI_AWCACHE(),.M_AXI_AWPROT(),.M_AXI_AWQOS(),
    .M_AXI_AWVALID(m_awvalid),.M_AXI_AWREADY(m_awready),
    .M_AXI_WDATA(m_wdata),.M_AXI_WSTRB(m_wstrb),.M_AXI_WLAST(m_wlast),
    .M_AXI_WVALID(m_wvalid),.M_AXI_WREADY(m_wready),
    .M_AXI_BID(m_bid),.M_AXI_BRESP(m_bresp),.M_AXI_BVALID(m_bvalid),.M_AXI_BREADY(m_bready),
    .M_AXI_ARID(m_arid),.M_AXI_ARADDR(m_araddr),.M_AXI_ARLEN(m_arlen),
    .M_AXI_ARSIZE(m_arsize),.M_AXI_ARBURST(m_arburst),.M_AXI_ARLOCK(),
    .M_AXI_ARCACHE(),.M_AXI_ARPROT(),.M_AXI_ARQOS(),
    .M_AXI_ARVALID(m_arvalid),.M_AXI_ARREADY(m_arready),
    .M_AXI_RID(m_rid),.M_AXI_RDATA(m_rdata),.M_AXI_RRESP(m_rresp),
    .M_AXI_RLAST(m_rlast),.M_AXI_RVALID(m_rvalid),.M_AXI_RREADY(m_rready));

  always @(posedge m_clk) begin
    if(!m_rstn) begin
      m_awready<=0;m_wready<=0;m_arready<=0;m_bvalid<=0;m_rvalid<=0;
      have_aw<=0;have_w<=0;tick<=0;
    end else begin
      tick<=tick+1;
      m_awready<=(tick[1:0]!=0); m_wready<=(tick[2:1]!=0); m_arready<=(tick[2:0]!=2);
      if(m_awvalid&&m_awready) begin have_aw<=1;aw_hold<=m_awaddr;awid_hold<=m_awid; end
      if(m_wvalid&&m_wready) begin have_w<=1;wd_hold<=m_wdata; end
      if((have_aw||(m_awvalid&&m_awready))&&(have_w||(m_wvalid&&m_wready))&&!m_bvalid) begin
        mem[(have_aw?aw_hold:m_awaddr)>>2]<=have_w?wd_hold:m_wdata;
        m_bid<=have_aw?awid_hold:m_awid;m_bresp<=0;m_bvalid<=1;
        have_aw<=0;have_w<=0;mwreq=mwreq+1;
      end else if(m_bvalid&&m_bready) m_bvalid<=0;
      if(m_arvalid&&m_arready&&!m_rvalid) begin
        m_rid<=m_arid;m_rdata<=mem[m_araddr>>2];m_rresp<=0;m_rlast<=1;m_rvalid<=1;mrreq=mrreq+1;
      end else if(m_rvalid&&m_rready) m_rvalid<=0;
      if(paw&&(!m_awvalid||m_awaddr!==pawaddr)) begin $display("CDC/RESET VIOLATION [AXI_AW_STALL_STABILITY]: destination AW changed while stalled");errors=errors+1;end
      if(pw&&(!m_wvalid||m_wdata!==pwdata)) begin $display("CDC/RESET VIOLATION [AXI_W_STALL_STABILITY]: destination W changed while stalled");errors=errors+1;end
      if(par&&(!m_arvalid||m_araddr!==paraddr)) begin $display("CDC/RESET VIOLATION [AXI_AR_STALL_STABILITY]: destination AR changed while stalled");errors=errors+1;end
      if((m_awvalid&&^m_awaddr===1'bx)||(m_wvalid&&^m_wdata===1'bx)||(m_arvalid&&^m_araddr===1'bx)) begin
        $display("CDC/RESET VIOLATION [AXI_REQUEST_KNOWN]: X on destination request");errors=errors+1;
      end
      paw<=m_awvalid&&!m_awready;pw<=m_wvalid&&!m_wready;par<=m_arvalid&&!m_arready;
      pawaddr<=m_awaddr;pwdata<=m_wdata;paraddr<=m_araddr;
    end
  end

  always @(posedge s_clk) begin
    if(!s_rstn) begin pb<=0;pr<=0;age_b<=0;age_r<=0;end
    else begin
      if(s_awvalid&&s_awready) begin wreq=wreq+1;age_b<=1;end
      if(s_arvalid&&s_arready) begin rreq=rreq+1;age_r<=1;end
      if(s_bvalid&&s_bready) begin brsp=brsp+1;age_b<=0;if(brsp>wreq)begin $display("CDC/RESET VIOLATION [AXI_WRITE_RESPONSE_COHERENCY]: B response without request");errors=errors+1;end end
      if(s_rvalid&&s_rready&&s_rlast) begin rrsp=rrsp+1;age_r<=0;if(rrsp>rreq)begin $display("CDC/RESET VIOLATION [AXI_READ_RESPONSE_COHERENCY]: R response without request");errors=errors+1;end end
      if(wreq>brsp) begin age_b<=age_b+1;if(age_b>160)begin $display("CDC/RESET VIOLATION [AXI_WRITE_CROSS_DOMAIN_LATENCY]: B response latency exceeded");errors=errors+1;age_b<=0;end end
      if(rreq>rrsp) begin age_r<=age_r+1;if(age_r>160)begin $display("CDC/RESET VIOLATION [AXI_READ_CROSS_DOMAIN_LATENCY]: R response latency exceeded");errors=errors+1;age_r<=0;end end
      if(pb&&(!s_bvalid)) begin $display("CDC/RESET VIOLATION [AXI_B_STALL_STABILITY]: B response dropped while stalled");errors=errors+1;end
      if(pr&&(!s_rvalid||s_rdata!==prdata)) begin $display("CDC/RESET VIOLATION [AXI_R_STALL_STABILITY]: R response changed while stalled");errors=errors+1;end
      if((s_bvalid&&^s_bresp===1'bx)||(s_rvalid&&^s_rdata===1'bx))begin $display("CDC/RESET VIOLATION [AXI_RESPONSE_KNOWN]: X on source response");errors=errors+1;end
      pb<=s_bvalid&&!s_bready;pr<=s_rvalid&&!s_rready;prdata<=s_rdata;
    end
  end

  task write_one;
    input [7:0] a;input [31:0] d;
    begin
      @(negedge s_clk);s_awid=1;s_awaddr=a;s_awvalid=1;s_wdata=d;s_wstrb=4'hf;s_wlast=1;s_wvalid=1;s_bready=0;
      while(s_awvalid||s_wvalid)begin @(negedge s_clk);if(s_awready)s_awvalid=0;if(s_wready)s_wvalid=0;end
      repeat(5)@(negedge s_clk);s_bready=1;while(!s_bvalid)@(negedge s_clk);
      @(negedge s_clk);s_bready=0;s_wlast=0;
    end
  endtask
  task read_one;
    input [7:0] a;input [31:0] e;
    begin
      @(negedge s_clk);s_arid=2;s_araddr=a;s_arvalid=1;s_rready=0;
      while(!s_arready)@(negedge s_clk);@(negedge s_clk);s_arvalid=0;
      repeat(4)@(negedge s_clk);s_rready=1;while(!s_rvalid)@(negedge s_clk);
      if(s_rdata!==e||!s_rlast)begin $display("CDC/RESET VIOLATION [AXI_DATA_COHERENCY]: read %h expected %h",s_rdata,e);errors=errors+1;end
      @(negedge s_clk);s_rready=0;
    end
  endtask

  initial begin
    errors=0;wreq=0;brsp=0;rreq=0;rrsp=0;mwreq=0;mrreq=0;tick=0;age_b=0;age_r=0;
    s_clk=0;m_clk=0;s_rstn=0;s_awid=0;s_awaddr=0;s_awlen=0;s_awsize=2;s_awburst=1;s_awvalid=0;
    s_wdata=0;s_wstrb=0;s_wlast=0;s_wvalid=0;s_bready=0;s_arid=0;s_araddr=0;s_arlen=0;s_arsize=2;s_arburst=1;s_arvalid=0;s_rready=0;
    m_awready=0;m_wready=0;m_bvalid=0;m_arready=0;m_rvalid=0;m_rlast=0;m_bid=0;m_rid=0;m_bresp=0;m_rresp=0;m_rdata=0;
    have_aw=0;have_w=0;paw=0;pw=0;par=0;pb=0;pr=0;
    for(i=0;i<64;i=i+1)mem[i]=0;
    repeat(7)@(posedge s_clk);s_rstn=1;repeat(10)@(posedge s_clk);
    write_one(8'h10,32'h11112222);read_one(8'h10,32'h11112222);
    write_one(8'h14,32'ha5a55a5a);read_one(8'h14,32'ha5a55a5a);
    @(negedge s_clk);s_araddr=8'h18;s_arvalid=1;
    repeat(2)@(posedge m_clk);s_rstn=0;s_arvalid=0;
    repeat(8)@(posedge s_clk);s_rstn=1;repeat(12)@(posedge s_clk);
    wreq=0;brsp=0;rreq=0;rrsp=0;mwreq=0;mrreq=0;
    write_one(8'h18,32'hcafef00d);read_one(8'h18,32'hcafef00d);
    if(wreq!=brsp||wreq!=mwreq||rreq!=rrsp||rreq!=mrreq)begin $display("CDC/RESET VIOLATION [AXI_TRANSACTION_CONSERVATION]: source and destination transaction counts differ");errors=errors+1;end
    if(errors==0)$display("AXIXCLK ENHANCED: ALL TESTS PASSED");else $display("AXIXCLK ENHANCED: TESTS FAILED (%0d)",errors);
    $finish;
  end
  initial begin #220000;$display("AXIXCLK ENHANCED: TIMEOUT");$finish;end
endmodule
