`timescale 1ns/1ps

module apbslave_tb_fixed;

  localparam AW = 12;
  localparam DW = 32;

  // Clock and reset
  reg PCLK    = 0;
  reg PRESETn = 0;

  // Master-driven signals
  reg           PSEL    = 0;
  reg           PENABLE = 0;
  reg           PWRITE  = 0;
  reg [AW-1:0]  PADDR   = 0;
  reg [DW-1:0]  PWDATA  = 0;
  reg [DW/8-1:0] PWSTRB = 0;
  reg [2:0]     PPROT   = 0;

  // Slave-driven signals
  wire           PREADY;
  wire           PSLVERR;
  wire [DW-1:0]  PRDATA;

  integer errors = 0;

  always #5 PCLK = ~PCLK;  // 100 MHz

  // -------------------------------------------------------------------------
  // DUT
  // -------------------------------------------------------------------------
  apbslave #(
    .C_APB_ADDR_WIDTH(AW),
    .C_APB_DATA_WIDTH(DW)
  ) dut (
    .PCLK    (PCLK),
    .PRESETn (PRESETn),
    .PSEL    (PSEL),
    .PENABLE (PENABLE),
    .PREADY  (PREADY),
    .PADDR   (PADDR),
    .PWRITE  (PWRITE),
    .PWDATA  (PWDATA),
    .PWSTRB  (PWSTRB),
    .PPROT   (PPROT),
    .PRDATA  (PRDATA),
    .PSLVERR (PSLVERR)
  );

  // -------------------------------------------------------------------------
  // APB write task
  //
  // APB write protocol (per spec):
  //   Cycle N   : SETUP  — assert PSEL=1, PENABLE=0, PWRITE=1, PADDR, PWDATA, PWSTRB
  //               DUT writes mem[] on THIS posedge (PSEL && !PENABLE && PWRITE)
  //   Cycle N+1 : ACCESS — assert PENABLE=1; DUT asserts PREADY=1 on this posedge
  //               Transfer complete — deassert all control signals in the same cycle
  // -------------------------------------------------------------------------
  task apb_write;
    input [AW-1:0]   addr;
    input [DW-1:0]   data;
    input [DW/8-1:0] strb;
    begin
      // Drive SETUP phase after the falling edge
      @(negedge PCLK);
      PADDR  = addr;
      PWDATA = data;
      PWSTRB = strb;
      PWRITE = 1'b1;
      PSEL   = 1'b1;
      PENABLE = 1'b0;
      // DUT captures the write on the upcoming posedge (PSEL=1, PENABLE=0, PWRITE=1)

      // Drive ACCESS phase
      @(negedge PCLK);
      PENABLE = 1'b1;
      // DUT asserts PREADY=1 for exactly one cycle here

      // Wait for PREADY (handles variable-latency slaves too)
      @(posedge PCLK);
      while (!PREADY) @(posedge PCLK);

      // Transfer complete — deassert immediately (same negedge, no extra cycle)
      @(negedge PCLK);
      PSEL    = 1'b0;
      PENABLE = 1'b0;
      PWRITE  = 1'b0;
      PWSTRB  = 0;
    end
  endtask

  // -------------------------------------------------------------------------
  // APB read task
  //
  //   Cycle N   : SETUP  — PSEL=1, PENABLE=0, PWRITE=0, PADDR
  //               DUT registers PRDATA from mem[] on this posedge
  //   Cycle N+1 : ACCESS — PENABLE=1; DUT asserts PREADY=1 and PRDATA is stable
  //               Sample PRDATA after posedge when PSEL & PENABLE & PREADY
  // -------------------------------------------------------------------------
  task apb_read_check;
    input [AW-1:0] addr;
    input [DW-1:0] exp;
    reg   [DW-1:0] captured;
    begin
      @(negedge PCLK);
      PADDR   = addr;
      PWRITE  = 1'b0;
      PSEL    = 1'b1;
      PENABLE = 1'b0;
      // DUT registers PRDATA on the upcoming posedge

      @(negedge PCLK);
      PENABLE = 1'b1;

      // Wait for PREADY, then sample PRDATA — both stable at this posedge
      @(posedge PCLK);
      while (!PREADY) @(posedge PCLK);
      // Small propagation delay before sampling combinational outputs
      #1;
      captured = PRDATA;

      if (captured !== exp) begin
        $display("FAIL [read] addr=%h  got=%h  exp=%h", addr, captured, exp);
        errors = errors + 1;
      end else begin
        $display("PASS [read] addr=%h  data=%h", addr, captured);
      end

      @(negedge PCLK);
      PSEL    = 1'b0;
      PENABLE = 1'b0;
    end
  endtask

  // -------------------------------------------------------------------------
  // APB protocol checker (runs every clock)
  // Checks slave-side outputs as well as master-driven bus invariants.
  // -------------------------------------------------------------------------
  always @(posedge PCLK) begin
    if (PRESETn) begin
      // PENABLE must never be high without PSEL
      if (PENABLE && !PSEL) begin
        $display("PROTOCOL FAIL: PENABLE=1 without PSEL at time %0t", $time);
        errors = errors + 1;
      end
      // PREADY must only be asserted during the ACCESS phase (PSEL & PENABLE)
      if (PREADY && !(PSEL && PENABLE)) begin
        $display("PROTOCOL FAIL: PREADY outside ACCESS phase at time %0t", $time);
        errors = errors + 1;
      end
      // PSLVERR must be 0 in this design
      if (PSLVERR) begin
        $display("PROTOCOL FAIL: unexpected PSLVERR at time %0t", $time);
        errors = errors + 1;
      end
    end
  end

  // -------------------------------------------------------------------------
  // Stimulus
  // -------------------------------------------------------------------------
  initial begin
    // Hold reset for 5 clocks
    repeat (5) @(posedge PCLK);
    PRESETn = 1'b1;
    repeat (2) @(posedge PCLK);

    $display("=== TEST: basic write/read ===");
    apb_write(12'h000, 32'hDEADBEEF, {DW/8{1'b1}});
    apb_read_check(12'h000, 32'hDEADBEEF);

    apb_write(12'h004, 32'h12345678, {DW/8{1'b1}});
    apb_read_check(12'h004, 32'h12345678);

    // Make sure different addresses are independent
    apb_read_check(12'h000, 32'hDEADBEEF);

    $display("=== TEST: byte-strobe partial write ===");
    // Write 0xFF to only byte 0 of address 0x008, leave other bytes as 0x00
    apb_write(12'h008, 32'h000000FF, 4'b0001);
    apb_read_check(12'h008, 32'h000000FF);

    // Now overwrite only the top byte with 0xAB
    apb_write(12'h008, 32'hAB000000, 4'b1000);
    apb_read_check(12'h008, 32'hAB0000FF);

    $display("=== TEST: back-to-back transfers ===");
    apb_write(12'h010, 32'hAAAA5555, {DW/8{1'b1}});
    apb_write(12'h014, 32'h5555AAAA, {DW/8{1'b1}});
    apb_read_check(12'h010, 32'hAAAA5555);
    apb_read_check(12'h014, 32'h5555AAAA);

    // Final result
    repeat (2) @(posedge PCLK);
    if (errors == 0)
      $display("ALL TESTS PASSED");
    else
      $display("TESTS FAILED: %0d error(s)", errors);

    $finish;
  end

endmodule
