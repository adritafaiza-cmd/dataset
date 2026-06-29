`timescale 1ns/1ps
`default_nettype none

module axilxbar_assert;

  localparam NM = 2;
  localparam NS = 2;
  localparam AW = 8;
  localparam DW = 32;
  localparam TIMEOUT = 100;

  reg clk = 0;
  reg rstn = 0;
  integer errors = 0;
  integer t;

  always #5 clk = ~clk;

  reg  [NM-1:0] s_awvalid, s_wvalid, s_bready, s_arvalid, s_rready;
  wire [NM-1:0] s_awready, s_wready, s_bvalid, s_arready, s_rvalid;

  reg  [NM*AW-1:0] s_awaddr, s_araddr;
  reg  [NM*3-1:0]  s_awprot, s_arprot;
  reg  [NM*DW-1:0] s_wdata;
  reg  [NM*DW/8-1:0] s_wstrb;

  wire [NM*2-1:0]  s_bresp, s_rresp;
  wire [NM*DW-1:0] s_rdata;

  wire [NS*AW-1:0] m_awaddr, m_araddr;
  wire [NS*3-1:0]  m_awprot, m_arprot;
  wire [NS-1:0] m_awvalid, m_wvalid, m_bready, m_arvalid, m_rready;

  reg  [NS-1:0] m_awready, m_wready, m_bvalid, m_arready, m_rvalid;
  wire [NS*DW-1:0] m_wdata;
  wire [NS*DW/8-1:0] m_wstrb;

  reg [NS*2-1:0]  m_bresp, m_rresp;
  reg [NS*DW-1:0] m_rdata;

  axilxbar #(
    .C_AXI_DATA_WIDTH(DW),
    .C_AXI_ADDR_WIDTH(AW),
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
    .S_AXI_AWADDR(s_awaddr),
    .S_AXI_AWPROT(s_awprot),

    .S_AXI_WVALID(s_wvalid),
    .S_AXI_WREADY(s_wready),
    .S_AXI_WDATA(s_wdata),
    .S_AXI_WSTRB(s_wstrb),

    .S_AXI_BVALID(s_bvalid),
    .S_AXI_BREADY(s_bready),
    .S_AXI_BRESP(s_bresp),

    .S_AXI_ARVALID(s_arvalid),
    .S_AXI_ARREADY(s_arready),
    .S_AXI_ARADDR(s_araddr),
    .S_AXI_ARPROT(s_arprot),

    .S_AXI_RVALID(s_rvalid),
    .S_AXI_RREADY(s_rready),
    .S_AXI_RDATA(s_rdata),
    .S_AXI_RRESP(s_rresp),

    .M_AXI_AWADDR(m_awaddr),
    .M_AXI_AWPROT(m_awprot),
    .M_AXI_AWVALID(m_awvalid),
    .M_AXI_AWREADY(m_awready),

    .M_AXI_WDATA(m_wdata),
    .M_AXI_WSTRB(m_wstrb),
    .M_AXI_WVALID(m_wvalid),
    .M_AXI_WREADY(m_wready),

    .M_AXI_BRESP(m_bresp),
    .M_AXI_BVALID(m_bvalid),
    .M_AXI_BREADY(m_bready),

    .M_AXI_ARADDR(m_araddr),
    .M_AXI_ARPROT(m_arprot),
    .M_AXI_ARVALID(m_arvalid),
    .M_AXI_ARREADY(m_arready),

    .M_AXI_RDATA(m_rdata),
    .M_AXI_RRESP(m_rresp),
    .M_AXI_RVALID(m_rvalid),
    .M_AXI_RREADY(m_rready)
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

  task wait_or_timeout;
    input condition;
    input [255:0] msg;
    begin
      t = 0;
      while (!condition && t < TIMEOUT) begin
        @(posedge clk);
        t = t + 1;
      end

      if (!condition) begin
        $display("TIMEOUT: %s", msg);
        errors = errors + 1;
      end else begin
        $display("OK: %s", msg);
      end
    end
  endtask

  task axil_write_m0;
    input [AW-1:0] addr;
    input [DW-1:0] data;
    integer slave;
    begin
      slave = addr[7] ? 1 : 0;

      @(negedge clk);
      s_awaddr[0 +: AW] = addr;
      s_wdata[0 +: DW] = data;
      s_wstrb[0 +: DW/8] = 4'hf;

      s_awvalid[0] = 1'b1;
      s_wvalid[0]  = 1'b1;
      s_bready[0]  = 1'b1;

      m_awready[slave] = 1'b1;
      m_wready[slave]  = 1'b1;

      wait_or_timeout(m_awvalid[slave], "m_awvalid asserted");
      check(m_awaddr[slave*AW +: AW] == addr, "xbar routed write address");

      wait_or_timeout(m_wvalid[slave], "m_wvalid asserted");
      check(m_wdata[slave*DW +: DW] == data, "xbar routed write data");

      wait_or_timeout(s_awready[0], "s_awready asserted");
      wait_or_timeout(s_wready[0], "s_wready asserted");

      @(negedge clk);
      s_awvalid[0] = 1'b0;
      s_wvalid[0]  = 1'b0;
      m_awready[slave] = 1'b0;
      m_wready[slave]  = 1'b0;

      repeat (2) @(posedge clk);

      m_bresp[slave*2 +: 2] = 2'b00;
      m_bvalid[slave] = 1'b1;

      wait_or_timeout(s_bvalid[0], "s_bvalid asserted");
      check(s_bresp[0 +: 2] == 2'b00, "xbar returned write response");

      @(negedge clk);
      m_bvalid[slave] = 1'b0;
      s_bready[0] = 1'b0;

      repeat (5) @(posedge clk);
    end
  endtask

  task axil_read_m1;
    input [AW-1:0] addr;
    input [DW-1:0] data;
    integer slave;
    begin
      slave = addr[7] ? 1 : 0;

      @(negedge clk);
      s_araddr[AW +: AW] = addr;
      s_arvalid[1] = 1'b1;
      s_rready[1]  = 1'b1;

      m_arready[slave] = 1'b1;

      wait_or_timeout(m_arvalid[slave], "m_arvalid asserted");
      check(m_araddr[slave*AW +: AW] == addr, "xbar routed read address");

      wait_or_timeout(s_arready[1], "s_arready asserted");

      @(negedge clk);
      s_arvalid[1] = 1'b0;
      m_arready[slave] = 1'b0;

      repeat (2) @(posedge clk);

      m_rdata[slave*DW +: DW] = data;
      m_rresp[slave*2 +: 2] = 2'b00;
      m_rvalid[slave] = 1'b1;

      wait_or_timeout(s_rvalid[1], "s_rvalid asserted");
      check(s_rdata[DW +: DW] == data, "xbar returned read data");

      @(negedge clk);
      m_rvalid[slave] = 1'b0;
      s_rready[1] = 1'b0;

      repeat (5) @(posedge clk);
    end
  endtask

  initial begin
    s_awvalid = 0;
    s_wvalid  = 0;
    s_bready  = 0;
    s_arvalid = 0;
    s_rready  = 0;

    s_awaddr = 0;
    s_araddr = 0;
    s_awprot = 0;
    s_arprot = 0;
    s_wdata  = 0;
    s_wstrb  = 0;

    m_awready = 0;
    m_wready  = 0;
    m_bvalid  = 0;
    m_arready = 0;
    m_rvalid  = 0;

    m_bresp = 0;
    m_rresp = 0;
    m_rdata = 0;

    repeat (5) @(posedge clk);
    rstn = 1'b1;

    repeat (5) @(posedge clk);

    $display("TEST AXILXBAR");

    axil_write_m0(8'h04, 32'h11112222);
    axil_write_m0(8'h84, 32'h33334444);

    axil_read_m1(8'h08, 32'h55556666);
    axil_read_m1(8'h88, 32'h77778888);

    if (errors == 0) begin
      $display("ALL TESTS PASSED");
    end else begin
      $display("TESTS FAILED: %0d errors", errors);
    end

    $finish;
  end

endmodule

`default_nettype wire
