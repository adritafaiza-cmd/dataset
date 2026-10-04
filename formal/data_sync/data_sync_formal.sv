module data_sync_formal;
  localparam STAGES = 2;
  localparam DWIDTH = 8;
  reg clk = 0;
  always @($global_clock) clk <= !clk;
  (* anyseq *) reg rstn;
  (* anyseq *) reg [DWIDTH-1:0] din;
  (* anyseq *) reg dready_i;
  wire [DWIDTH-1:0] dout;
  wire dready_o;
  data_sync #(.STAGES(STAGES), .DWIDTH(DWIDTH)) dut (.*);

  reg [STAGES-1:0] ready_pipe = 0;
  reg [DWIDTH-1:0] held_data = 0;
  reg model_ready = 0;
  reg past_valid = 0;
  initial assume(!rstn);

  always @(posedge clk) begin
    past_valid <= 1;
    if (!rstn) begin
      ready_pipe <= 0;
      held_data <= 0;
      model_ready <= 0;
    end else begin
      ready_pipe <= {ready_pipe[0], dready_i};
      if (ready_pipe[1]) held_data <= din;
      model_ready <= ready_pipe[1];
    end
    if (past_valid) begin
      assert(dready_o == model_ready);
      assert(dout == held_data);
      if (dready_o) assert(dout == held_data);
    end
    cover(past_valid && rstn && dready_o && dout != 0);
    cover(past_valid && rstn && !dready_o);
  end
endmodule
