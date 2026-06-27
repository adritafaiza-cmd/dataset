`timescale 1ns/1ps
`default_nettype none

module axilxbar_assert;

  localparam NM = 2;
  localparam NS = 2;
  localparam AW = 8;
  localparam DW = 32;

  reg clk = 0;
  reg rstn = 0;

  integer errors = 0;

  always #5 clk = ~clk;

  // Slave-side AXI-Lite signals
  reg  [NM-1:0] s_awvalid;
  wire [NM-1:0] s_awready;
  reg  [NM*AW-1:0] s_awaddr;
  reg  [NM*3-1:0] s_awprot;

  reg  [NM-1:0] s_wvalid;
  wire [NM-1:0] s_wready;
  reg  [NM*DW-1:0] s_wdata;
  reg  [NM*DW/8-1:0] s_wstrb;

  wire [NM-1:0] s_bvalid;
  reg  [NM-1:0] s_bready;
  wire [NM*2-1:0] s_bresp;

  reg  [NM-1:0] s_arvalid;
  wire [NM-1:0] s_arready;
  reg  [NM*AW-1:0] s_araddr;
  reg  [NM*3-1:0] s_arprot;

  wire [NM-1:0] s_rvalid;
  reg  [NM-1:0] s_rready;
  wire [NM*DW-1:0] s_rdata;
  wire [NM*2-1:0] s_rresp;

  // Master-side AXI-Lite signals
  wire [NS*AW-1:0] m_awaddr;
  wire [NS*3-1:0] m_awprot;
  wire [NS-1:0] m_awvalid;
  reg  [NS-1:0] m_awready;

  wire [NS*DW-1:0] m_wdata;
  wire [NS*DW/8-1:0] m_wstrb;
  wire [NS-1:0] m_wvalid;
  reg  [NS-1:0] m_wready;

  reg  [NS*2-1:0] m_bresp;
  reg  [NS-1:0] m_bvalid;
  wire [NS-1:0] m_bready;

  wire [NS*AW-1:0] m_araddr;
  wire [NS*3-1:0] m_arprot;
  wire [NS-1:0] m_arvalid;
  reg  [NS-1:0] m_arready;

  reg  [NS*DW-1:0] m_rdata;
  reg  [NS*2-1:0] m_rresp;
  reg  [NS-1:0] m_rvalid;
  wire [NS-1:0] m_rready;

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

  task axil_write_m0;
    input [AW-1:0] addr;
    input [DW-1:0] data;
    integer slave;
    begin
      slave = addr[7] ? 1 : 0;

      @(negedge clk);

      s_awaddr[0 +: AW] = addr;
      s_wdata[0 +: DW]  = data;
      s_wstrb[0 +: DW/8] = 4'hf;

      s_awvalid[0] = 1'b1;
      s_wvalid[0]  = 1'b1;
      s_bready[0]  = 1'b1;

      wait (m_awvalid[slave] && m_wvalid[slave]);

      check(m_awaddr[slave*AW +: AW] == addr, "xbar routed write address");
      check(m_wdata[slave*DW +: DW] == data, "xbar routed write data");

      m_awready[slave] = 1'b1;
      m_wready[slave]  = 1'b1;

      @(negedge clk);

      m_awready = 0;
      m_wready  = 0;

      s_awvalid[0] = 1'b0;
      s_wvalid[0]  = 1'b0;

      m_bresp[slave*2 +: 2] = 2'b00;
      m_bvalid[slave] = 1'b1;

      wait (m_bready[slave]);

      @(negedge clk);

      m_bvalid[slave] = 1'b0;

      wait (s_bvalid[0]);

      s_bready[0] = 1'b0;
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

      wait (m_arvalid[slave]);

      check(m_araddr[slave*AW +: AW] == addr, "xbar routed read address");

      m_arready[slave] = 1'b1;

      @(negedge clk);

      m_arready = 0;
      s_arvalid[1] = 1'b0;

      m_rdata[slave*DW +: DW] = data;
      m_rresp[slave*2 +: 2] = 2'b00;
      m_rvalid[slave] = 1'b1;

      wait (m_rready[slave]);

      @(negedge clk);

      m_rvalid[slave] = 1'b0;

      wait (s_rvalid[1]);

      check(s_rdata[DW +: DW] == data, "xbar returned read data");

      s_rready[1] = 1'b0;
    end
  endtask

  // Slave-side VALID must remain asserted until READY
  reg prev_s_aw_wait;
  reg prev_s_w_wait;
  reg prev_s_ar_wait;

  always @(posedge clk) begin
    if (!rstn) begin
      prev_s_aw_wait <= 1'b0;
      prev_s_w_wait  <= 1'b0;
      prev_s_ar_wait <= 1'b0;
    end else begin
      if (prev_s_aw_wait && !(|s_awvalid)) begin
        $display("ASSERT FAIL: S_AWVALID dropped before AWREADY");
        errors = errors + 1;
      end

      if (prev_s_w_wait && !(|s_wvalid)) begin
        $display("ASSERT FAIL: S_WVALID dropped before WREADY");
        errors = errors + 1;
      end

      if (prev_s_ar_wait && !(|s_arvalid)) begin
        $display("ASSERT FAIL: S_ARVALID dropped before ARREADY");
        errors = errors + 1;
      end

      prev_s_aw_wait <= |(s_awvalid & ~s_awready);
      prev_s_w_wait  <= |(s_wvalid  & ~s_wready);
      prev_s_ar_wait <= |(s_arvalid & ~s_arready);
    end
  end

  // Master-side VALID must remain asserted until READY
  reg prev_m_aw_wait;
  reg prev_m_w_wait;
  reg prev_m_ar_wait;

  always @(posedge clk) begin
    if (!rstn) begin
      prev_m_aw_wait <= 1'b0;
      prev_m_w_wait  <= 1'b0;
      prev_m_ar_wait <= 1'b0;
    end else begin
      if (prev_m_aw_wait && !(|m_awvalid)) begin
        $display("ASSERT FAIL: M_AWVALID dropped before AWREADY");
        errors = errors + 1;
      end

      if (prev_m_w_wait && !(|m_wvalid)) begin
        $display("ASSERT FAIL: M_WVALID dropped before WREADY");
        errors = errors + 1;
      end

      if (prev_m_ar_wait && !(|m_arvalid)) begin
        $display("ASSERT FAIL: M_ARVALID dropped before ARREADY");
        errors = errors + 1;
      end

      prev_m_aw_wait <= |(m_awvalid & ~m_awready);
      prev_m_w_wait  <= |(m_wvalid  & ~m_wready);
      prev_m_ar_wait <= |(m_arvalid & ~m_arready);
    end
  end

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
    m_bresp   = 0;
    m_rresp   = 0;
    m_rdata   = 0;

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
