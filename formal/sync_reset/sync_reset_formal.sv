module sync_reset_formal;
  localparam N = 2;
  reg clk = 0;
  always @($global_clock) clk <= !clk;
  (* anyseq *) reg rst;
  wire out;
  sync_reset #(.N(N)) dut (.*);

  reg [N-1:0] model = {N{1'b1}};
  reg past_valid = 0;
  initial assume(rst);
  always @(posedge clk or posedge rst) begin
    if (rst) model <= {N{1'b1}};
    else model <= {model[0], 1'b0};
  end
  always @($global_clock) begin
    past_valid <= 1;
    if (past_valid) begin
      assert(out == model[1]);
      if (rst) assert(out);
    end
    cover(past_valid && !rst && !out);
    cover(past_valid && rst && out);
  end
endmodule
