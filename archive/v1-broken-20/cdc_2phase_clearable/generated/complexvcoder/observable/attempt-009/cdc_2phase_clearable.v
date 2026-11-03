module sync_register #(
  parameter WIDTH = 1,
  parameter STAGES = 3
)(
  input  clk,
  input  rst_ni,
  input  [WIDTH-1:0] data_in,
  input  valid_in,
  output ready_in,
  input  ready_out,
  output [WIDTH-1:0] data_out,
  output valid_out
);

  localparam DEPTH = 2**STAGES;

  logic [WIDTH-1:0] mem [0:DEPTH-1];
  logic [STAGES-1:0] valid_reg;
  logic [STAGES-1:0] ready_reg;

  always_ff @(posedge clk or negedge rst_ni) begin
    if (!rst_ni) begin
      valid_reg <= {STAGES{1'b0}};
      ready_reg <= {STAGES{1'b0}};
      mem <= '{default: {WIDTH{1'b0}}};
    end else begin
      valid_reg <= {ready_out, valid_reg[STAGES-2:0]};
      ready_reg <= {valid_in, ready_reg[STAGES-2:0]};
      if (ready_out && valid_in) begin
        mem[0] <= data_in;
      end else if (ready_reg[0] && valid_reg[0]) begin
        mem <= {mem[1:DEPTH-1], mem[0]};
      end
    end
  end

  assign data_out = mem[0];
  assign valid_out = valid_reg[0];
  assign ready_in = ready_reg[STAGES-1];

endmodule

module clear_logic (
  input  clk,
  input  rst_ni,
  input  clear_i,
  output clear_pending_o
);

  logic clear_reg;
  logic clear_pending_reg;

  always_ff @(posedge clk or negedge rst_ni) begin
    if (!rst_ni) begin
      clear_reg <= 1'b0;
      clear_pending_reg <= 1'b0;
    end else begin
      clear_reg <= clear_i;
      clear_pending_reg <= clear_reg;
    end
  end

  assign clear_pending_o = clear_pending_reg;

endmodule

module cdc_2phase_clearable #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3,
  parameter CLEAR_ON_ASYNC_RESET = 1
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  src_clear_i,
  output src_clear_pending_o,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,
  input  dst_rst_ni,
  input  dst_clk_i,
  input  dst_clear_i,
  output dst_clear_pending_o,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);

  sync_register #(
    .WIDTH(WIDTH),
    .STAGES(SYNC_STAGES)
  ) src_sync_reg (
    .clk(src_clk_i),
    .rst_ni(src_rst_ni),
    .data_in(src_data_i),
    .valid_in(src_valid_i),
    .ready_in(src_ready_o),
    .ready_out(dst_ready_i),
    .data_out(),
    .valid_out()
  );

  sync_register #(
    .WIDTH(WIDTH),
    .STAGES(SYNC_STAGES)
  ) dst_sync_reg (
    .clk(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .data_in(dst_data_o),
    .valid_in(dst_valid_o),
    .ready_in(dst_ready_i),
    .ready_out(src_ready_o),
    .data_out(),
    .valid_out()
  );

  clear_logic src_clear_logic (
    .clk(src_clk_i),
    .rst_ni(src_rst_ni),
    .clear_i(src_clear_i),
    .clear_pending_o(src_clear_pending_o)
  );

  clear_logic dst_clear_logic (
    .clk(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .clear_i(dst_clear_i),
    .clear_pending_o(dst_clear_pending_o)
  );

endmodule
