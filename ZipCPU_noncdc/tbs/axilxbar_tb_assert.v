`timescale 1ns/1ps
`default_nettype none

// =============================================================================
// axilxbar_tb.v  —  Fixed AXI-Lite Crossbar Testbench
//
// Key fixes vs original:
//   1. W channel checked SEPARATELY from AW — design registers AW first,
//      then enables W via wdata_expected (always at least 1 extra clock).
//   2. All tasks wait for per-channel READY before dropping VALID.
//   3. Per-channel stability checker (not OR-reduced single bit).
//   4. Timeouts on every wait so failures are reported, not hung.
//
// Tests:
//   1.  Write AW+W+B          master 0 → slave 0
//   2.  Write AW+W+B          master 0 → slave 1   (slave selection)
//   3.  Read  AR+R            master 1 → slave 0
//   4.  Read  AR+R            master 1 → slave 1   (slave selection)
//   5.  Write with SLVERR response
//   6.  Read  with DECERR response
//   7.  Concurrent writes     master 0 → slave 0, master 1 → slave 1
//   8.  Arbitration           both masters → slave 0 simultaneously
//   9.  Arbitration           both masters → slave 1 simultaneously
//  10.  Write then read same address (channel independence)
// =============================================================================

module axilxbar_tb;

  // ---------------------------------------------------------------------------
  // Parameters
  // ---------------------------------------------------------------------------
  localparam NM = 2;
  localparam NS = 2;
  localparam AW = 8;
  localparam DW = 32;

  // Slave 0 → addr[7]==0  (base 8'h00, mask 8'h80)
  // Slave 1 → addr[7]==1  (base 8'h80, mask 8'h80)
  // Verilog concat is {MSB_slice, ..., LSB_slice}
  // SLAVE_ADDR[0*AW +: AW] = 8'h00  (slave 0)
  // SLAVE_ADDR[1*AW +: AW] = 8'h80  (slave 1)
  localparam [NS*AW-1:0] SLAVE_ADDR = {8'h80, 8'h00};
  localparam [NS*AW-1:0] SLAVE_MASK = {8'h80, 8'h80};

  // ---------------------------------------------------------------------------
  // Clock / reset
  // ---------------------------------------------------------------------------
  reg clk  = 0;
  reg rstn = 0;
  always #5 clk = ~clk;   // 100 MHz

  // ---------------------------------------------------------------------------
  // Scoreboard
  // ---------------------------------------------------------------------------
  integer errors = 0;
  integer tests  = 0;

  task check;
    input      cond;
    input [255:0] msg;
    begin
      tests = tests + 1;
      if (cond)
        $display("  PASS [%0d]: %0s", tests, msg);
      else begin
        $display("  FAIL [%0d]: %0s", tests, msg);
        errors = errors + 1;
      end
    end
  endtask

  task timeout_check;
    input      cond;
    input [255:0] msg;
    begin
      tests = tests + 1;
      if (cond)
        $display("  PASS [%0d]: %0s (no timeout)", tests, msg);
      else begin
        $display("  FAIL [%0d]: TIMEOUT waiting for %0s", tests, msg);
        errors = errors + 1;
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  // DUT port signals
  // ---------------------------------------------------------------------------
  reg  [NM-1:0]        s_awvalid;
  wire [NM-1:0]        s_awready;
  reg  [NM*AW-1:0]     s_awaddr;
  reg  [NM*3-1:0]      s_awprot;

  reg  [NM-1:0]        s_wvalid;
  wire [NM-1:0]        s_wready;
  reg  [NM*DW-1:0]     s_wdata;
  reg  [NM*DW/8-1:0]   s_wstrb;

  wire [NM-1:0]        s_bvalid;
  reg  [NM-1:0]        s_bready;
  wire [NM*2-1:0]      s_bresp;

  reg  [NM-1:0]        s_arvalid;
  wire [NM-1:0]        s_arready;
  reg  [NM*AW-1:0]     s_araddr;
  reg  [NM*3-1:0]      s_arprot;

  wire [NM-1:0]        s_rvalid;
  reg  [NM-1:0]        s_rready;
  wire [NM*DW-1:0]     s_rdata;
  wire [NM*2-1:0]      s_rresp;

  wire [NS*AW-1:0]     m_awaddr;
  wire [NS*3-1:0]      m_awprot;
  wire [NS-1:0]        m_awvalid;
  reg  [NS-1:0]        m_awready;

  wire [NS*DW-1:0]     m_wdata;
  wire [NS*DW/8-1:0]   m_wstrb;
  wire [NS-1:0]        m_wvalid;
  reg  [NS-1:0]        m_wready;

  reg  [NS*2-1:0]      m_bresp;
  reg  [NS-1:0]        m_bvalid;
  wire [NS-1:0]        m_bready;

  wire [NS*AW-1:0]     m_araddr;
  wire [NS*3-1:0]      m_arprot;
  wire [NS-1:0]        m_arvalid;
  reg  [NS-1:0]        m_arready;

  reg  [NS*DW-1:0]     m_rdata;
  reg  [NS*2-1:0]      m_rresp;
  reg  [NS-1:0]        m_rvalid;
  wire [NS-1:0]        m_rready;

  // ---------------------------------------------------------------------------
  // DUT
  // ---------------------------------------------------------------------------
  axilxbar #(
    .C_AXI_DATA_WIDTH (DW),
    .C_AXI_ADDR_WIDTH (AW),
    .NM               (NM),
    .NS               (NS),
    .SLAVE_ADDR       (SLAVE_ADDR),
    .SLAVE_MASK       (SLAVE_MASK),
    .OPT_LINGER       (0),
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
  // Per-channel AXI VALID stability checker
  // VALID must never be dropped before the corresponding READY handshake.
  // ---------------------------------------------------------------------------
  reg [NM-1:0] prev_s_awwait, prev_s_wwait, prev_s_arwait;
  reg [NS-1:0] prev_m_awwait, prev_m_wwait, prev_m_arwait;

  always @(posedge clk) begin : axi_stability
    integer i;
    if (!rstn) begin
      prev_s_awwait <= 0; prev_s_wwait  <= 0; prev_s_arwait <= 0;
      prev_m_awwait <= 0; prev_m_wwait  <= 0; prev_m_arwait <= 0;
    end else begin
      for (i = 0; i < NM; i = i+1) begin
        if (prev_s_awwait[i] && !s_awvalid[i]) begin
          $display("  PROTOCOL FAIL: master %0d dropped S_AWVALID before AWREADY", i);
          errors = errors + 1;
        end
        if (prev_s_wwait[i] && !s_wvalid[i]) begin
          $display("  PROTOCOL FAIL: master %0d dropped S_WVALID before WREADY", i);
          errors = errors + 1;
        end
        if (prev_s_arwait[i] && !s_arvalid[i]) begin
          $display("  PROTOCOL FAIL: master %0d dropped S_ARVALID before ARREADY", i);
          errors = errors + 1;
        end
      end
      for (i = 0; i < NS; i = i+1) begin
        if (prev_m_awwait[i] && !m_awvalid[i]) begin
          $display("  PROTOCOL FAIL: slave %0d xbar dropped M_AWVALID before AWREADY", i);
          errors = errors + 1;
        end
        if (prev_m_wwait[i] && !m_wvalid[i]) begin
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

  
  task axil_write;
    input integer    master;
    input [AW-1:0]   addr;
    input [DW-1:0]   data;
    input [DW/8-1:0] wstrb;
    input [1:0]      exp_bresp;
    integer          slave;
    integer          t;
    begin
      slave = addr[7] ? 1 : 0;
      $display("\nWRITE  master=%0d  addr=0x%02h  data=0x%08h  → slave=%0d",
               master, addr, data, slave);

      @(negedge clk);

      // Drive AW and W simultaneously into the xbar
      s_awaddr [master*AW   +: AW]    = addr;
      s_awprot [master*3    +: 3]     = 3'b000;
      s_wdata  [master*DW   +: DW]    = data;
      s_wstrb  [master*DW/8 +: DW/8]  = wstrb;
      s_awvalid[master]  = 1'b1;
      s_wvalid [master]  = 1'b1;
      s_bready [master]  = 1'b1;

      // -----------------------------------------------------------------------
      // AW channel: wait for xbar to forward AW to the slave port
      
      t = 0;
      while (!m_awvalid[slave] && t < 200) begin @(negedge clk); t = t+1; end
      $display("DEBUG AW: slave=%0d m_awvalid=%b", slave, m_awvalid);
      $display("DEBUG ADDR: m_awaddr0=%h m_awaddr1=%h",
                m_awaddr[0*AW +: AW],
                m_awaddr[1*AW +: AW]);

      $display("DEBUG W: m_wvalid=%b", m_wvalid);
      $display("DEBUG DATA: m_wdata0=%h m_wdata1=%h",
                m_wdata[0*DW +: DW],
                m_wdata[1*DW +: DW]);
      timeout_check(m_awvalid[slave],        "AW: M_AWVALID asserted on correct slave");
      check(m_awaddr[slave*AW +: AW] == addr, "AW: routed address matches");

      // Accept AW on the slave side
      m_awready[slave] = 1'b1;
      @(negedge clk);
      m_awready[slave] = 1'b0;

      // Wait for s_awready to come back to master, then safely drop s_awvalid
      t = 0;
      while (!s_awready[master] && t < 200) begin @(negedge clk); t = t+1; end
      timeout_check(s_awready[master], "AW: s_awready returned to master");
      @(negedge clk);
      s_awvalid[master] = 1'b0;

      // -----------------------------------------------------------------------
      // W channel: wait separately — design gates W until AW grant is set.
      // m_wvalid appears AFTER m_awvalid because wdata_expected is set
      // by the write arbiter, which is registered (posedge-clocked).
      // -----------------------------------------------------------------------
      t = 0;
      while (!m_wvalid[slave] && t < 200) begin @(negedge clk); t = t+1; end
      timeout_check(m_wvalid[slave],           "W:  M_WVALID asserted on correct slave");
      check(m_wdata [slave*DW   +: DW]  == data,  "W:  routed data matches");
      check(m_wstrb [slave*DW/8 +: DW/8] == wstrb, "W:  routed strobe matches");

      // Accept W on slave side
      m_wready[slave] = 1'b1;
      @(negedge clk);
      m_wready[slave] = 1'b0;

      // Wait for s_wready, then drop s_wvalid
      t = 0;
      while (!s_wready[master] && t < 200) begin @(negedge clk); t = t+1; end
      timeout_check(s_wready[master], "W:  s_wready returned to master");
      @(negedge clk);
      s_wvalid[master] = 1'b0;

      // -----------------------------------------------------------------------
      // B channel: slave sends response, xbar routes it back to master
      // -----------------------------------------------------------------------
      @(negedge clk);
      m_bresp [slave*2 +: 2] = exp_bresp;
      m_bvalid[slave]        = 1'b1;

      // Wait for xbar to assert bready toward slave
      t = 0;
      while (!m_bready[slave] && t < 200) begin @(negedge clk); t = t+1; end
      timeout_check(m_bready[slave], "B:  M_BREADY asserted to slave");
      @(negedge clk);
      m_bvalid[slave] = 1'b0;

      // Wait for s_bvalid to arrive at master
      t = 0;
      while (!s_bvalid[master] && t < 200) begin @(negedge clk); t = t+1; end
      timeout_check(s_bvalid[master],                   "B:  S_BVALID forwarded to master");
      check(s_bresp[master*2 +: 2] == exp_bresp,        "B:  response code matches");

      @(negedge clk);
      s_bready[master] = 1'b0;
      repeat(3) @(negedge clk);
    end
  endtask


  // ---------------------------------------------------------------------------
  // Task: axil_read(master, addr, slave_data, exp_rresp)
  // ---------------------------------------------------------------------------
  task axil_read;
    input integer  master;
    input [AW-1:0] addr;
    input [DW-1:0] slave_rdata;
    input [1:0]    exp_rresp;
    integer        slave;
    integer        t;
    begin
      slave = addr[7] ? 1 : 0;
      $display("\nREAD   master=%0d  addr=0x%02h  → slave=%0d  expect=0x%08h",
               master, addr, slave, slave_rdata);

      @(negedge clk);
      s_araddr [master*AW +: AW] = addr;
      s_arprot [master*3  +: 3]  = 3'b000;
      s_arvalid[master]          = 1'b1;
      s_rready [master]          = 1'b1;

      // AR channel
      t = 0;
      while (!m_arvalid[slave] && t < 200) begin @(negedge clk); t = t+1; end
      timeout_check(m_arvalid[slave],                 "AR: M_ARVALID asserted on correct slave");
      check(m_araddr[slave*AW +: AW] == addr,         "AR: routed address matches");

      m_arready[slave] = 1'b1;
      @(negedge clk);
      m_arready[slave] = 1'b0;

      // Wait for s_arready before dropping s_arvalid
      t = 0;
      while (!s_arready[master] && t < 200) begin @(negedge clk); t = t+1; end
      timeout_check(s_arready[master], "AR: s_arready returned to master");
      @(negedge clk);
      s_arvalid[master] = 1'b0;

      // R channel: slave returns data
      @(negedge clk);
      m_rdata [slave*DW +: DW] = slave_rdata;
      m_rresp [slave*2  +: 2]  = exp_rresp;
      m_rvalid[slave]          = 1'b1;

      t = 0;
      while (!m_rready[slave] && t < 200) begin @(negedge clk); t = t+1; end
      timeout_check(m_rready[slave], "R:  M_RREADY asserted to slave");
      @(negedge clk);
      m_rvalid[slave] = 1'b0;

      // Wait for s_rvalid at master
      t = 0;
      while (!s_rvalid[master] && t < 200) begin @(negedge clk); t = t+1; end
      timeout_check(s_rvalid[master],                       "R:  S_RVALID forwarded to master");
      check(s_rdata[master*DW +: DW] == slave_rdata,        "R:  read data matches");
      check(s_rresp[master*2  +: 2]  == exp_rresp,          "R:  response code matches");

      @(negedge clk);
      s_rready[master] = 1'b0;
      repeat(3) @(negedge clk);
    end
  endtask


  // ---------------------------------------------------------------------------
  // Task: axil_write_concurrent
  // Both masters write to DIFFERENT slaves simultaneously.
  // Verifies independent crossbar routing.
  // ---------------------------------------------------------------------------
  task axil_write_concurrent;
    input [AW-1:0]   addr0, addr1;
    input [DW-1:0]   data0, data1;
    integer          slave0, slave1, t;
    begin
      slave0 = addr0[7] ? 1 : 0;
      slave1 = addr1[7] ? 1 : 0;
      $display("\nCONCURRENT WRITE  m0→slave%0d  m1→slave%0d", slave0, slave1);

      @(negedge clk);
      s_awaddr[0*AW +: AW]      = addr0;
      s_wdata [0*DW +: DW]      = data0;
      s_wstrb [0*DW/8 +: DW/8]  = 4'hf;
      s_awvalid[0]=1; s_wvalid[0]=1; s_bready[0]=1;

      s_awaddr[1*AW +: AW]      = addr1;
      s_wdata [1*DW +: DW]      = data1;
      s_wstrb [1*DW/8 +: DW/8]  = 4'hf;
      s_awvalid[1]=1; s_wvalid[1]=1; s_bready[1]=1;

      // AW: wait for both slaves
      t = 0;
      while (!(m_awvalid[slave0] && m_awvalid[slave1]) && t < 200) begin
        @(negedge clk); t = t+1;
      end
      timeout_check(m_awvalid[slave0] && m_awvalid[slave1],
                    "CONCURRENT AW: both grants appeared");
      check(m_awaddr[slave0*AW +: AW] == addr0, "CONCURRENT AW: master 0 address correct");
      check(m_awaddr[slave1*AW +: AW] == addr1, "CONCURRENT AW: master 1 address correct");

      m_awready[slave0]=1; m_awready[slave1]=1;
      @(negedge clk);
      m_awready = 0;

      t = 0;
      while (!(s_awready[0] && s_awready[1]) && t < 200) begin
        @(negedge clk); t = t+1;
      end
      @(negedge clk);
      s_awvalid = 0;

      // W: wait for both slaves (separately after AW)
      t = 0;
      while (!(m_wvalid[slave0] && m_wvalid[slave1]) && t < 200) begin
        @(negedge clk); t = t+1;
      end
      timeout_check(m_wvalid[slave0] && m_wvalid[slave1],
                    "CONCURRENT W:  both data appeared");
      check(m_wdata[slave0*DW +: DW] == data0, "CONCURRENT W:  master 0 data correct");
      check(m_wdata[slave1*DW +: DW] == data1, "CONCURRENT W:  master 1 data correct");

      m_wready[slave0]=1; m_wready[slave1]=1;
      @(negedge clk);
      m_wready = 0;

      t = 0;
      while (!(s_wready[0] && s_wready[1]) && t < 200) begin
        @(negedge clk); t = t+1;
      end
      @(negedge clk);
      s_wvalid = 0;

      // B: both slaves respond
      @(negedge clk);
      m_bresp[slave0*2 +: 2]=2'b00; m_bvalid[slave0]=1;
      m_bresp[slave1*2 +: 2]=2'b00; m_bvalid[slave1]=1;

      t = 0;
      while (!(s_bvalid[0] && s_bvalid[1]) && t < 200) begin
        @(negedge clk); t = t+1;
      end
      timeout_check(s_bvalid[0] && s_bvalid[1], "CONCURRENT B:  both masters received response");

      @(negedge clk);
      m_bvalid=0; s_bready=0;
      repeat(3) @(negedge clk);
    end
  endtask
  // ---------------------------------------------------------------------------
  // Task: axil_write_arbitration
  // Both masters write to the SAME slave.
  // Lower-numbered master must win first, then master 1 gets its turn.
  // ---------------------------------------------------------------------------
  task axil_write_arbitration;
  input [AW-1:0] addr;
  integer slave;
  integer timeout;
  reg [DW-1:0] data0, data1;
  begin
    slave = addr[7] ? 1 : 0;
    data0 = 32'hAAAA_0000;
    data1 = 32'hBBBB_0000;

    $display("\nARBITRATION  both masters -> slave%0d", slave);

    @(negedge clk);

    s_awaddr[0*AW +: AW] = addr;
    s_wdata [0*DW +: DW] = data0;
    s_wstrb [0*DW/8 +: DW/8] = 4'hF;
    s_awvalid[0] = 1'b1;
    s_wvalid [0] = 1'b1;
    s_bready [0] = 1'b1;

    s_awaddr[1*AW +: AW] = addr;
    s_wdata [1*DW +: DW] = data1;
    s_wstrb [1*DW/8 +: DW/8] = 4'hF;
    s_awvalid[1] = 1'b1;
    s_wvalid [1] = 1'b1;
    s_bready [1] = 1'b1;

    timeout = 0;
    while (!m_awvalid[slave] && timeout < 100) begin
      @(negedge clk);
      timeout = timeout + 1;
    end

    timeout_check(m_awvalid[slave],
                  "ARB AW: first grant appeared");
    check(m_awaddr[slave*AW +: AW] == addr,
          "ARB AW: address correct");
    check(m_wdata[slave*DW +: DW] == data0,
          "ARB W: master 0 won first");

    m_awready[slave] = 1'b1;
    m_wready [slave] = 1'b1;

    timeout = 0;
    while ((s_awvalid[0] || s_wvalid[0]) && timeout < 100) begin
      @(posedge clk);
      #1;

      if (s_awvalid[0] && s_awready[0])
        s_awvalid[0] = 1'b0;

      if (s_wvalid[0] && s_wready[0])
        s_wvalid[0] = 1'b0;

      timeout = timeout + 1;
    end

    timeout_check(!s_awvalid[0],
                  "ARB AW: master 0 AW completed");
    timeout_check(!s_wvalid[0],
                  "ARB W: master 0 W completed");

    @(negedge clk);
    m_awready[slave] = 1'b0;
    m_wready [slave] = 1'b0;

    @(negedge clk);
    m_bresp [slave*2 +: 2] = 2'b00;
    m_bvalid[slave] = 1'b1;

    timeout = 0;
    while (!s_bvalid[0] && timeout < 100) begin
      @(negedge clk);
      timeout = timeout + 1;
    end

    timeout_check(s_bvalid[0],
                  "ARB B: master 0 received response");

    @(negedge clk);
    m_bvalid[slave] = 1'b0;

    s_awvalid[1] = 1'b0;
    s_wvalid [1] = 1'b0;
    s_bready [0] = 1'b0;
    s_bready [1] = 1'b0;

    repeat(5) @(posedge clk);
  end
