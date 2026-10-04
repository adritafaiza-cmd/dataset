module sync_wedge_formal;
  reg clk_i;
  (* anyseq *) reg rst_ni;
  (* anyseq *) reg en_i;
  (* anyseq *) reg serial_i;
  wire r_edge_o, f_edge_o, serial_o;
  sync_wedge #(.STAGES(2)) dut (.*);

  reg [1:0] pipe;
  reg model_q;
  reg reset_seen;

  initial begin
    pipe = 2'b00;
    model_q = 1'b0;
    reset_seen = 1'b0;
    assume(!rst_ni);
  end

  always @(posedge clk_i) begin
    if (!rst_ni) begin
      pipe <= 2'b00;
      model_q <= 1'b0;
      reset_seen <= 1'b1;
    end else begin
      pipe <= {pipe[0], serial_i};
      if (en_i)
        model_q <= pipe[1];
    end

    if (reset_seen && rst_ni) begin
      assert(serial_o == model_q);
      assert(r_edge_o == (pipe[1] && !model_q));
      assert(f_edge_o == (!pipe[1] && model_q));
      assert(!(r_edge_o && f_edge_o));
    end

    cover(reset_seen && rst_ni && r_edge_o);
    cover(reset_seen && rst_ni && f_edge_o);
  end
endmodule
