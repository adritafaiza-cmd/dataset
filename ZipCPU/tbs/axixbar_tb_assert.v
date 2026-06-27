`timescale 1ns/1ps
`default_nettype none

module axixbar_assert;

  localparam NM = 2;
  localparam NS = 2;
  localparam AW = 8;
  localparam DW = 32;
  localparam IW = 2;

  reg clk = 0;
  reg rstn = 0;

  integer errors = 0;

  always #5 clk = ~clk;

  // Slave-side AXI signals
  reg  [NM-1:0] s_awvalid;
  wire [NM-1:0] s_awready;
  reg  [NM*IW-1:0] s_awid;
  reg  [NM*AW-1:0] s_awaddr;
  reg  [NM*8-1:0] s_awlen;
  reg  [NM*3-1:0] s_awsize;
  reg  [NM*2-1:0] s_awburst;
  reg  [NM-1:0] s_awlock;
  reg  [NM*4-1:0] s_awcache;
  reg  [NM*3-1:0] s_awprot;
  reg  [NM*4-1:0] s_awqos;

  reg  [NM-1:0] s_wvalid;
  wire [NM-1:0] s_wready;
  reg  [NM*DW-1:0] s_wdata;
  reg  [NM*DW/8-1:0] s_wstrb;
  reg  [NM-1:0] s_wlast;

  wire [NM-1:0] s_bvalid;
  reg  [NM-1:0] s_bready;
  wire [NM*IW-1:0] s_bid;
  wire [NM*2-1:0] s_bresp;

  reg  [NM-1:0] s_arvalid;
  wire [NM-1:0] s_arready;
  reg  [NM*IW-1:0] s_arid;
  reg  [NM*AW-1:0] s_araddr;
  reg  [NM*8-1:0] s_arlen;
  reg  [NM*3-1:0] s_arsize;
  reg  [NM*2-1:0] s_arburst;
  reg  [NM-1:0] s_arlock;
  reg  [NM*4-1:0] s_arcache;
  reg  [NM*3-1:0] s_arprot;
  reg  [NM*4-1:0] s_arqos;

  wire [NM-1:0] s_rvalid;
  reg  [NM-1:0] s_rready;
  wire [NM*IW-1:0] s_rid;
  wire [NM*DW-1:0] s_rdata;
  wire [NM*2-1:0] s_rresp;
  wire [NM-1:0] s_rlast;

  // Master-side AXI signals
  wire [NS-1:0] m_awvalid;
  reg  [NS-1:0] m_awready;
  wire [NS*IW-1:0] m_awid;
  wire [NS*AW-1:0] m_awaddr;
  wire [NS*8-1:0] m_awlen;
  wire [NS*3-1:0] m_awsize;
  wire [NS*2-1:0] m_awburst;
  wire [NS-1:0] m_awlock;
  wire [NS*4-1:0] m_awcache;
  wire [NS*3-1:0] m_awprot;
  wire [NS*4-1:0] m_awqos;

  wire [NS-1:0] m_wvalid;
  reg  [NS-1:0] m_wready;
  wire [NS*DW-1:0] m_wdata;
  wire [NS*DW/8-1:0] m_wstrb;
  wire [NS-1:0] m_wlast;

  reg  [NS-1:0] m_bvalid;
  wire [NS-1:0] m_bready;
  reg  [NS*IW-1:0] m_bid;
  reg  [NS*2-1:0] m_bresp;

  wire [NS-1:0] m_arvalid;
  reg  [NS-1:0] m_arready;
  wire [NS*IW-1:0] m_arid;
  wire [NS*AW-1:0] m_araddr;
  wire [NS*8-1:0] m_arlen;
  wire [NS*3-1:0] m_arsize;
  wire [NS*2-1:0] m_arburst;
  wire [NS-1:0] m_arlock;
  wire [NS*4-1:0] m_arcache;
  wire [NS*3-1:0] m_arprot;
  wire [NS*4-1:0] m_arqos;

  reg  [NS-1:0] m_rvalid;
  wire [NS-1:0] m_rready;
  reg  [NS*IW-1:0] m_rid;
  reg  [NS*DW-1:0] m_rdata;
  reg  [NS*2-1:0] m_rresp;
  reg  [NS-1:0] m_rlast;

  axixbar #(
    .C_AXI_DATA_WIDTH(DW),
    .C_AXI_ADDR_WIDTH(AW),
    .C_AXI_ID_WIDTH(IW),
    .NM(NM),
    .NS(NS),
    .SLAVE_ADDR({8'h80, 8'h00}),
    .SLAVE_MASK({8'h80, 8'h80}),
    .OPT_LINGER(1),
    .LGMAXBURST(2)
  ) dut (
    .S_AXI_ACLK(clk),
    .S_AXI_ARESETN(rstn),

    .S_AXI_AWVALID(s_awvalid),
    .S_AXI_AWREADY(s_awready),
    .S_AXI_AWID(s_awid),
    .S_AXI_AWADDR(s_awaddr),
    .S_AXI_AWLEN(s_awlen),
    .S_AXI_AWSIZE(s_awsize),
    .S_AXI_AWBURST(s_awburst),
    .S_AXI_AWLOCK(s_awlock),
    .S_AXI_AWCACHE(s_awcache),
    .S_AXI_AWPROT(s_awprot),
    .S_AXI_AWQOS(s_awqos),

    .S_AXI_WVALID(s_wvalid),
    .S_AXI_WREADY(s_wready),
    .S_AXI_WDATA(s_wdata),
    .S_AXI_WSTRB(s_wstrb),
    .S_AXI_WLAST(s_wlast),

    .S_AXI_BVALID(s_bvalid),
    .S_AXI_BREADY(s_bready),
    .S_AXI_BID(s_bid),
    .S_AXI_BRESP(s_bresp),

    .S_AXI_ARVALID(s_arvalid),
    .S_AXI_ARREADY(s_arready),
    .S_AXI_ARID(s_arid),
    .S_AXI_ARADDR(s_araddr),
    .S_AXI_ARLEN(s_arlen),
    .S_AXI_ARSIZE(s_arsize),
    .S_AXI_ARBURST(s_arburst),
    .S_AXI_ARLOCK(s_arlock),
    .S_AXI_ARCACHE(s_arcache),
    .S_AXI_ARPROT(s_arprot),
    .S_AXI_ARQOS(s_arqos),

    .S_AXI_RVALID(s_rvalid),
    .S_AXI_RREADY(s_rready),
    .S_AXI_RID(s_rid),
    .S_AXI_RDATA(s_rdata),
    .S_AXI_RRESP(s_rresp),
    .S_AXI_RLAST(s_rlast),

    .M_AXI_AWVALID(m_awvalid),
    .M_AXI_AWREADY(m_awready),
    .M_AXI_AWID(m_awid),
    .M_AXI_AWADDR(m_awaddr),
    .M_AXI_AWLEN(m_awlen),
    .M_AXI_AWSIZE(m_awsize),
    .M_AXI_AWBURST(m_awburst),
    .M_AXI_AWLOCK(m_awlock),
    .M_AXI_AWCACHE(m_awcache),
    .M_AXI_AWPROT(m_awprot),
    .M_AXI_AWQOS(m_awqos),

    .M_AXI_WVALID(m_wvalid),
    .M_AXI_WREADY(m_wready),
    .M_AXI_WDATA(m_wdata),
    .M_AXI_WSTRB(m_wstrb),
    .M_AXI_WLAST(m_wlast),

    .M_AXI_BVALID(m_bvalid),
    .M_AXI_BREADY(m_bready),
    .M_AXI_BID(m_bid),
    .M_AXI_BRESP(m_bresp),

    .M_AXI_ARVALID(m_arvalid),
    .M_AXI_ARREADY(m_arready),
    .M_AXI_ARID(m_arid),
    .M_AXI_ARADDR(m_araddr),
    .M_AXI_ARLEN(m_arlen),
    .M_AXI_ARSIZE(m_arsize),
    .M_AXI_ARBURST(m_arburst),
    .M_AXI_ARLOCK(m_arlock),
    .M_AXI_ARCACHE(m_arcache),
    .M_AXI_ARQOS(m_arqos),
    .M_AXI_ARPROT(m_arprot),

    .M_AXI_RVALID(m_rvalid),
    .M_AXI_RREADY(m_rready),
    .M_AXI_RID(m_rid),
    .M_AXI_RDATA(m_rdata),
    .M_AXI_RRESP(m_rresp),
    .M_AXI_RLAST(m_rlast)
  );

  task check;
    input cond;
    input [255:0] msg;
    begin
      if (cond) begin
        $display("PASS: %s", msg);
      end else begin
        $display("FAIL: %s", msg);
        errors = errors + 1;
      end
    end
  endtask

  task axi_write_m0;
    input [AW-1:0] addr;
    input [DW-1:0] data;
    integer sl;
    begin
      sl = addr[7] ? 1 : 0;

      @(negedge clk);

      s_awid[0 +: IW] = 1;
      s_awaddr[0 +: AW] = addr;
      s_awlen[0 +: 8] = 0;
      s_awsize[0 +: 3] = 3'd2;
      s_awburst[0 +: 2] = 2'b01;
      s_awlock[0] = 1'b0;
      s_awcache[0 +: 4] = 4'b0011;
      s_awprot[0 +: 3] = 3'b000;
      s_awqos[0 +: 4] = 4'b0000;

      s_wdata[0 +: DW] = data;
      s_wstrb[0 +: DW/8] = 4'hf;
      s_wlast[0] = 1'b1;

      s_awvalid[0] = 1'b1;
      s_wvalid[0] = 1'b1;
      s_bready[0] = 1'b1;

      m_awready[sl] = 1'b1;
      m_wready[sl] = 1'b1;

      wait (m_awvalid[sl]);
      check(m_awaddr[sl*AW +: AW] == addr, "AXIXBAR write address route");

      wait (m_wvalid[sl]);
      check(m_wdata[sl*DW +: DW] == data, "AXIXBAR write data route");

      wait (s_awready[0] && s_wready[0]);

      @(negedge clk);

      s_awvalid[0] = 1'b0;
      s_wvalid[0] = 1'b0;
      m_awready[sl] = 1'b0;
      m_wready[sl] = 1'b0;

      @(negedge clk);

      m_bid[sl*IW +: IW] = m_awid[sl*IW +: IW];
      m_bresp[sl*2 +: 2] = 2'b00;
      m_bvalid[sl] = 1'b1;

      wait (s_bvalid[0]);
      check(s_bresp[0 +: 2] == 2'b00, "AXIXBAR write response OKAY");

      @(negedge clk);

      m_bvalid[sl] = 1'b0;
      s_bready[0] = 1'b0;

      repeat (3) @(posedge clk);
    end
  endtask

  task axi_read_m1;
    input [AW-1:0] addr;
    input [DW-1:0] data;
    integer sl;
    begin
      sl = addr[7] ? 1 : 0;

      @(negedge clk);

      s_arid[IW +: IW] = 2;
      s_araddr[AW +: AW] = addr;
      s_arlen[8 +: 8] = 0;
      s_arsize[3 +: 3] = 3'd2;
      s_arburst[2 +: 2] = 2'b01;
      s_arlock[1] = 1'b0;
      s_arcache[4 +: 4] = 4'b0011;
      s_arprot[3 +: 3] = 3'b000;
      s_arqos[4 +: 4] = 4'b0000;

      s_arvalid[1] = 1'b1;
      s_rready[1] = 1'b1;

      m_arready[sl] = 1'b1;

      wait (m_arvalid[sl]);
      check(m_araddr[sl*AW +: AW] == addr, "AXIXBAR read address route");

      wait (s_arready[1]);

      @(negedge clk);

      s_arvalid[1] = 1'b0;
      m_arready[sl] = 1'b0;

      @(negedge clk);

      m_rid[sl*IW +: IW] = m_arid[sl*IW +: IW];
      m_rdata[sl*DW +: DW] = data;
      m_rresp[sl*2 +: 2] = 2'b00;
      m_rlast[sl] = 1'b1;
      m_rvalid[sl] = 1'b1;

      wait (s_rvalid[1]);
      check(s_rdata[DW +: DW] == data, "AXIXBAR read data return");

      @(negedge clk);

      m_rvalid[sl] = 1'b0;
      s_rready[1] = 1'b0;

      repeat (3) @(posedge clk);
    end
  endtask

  initial begin
    s_awvalid = 0;
    s_wvalid = 0;
    s_bready = 0;
    s_arvalid = 0;
    s_rready = 0;
    s_wlast = 0;

    s_awid = 0;
    s_awaddr = 0;
    s_awlen = 0;
    s_awsize = 0;
    s_awburst = 0;
    s_awlock = 0;
    s_awcache = 0;
    s_awprot = 0;
    s_awqos = 0;

    s_arid = 0;
    s_araddr = 0;
    s_arlen = 0;
    s_arsize = 0;
    s_arburst = 0;
    s_arlock = 0;
    s_arcache = 0;
    s_arprot = 0;
    s_arqos = 0;

    s_wdata = 0;
    s_wstrb = 0;

    m_awready = 0;
    m_wready = 0;
    m_bvalid = 0;
    m_arready = 0;
    m_rvalid = 0;
    m_rlast = 0;

    m_bid = 0;
    m_bresp = 0;
    m_rid = 0;
    m_rresp = 0;
    m_rdata = 0;

    repeat (5) @(posedge clk);
    rstn = 1'b1;

    repeat (5) @(posedge clk);

    $display("TEST AXIXBAR");

    axi_write_m0(8'h04, 32'haaaa5555);
    repeat (5) @(posedge clk);

    axi_write_m0(8'h84, 32'hbbbb6666);
    repeat (5) @(posedge clk);

    axi_read_m1(8'h08, 32'hcccc7777);
    repeat (5) @(posedge clk);

    axi_read_m1(8'h88, 32'hdddd8888);
    repeat (5) @(posedge clk);

    if (errors == 0) begin
      $display("ALL TESTS PASSED");
    end else begin
      $display("TESTS FAILED: %0d errors", errors);
    end

    $finish;
  end

endmodule

`default_nettype wire
