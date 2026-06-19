`timescale 1ns/1ps
module wbxclk_tb;
  localparam AW=8, DW=32, LGFIFO=3;
  reg wb_clk=0, xclk=0, reset=1; always #5 wb_clk=~wb_clk; always #7 xclk=~xclk;
  reg cyc=0,stb=0,we=0; reg [AW-1:0] addr=0; reg [DW-1:0] data=0; reg [DW/8-1:0] sel=0; wire stall,ack,err; wire [DW-1:0] rdata;
  wire x_cyc,x_stb,x_we; wire [AW-1:0] x_addr; wire [DW-1:0] x_data; wire [DW/8-1:0] x_sel; reg x_stall=0,x_ack=0,x_err=0; reg [DW-1:0] x_rdata=0;
  reg [DW-1:0] mem[0:255]; integer errors=0;
  wbxclk #(.AW(AW),.DW(DW),.LGFIFO(LGFIFO)) dut(
    .i_wb_clk(wb_clk),.i_reset(reset),.i_wb_cyc(cyc),.i_wb_stb(stb),.i_wb_we(we),.i_wb_addr(addr),.i_wb_data(data),.i_wb_sel(sel),.o_wb_stall(stall),.o_wb_ack(ack),.o_wb_data(rdata),.o_wb_err(err),
    .i_xclk_clk(xclk),.o_xclk_cyc(x_cyc),.o_xclk_stb(x_stb),.o_xclk_we(x_we),.o_xclk_addr(x_addr),.o_xclk_data(x_data),.o_xclk_sel(x_sel),.i_xclk_stall(x_stall),.i_xclk_ack(x_ack),.i_xclk_data(x_rdata),.i_xclk_err(x_err));
  always @(posedge xclk) begin
    x_ack <= 0;
    if(x_cyc && x_stb && !x_stall) begin
      x_ack <= 1;
      if(x_we) mem[x_addr] <= x_data;
      x_rdata <= mem[x_addr];
    end
  end
  task wb_write(input [AW-1:0] a,input [DW-1:0] d); begin
    @(negedge wb_clk); cyc=1; stb=1; we=1; addr=a; data=d; sel=4'hf; while(stall) @(negedge wb_clk);
    @(negedge wb_clk); stb=0; while(!ack) @(negedge wb_clk); @(negedge wb_clk); cyc=0; we=0;
  end endtask
  task wb_read_check(input [AW-1:0] a,input [DW-1:0] exp); begin
    @(negedge wb_clk); cyc=1; stb=1; we=0; addr=a; sel=4'hf; while(stall) @(negedge wb_clk);
    @(negedge wb_clk); stb=0; while(!ack) @(negedge wb_clk); #1;
    if(rdata!==exp) begin $display("FAIL: addr=%h actual=%h expected=%h",a,rdata,exp); errors=errors+1; end else $display("PASS: addr=%h data=%h",a,rdata);
    @(negedge wb_clk); cyc=0;
  end endtask
  initial begin
    repeat(8) @(posedge wb_clk); reset=0; repeat(8) @(posedge wb_clk);
    $display("TEST WBXCLK"); wb_write(8'h01,32'h1234abcd); wb_read_check(8'h01,32'h1234abcd); wb_write(8'h02,32'hc001d00d); wb_read_check(8'h02,32'hc001d00d);
    if(errors==0) $display("ALL TESTS PASSED"); else $display("TESTS FAILED: %0d errors",errors); $finish;
  end
endmodule
