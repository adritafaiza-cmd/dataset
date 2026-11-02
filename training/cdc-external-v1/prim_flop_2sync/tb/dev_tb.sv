module dev_tb;
  logic clk_i, rst_ni; logic [3:0] d_i; logic [3:0] q_o;
  prim_flop_2sync #(.Width(4)) dut(.clk_i(clk_i), .rst_ni(rst_ni), .d_i(d_i), .q_o(q_o));
  always #5 clk_i = ~clk_i;
  initial begin clk_i=0; rst_ni=0; d_i=0; #12; if (q_o!==0) $display("RESET FAIL"); rst_ni=1; d_i=4'hA; #22; if (q_o!==4'hA) $display("SYNC FAIL"); else $display("PASS"); $finish; end
endmodule
