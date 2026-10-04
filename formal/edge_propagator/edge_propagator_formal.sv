module edge_propagator_formal;
  (* gclk *) reg gclk;
  reg [5:0] tick = 0;
  always @(posedge gclk) tick <= tick + 1'b1;
  wire clk_tx_i = tick[0];
  wire clk_rx_i = tick[1];
  wire rstn_tx_i = (tick >= 8);
  wire rstn_rx_i = (tick >= 8);
  (* anyseq *) reg edge_i;
  wire edge_o;
  edge_propagator dut (.*);

  always @* begin
    if (tick < 10)
      assume(!edge_i);
  end

  always @(posedge clk_rx_i) begin
    if (!rstn_rx_i)
      assert(!edge_o);
    if (rstn_rx_i && $past(rstn_rx_i) && $past(edge_o))
      assert(!edge_o);
  end

  always @(posedge gclk) begin
    cover(tick > 12 && rstn_tx_i && rstn_rx_i && edge_o);
    cover(tick > 12 && rstn_tx_i && rstn_rx_i && !edge_o);
  end
endmodule
