`timescale 1ns/1ps
// Assertion-enhanced starter testbench generated for simulation + protocol checking.
module easyaxil_assert;
  localparam AW=4, DW=32;
  reg ACLK=0, ARESETN=0;
  reg AWVALID=0,WVALID=0,BREADY=0,ARVALID=0,RREADY=0; wire AWREADY,WREADY,BVALID,ARREADY,RVALID; wire [1:0] BRESP,RRESP;
  reg [AW-1:0] AWADDR=0,ARADDR=0; reg [2:0] AWPROT=0,ARPROT=0; reg [DW-1:0] WDATA=0; reg [DW/8-1:0] WSTRB=0; wire [DW-1:0] RDATA;
  integer errors=0; always #5 ACLK=~ACLK;
  easyaxil #(.C_AXI_ADDR_WIDTH(AW),.OPT_SKIDBUFFER(0),.OPT_LOWPOWER(0)) dut(
    .S_AXI_ACLK(ACLK),.S_AXI_ARESETN(ARESETN),.S_AXI_AWVALID(AWVALID),.S_AXI_AWREADY(AWREADY),.S_AXI_AWADDR(AWADDR),.S_AXI_AWPROT(AWPROT),
    .S_AXI_WVALID(WVALID),.S_AXI_WREADY(WREADY),.S_AXI_WDATA(WDATA),.S_AXI_WSTRB(WSTRB),.S_AXI_BVALID(BVALID),.S_AXI_BREADY(BREADY),.S_AXI_BRESP(BRESP),
    .S_AXI_ARVALID(ARVALID),.S_AXI_ARREADY(ARREADY),.S_AXI_ARADDR(ARADDR),.S_AXI_ARPROT(ARPROT),.S_AXI_RVALID(RVALID),.S_AXI_RREADY(RREADY),.S_AXI_RDATA(RDATA),.S_AXI_RRESP(RRESP));
  task axil_write(input [AW-1:0] addr,input [DW-1:0] data); begin
    @(negedge ACLK); AWADDR=addr; WDATA=data; WSTRB=4'hf; AWVALID=1; WVALID=1; BREADY=1;
    while(!(AWREADY&&WREADY)) @(negedge ACLK);
    @(negedge ACLK); AWVALID=0; WVALID=0; while(!BVALID) @(negedge ACLK);
    if(BRESP!==2'b00) begin $display("FAIL: BRESP=%b",BRESP); errors=errors+1; end
    @(negedge ACLK); BREADY=0;
  end endtask
  task axil_read_check(input [AW-1:0] addr,input [DW-1:0] exp); begin
    @(negedge ACLK); ARADDR=addr; ARVALID=1; RREADY=1; while(!ARREADY) @(negedge ACLK);
    @(negedge ACLK); ARVALID=0; while(!RVALID) @(negedge ACLK); #1;
    if(RDATA!==exp) begin $display("FAIL: addr=%h actual=%h expected=%h",addr,RDATA,exp); errors=errors+1; end else $display("PASS: addr=%h data=%h",addr,RDATA);
    @(negedge ACLK); RREADY=0;
  end endtask
  initial begin
    repeat(5) @(posedge ACLK); ARESETN=1; repeat(2) @(posedge ACLK);
    $display("TEST EASYAXIL"); axil_write(4'h0,32'haabbccdd); axil_read_check(4'h0,32'haabbccdd); axil_write(4'h4,32'h12345678); axil_read_check(4'h4,32'h12345678);
    if(errors==0) $display("ALL TESTS PASSED"); else $display("TESTS FAILED: %0d errors",errors); $finish;
  end


  // ---------------- Assertion monitors ----------------
  // VALID must remain asserted until READY for AXI-Lite address/data channels
  reg prev_aw_wait, prev_w_wait, prev_ar_wait;
  always @(posedge ACLK) begin
    if (!ARESETN) begin
      prev_aw_wait <= 1'b0; prev_w_wait <= 1'b0; prev_ar_wait <= 1'b0;
    end else begin
      if (prev_aw_wait) if (!AWVALID) begin $display("ASSERT FAIL: AWVALID dropped before AWREADY"); errors = errors + 1; end
      if (prev_w_wait)  if (!WVALID) begin $display("ASSERT FAIL: WVALID dropped before WREADY"); errors = errors + 1; end
      if (prev_ar_wait) if (!ARVALID) begin $display("ASSERT FAIL: ARVALID dropped before ARREADY"); errors = errors + 1; end
      prev_aw_wait <= (AWVALID && !AWREADY);
      prev_w_wait  <= (WVALID  && !WREADY);
      prev_ar_wait <= (ARVALID && !ARREADY);
    end
  end

endmodule
