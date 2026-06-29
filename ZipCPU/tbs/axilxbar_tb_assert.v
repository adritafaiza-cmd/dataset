`timescale 1ns/1ps
`default_nettype none

// =============================================================================
// axilxbar_tb.v
// AXI-Lite Crossbar Testbench
//
// Coverage:
//   - Write address channel  (AW)
//   - Write data channel     (W)
//   - Write response channel (B)
//   - Read address channel   (AR)
//   - Read data channel      (R)
//   - Crossbar routing       (addr-based slave selection)
//   - Slave selection        (SLAVE_ADDR / SLAVE_MASK)
//   - Arbitration            (two masters competing for same slave)
// =============================================================================

module axilxbar_tb;

  // ---------------------------------------------------------------------------
  // Parameters — must match DUT instantiation below
  // ---------------------------------------------------------------------------
  localparam NM = 2;          // number of masters
  localparam NS = 2;          // number of slaves
  localparam AW = 8;          // address width
  localparam DW = 32;         // data width

  // Slave 0: addr[7]==0  → base 8'h00, mask 8'h80
  // Slave 1: addr[7]==1  → base 8'h80, mask 8'h80
  localparam [NS*AW-1:0] SLAVE_ADDR = {8'h80, 8'h00};
  localparam [NS*AW-1:0] SLAVE_MASK = {8'h80, 8'h80};

  // ---------------------------------------------------------------------------
  // Clock / reset
  // ---------------------------------------------------------------------------
  reg clk  = 0;
  reg rstn = 0;
  always #5 clk = ~clk;   // 100 MHz

  // ---------------------------------------------------------------------------
  // Error / pass tracking
  // ---------------------------------------------------------------------------
  integer errors   = 0;
  integer tests    = 0;

  task check;
    input      cond;
    input [255:0] msg;
    begin
      tests = tests + 1;
      if (cond) begin
        $display("  PASS [%0d]: %0s", tests, msg);
      end else begin
        $display("  FAIL [%0d]: %0s", tests, msg);
        errors = errors + 1;
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  // DUT port signals
  // ---------------------------------------------------------------------------

  // --- Slave-side (masters driving into the xbar) ---
  reg  [NM-1:0]       s_awvalid;
  wire [NM-1:0]       s_awready;
  reg  [NM*AW-1:0]    s_awaddr;
  reg  [NM*3-1:0]     s_awprot;

  reg  [NM-1:0]       s_wvalid;
  wire [NM-1:0]       s_wready;
  reg  [NM*DW-1:0]    s_wdata;
  reg  [NM*DW/8-1:0]  s_wstrb;

  wire [NM-1:0]       s_bvalid;
  reg  [NM-1:0]       s_bready;
  wire [NM*2-1:0]     s_bresp;

  reg  [NM-1:0]       s_arvalid;
  wire [NM-1:0]       s_arready;
  reg  [NM*AW-1:0]    s_araddr;
  reg  [NM*3-1:0]     s_arprot;

  wire [NM-1:0]       s_rvalid;
  reg  [NM-1:0]       s_rready;
  wire [NM*DW-1:0]    s_rdata;
  wire [NM*2-1:0]     s_rresp;

  // --- Master-side (xbar driving out to slaves) ---
  wire [NS*AW-1:0]    m_awaddr;
  wire [NS*3-1:0]     m_awprot;
  wire [NS-1:0]       m_awvalid;
  reg  [NS-1:0]       m_awready;

  wire [NS*DW-1:0]    m_wdata;
  wire [NS*DW/8-1:0]  m_wstrb;
  wire [NS-1:0]       m_wvalid;
  reg  [NS-1:0]       m_wready;

  reg  [NS*2-1:0]     m_bresp;
  reg  [NS-1:0]       m_bvalid;
  wire [NS-1:0]       m_bready;

  wire [NS*AW-1:0]    m_araddr;
  wire [NS*3-1:0]     m_arprot;
  wire [NS-1:0]       m_arvalid;
  reg  [NS-1:0]       m_arready;

  reg  [NS*DW-1:0]    m_rdata;
  reg  [NS*2-1:0]     m_rresp;
  reg  [NS-1:0]       m_rvalid;
  wire [NS-1:0]       m_rready;

  // ---------------------------------------------------------------------------
  // DUT instantiation
  // ---------------------------------------------------------------------------
  axilxbar #(
    .C_AXI_DATA_WIDTH (DW),
    .C_AXI_ADDR_WIDTH (AW),
    .NM               (NM),
    .NS               (NS),
    .SLAVE_ADDR       (SLAVE_ADDR),
    .SLAVE_MASK       (SLAVE_MASK),
    .OPT_LINGER       (1),
    .LGMAXBURST       (2)
  ) dut (
    .S_AXI_ACLK    (clk),
    .S_AXI_ARESETN (rstn),

    .S_AXI_AWVALID (s_awvalid), .S_AXI_AWREADY (s_awready),
    .S_AXI_AWADDR  (s_awaddr),  .S_AXI_AWPROT  (s_awprot),

    .S_AXI_WVALID  (s_wvalid),  .S_AXI_WREADY  (s_wready),
    .S_AXI_WDATA   (s_wdata),   .S_AXI_WSTRB   (s_wstrb),

    .S_AXI_BVALID  (s_bvalid),  .S_AXI_BREADY  (s_bready),
    .S_AXI_BRESP   (s_bresp),

    .S_AXI_ARVALID (s_arvalid), .S_AXI_ARREADY (s_arready),
    .S_AXI_ARADDR  (s_araddr),  .S_AXI_ARPROT  (s_arprot),

    .S_AXI_RVALID  (s_rvalid),  .S_AXI_RREADY  (s_rready),
    .S_AXI_RDATA   (s_rdata),   .S_AXI_RRESP   (s_rresp),

    .M_AXI_AWADDR  (m_awaddr),  .M_AXI_AWPROT  (m_awprot),
    .M_AXI_AWVALID (m_awvalid), .M_AXI_AWREADY (m_awready),

    .M_AXI_WDATA   (m_wdata),   .M_AXI_WSTRB   (m_wstrb),
    .M_AXI_WVALID  (m_wvalid),  .M_AXI_WREADY  (m_wready),

    .M_AXI_BRESP   (m_bresp),   .M_AXI_BVALID  (m_bvalid),
    .M_AXI_BREADY  (m_bready),

    .M_AXI_ARADDR  (m_araddr),  .M_AXI_ARPROT  (m_arprot),
    .M_AXI_ARVALID (m_arvalid), .M_AXI_ARREADY (m_arready),

    .M_AXI_RDATA   (m_rdata),   .M_AXI_RRESP   (m_rresp),
    .M_AXI_RVALID  (m_rvalid),  .M_AXI_RREADY  (m_rready)
  );

  // ---------------------------------------------------------------------------
  // AXI-Lite VALID stability checker
  // Rule: once VALID is asserted it must stay high until the READY handshake.
  // Checks both the slave-side inputs and master-side outputs of the xbar.
  // ---------------------------------------------------------------------------
  reg [NM-1:0] prev_s_awwait, prev_s_wwait, prev_s_arwait;
  reg [NS-1:0] prev_m_awwait, prev_m_wwait, prev_m_arwait;

  always @(posedge clk) begin : axi_stability
    integer i;
    if (!rstn) begin
      prev_s_awwait <= 0; prev_s_wwait  <= 0; prev_s_arwait <= 0;
      prev_m_awwait <= 0; prev_m_wwait  <= 0; prev_m_arwait <= 0;
    end else begin
      // Per-master slave-side checks
      for (i = 0; i < NM; i = i+1) begin
        if (prev_s_awwait[i] && !s_awvalid[i]) begin
          $display("  PROTOCOL FAIL: master %0d dropped S_AWVALID before AWREADY", i);
          errors = errors + 1;
        end
        if (prev_s_wwait[i]  && !s_wvalid[i]) begin
          $display("  PROTOCOL FAIL: master %0d dropped S_WVALID before WREADY", i);
          errors = errors + 1;
        end
        if (prev_s_arwait[i] && !s_arvalid[i]) begin
          $display("  PROTOCOL FAIL: master %0d dropped S_ARVALID before ARREADY", i);
          errors = errors + 1;
        end
      end
      // Per-slave master-side checks (xbar outputs must be stable)
      for (i = 0; i < NS; i = i+1) begin
        if (prev_m_awwait[i] && !m_awvalid[i]) begin
          $display("  PROTOCOL FAIL: slave %0d xbar dropped M_AWVALID before AWREADY", i);
          errors = errors + 1;
        end
        if (prev_m_wwait[i]  && !m_wvalid[i]) begin
          $display("  PROTOCOL FAIL: slave %0d xbar dropped M_WVALID before WREADY", i);
          errors = errors + 1;
        end
        if (prev_m_arwait[i] && !m_arvalid[i]) begin
          $display("  PROTOCOL FAIL: slave %0d xbar dropped M_ARVALID before ARREADY", i);
          errors = errors + 1;
        end
      end

      prev_s_awwait <= s_awvalid & ~s_awready;
      prev_s_wwait  <= s_wvalid  & ~s_wready;
      prev_s_arwait <= s_arvalid & ~s_arready;
      prev_m_awwait <= m_awvalid & ~m_awready;
      prev_m_wwait  <= m_wvalid  & ~m_wready;
      prev_m_arwait <= m_arvalid & ~m_arready;
    end
  end

  // ---------------------------------------------------------------------------
  // Task: axil_write(master_id, addr, data, wstrb, exp_bresp)
  //
  //   Drives a complete AXI-Lite write (AW + W + B) from the chosen master.
  //   Waits for AWREADY and WREADY before deasserting VALID (protocol safe).
  //   Drives a slave OKAY response and checks it propagates back correctly.
  // ---------------------------------------------------------------------------
  task axil_write;
    input integer   master;          // which master (0 or 1)
    input [AW-1:0]  addr;
    input [DW-1:0]  data;
    input [DW/8-1:0] wstrb;
    input [1:0]     exp_bresp;       // expected response code from slave
    integer         slave;
    integer         timeout;
    begin
      slave = (addr[7]) ? 1 : 0;
      $display("\nWRITE  master=%0d  addr=0x%02h  data=0x%08h  → slave=%0d",
               master, addr, data, slave);

      @(negedge clk);

      // --- Drive AW and W simultaneously ---
      s_awaddr [master*AW  +: AW]   = addr;
      s_awprot [master*3   +: 3]    = 3'b000;
      s_wdata  [master*DW  +: DW]   = data;
      s_wstrb  [master*DW/8 +: DW/8] = wstrb;
      s_awvalid[master]              = 1'b1;
      s_wvalid [master]              = 1'b1;
      s_bready [master]              = 1'b1;   // always ready for response

      // --- TEST: AW channel — wait for xbar to forward the address ---
      timeout = 0;
      while (!m_awvalid[slave] && timeout < 100) begin
        @(negedge clk); timeout = timeout + 1;
      end
      check(m_awvalid[slave],               "AW: xbar asserted M_AWVALID to correct slave");
      check(m_awaddr[slave*AW +: AW] == addr, "AW: routed address matches");

      // --- TEST: W channel — write data forwarded to same slave ---
      check(m_wvalid[slave],                "W:  xbar asserted M_WVALID to correct slave");
      check(m_wdata [slave*DW +: DW] == data, "W:  routed data matches");
      check(m_wstrb [slave*DW/8 +: DW/8] == wstrb, "W:  routed strobe matches");

      // Handshake: accept address and data on the slave side
      m_awready[slave] = 1'b1;
      m_wready [slave] = 1'b1;

      // Wait until the xbar sees AWREADY/WREADY and propagates back to master
      @(posedge clk); #1;   // let DUT register the handshake
      wait (s_awready[master]);
      wait (s_wready[master]);

      @(negedge clk);
      s_awvalid[master] = 1'b0;
      s_wvalid [master] = 1'b0;
      m_awready[slave]  = 1'b0;
      m_wready [slave]  = 1'b0;

      // --- TEST: B channel — slave sends response, xbar routes it back ---
      @(negedge clk);
      m_bresp [slave*2 +: 2] = exp_bresp;
      m_bvalid[slave]        = 1'b1;

      timeout = 0;
      while (!m_bready[slave] && timeout < 100) begin
        @(negedge clk); timeout = timeout + 1;
      end
      check(m_bready[slave], "B:  xbar asserted M_BREADY to slave");

      @(negedge clk);
      m_bvalid[slave] = 1'b0;

      timeout = 0;
      while (!s_bvalid[master] && timeout < 100) begin
        @(negedge clk); timeout = timeout + 1;
      end
      check(s_bvalid[master],                      "B:  xbar forwarded BVALID to master");
      check(s_bresp[master*2 +: 2] == exp_bresp,   "B:  response code matches");

      @(negedge clk);
      s_bready[master] = 1'b0;

      repeat(2) @(negedge clk);
    end
  endtask

  // ---------------------------------------------------------------------------
  // Task: axil_read(master_id, addr, slave_data, exp_rresp)
  //
  //   Drives a complete AXI-Lite read (AR + R) from the chosen master.
  //   Waits for ARREADY before deasserting ARVALID (protocol safe).
  //   Drives slave read data and checks it propagates back to master.
  // ---------------------------------------------------------------------------
  task axil_read;
    input integer  master;
    input [AW-1:0] addr;
    input [DW-1:0] slave_rdata;     // data the slave will return
    input [1:0]    exp_rresp;
    integer        slave;
    integer        timeout;
    begin
      slave = (addr[7]) ? 1 : 0;
      $display("\nREAD   master=%0d  addr=0x%02h  → slave=%0d  expect=0x%08h",
               master, addr, slave, slave_rdata);

      @(negedge clk);

      s_araddr [master*AW +: AW] = addr;
      s_arprot [master*3  +: 3]  = 3'b000;
      s_arvalid[master]          = 1'b1;
      s_rready [master]          = 1'b1;

      // --- TEST: AR channel ---
      timeout = 0;
      while (!m_arvalid[slave] && timeout < 100) begin
        @(negedge clk); timeout = timeout + 1;
      end
      check(m_arvalid[slave],                 "AR: xbar asserted M_ARVALID to correct slave");
      check(m_araddr[slave*AW +: AW] == addr, "AR: routed address matches");

      m_arready[slave] = 1'b1;

      // Wait for ARREADY to propagate back before dropping ARVALID
      @(posedge clk); #1;
      wait (s_arready[master]);

      @(negedge clk);
      s_arvalid[master] = 1'b0;
      m_arready[slave]  = 1'b0;

      // --- TEST: R channel — slave returns data ---
      @(negedge clk);
      m_rdata [slave*DW +: DW] = slave_rdata;
      m_rresp [slave*2  +: 2]  = exp_rresp;
      m_rvalid[slave]          = 1'b1;

      timeout = 0;
      while (!m_rready[slave] && timeout < 100) begin
        @(negedge clk); timeout = timeout + 1;
      end
      check(m_rready[slave], "R:  xbar asserted M_RREADY to slave");

      @(negedge clk);
      m_rvalid[slave] = 1'b0;

      timeout = 0;
      while (!s_rvalid[master] && timeout < 100) begin
        @(negedge clk); timeout = timeout + 1;
      end
      check(s_rvalid[master],                       "R:  xbar forwarded RVALID to master");
      check(s_rdata[master*DW +: DW] == slave_rdata, "R:  read data matches");
      check(s_rresp[master*2  +: 2]  == exp_rresp,   "R:  response code matches");

      @(negedge clk);
      s_rready[master] = 1'b0;

      repeat(2) @(negedge clk);
    end
  endtask

  // ---------------------------------------------------------------------------
  // Task: axil_write_concurrent — both masters write simultaneously to
  //       *different* slaves to test independent routing.
  // ---------------------------------------------------------------------------
  task axil_write_concurrent;
    input [AW-1:0]  addr0, addr1;
    input [DW-1:0]  data0, data1;
    integer         slave0, slave1;
    integer         timeout;
    begin
      slave0 = addr0[7] ? 1 : 0;
      slave1 = addr1[7] ? 1 : 0;
      $display("\nWRITE CONCURRENT  m0→slave%0d  m1→slave%0d", slave0, slave1);

      @(negedge clk);

      // Drive both masters at once
      s_awaddr[0*AW +: AW]    = addr0;
      s_wdata [0*DW +: DW]    = data0;
      s_wstrb [0*DW/8 +: DW/8] = 4'hf;
      s_awvalid[0] = 1; s_wvalid[0] = 1; s_bready[0] = 1;

      s_awaddr[1*AW +: AW]    = addr1;
      s_wdata [1*DW +: DW]    = data1;
      s_wstrb [1*DW/8 +: DW/8] = 4'hf;
      s_awvalid[1] = 1; s_wvalid[1] = 1; s_bready[1] = 1;

      // Wait for both to appear on correct slave ports
      timeout = 0;
      while (!(m_awvalid[slave0] && m_awvalid[slave1]) && timeout < 100) begin
        @(negedge clk); timeout = timeout + 1;
      end

      check(m_awvalid[slave0], "CONCURRENT AW: master 0 routed to correct slave");
      check(m_awvalid[slave1], "CONCURRENT AW: master 1 routed to correct slave");
      check(m_awaddr[slave0*AW +: AW] == addr0, "CONCURRENT AW: master 0 address correct");
      check(m_awaddr[slave1*AW +: AW] == addr1, "CONCURRENT AW: master 1 address correct");
      check(m_wdata [slave0*DW +: DW] == data0, "CONCURRENT W:  master 0 data correct");
      check(m_wdata [slave1*DW +: DW] == data1, "CONCURRENT W:  master 1 data correct");

      // Accept on both slaves
      m_awready[slave0] = 1; m_wready[slave0] = 1;
      m_awready[slave1] = 1; m_wready[slave1] = 1;

      @(posedge clk); #1;
      wait (s_awready[0] && s_awready[1]);

      @(negedge clk);
      s_awvalid = 0; s_wvalid = 0;
      m_awready = 0; m_wready = 0;

      // Send responses from both slaves
      @(negedge clk);
      m_bresp[slave0*2 +: 2] = 2'b00; m_bvalid[slave0] = 1;
      m_bresp[slave1*2 +: 2] = 2'b00; m_bvalid[slave1] = 1;

      timeout = 0;
      while (!(s_bvalid[0] && s_bvalid[1]) && timeout < 100) begin
        @(negedge clk); timeout = timeout + 1;
      end
      check(s_bvalid[0], "CONCURRENT B: master 0 received response");
      check(s_bvalid[1], "CONCURRENT B: master 1 received response");

      @(negedge clk);
      m_bvalid = 0; s_bready = 0;
      repeat(2) @(negedge clk);
    end
  endtask

  // ---------------------------------------------------------------------------
  // Task: axil_write_arbitration — both masters target the *same* slave.
  //       Verifies the xbar grants one at a time (lower master wins first).
  // ---------------------------------------------------------------------------
  task axil_write_arbitration;
    input [AW-1:0] addr;    // same slave for both masters
    integer        slave;
    integer        timeout;
    reg [DW-1:0]   data0, data1;
    begin
      slave = addr[7] ? 1 : 0;
      data0 = 32'hAAAA_0000;
      data1 = 32'hBBBB_0000;
      $display("\nARBITRATION  both masters → slave%0d  (master 0 should win)", slave);

      @(negedge clk);

      // Both request simultaneously
      s_awaddr[0*AW +: AW]     = addr;
      s_wdata [0*DW +: DW]     = data0;
      s_wstrb [0*DW/8 +: DW/8] = 4'hf;
      s_awvalid[0] = 1; s_wvalid[0] = 1; s_bready[0] = 1;

      s_awaddr[1*AW +: AW]     = addr;
      s_wdata [1*DW +: DW]     = data1;
      s_wstrb [1*DW/8 +: DW/8] = 4'hf;
      s_awvalid[1] = 1; s_wvalid[1] = 1; s_bready[1] = 1;

      // Wait for the first grant to appear on the slave port
      timeout = 0;
      while (!m_awvalid[slave] && timeout < 100) begin
        @(negedge clk); timeout = timeout + 1;
      end

      // Lower-numbered master (0) must win the arbitration
      check(m_awvalid[slave],                    "ARB: xbar granted access to slave");
      check(m_awaddr[slave*AW +: AW] == addr,    "ARB: granted address correct");
      check(m_wdata [slave*DW +: DW] == data0,   "ARB: master 0 won (lower ID has priority)");

      // Complete master 0's transaction
      m_awready[slave] = 1; m_wready[slave] = 1;
      @(posedge clk); #1;
      wait (s_awready[0]);

      @(negedge clk);
      s_awvalid[0] = 0; s_wvalid[0] = 0;
      m_awready[slave] = 0; m_wready[slave] = 0;

      // B channel for master 0
      @(negedge clk);
      m_bresp[slave*2 +: 2] = 2'b00; m_bvalid[slave] = 1;
      timeout = 0;
      while (!s_bvalid[0] && timeout < 100) begin
        @(negedge clk); timeout = timeout + 1;
      end
      check(s_bvalid[0], "ARB: master 0 received write response");
      @(negedge clk);
      m_bvalid[slave] = 0;

      // Now master 1 should get the grant
      timeout = 0;
      while (!m_awvalid[slave] && timeout < 100) begin
        @(negedge clk); timeout = timeout + 1;
      end
      check(m_awvalid[slave],                   "ARB: xbar granted slave to master 1 next");
      check(m_wdata[slave*DW +: DW] == data1,   "ARB: master 1 data forwarded after winning");

      m_awready[slave] = 1; m_wready[slave] = 1;
      @(posedge clk); #1;
      wait (s_awready[1]);

      @(negedge clk);
      s_awvalid[1] = 0; s_wvalid[1] = 0;
      m_awready[slave] = 0; m_wready[slave] = 0;

      @(negedge clk);
      m_bresp[slave*2 +: 2] = 2'b00; m_bvalid[slave] = 1;
      timeout = 0;
      while (!s_bvalid[1] && timeout < 100) begin
        @(negedge clk); timeout = timeout + 1;
      end
      check(s_bvalid[1], "ARB: master 1 received write response");

      @(negedge clk);
      m_bvalid[slave] = 0; s_bready = 0;
      repeat(2) @(negedge clk);
    end
  endtask

  // ---------------------------------------------------------------------------
  // Main test sequence
  // ---------------------------------------------------------------------------
  initial begin
    // -- Initialise all driven signals --
    s_awvalid = 0; s_wvalid  = 0; s_bready  = 0;
    s_arvalid = 0; s_rready  = 0;
    s_awaddr  = 0; s_awprot  = 0;
    s_araddr  = 0; s_arprot  = 0;
    s_wdata   = 0; s_wstrb   = 0;

    m_awready = 0; m_wready  = 0;
    m_bvalid  = 0; m_bresp   = 0;
    m_arready = 0;
    m_rvalid  = 0; m_rresp   = 0; m_rdata = 0;

    // -- Reset sequence --
    repeat(5) @(posedge clk);
    rstn = 1;
    repeat(5) @(posedge clk);

    $display("=================================================");
    $display(" AXILXBAR TESTBENCH");
    $display("=================================================");

    // =========================================================
    // 1. WRITE ADDRESS + DATA + RESPONSE — master 0 → slave 0
    // =========================================================
    $display("\n--- 1. Basic write: master 0 to slave 0 (addr[7]=0) ---");
    axil_write(0, 8'h10, 32'hDEAD_BEEF, 4'hF, 2'b00);

    // =========================================================
    // 2. WRITE — master 0 → slave 1  (tests slave selection)
    // =========================================================
    $display("\n--- 2. Basic write: master 0 to slave 1 (addr[7]=1) ---");
    axil_write(0, 8'hA0, 32'hCAFE_BABE, 4'hF, 2'b00);

    // =========================================================
    // 3. READ ADDRESS + DATA — master 1 → slave 0
    // =========================================================
    $display("\n--- 3. Basic read: master 1 to slave 0 (addr[7]=0) ---");
    axil_read(1, 8'h20, 32'h1234_5678, 2'b00);

    // =========================================================
    // 4. READ — master 1 → slave 1  (tests slave selection)
    // =========================================================
    $display("\n--- 4. Basic read: master 1 to slave 1 (addr[7]=1) ---");
    axil_read(1, 8'hC4, 32'h9ABC_DEF0, 2'b00);

    // =========================================================
    // 5. SLAVE SELECTION — write with SLVERR response
    // =========================================================
    $display("\n--- 5. Write response: slave returns SLVERR ---");
    axil_write(0, 8'h30, 32'h0000_0001, 4'h1, 2'b10);

    // =========================================================
    // 6. SLAVE SELECTION — read with DECERR response
    // =========================================================
    $display("\n--- 6. Read response: slave returns DECERR ---");
    axil_read(1, 8'hB0, 32'h0000_0000, 2'b11);

    // =========================================================
    // 7. CROSSBAR ROUTING — both masters, different slaves
    //    (simultaneous independent transactions)
    // =========================================================
    $display("\n--- 7. Crossbar routing: concurrent masters to different slaves ---");
    axil_write_concurrent(8'h04, 8'h84, 32'hAAAA_1111, 32'hBBBB_2222);

    // =========================================================
    // 8. ARBITRATION — both masters contend for the same slave
    // =========================================================
    $display("\n--- 8. Arbitration: both masters target slave 0 simultaneously ---");
    axil_write_arbitration(8'h08);

    // =========================================================
    // 9. ARBITRATION — same but on slave 1
    // =========================================================
    $display("\n--- 9. Arbitration: both masters target slave 1 simultaneously ---");
    axil_write_arbitration(8'h90);

    // =========================================================
    // 10. WRITE then READ — same address, verify independence
    
    $display("\n--- 10. Write then read back: master 0 to slave 0 ---");
    axil_write(0, 8'h44, 32'h5A5A_5A5A, 4'hF, 2'b00);
    axil_read (0, 8'h44, 32'h5A5A_5A5A, 2'b00);

    
    // Results
    $display("\n=================================================");
    if (errors == 0)
      $display(" ALL %0d TESTS PASSED", tests);
    else
      $display(" %0d / %0d TESTS FAILED", errors, tests);
    $display("=================================================\n");

    $finish;
  end

  // Safety watchdog — prevents infinite simulation on deadlock
  initial begin
    #100000;
    $display("WATCHDOG TIMEOUT — simulation hung");
    $finish;
  end

endmodule

`default_nettype wire
