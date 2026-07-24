`timescale 1ns/1ps
`default_nettype none

module axisafety_assert;

  localparam IW = 1;
  localparam DW = 32;
  localparam AW = 8;

  reg clk = 1'b0;
  reg rstn = 1'b0;

  always #5 clk = ~clk;

  integer errors = 0;
  integer tests  = 0;

  wire rfault;
  wire wfault;
  wire m_rstn;

  reg  [IW-1:0] s_awid;
  reg  [AW-1:0] s_awaddr;
  reg  [7:0]    s_awlen;
  reg  [2:0]    s_awsize;
  reg  [1:0]    s_awburst;
  reg           s_awlock;
  reg  [3:0]    s_awcache;
  reg  [2:0]    s_awprot;
  reg  [3:0]    s_awqos;
  reg           s_awvalid;
  wire          s_awready;

  reg  [DW-1:0]   s_wdata;
  reg  [DW/8-1:0] s_wstrb;
  reg             s_wlast;
  reg             s_wvalid;
  wire            s_wready;

  wire [IW-1:0] s_bid;
  wire [1:0]    s_bresp;
  wire          s_bvalid;
  reg           s_bready;

  reg  [IW-1:0] s_arid;
  reg  [AW-1:0] s_araddr;
  reg  [7:0]    s_arlen;
  reg  [2:0]    s_arsize;
  reg  [1:0]    s_arburst;
  reg           s_arlock;
  reg  [3:0]    s_arcache;
  reg  [2:0]    s_arprot;
  reg  [3:0]    s_arqos;
  reg           s_arvalid;
  wire          s_arready;

  wire [IW-1:0] s_rid;
  wire [DW-1:0] s_rdata;
  wire [1:0]    s_rresp;
  wire          s_rlast;
  wire          s_rvalid;
  reg           s_rready;

  wire [IW-1:0] m_awid;
  wire [AW-1:0] m_awaddr;
  wire [7:0]    m_awlen;
  wire [2:0]    m_awsize;
  wire [1:0]    m_awburst;
  wire          m_awlock;
  wire [3:0]    m_awcache;
  wire [2:0]    m_awprot;
  wire [3:0]    m_awqos;
  wire          m_awvalid;
  reg           m_awready;

  wire [DW-1:0]   m_wdata;
  wire [DW/8-1:0] m_wstrb;
  wire            m_wlast;
  wire            m_wvalid;
  reg             m_wready;

  reg  [IW-1:0] m_bid;
  reg  [1:0]    m_bresp;
  reg           m_bvalid;
  wire          m_bready;

  wire [IW-1:0] m_arid;
  wire [AW-1:0] m_araddr;
  wire [7:0]    m_arlen;
  wire [2:0]    m_arsize;
  wire [1:0]    m_arburst;
  wire          m_arlock;
  wire [3:0]    m_arcache;
  wire [2:0]    m_arprot;
  wire [3:0]    m_arqos;
  wire          m_arvalid;
  reg           m_arready;

  reg  [IW-1:0] m_rid;
  reg  [DW-1:0] m_rdata;
  reg  [1:0]    m_rresp;
  reg           m_rlast;
  reg           m_rvalid;
  wire          m_rready;

  axisafety #(
    .C_S_AXI_ID_WIDTH  (IW),
    .C_S_AXI_DATA_WIDTH(DW),
    .C_S_AXI_ADDR_WIDTH(AW),
    .OPT_SELF_RESET    (1'b0),
    .OPT_TIMEOUT       (8)
  ) dut (
    .o_read_fault      (rfault),
    .o_write_fault     (wfault),

    .S_AXI_ACLK        (clk),
    .S_AXI_ARESETN     (rstn),
    .M_AXI_ARESETN     (m_rstn),

    .S_AXI_AWID        (s_awid),
    .S_AXI_AWADDR      (s_awaddr),
    .S_AXI_AWLEN       (s_awlen),
    .S_AXI_AWSIZE      (s_awsize),
    .S_AXI_AWBURST     (s_awburst),
    .S_AXI_AWLOCK      (s_awlock),
    .S_AXI_AWCACHE     (s_awcache),
    .S_AXI_AWPROT      (s_awprot),
    .S_AXI_AWQOS       (s_awqos),
    .S_AXI_AWVALID     (s_awvalid),
    .S_AXI_AWREADY     (s_awready),

    .S_AXI_WDATA       (s_wdata),
    .S_AXI_WSTRB       (s_wstrb),
    .S_AXI_WLAST       (s_wlast),
    .S_AXI_WVALID      (s_wvalid),
    .S_AXI_WREADY      (s_wready),

    .S_AXI_BID         (s_bid),
    .S_AXI_BRESP       (s_bresp),
    .S_AXI_BVALID      (s_bvalid),
    .S_AXI_BREADY      (s_bready),

    .S_AXI_ARID        (s_arid),
    .S_AXI_ARADDR      (s_araddr),
    .S_AXI_ARLEN       (s_arlen),
    .S_AXI_ARSIZE      (s_arsize),
    .S_AXI_ARBURST     (s_arburst),
    .S_AXI_ARLOCK      (s_arlock),
    .S_AXI_ARCACHE     (s_arcache),
    .S_AXI_ARPROT      (s_arprot),
    .S_AXI_ARQOS       (s_arqos),
    .S_AXI_ARVALID     (s_arvalid),
    .S_AXI_ARREADY     (s_arready),

    .S_AXI_RID         (s_rid),
    .S_AXI_RDATA       (s_rdata),
    .S_AXI_RRESP       (s_rresp),
    .S_AXI_RLAST       (s_rlast),
    .S_AXI_RVALID      (s_rvalid),
    .S_AXI_RREADY      (s_rready),

    .M_AXI_AWID        (m_awid),
    .M_AXI_AWADDR      (m_awaddr),
    .M_AXI_AWLEN       (m_awlen),
    .M_AXI_AWSIZE      (m_awsize),
    .M_AXI_AWBURST     (m_awburst),
    .M_AXI_AWLOCK      (m_awlock),
    .M_AXI_AWCACHE     (m_awcache),
    .M_AXI_AWPROT      (m_awprot),
    .M_AXI_AWQOS       (m_awqos),
    .M_AXI_AWVALID     (m_awvalid),
    .M_AXI_AWREADY     (m_awready),

    .M_AXI_WDATA       (m_wdata),
    .M_AXI_WSTRB       (m_wstrb),
    .M_AXI_WLAST       (m_wlast),
    .M_AXI_WVALID      (m_wvalid),
    .M_AXI_WREADY      (m_wready),

    .M_AXI_BID         (m_bid),
    .M_AXI_BRESP       (m_bresp),
    .M_AXI_BVALID      (m_bvalid),
    .M_AXI_BREADY      (m_bready),

    .M_AXI_ARID        (m_arid),
    .M_AXI_ARADDR      (m_araddr),
    .M_AXI_ARLEN       (m_arlen),
    .M_AXI_ARSIZE      (m_arsize),
    .M_AXI_ARBURST     (m_arburst),
    .M_AXI_ARLOCK      (m_arlock),
    .M_AXI_ARCACHE     (m_arcache),
    .M_AXI_ARPROT      (m_arprot),
    .M_AXI_ARQOS       (m_arqos),
    .M_AXI_ARVALID     (m_arvalid),
    .M_AXI_ARREADY     (m_arready),

    .M_AXI_RID         (m_rid),
    .M_AXI_RDATA       (m_rdata),
    .M_AXI_RRESP       (m_rresp),
    .M_AXI_RLAST       (m_rlast),
    .M_AXI_RVALID      (m_rvalid),
    .M_AXI_RREADY      (m_rready)
  );

  task check;
    input cond;
    input [255:0] msg;
    begin
      tests = tests + 1;

      if (cond) begin
        $display("PASS [%0d]: %0s", tests, msg);
      end else begin
        $display("FAIL [%0d]: %0s", tests, msg);
        errors = errors + 1;
      end
    end
  endtask

  task reset_dut;
    begin
      s_awvalid = 1'b0;
      s_wvalid  = 1'b0;
      s_bready  = 1'b0;
      s_arvalid = 1'b0;
      s_rready  = 1'b0;

      m_awready = 1'b0;
      m_wready  = 1'b0;
      m_bvalid  = 1'b0;
      m_arready = 1'b0;
      m_rvalid  = 1'b0;

      rstn = 1'b0;
      repeat(5) @(posedge clk);

      rstn = 1'b1;
      repeat(5) @(posedge clk);
    end
  endtask

  task good_write;
    integer timeout;
    reg aw_done;
    reg w_done;
    begin
      $display("\nTEST: good AXI write");

      @(negedge clk);

      s_awid    = 0;
      s_awaddr  = 8'h20;
      s_awlen   = 8'd0;
      s_awsize  = 3'd2;
      s_awburst = 2'b01;
      s_awvalid = 1'b1;

      s_wdata   = 32'hDEAD_BEEF;
      s_wstrb   = 4'hF;
      s_wlast   = 1'b1;
      s_wvalid  = 1'b1;

      s_bready  = 1'b1;

      m_awready = 1'b1;
      m_wready  = 1'b1;

      aw_done = 1'b0;
      w_done  = 1'b0;
      timeout = 0;

      while ((!aw_done || !w_done) && timeout < 100) begin
        @(posedge clk);

        if (!aw_done && s_awvalid && s_awready)
          aw_done = 1'b1;

        if (!w_done && s_wvalid && s_wready)
          w_done = 1'b1;

        timeout = timeout + 1;
      end

      @(negedge clk);

      if (aw_done)
        s_awvalid = 1'b0;

      if (w_done)
        s_wvalid = 1'b0;

      check(aw_done, "write address accepted");
      check(w_done,  "write data accepted");

      @(negedge clk);
      m_awready = 1'b0;
      m_wready  = 1'b0;

      m_bid    = 0;
      m_bresp  = 2'b00;
      m_bvalid = 1'b1;

      timeout = 0;
      while (!s_bvalid && timeout < 100) begin
        @(posedge clk);
        timeout = timeout + 1;
      end

      check(s_bvalid, "write response returned");
      check(s_bresp == 2'b00, "write response is OKAY");

      @(negedge clk);
      m_bvalid = 1'b0;
      s_bready = 1'b0;

      repeat(3) @(posedge clk);
    end
  endtask

  task good_read;
    integer timeout;
    begin
      $display("\nTEST: good AXI read");

      @(negedge clk);

      s_arid    = 0;
      s_araddr  = 8'h30;
      s_arlen   = 8'd0;
      s_arsize  = 3'd2;
      s_arburst = 2'b01;
      s_arvalid = 1'b1;
      s_rready  = 1'b1;

      m_arready = 1'b1;

      timeout = 0;
      while (!s_arready && timeout < 100) begin
        @(posedge clk);
        timeout = timeout + 1;
      end

      check(s_arready, "read address accepted");

      @(negedge clk);
      s_arvalid = 1'b0;
      m_arready = 1'b0;

      m_rid    = 0;
      m_rdata  = 32'hCAFE_BABE;
      m_rresp  = 2'b00;
      m_rlast  = 1'b1;
      m_rvalid = 1'b1;

      timeout = 0;
      while (!s_rvalid && timeout < 100) begin
        @(posedge clk);
        timeout = timeout + 1;
      end

      check(s_rvalid, "read response returned");
      check(s_rdata == 32'hCAFE_BABE, "read data matches");
      check(s_rresp == 2'b00, "read response is OKAY");
      check(s_rlast, "read response asserted RLAST");

      @(negedge clk);
      m_rvalid = 1'b0;
      s_rready = 1'b0;

      repeat(3) @(posedge clk);
    end
  endtask

  task read_timeout_test;
    begin
      $display("\nTEST: read timeout fault");

      reset_dut();

      @(negedge clk);
      s_araddr  = 8'h40;
      s_arlen   = 8'd0;
      s_arvalid = 1'b1;
      s_rready  = 1'b1;

      m_arready = 1'b0;
      m_rvalid  = 1'b0;

      repeat(25) @(posedge clk);

      check(rfault, "read fault asserted on timeout");

      s_arvalid = 1'b0;
      s_rready  = 1'b0;
    end
  endtask

  reg prev_s_aw_wait;
  reg prev_s_w_wait;
  reg prev_s_ar_wait;

  reg prev_m_aw_wait;
  reg prev_m_w_wait;
  reg prev_m_ar_wait;

  always @(posedge clk) begin
    if (!rstn) begin
      prev_s_aw_wait <= 1'b0;
      prev_s_w_wait  <= 1'b0;
      prev_s_ar_wait <= 1'b0;

      prev_m_aw_wait <= 1'b0;
      prev_m_w_wait  <= 1'b0;
      prev_m_ar_wait <= 1'b0;
    end else begin
      if (prev_s_aw_wait && !s_awvalid) begin
        $display("ASSERT FAIL: S_AWVALID dropped before S_AWREADY");
        errors = errors + 1;
      end

      if (prev_s_w_wait && !s_wvalid) begin
        $display("ASSERT FAIL: S_WVALID dropped before S_WREADY");
        errors = errors + 1;
      end

      if (prev_s_ar_wait && !s_arvalid) begin
        $display("ASSERT FAIL: S_ARVALID dropped before S_ARREADY");
        errors = errors + 1;
      end

      if (prev_m_aw_wait && !m_awvalid) begin
        $display("ASSERT FAIL: M_AWVALID dropped before M_AWREADY");
        errors = errors + 1;
      end

      if (prev_m_w_wait && !m_wvalid) begin
        $display("ASSERT FAIL: M_WVALID dropped before M_WREADY");
        errors = errors + 1;
      end

      if (prev_m_ar_wait && !m_arvalid) begin
        $display("ASSERT FAIL: M_ARVALID dropped before M_ARREADY");
        errors = errors + 1;
      end

      prev_s_aw_wait <= s_awvalid && !s_awready;
      prev_s_w_wait  <= s_wvalid  && !s_wready;
      prev_s_ar_wait <= s_arvalid && !s_arready;

      prev_m_aw_wait <= m_awvalid && !m_awready;
      prev_m_w_wait  <= m_wvalid  && !m_wready;
      prev_m_ar_wait <= m_arvalid && !m_arready;
    end
  end

  initial begin
    s_awid    = 0;
    s_awaddr  = 0;
    s_awlen   = 0;
    s_awsize  = 3'd2;
    s_awburst = 2'b01;
    s_awlock  = 0;
    s_awcache = 0;
    s_awprot  = 0;
    s_awqos   = 0;
    s_awvalid = 0;

    s_wdata   = 0;
    s_wstrb   = 4'hF;
    s_wlast   = 1'b1;
    s_wvalid  = 0;
    s_bready  = 0;

    s_arid    = 0;
    s_araddr  = 0;
    s_arlen   = 0;
    s_arsize  = 3'd2;
    s_arburst = 2'b01;
    s_arlock  = 0;
    s_arcache = 0;
    s_arprot  = 0;
    s_arqos   = 0;
    s_arvalid = 0;
    s_rready  = 0;

    m_awready = 0;
    m_wready  = 0;

    m_bvalid = 0;
    m_bid    = 0;
    m_bresp  = 0;

    m_arready = 0;

    m_rvalid = 0;
    m_rid    = 0;
    m_rdata  = 0;
    m_rresp  = 0;
    m_rlast  = 1'b1;

    reset_dut();

    $display("========================================");
    $display(" AXISAFETY TESTBENCH");
    $display("========================================");

    $display("rstn=%b m_rstn=%b wfault=%b rfault=%b",
             rstn, m_rstn, wfault, rfault);

    good_write();

    reset_dut();
    good_read();

    read_timeout_test();

    $display("========================================");

    if (errors == 0)
      $display("ALL %0d TESTS PASSED", tests);
    else
      $display("%0d / %0d TESTS FAILED", errors, tests);

    $display("========================================");

    $finish;
  end

  initial begin
    #100000;
    $display("WATCHDOG TIMEOUT");
    $finish;
  end

endmodule

`default_nettype wire