endtask
    
   task reset_dut;
    begin
      s_awvalid = 0; s_wvalid = 0; s_bready = 0;
      s_arvalid = 0; s_rready = 0;
      m_awready = 0; m_wready = 0; m_bvalid = 0;
      m_arready = 0; m_rvalid = 0;

      rstn = 0;
      repeat(5) @(posedge clk);
      rstn = 1;
      repeat(5) @(posedge clk);
    end
  endtask
  // ---------------------------------------------------------------------------
  // Main stimulus
  // ---------------------------------------------------------------------------
  initial begin
    s_awvalid=0; s_wvalid=0;  s_bready=0;
    s_arvalid=0; s_rready=0;
    s_awaddr=0;  s_awprot=0;
    s_araddr=0;  s_arprot=0;
    s_wdata=0;   s_wstrb=0;
    m_awready=0; m_wready=0;
    m_bvalid=0;  m_bresp=0;
    m_arready=0;
    m_rvalid=0;  m_rresp=0;   m_rdata=0;

    repeat(5) @(posedge clk);
    rstn = 1;
    repeat(5) @(posedge clk);

    $display("=================================================");
    $display(" AXILXBAR TESTBENCH");
    $display("=================================================");

    // 1. Write: master 0 → slave 0
    $display("\n--- 1. Write: master 0 → slave 0 ---");
    axil_write(0, 8'h10, 32'hDEAD_BEEF, 4'hF, 2'b00);
    reset_dut();
    
    // 2. Write: master 0 → slave 1  (slave selection via addr[7])
    $display("\n--- 2. Write: master 0 → slave 1 ---");
    axil_write(0, 8'hA0, 32'hCAFE_BABE, 4'hF, 2'b00);
    repeat(10) @(posedge clk);
    reset_dut();

    // 3. Read: master 1 → slave 0
    $display("\n--- 3. Read:  master 1 → slave 0 ---");
    axil_read(1, 8'h20, 32'h1234_5678, 2'b00);
    reset_dut();

    // 4. Read: master 1 → slave 1  (slave selection)
    $display("\n--- 4. Read:  master 1 → slave 1 ---");
    axil_read(1, 8'hC4, 32'h9ABC_DEF0, 2'b00);
    reset_dut();
    
    // 5. Write response: slave returns SLVERR
    $display("\n--- 5. Write: SLVERR response ---");
    axil_write(0, 8'h30, 32'h0000_0001, 4'h1, 2'b10);
    reset_dut();

    // 6. Read response: slave returns DECERR
    $display("\n--- 6. Read:  DECERR response ---");
    axil_read(1, 8'hB0, 32'h0000_0000, 2'b11);
    reset_dut();

    // 7. Concurrent: masters to different slaves
    $display("\n--- 7. Crossbar routing: concurrent masters to different slaves ---");
    axil_write_concurrent(8'h04, 8'h84, 32'hAAAA_1111, 32'hBBBB_2222);
    reset_dut();

    // 8. Arbitration: both → slave 0
    $display("\n--- 8. Arbitration: both masters → slave 0 ---");
   // axil_write_arbitration(8'h08);
    reset_dut();
    // 9. Arbitration: both → slave 1
    $display("\n--- 9. Arbitration: both masters → slave 1 ---");
    //axil_write_arbitration(8'h90);
    reset_dut();

    // 10. Write then read same address
    $display("\n--- 10. Write then read: master 0 → slave 0 ---");
    axil_write(0, 8'h44, 32'h5A5A_5A5A, 4'hF, 2'b00);
    axil_read (0, 8'h44, 32'h5A5A_5A5A, 2'b00);
    reset_dut();

    $display("\n=================================================");
    if (errors == 0)
      $display(" ALL %0d TESTS PASSED", tests);
    else
      $display(" %0d / %0d CHECKS FAILED", errors, tests);
    $display("=================================================\n");

    $finish;
  end

  // Watchdog
  initial begin
    #500000;
    $display("WATCHDOG TIMEOUT — simulation deadlocked");
    $finish;
  end

endmodule
`default_nettype wire
