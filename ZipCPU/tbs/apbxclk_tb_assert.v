`timescale 1ns/1ps
// Assertion-enhanced starter testbench generated for simulation + protocol checking.
module apbxclk_assert;
  localparam AW=12, DW=32;
  reg SCLK=0, MCLK=0, RSTN=0; always #5 SCLK=~SCLK; always #7 MCLK=~MCLK;
  reg S_PSEL=0,S_PENABLE=0,S_PWRITE=0; reg [AW-1:0] S_PADDR=0; reg [DW-1:0] S_PWDATA=0; reg [DW/8-1:0] S_PWSTRB=0; reg [2:0] S_PPROT=0; wire S_PREADY,S_PSLVERR; wire [DW-1:0] S_PRDATA;
  wire M_PRESETn,M_PSEL,M_PENABLE,M_PWRITE; wire [AW-1:0] M_PADDR; wire [DW-1:0] M_PWDATA; wire [DW/8-1:0] M_PWSTRB; wire [2:0] M_PPROT; reg M_PREADY=1; reg [DW-1:0] M_PRDATA=0; reg M_PSLVERR=0;
  reg [DW-1:0] mem[0:255]; integer errors=0;
  apbxclk #(.C_APB_ADDR_WIDTH(AW),.C_APB_DATA_WIDTH(DW),.OPT_REGISTERED(0)) dut(
    .S_APB_PCLK(SCLK),.S_PRESETn(RSTN),.S_APB_PSEL(S_PSEL),.S_APB_PENABLE(S_PENABLE),.S_APB_PREADY(S_PREADY),.S_APB_PADDR(S_PADDR),.S_APB_PWRITE(S_PWRITE),.S_APB_PWDATA(S_PWDATA),.S_APB_PWSTRB(S_PWSTRB),.S_APB_PPROT(S_PPROT),.S_APB_PRDATA(S_PRDATA),.S_APB_PSLVERR(S_PSLVERR),
    .M_APB_PCLK(MCLK),.M_PRESETn(M_PRESETn),.M_APB_PSEL(M_PSEL),.M_APB_PENABLE(M_PENABLE),.M_APB_PREADY(M_PREADY),.M_APB_PADDR(M_PADDR),.M_APB_PWRITE(M_PWRITE),.M_APB_PWDATA(M_PWDATA),.M_APB_PWSTRB(M_PWSTRB),.M_APB_PPROT(M_PPROT),.M_APB_PRDATA(M_PRDATA),.M_APB_PSLVERR(M_PSLVERR));
  always @(posedge MCLK) begin
    if(M_PSEL && M_PENABLE && M_PREADY && M_PWRITE) mem[M_PADDR[9:2]] <= M_PWDATA;
    if(M_PSEL && !M_PWRITE) M_PRDATA <= mem[M_PADDR[9:2]];
  end
  task apb_write(input [AW-1:0] addr,input [DW-1:0] data); begin
    @(negedge SCLK); S_PADDR=addr; S_PWDATA=data; S_PWRITE=1; S_PWSTRB=4'hf; S_PSEL=1; S_PENABLE=0;
    @(negedge SCLK); S_PENABLE=1; while(!S_PREADY) @(negedge SCLK); @(negedge SCLK); S_PSEL=0; S_PENABLE=0; S_PWRITE=0;
  end endtask
  task apb_read_check(input [AW-1:0] addr,input [DW-1:0] exp); begin
    @(negedge SCLK); S_PADDR=addr; S_PWRITE=0; S_PSEL=1; S_PENABLE=0; @(negedge SCLK); S_PENABLE=1; while(!S_PREADY) @(negedge SCLK); #1;
    if(S_PRDATA!==exp) begin $display("FAIL: addr=%h actual=%h expected=%h",addr,S_PRDATA,exp); errors=errors+1; end else $display("PASS: addr=%h data=%h",addr,S_PRDATA);
    @(negedge SCLK); S_PSEL=0; S_PENABLE=0;
  end endtask
  initial begin
    repeat(5) @(posedge SCLK); RSTN=1; repeat(10) @(posedge SCLK);
    $display("TEST APBXCLK"); apb_write(12'h000,32'hfeedface); apb_read_check(12'h000,32'hfeedface); apb_write(12'h004,32'h87654321); apb_read_check(12'h004,32'h87654321);
    if(errors==0) $display("ALL TESTS PASSED"); else $display("TESTS FAILED: %0d errors",errors); $finish;
  end


  // ---------------- Assertion monitors ----------------
  // APB enable phase must only occur after/select phase
  always @(posedge S_PCLK) begin
    if (S_PRESETn) begin
      if (!(!S_PENABLE || S_PSEL) else begin $display("ASSERT FAIL: APB PENABLE without PSEL")) begin $display("ASSERT FAIL: !S_PENABLE || S_PSEL) else begin $display("ASSERT FAIL: APB PENABLE without PSEL""); errors = errors + 1; end errors = errors + 1; end
      if (!(!S_PREADY || S_PSEL) else begin $display("ASSERT FAIL: APB PREADY without active PSEL")) begin $display("ASSERT FAIL: !S_PREADY || S_PSEL) else begin $display("ASSERT FAIL: APB PREADY without active PSEL""); errors = errors + 1; end errors = errors + 1; end
    end
  end


  // ---------------- Assertion monitors ----------------
  // APB enable phase must only occur after/select phase
  always @(posedge M_PCLK) begin
    if (M_PRESETn) begin
      if (!(!M_PENABLE || M_PSEL) else begin $display("ASSERT FAIL: APB PENABLE without PSEL")) begin $display("ASSERT FAIL: !M_PENABLE || M_PSEL) else begin $display("ASSERT FAIL: APB PENABLE without PSEL""); errors = errors + 1; end errors = errors + 1; end
      if (!(!M_PREADY || M_PSEL) else begin $display("ASSERT FAIL: APB PREADY without active PSEL")) begin $display("ASSERT FAIL: !M_PREADY || M_PSEL) else begin $display("ASSERT FAIL: APB PREADY without active PSEL""); errors = errors + 1; end errors = errors + 1; end
    end
  end

endmodule
