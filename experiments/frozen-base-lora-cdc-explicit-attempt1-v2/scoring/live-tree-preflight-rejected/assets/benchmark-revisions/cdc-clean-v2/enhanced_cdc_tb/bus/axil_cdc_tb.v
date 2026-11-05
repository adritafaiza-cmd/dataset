`timescale 1ns/1ps
module axil_cdc_tb;
  integer errors, swr, sbr, srd, srr, mwr, mrd, age_b, age_r, tick, i;
  reg s_clk,m_clk,s_rst,m_rst;
  reg [7:0] s_awaddr,s_araddr;
  reg [31:0] s_wdata;
  reg s_awvalid,s_wvalid,s_bready,s_arvalid,s_rready;
  wire s_awready,s_wready,s_bvalid,s_arready,s_rvalid;
  wire [1:0] s_bresp,s_rresp;
  wire [31:0] s_rdata;
  wire [7:0] m_awaddr,m_araddr;
  wire [31:0] m_wdata;
  wire [3:0] m_wstrb;
  wire [2:0] m_awprot,m_arprot;
  wire m_awvalid,m_wvalid,m_bready,m_arvalid,m_rready;
  reg m_awready,m_wready,m_bvalid,m_arready,m_rvalid;
  reg [1:0] m_bresp,m_rresp;
  reg [31:0] m_rdata;
  reg [31:0] mem[0:15];
  reg have_aw,have_w;
  reg [7:0] aw_hold;
  reg [31:0] w_hold;
  reg ps_aw,ps_w,ps_ar,ps_b,ps_r;
  reg [7:0] p_awaddr,p_araddr;
  reg [31:0] p_wdata,p_rdata;
  reg [1:0] p_bresp,p_rresp;

  always #5 s_clk=~s_clk;
  always #8 m_clk=~m_clk;
  axil_cdc #(.DATA_WIDTH(32),.ADDR_WIDTH(8)) dut(
    .s_clk(s_clk),.s_rst(s_rst),.s_axil_awaddr(s_awaddr),.s_axil_awprot(3'b0),
    .s_axil_awvalid(s_awvalid),.s_axil_awready(s_awready),
    .s_axil_wdata(s_wdata),.s_axil_wstrb(4'hf),.s_axil_wvalid(s_wvalid),
    .s_axil_wready(s_wready),.s_axil_bresp(s_bresp),.s_axil_bvalid(s_bvalid),
    .s_axil_bready(s_bready),.s_axil_araddr(s_araddr),.s_axil_arprot(3'b0),
    .s_axil_arvalid(s_arvalid),.s_axil_arready(s_arready),
    .s_axil_rdata(s_rdata),.s_axil_rresp(s_rresp),.s_axil_rvalid(s_rvalid),
    .s_axil_rready(s_rready),.m_clk(m_clk),.m_rst(m_rst),
    .m_axil_awaddr(m_awaddr),.m_axil_awprot(m_awprot),
    .m_axil_awvalid(m_awvalid),.m_axil_awready(m_awready),
    .m_axil_wdata(m_wdata),.m_axil_wstrb(m_wstrb),
    .m_axil_wvalid(m_wvalid),.m_axil_wready(m_wready),
    .m_axil_bresp(m_bresp),.m_axil_bvalid(m_bvalid),.m_axil_bready(m_bready),
    .m_axil_araddr(m_araddr),.m_axil_arprot(m_arprot),
    .m_axil_arvalid(m_arvalid),.m_axil_arready(m_arready),
    .m_axil_rdata(m_rdata),.m_axil_rresp(m_rresp),
    .m_axil_rvalid(m_rvalid),.m_axil_rready(m_rready));

  always @(posedge m_clk) begin
    if(m_rst) begin
      m_awready<=0; m_wready<=0; m_arready<=0; m_bvalid<=0; m_rvalid<=0;
      have_aw<=0; have_w<=0; tick<=0;
    end else begin
      tick<=tick+1;
      m_awready<=(tick[1:0]!=0);
      m_wready<=(tick[2:1]!=0);
      m_arready<=(tick[2:0]!=3);
      if(m_awvalid && m_awready) begin have_aw<=1; aw_hold<=m_awaddr; end
      if(m_wvalid && m_wready) begin have_w<=1; w_hold<=m_wdata; end
      if((have_aw || (m_awvalid&&m_awready)) &&
         (have_w || (m_wvalid&&m_wready)) && !m_bvalid) begin
        mem[(have_aw?aw_hold:m_awaddr)>>2] <= have_w?w_hold:m_wdata;
        have_aw<=0; have_w<=0; m_bvalid<=1; m_bresp<=0; mwr=mwr+1;
      end else if(m_bvalid&&m_bready) m_bvalid<=0;
      if(m_arvalid&&m_arready&&!m_rvalid) begin
        m_rdata<=mem[m_araddr[5:2]]; m_rresp<=0; m_rvalid<=1; mrd=mrd+1;
      end else if(m_rvalid&&m_rready) m_rvalid<=0;
      if(ps_aw&&(!m_awvalid||m_awaddr!==p_awaddr)) begin $display("CDC/RESET VIOLATION [AXIL_AW_STALL_STABILITY]: destination AW changed while stalled"); errors=errors+1; end
      if(ps_w&&(!m_wvalid||m_wdata!==p_wdata)) begin $display("CDC/RESET VIOLATION [AXIL_W_STALL_STABILITY]: destination W changed while stalled"); errors=errors+1; end
      if(ps_ar&&(!m_arvalid||m_araddr!==p_araddr)) begin $display("CDC/RESET VIOLATION [AXIL_AR_STALL_STABILITY]: destination AR changed while stalled"); errors=errors+1; end
      if((m_awvalid&&^m_awaddr===1'bx)||(m_wvalid&&^m_wdata===1'bx)||
         (m_arvalid&&^m_araddr===1'bx)) begin $display("CDC/RESET VIOLATION [AXIL_REQUEST_KNOWN]: X on destination request"); errors=errors+1; end
      ps_aw<=m_awvalid&&!m_awready; ps_w<=m_wvalid&&!m_wready;
      ps_ar<=m_arvalid&&!m_arready; p_awaddr<=m_awaddr; p_wdata<=m_wdata; p_araddr<=m_araddr;
    end
  end

  always @(posedge s_clk) begin
    if(s_rst) begin ps_b<=0; ps_r<=0; age_b<=0; age_r<=0; end
    else begin
      if(s_awvalid&&s_awready) swr=swr+1;
      if(s_arvalid&&s_arready) begin srd=srd+1; age_r<=1; end
      if(s_bvalid&&s_bready) begin
        sbr=sbr+1; age_b<=0;
        if(sbr>swr) begin $display("CDC/RESET VIOLATION [AXIL_WRITE_RESPONSE_COHERENCY]: B response without write"); errors=errors+1; end
      end
      if(s_rvalid&&s_rready) begin
        srr=srr+1; age_r<=0;
        if(srr>srd) begin $display("CDC/RESET VIOLATION [AXIL_READ_RESPONSE_COHERENCY]: R response without read"); errors=errors+1; end
      end
      if(swr>sbr) begin age_b<=age_b+1; if(age_b>120) begin $display("CDC/RESET VIOLATION [AXIL_WRITE_CROSS_DOMAIN_LATENCY]: B response latency exceeded"); errors=errors+1; age_b<=0; end end
      if(srd>srr) begin age_r<=age_r+1; if(age_r>120) begin $display("CDC/RESET VIOLATION [AXIL_READ_CROSS_DOMAIN_LATENCY]: R response latency exceeded"); errors=errors+1; age_r<=0; end end
      if(ps_b&&(!s_bvalid||s_bresp!==p_bresp)) begin $display("CDC/RESET VIOLATION [AXIL_B_STALL_STABILITY]: source B changed while stalled"); errors=errors+1; end
      if(ps_r&&(!s_rvalid||s_rdata!==p_rdata||s_rresp!==p_rresp)) begin $display("CDC/RESET VIOLATION [AXIL_R_STALL_STABILITY]: source R changed while stalled"); errors=errors+1; end
      if((s_bvalid&&^s_bresp===1'bx)||(s_rvalid&&((^s_rdata===1'bx)||(^s_rresp===1'bx)))) begin
        $display("CDC/RESET VIOLATION [AXIL_RESPONSE_KNOWN]: X on source response"); errors=errors+1;
      end
      ps_b<=s_bvalid&&!s_bready; ps_r<=s_rvalid&&!s_rready;
      p_bresp<=s_bresp; p_rdata<=s_rdata; p_rresp<=s_rresp;
    end
  end

  task write_word;
    input [7:0] a; input [31:0] d;
    reg aw_done, w_done;
    begin
      @(negedge s_clk); s_awaddr=a; s_wdata=d; s_awvalid=1; s_wvalid=1; s_bready=0;
      while(s_awvalid||s_wvalid) begin
        @(posedge s_clk); aw_done=s_awvalid&&s_awready; w_done=s_wvalid&&s_wready;
        #1;
        if(aw_done) s_awvalid=0;
        if(w_done) s_wvalid=0;
      end
      repeat(3) @(negedge s_clk); s_bready=1;
      while(!s_bvalid) @(negedge s_clk);
      @(negedge s_clk); s_bready=0;
    end
  endtask
  task read_check;
    input [7:0] a; input [31:0] e;
    reg ar_done;
    begin
      @(negedge s_clk); s_araddr=a; s_arvalid=1; s_rready=0;
      ar_done=0;
      while(!ar_done) begin @(posedge s_clk); ar_done=s_arvalid&&s_arready; end
      #1 s_arvalid=0;
      repeat(4) @(negedge s_clk); s_rready=1;
      while(!s_rvalid) @(negedge s_clk);
      if(s_rdata!==e) begin $display("CDC/RESET VIOLATION [AXIL_DATA_COHERENCY]: read %h expected %h",s_rdata,e); errors=errors+1; end
      @(negedge s_clk); s_rready=0;
    end
  endtask

  initial begin
    errors=0;swr=0;sbr=0;srd=0;srr=0;mwr=0;mrd=0;age_b=0;age_r=0;tick=0;
    s_clk=0;m_clk=0;s_rst=1;m_rst=1;s_awaddr=0;s_araddr=0;s_wdata=0;
    s_awvalid=0;s_wvalid=0;s_bready=0;s_arvalid=0;s_rready=0;
    m_awready=0;m_wready=0;m_arready=0;m_bvalid=0;m_rvalid=0;m_bresp=0;m_rresp=0;m_rdata=0;
    have_aw=0;have_w=0;ps_aw=0;ps_w=0;ps_ar=0;ps_b=0;ps_r=0;
    for(i=0;i<16;i=i+1) mem[i]=0;
    repeat(5) @(posedge s_clk); s_rst=0;
    repeat(4) @(posedge m_clk); m_rst=0;
    write_word(8'h04,32'h12345678); read_check(8'h04,32'h12345678);
    write_word(8'h08,32'ha5a55a5a); read_check(8'h08,32'ha5a55a5a);
    /* Reset each clock domain independently before the active reset case. */
    m_rst=1; repeat(3) @(posedge m_clk); m_rst=0;
    repeat(5) @(posedge s_clk);
    s_rst=1; repeat(3) @(posedge s_clk); s_rst=0;
    repeat(5) @(posedge m_clk);
    swr=0;sbr=0;srd=0;srr=0;mwr=0;mrd=0;
    @(negedge s_clk); s_araddr=8'h0c;s_arvalid=1;
    repeat(2) @(posedge m_clk); s_rst=1;m_rst=1;s_arvalid=0;
    repeat(4) @(posedge m_clk); m_rst=0;
    repeat(4) @(posedge s_clk); s_rst=0;
    swr=0;sbr=0;srd=0;srr=0;mwr=0;mrd=0;
    repeat(8) @(posedge s_clk);
    write_word(8'h0c,32'hcafef00d); read_check(8'h0c,32'hcafef00d);
    if(swr!=sbr||swr!=mwr||srd!=srr||srd!=mrd) begin
      $display("CDC/RESET VIOLATION [AXIL_TRANSACTION_CONSERVATION]: W %0d/%0d/%0d R %0d/%0d/%0d",swr,sbr,mwr,srd,srr,mrd); errors=errors+1;
    end
    if(errors==0) $display("AXIL CDC ENHANCED: ALL TESTS PASSED");
    else $display("AXIL CDC ENHANCED: TESTS FAILED (%0d)",errors);
    $finish;
  end
  initial begin #180000; $display("AXIL CDC ENHANCED: TIMEOUT"); $finish; end
endmodule
