module areset_sync_formal;
  localparam STAGES = 2;
  reg clk = 0;
  always @($global_clock) clk <= !clk;
  (* anyseq *) reg async_rst_i;
  wire sync_rst_o;
  areset_sync #(.STAGES(STAGES)) dut (.*);

  reg [STAGES-1:0] model;
  reg [2:0] age = 0;
  initial begin
    model = 0;
    assume(!async_rst_i);
  end
  always @(posedge clk) begin
    model <= {model[0], async_rst_i};
    if (age < STAGES+1) age <= age + 1;
    if (age >= STAGES) assert(sync_rst_o == model[1]);
    cover(age >= STAGES && sync_rst_o);
    cover(age >= STAGES && !sync_rst_o);
  end
endmodule
