module areset_deassert_sync_formal;
  localparam CHAINS = 2;
  reg clk = 0;
  always @($global_clock) clk <= !clk;
  (* anyseq *) reg async_rst_i;
  wire sync_rst_o;
  areset_deassert_sync #(.CHAINS(CHAINS), .RST_POL(1'b1)) dut (.*);

  reg [CHAINS-1:0] model = {CHAINS{1'b1}};
  reg past_valid = 0;
  initial assume(async_rst_i);
  always @(posedge clk or posedge async_rst_i) begin
    if (async_rst_i) model <= {CHAINS{1'b1}};
    else model <= {model[0], 1'b0};
  end
  always @($global_clock) begin
    past_valid <= 1;
    if (past_valid) begin
      assert(sync_rst_o == model[1]);
      if (async_rst_i) assert(sync_rst_o);
    end
    cover(past_valid && !async_rst_i && !sync_rst_o);
    cover(past_valid && async_rst_i && sync_rst_o);
  end
endmodule
