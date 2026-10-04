module rstgen_formal;
  reg clk_i = 0;
  always @($global_clock) clk_i <= !clk_i;
  (* anyseq *) reg rst_ni;
  (* anyseq *) reg test_mode_i;
  wire rst_no, init_no;
  rstgen dut (.*);

  reg [3:0] model = 0;
  reg past_valid = 0;
  initial assume(!rst_ni);
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) model <= 0;
    else model <= {model[2:0], 1'b1};
  end
  always @($global_clock) begin
    past_valid <= 1;
    if (past_valid) begin
      assert(rst_no == init_no);
      assert(rst_no == model[3]);
      if (!rst_ni) assert(!rst_no && !init_no);
    end
    cover(past_valid && rst_ni && rst_no && init_no);
    cover(past_valid && !rst_ni && !rst_no && !init_no);
  end
endmodule
