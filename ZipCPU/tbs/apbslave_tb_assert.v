`timescale 1ns/1ps

module apbslave_assert;

  localparam AW = 12;
  localparam DW = 32;

  reg PCLK = 0;
  reg PRESETn = 0;

  reg PSEL = 0;
  reg PENABLE = 0;
  reg PWRITE = 0;

  reg [AW-1:0] PADDR = 0;
  reg [DW-1:0] PWDATA = 0;
  reg [DW/8-1:0] PWSTRB = 0;
  reg [2:0] PPROT = 0;

  wire PREADY;
  wire PSLVERR;
  wire [DW-1:0] PRDATA;

  integer errors = 0;

  always #5 PCLK = ~PCLK;

  apbslave #(
    .C_APB_ADDR_WIDTH(AW),
    .C_APB_DATA_WIDTH(DW)
  ) dut (
    .PCLK(PCLK),
    .PRESETn(PRESETn),
    .PSEL(PSEL),
    .PENABLE(PENABLE),
    .PREADY(PREADY),
    .PADDR(PADDR),
    .PWRITE(PWRITE),
    .PWDATA(PWDATA),
    .PWSTRB(PWSTRB),
    .PPROT(PPROT),
    .PRDATA(PRDATA),
    .PSLVERR(PSLVERR)
  );

  task apb_write;
    input [AW-1:0] addr;
    input [DW-1:0] data;
    begin
      @(negedge PCLK);
      PADDR = addr;
      PWDATA = data;
      PWRITE = 1'b1;
      PWSTRB = {DW/8{1'b1}};
      PSEL = 1'b1;
      PENABLE = 1'b0;

      @(negedge PCLK);
      PENABLE = 1'b1;
      while (!PREADY) @(negedge PCLK);

      @(negedge PCLK);
      PSEL = 1'b0;
      PENABLE = 1'b0;
      PWRITE = 1'b0;
      PWSTRB = 0;
    end
  endtask

  task apb_read_check;
    input [AW-1:0] addr;
    input [DW-1:0] exp;
    begin
      @(negedge PCLK);
      PADDR = addr;
      PWRITE = 1'b0;
      PSEL = 1'b1;
      PENABLE = 1'b0;

      @(negedge PCLK);
      PENABLE = 1'b1;
      while (!PREADY) @(negedge PCLK);

      @(posedge PCLK);
      #1;

      if (PRDATA !== exp) begin
        $display("FAIL: addr=%h actual=%h expected=%h", addr, PRDATA, exp);
        errors = errors + 1;
      end else begin
        $display("PASS: addr=%h data=%h", addr, PRDATA);
      end

      @(negedge PCLK);
      PSEL = 1'b0;
      PENABLE = 1'b0;
    end
  endtask

  always @(posedge PCLK) begin
    if (PRESETn) begin
      if (PENABLE && !PSEL) begin
        $display("ASSERT FAIL: APB PENABLE without PSEL");
        errors = errors + 1;
      end

      if (PREADY && !PSEL) begin
        $display("ASSERT FAIL: APB PREADY without active PSEL");
        errors = errors + 1;
      end
    end
  end

  initial begin
    repeat (5) @(posedge PCLK);
    PRESETn = 1'b1;

    repeat (2) @(posedge PCLK);

    $display("TEST APBSLAVE");

    apb_write(12'h000, 32'hdeadbeef);
    apb_read_check(12'h000, 32'hdeadbeef);

    apb_write(12'h004, 32'h12345678);
    apb_read_check(12'h004, 32'h12345678);

    if (errors == 0) begin
      $display("ALL TESTS PASSED");
    end else begin
      $display("TESTS FAILED: %0d errors", errors);
    end

    $finish;
  end

endmodule
