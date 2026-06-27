`timescale 1ns/1ps
`default_nettype none

module axilxbar_assert;

  localparam NM = 2;
  localparam NS = 2;
  localparam AW = 8;
  localparam DW = 32;

  reg clk  = 0;
  reg rstn = 0;

  integer errors = 0;

  always #5 clk = ~clk;


  // Bus signals
-
  reg  [NM-1:0]      s_awvalid;
  wire [NM-1:0]      s_awready;
  reg  [NM*AW-1:0]   s_awaddr;
  reg  [NM*3-1:0]    s_awprot;

  reg  [NM-1:0]      s_wvalid;
  wire [NM-1:0]      s_wready;
  reg  [NM*DW-1:0]   s_wdata;
  reg  [NM*DW/8-1:0] s_wstrb;

  wire [NM-1:0]      s_bvalid;
  reg  [NM-1:0]      s_bready;
  wire [NM*2-1:0]    s_bresp;

  reg  [NM-1:0]      s_arvalid;
  wire [NM-1:0]      s_arready;
  reg  [NM*AW-1:0]   s_araddr;
  reg  [NM*3-1:0]    s_arprot;

  wire [NM-1:0]      s_rvalid;
  reg  [NM-1:0]      s_rready;
  wire [NM*DW-1:0]   s_rdata;
  wire [NM*2-1:0]    s_rresp;

  wire [NS*AW-1:0]   m_awaddr;
  wire [NS*3-1:0]    m_awprot;
  wire [NS-1:0]      m_awvalid;
  reg  [NS-1:0]      m_awready;

  wire [NS*DW-1:0]   m_wdata;
  wire [NS*DW/8-1:0] m_wstrb;
  wire [NS-1:0]      m_wvalid;
  reg  [NS-1:0]      m_wready;

  reg  [NS*2-1:0]    m_bresp;
  reg  [NS-1:0]      m_bvalid;
  wire [NS-1:0]      m_bready;

  wire [NS*AW-1:0]   m_araddr;
  wire [NS*3-1:0]    m_arprot;
  wire [NS-1:0]      m_arvalid;
  reg  [NS-1:0]      m_arready;

  reg  [NS*DW-1:0]   m_rdata;
  reg  [NS*2-1:0]    m_rresp;
  reg  [NS-1:0]      m_rvalid;
  wire [NS-1:0]      m_rready;


  // DUT
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
    .S_AXI_ACLK(clk),    .S_AXI_ARESETN(rstn),
    .S_AXI_AWVALID(s_awvalid), .S_AXI_AWREADY(s_awready),
    .S_AXI_AWADDR(s_awaddr),   .S_AXI_AWPROT(s_awprot),
    .S_AXI_WVALID(s_wvalid),   .S_AXI_WREADY(s_wready),
    .S_AXI_WDATA(s_wdata),     .S_AXI_WSTRB(s_wstrb),
    .S_AXI_BVALID(s_bvalid),   .S_AXI_BREADY(s_bready),
    .S_AXI_BRESP(s_bresp),
    .S_AXI_ARVALID(s_arvalid), .S_AXI_ARREADY(s_arready),
    .S_AXI_ARADDR(s_araddr),   .S_AXI_ARPROT(s_arprot),
    .S_AXI_RVALID(s_rvalid),   .S_AXI_RREADY(s_rready),
    .S_AXI_RDATA(s_rdata),     .S_AXI_RRESP(s_rresp),
    .M_AXI_AWADDR(m_awaddr),   .M_AXI_AWPROT(m_awprot),
    .M_AXI_AWVALID(m_awvalid), .M_AXI_AWREADY(m_awready),
    .M_AXI_WDATA(m_wdata),     .M_AXI_WSTRB(m_wstrb),
    .M_AXI_WVALID(m_wvalid),   .M_AXI_WREADY(m_wready),
    .M_AXI_BRESP(m_bresp),     .M_AXI_BVALID(m_bvalid),
    .M_AXI_BREADY(m_bready),
    .M_AXI_ARADDR(m_araddr),   .M_AXI_ARPROT(m_arprot),
    .M_AXI_ARVALID(m_arvalid), .M_AXI_ARREADY(m_arready),
    .M_AXI_RDATA(m_rdata),     .M_AXI_RRESP(m_rresp),
    .M_AXI_RVALID(m_rvalid),   .M_AXI_RREADY(m_rready)
  );

  // Helpers

  task check;
    input cond;
    input [255:0] msg;
    begin
      if (cond) $display("PASS: %s", msg);
      else begin
        $display("FAIL: %s", msg);
        errors = errors + 1;
      end
    end
  endtask

  // AXI-Lite write — master index M (0 or 1)
  
  task axil_write;
    input integer    M;       // which master (0 or 1)
    input [AW-1:0]   addr;
    input [DW-1:0]   data;
    integer          slave;
    begin
      slave = addr[AW-1] ? 1 : 0;  // bit7=1 → slave1, bit7=0 → slave0

      // --- AW + W: present both channels simultaneously (negedge driven) ---
      @(negedge clk);
      s_awaddr[M*AW  +: AW]    = addr;
      s_awprot[M*3   +: 3]     = 3'b000;
      s_wdata [M*DW  +: DW]    = data;
      s_wstrb [M*DW/8 +: DW/8] = {DW/8{1'b1}};
      s_awvalid[M] = 1'b1;
      s_wvalid [M] = 1'b1;
      s_bready [M] = 1'b1;

      // Wait until the crossbar has routed both channels to the slave port
      @(posedge clk);
      while (!(m_awvalid[slave] && m_wvalid[slave])) @(posedge clk);

      // Check routing BEFORE accepting (signals stable here)
      check(m_awaddr[slave*AW +: AW] == addr, "xbar routed write address");
      check(m_wdata [slave*DW +: DW] == data, "xbar routed write data");

      // Accept on the slave side
      @(negedge clk);
      m_awready[slave] = 1'b1;
      m_wready [slave] = 1'b1;

      // --- FIX: hold s_awvalid / s_wvalid until s_awready / s_wready seen ---
      // The skidbuffer inside the crossbar propagates READY back to the master
      // port with up to one clock of latency; we must not drop VALID early.
      @(posedge clk);
      while (!s_awready[M]) @(posedge clk);   // wait for AW handshake
      @(negedge clk);
      s_awvalid[M] = 1'b0;

      @(posedge clk);
      while (!s_wready[M])  @(posedge clk);   // wait for W handshake
      @(negedge clk);
      s_wvalid[M] = 1'b0;

      // Deassert slave-side ready (already latched)
      @(negedge clk);
      m_awready = {NS{1'b0}};
      m_wready  = {NS{1'b0}};

      // --- B channel: slave sends response ---
      m_bresp [slave*2 +: 2] = 2'b00;
      m_bvalid[slave]         = 1'b1;

      @(posedge clk);
      while (!m_bready[slave]) @(posedge clk);
      @(negedge clk);
      m_bvalid[slave] = 1'b0;

      // Wait for crossbar to forward BRESP back to the master port
      @(posedge clk);
      while (!s_bvalid[M]) @(posedge clk);

      // FIX: check BRESP while it is valid
      check(s_bresp[M*2 +: 2] == 2'b00, "xbar returned OKAY bresp");

      @(negedge clk);
      s_bready[M] = 1'b0;
    end
  endtask

  // AXI-Lite read — master index M (0 or 1)

  task axil_read;
    input integer    M;
    input [AW-1:0]   addr;
    input [DW-1:0]   exp;
    integer          slave;
    begin
      slave = addr[AW-1] ? 1 : 0;

      // --- AR channel ---
      @(negedge clk);
      s_araddr[M*AW +: AW] = addr;
      s_arprot[M*3  +: 3]  = 3'b000;
      s_arvalid[M]          = 1'b1;
      s_rready [M]          = 1'b1;

      // Wait for crossbar to route AR to slave
      @(posedge clk);
      while (!m_arvalid[slave]) @(posedge clk);

      check(m_araddr[slave*AW +: AW] == addr, "xbar routed read address");

      // Accept AR on slave side
      @(negedge clk);
      m_arready[slave] = 1'b1;

      // --- FIX: hold s_arvalid until s_arready seen ---
      @(posedge clk);
      while (!s_arready[M]) @(posedge clk);
      @(negedge clk);
      s_arvalid[M]     = 1'b0;
      m_arready        = {NS{1'b0}};

      // --- R channel: slave sends read data ---
      m_rdata[slave*DW +: DW] = exp;
      m_rresp[slave*2  +: 2]  = 2'b00;
      m_rvalid[slave]          = 1'b1;

      @(posedge clk);
      while (!m_rready[slave]) @(posedge clk);
      @(negedge clk);
      m_rvalid[slave] = 1'b0;

      // Wait for crossbar to forward R to master
      @(posedge clk);
      while (!s_rvalid[M]) @(posedge clk);

      // FIX: sample while valid, before dropping ready
      check(s_rdata[M*DW +: DW] == exp,   "xbar returned read data");
      check(s_rresp[M*2  +: 2]  == 2'b00, "xbar returned OKAY rresp");

      @(negedge clk);
      s_rready[M] = 1'b0;
    end
  endtask

  // Per-master AXI protocol checker
  
  integer chk_i;
  reg [NM-1:0] prev_s_aw_wait;
  reg [NM-1:0] prev_s_w_wait;
  reg [NM-1:0] prev_s_ar_wait;

  always @(posedge clk) begin
    if (!rstn) begin
      prev_s_aw_wait <= {NM{1'b0}};
      prev_s_w_wait  <= {NM{1'b0}};
      prev_s_ar_wait <= {NM{1'b0}};
    end else begin
      for (chk_i = 0; chk_i < NM; chk_i = chk_i + 1) begin
        // AWVALID must stay high until AWREADY
        if (prev_s_aw_wait[chk_i] && !s_awvalid[chk_i]) begin
          $display("ASSERT FAIL: S_AWVALID[%0d] dropped before AWREADY at time %0t",
                   chk_i, $time);
          errors = errors + 1;
        end
        // WVALID must stay high until WREADY
        if (prev_s_w_wait[chk_i] && !s_wvalid[chk_i]) begin
          $display("ASSERT FAIL: S_WVALID[%0d] dropped before WREADY at time %0t",
                   chk_i, $time);
          errors = errors + 1;
        end
        // ARVALID must stay high until ARREADY
        if (prev_s_ar_wait[chk_i] && !s_arvalid[chk_i]) begin
          $display("ASSERT FAIL: S_ARVALID[%0d] dropped before ARREADY at time %0t",
                   chk_i, $time);
          errors = errors + 1;
        end
      end
      // Update per-master wait flags
      prev_s_aw_wait <= s_awvalid & ~s_awready;
      prev_s_w_wait  <= s_wvalid  & ~s_wready;
      prev_s_ar_wait <= s_arvalid & ~s_arready;
    end
  end

  // Master-side (crossbar→slave) VALID stability checker
  reg [NS-1:0] prev_m_aw_wait;
  reg [NS-1:0] prev_m_w_wait;
  reg [NS-1:0] prev_m_ar_wait;

  always @(posedge clk) begin
    if (!rstn) begin
      prev_m_aw_wait <= {NS{1'b0}};
      prev_m_w_wait  <= {NS{1'b0}};
      prev_m_ar_wait <= {NS{1'b0}};
    end else begin
      for (chk_i = 0; chk_i < NS; chk_i = chk_i + 1) begin
        if (prev_m_aw_wait[chk_i] && !m_awvalid[chk_i]) begin
          $display("ASSERT FAIL: M_AWVALID[%0d] dropped before AWREADY at time %0t",
                   chk_i, $time);
          errors = errors + 1;
        end
        if (prev_m_w_wait[chk_i] && !m_wvalid[chk_i]) begin
          $display("ASSERT FAIL: M_WVALID[%0d] dropped before WREADY at time %0t",
                   chk_i, $time);
          errors = errors + 1;
        end
        if (prev_m_ar_wait[chk_i] && !m_arvalid[chk_i]) begin
          $display("ASSERT FAIL: M_ARVALID[%0d] dropped before ARREADY at time %0t",
                   chk_i, $time);
          errors = errors + 1;
        end
      end
      prev_m_aw_wait <= m_awvalid & ~m_awready;
      prev_m_w_wait  <= m_wvalid  & ~m_wready;
      prev_m_ar_wait <= m_arvalid & ~m_arready;
    end
  end

  // Stimulus
  initial begin
    s_awvalid = 0; s_wvalid  = 0; s_bready  = 0;
    s_arvalid = 0; s_rready  = 0;
    s_awaddr  = 0; s_awprot  = 0;
    s_wdata   = 0; s_wstrb   = 0;
    s_araddr  = 0; s_arprot  = 0;
    m_awready = 0; m_wready  = 0;
    m_bvalid  = 0; m_bresp   = 0;
    m_arready = 0; m_rvalid  = 0;
    m_rdata   = 0; m_rresp   = 0;

    repeat (5) @(posedge clk);
    rstn = 1'b1;
    repeat (5) @(posedge clk);

    $display("TEST AXILXBAR");

    // Master 0 writes to both slaves
    axil_write(0, 8'h04, 32'h11112222);   // → slave 0
    axil_write(0, 8'h84, 32'h33334444);   // → slave 1

    // Master 1 reads from both slaves
    axil_read (1, 8'h08, 32'h55556666);   // → slave 0
    axil_read (1, 8'h88, 32'h77778888);   // → slave 1

    // FIX: test unmapped address → expect INTERCONNECT_ERROR (DECERR = 2'b11)
    $display("TEST: unmapped address DECERR");
    @(negedge clk);
    s_awaddr[0 +: AW] = 8'hFF;            // no slave matches this
    s_wdata [0 +: DW] = 32'hDEADBEEF;
    s_wstrb [0 +: DW/8] = {DW/8{1'b1}};
    s_awvalid[0] = 1'b1;
    s_wvalid [0] = 1'b1;
    s_bready [0] = 1'b1;
    // Crossbar will grant the NS (no-slave) path and return INTERCONNECT_ERROR
    @(posedge clk);
    while (!s_bvalid[0]) @(posedge clk);
    check(s_bresp[1:0] == 2'b11, "unmapped address returns DECERR");
    @(negedge clk);
    s_awvalid[0] = 1'b0;
    s_wvalid [0] = 1'b0;
    s_bready [0] = 1'b0;

    repeat (4) @(posedge clk);

    if (errors == 0)
      $display("ALL TESTS PASSED");
    else
      $display("TESTS FAILED: %0d errors", errors);

    $finish;
  end

endmodule
`default_nettype wire
