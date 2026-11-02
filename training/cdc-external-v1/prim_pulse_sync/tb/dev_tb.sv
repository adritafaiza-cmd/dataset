module dev_tb;
  logic clk_src_i, clk_dst_i, rst_src_ni, rst_dst_ni, src_pulse_i;
  logic dst_pulse_o;
  integer pulse_count;
  prim_pulse_sync dut(.clk_src_i(clk_src_i), .rst_src_ni(rst_src_ni), .src_pulse_i(src_pulse_i),
                      .clk_dst_i(clk_dst_i), .rst_dst_ni(rst_dst_ni), .dst_pulse_o(dst_pulse_o));
  always #5 clk_src_i = ~clk_src_i;
  always #7 clk_dst_i = ~clk_dst_i;
  always @(posedge clk_dst_i) if (dst_pulse_o) pulse_count = pulse_count + 1;
  initial begin
    clk_src_i=0; clk_dst_i=0; rst_src_ni=0; rst_dst_ni=0; src_pulse_i=0; pulse_count=0;
    #20; if (dst_pulse_o !== 0) $display("RESET FAIL");
    rst_src_ni=1; rst_dst_ni=1; #11; src_pulse_i=1; #10; src_pulse_i=0;
    #100; if (pulse_count != 1) $display("PULSE COUNT FAIL %0d", pulse_count); else $display("PASS");
    $finish;
  end
endmodule
