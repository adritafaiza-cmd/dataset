module sync_multistage_formal;
  reg clk_i;
  (* anyseq *) reg rst_ni;
  (* anyseq *) reg serial_i;
  wire serial_o;
  sync #(.STAGES(4), .ResetValue(1'b0)) dut (.*);

  reg [3:0] expected;
  reg reset_seen;

  initial begin
    expected = 4'b0000;
    reset_seen = 1'b0;
    assume(!rst_ni);
  end

  always @(posedge clk_i) begin
    if (!rst_ni) begin
      expected <= 4'b0000;
      reset_seen <= 1'b1;
    end else if (reset_seen)
      expected <= {expected[2:0], serial_i};

    if (reset_seen && rst_ni)
      assert(serial_o == expected[3]);

    cover(reset_seen && rst_ni && serial_o);
    cover(reset_seen && rst_ni && !serial_o);
  end
endmodule
