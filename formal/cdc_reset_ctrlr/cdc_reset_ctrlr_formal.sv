module cdc_reset_ctrlr_formal;
  reg [2:0] phase = 0;
  always @($global_clock) phase <= phase + 1'b1;
  wire a_clk_i = phase[0];
  wire b_clk_i = phase[1];

  reg [3:0] startup = 0;
  always @($global_clock) if (startup != 15) startup <= startup + 1'b1;
  wire a_rst_ni = startup >= 2;
  wire b_rst_ni = startup >= 4;
  (* anyseq *) reg a_clear_i, b_clear_i;
  wire a_clear_o, b_clear_o, a_isolate_o, b_isolate_o;
  wire a_clear_ack_i = a_clear_o;
  wire b_clear_ack_i = b_clear_o;
  wire a_isolate_ack_i = a_isolate_o;
  wire b_isolate_ack_i = b_isolate_o;

  cdc_reset_ctrlr #(.SYNC_STAGES(2)) dut (.*);

  reg active = 0, saw_a_iso = 0, saw_b_iso = 0;
  reg saw_a_clear = 0, saw_b_clear = 0;
  reg [6:0] age = 0;
  always @($global_clock) begin
    assume(!(a_clear_i && b_clear_i));
    if (!a_rst_ni || !b_rst_ni) assume(!a_clear_i && !b_clear_i);
    if (active || a_isolate_o || b_isolate_o)
      assume(!a_clear_i && !b_clear_i);

    assert(!a_clear_o || a_isolate_o);
    assert(!b_clear_o || b_isolate_o);
    if (!a_rst_ni) assert(!a_clear_o && !a_isolate_o);
    if (!b_rst_ni) assert(!b_clear_o && !b_isolate_o);

    if (!active && (a_isolate_o || b_isolate_o)) begin
      active <= 1;
      age <= 0;
      saw_a_iso <= a_isolate_o;
      saw_b_iso <= b_isolate_o;
      saw_a_clear <= a_clear_o;
      saw_b_clear <= b_clear_o;
    end else if (active) begin
      age <= age + 1'b1;
      saw_a_iso <= saw_a_iso || a_isolate_o;
      saw_b_iso <= saw_b_iso || b_isolate_o;
      saw_a_clear <= saw_a_clear || a_clear_o;
      saw_b_clear <= saw_b_clear || b_clear_o;
      assert(age < 70);
      if (saw_a_iso && saw_b_iso && saw_a_clear && saw_b_clear &&
          !a_isolate_o && !b_isolate_o) begin
        active <= 0;
        cover(1);
      end
    end
    cover(a_clear_o && b_clear_o);
  end
endmodule
