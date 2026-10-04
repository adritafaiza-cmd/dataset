module pulse_sync_formal;
  (* gclk *) reg gclk;
  reg [5:0] tick = 0;
  always @(posedge gclk) tick <= tick + 1'b1;
  wire clk_a = tick[0];
  wire clk_b = tick[1];
  wire rstn_a = (tick >= 8);
  wire rstn_b = (tick >= 8);
  (* anyseq *) reg pulseA_i;
  wire pulseB_o, busy_o;
  pulse_sync #(.STAGES(2)) dut (.*);

  always @* begin
    if (tick < 10)
      assume(!pulseA_i);
  end

  reg reset_seen_a = 0, reset_seen_b = 0;

  always @(posedge clk_a) begin
    if (!rstn_a) reset_seen_a <= 1;
    if (reset_seen_a && !rstn_a)
      assert(!busy_o);
  end

  always @(posedge clk_b) begin
    if (!rstn_b) reset_seen_b <= 1;
    if (reset_seen_b && !rstn_b)
      assert(!pulseB_o);
    if (reset_seen_b && rstn_b && $past(rstn_b) && $past(pulseB_o))
      assert(!pulseB_o);
  end

  always @(posedge gclk) begin
    cover(tick > 12 && rstn_a && rstn_b && busy_o);
    cover(tick > 12 && rstn_a && rstn_b && pulseB_o);
    cover(tick > 12 && rstn_a && rstn_b && !busy_o);
  end
endmodule
