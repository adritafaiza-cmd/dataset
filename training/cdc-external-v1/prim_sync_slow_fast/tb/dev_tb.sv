module dev_tb;
  logic clk_slow_i, clk_fast_i, rst_fast_ni;
  logic [31:0] wdata_i, rdata_o;
  prim_sync_slow_fast #(.Width(32)) dut(.clk_slow_i(clk_slow_i), .clk_fast_i(clk_fast_i),
      .rst_fast_ni(rst_fast_ni), .wdata_i(wdata_i), .rdata_o(rdata_o));
  always #10 clk_slow_i = ~clk_slow_i;
  always #2 clk_fast_i = ~clk_fast_i;
  initial begin
    clk_slow_i=0; clk_fast_i=0; rst_fast_ni=0; wdata_i=0;
    #12; if (rdata_o !== 0) $display("RESET FAIL");
    rst_fast_ni=1; wdata_i=32'h1234_5678;
    #80; if (rdata_o !== 32'h1234_5678) $display("DATA FAIL %h", rdata_o); else $display("PASS");
    $finish;
  end
endmodule
