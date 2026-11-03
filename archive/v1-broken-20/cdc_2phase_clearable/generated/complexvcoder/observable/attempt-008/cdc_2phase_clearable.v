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

  // Internal signals
  logic [WIDTH-1:0] src_to_dst_data;
  logic src_to_dst_valid;
  logic src_to_dst_ready;
  logic dst_to_src_valid;
  logic dst_to_src_ready;

  // Sync registers
  sync_register #(.WIDTH(WIDTH), .SYNC_STAGES(SYNC_STAGES)) src_to_dst_sync (
    .data_in(src_data_i),
    .valid_in(src_valid_i),
    .ready_in(src_ready_o),
    .clk(dst_clk_i),
    .rst_n(dst_rst_ni),
    .data_out(src_to_dst_data),
    .valid_out(src_to_dst_valid),
    .ready_out(src_to_dst_ready)
  );

  sync_register #(.WIDTH(WIDTH), .SYNC_STAGES(SYNC_STAGES)) dst_to_src_sync (
    .data_in(dst_data_o),
    .valid_in(dst_valid_o),
    .ready_in(dst_ready_i),
    .clk(src_clk_i),
    .rst_n(src_rst_ni),
    .data_out(dst_data_o),
    .valid_out(dst_to_src_valid),
    .ready_out(dst_to_src_ready)
  );

  // Clear signals
  clear_signal #(.WIDTH(WIDTH)) src_clear_signal (
    .clear_in(src_clear_i | dst_to_src_valid),
    .rst_n(src_rst_ni),
    .clear_out(src_clear_pending_o)
  );

  clear_signal #(.WIDTH(WIDTH)) dst_clear_signal (
    .clear_in(src_clear_i | src_to_dst_valid),
    .rst_n(dst_rst_ni),
    .clear_out(dst_clear_pending_o)
  );

  // Handshaking
  handshaking #(.WIDTH(WIDTH)) src_handshaking (
    .valid_in(src_to_dst_valid),
    .ready_in(src_to_dst_ready),
    .valid_out(src_valid_o),
    .ready_out(src_ready_o)
  );

  handshaking #(.WIDTH(WIDTH)) dst_handshaking (
    .valid_in(dst_to_src_valid),
    .ready_in(dst_to_src_ready),
    .valid_out(dst_valid_o),
    .ready_out(dst_ready_i)
  );

endmodule

module sync_register #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3
)(
  input  [WIDTH-1:0] data_in,
  input  valid_in,
  input  ready_in,
  input  clk,
  input  rst_n,
  output [WIDTH-1:0] data_out,
  output valid_out,
  output ready_out
);

  logic [WIDTH-1:0] sync_reg [0:SYNC_STAGES-1];
  logic [SYNC_STAGES-1:0] sync_valid;
  logic [SYNC_STAGES-1:0] sync_ready;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_reg <= '{default: 0};
      sync_valid <= '{default: 0};
      sync_ready <= '{default: 0};
    end else begin
      sync_reg[0] <= data_in;
      sync_valid[0] <= valid_in;
      sync_ready[0] <= ready_in;

      for (int i = 0; i < SYNC_STAGES-1; i++) begin
        sync_reg[i+1] <= sync_reg[i];
        sync_valid[i+1] <= sync_valid[i];
        sync_ready[i+1] <= sync_ready[i];
      end
    end
  end

  assign data_out = sync_reg[SYNC_STAGES-1];
  assign valid_out = sync_valid[SYNC_STAGES-1];
  assign ready_out = sync_ready[SYNC_STAGES-1];

endmodule

module clear_signal #(
  parameter WIDTH = 1
)(
  input  [WIDTH-1:0] clear_in,
  input  rst_n,
  output [WIDTH-1:0] clear_out
);

  logic clear_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      clear_reg <= 0;
    end else begin
      clear_reg <= clear_in;
    end
  end

  assign clear_out = clear_reg;

endmodule

module handshaking #(
  parameter WIDTH = 1
)(
  input  [WIDTH-1:0] valid_in,
  input  [WIDTH-1:0] ready_in,
  output [WIDTH-1:0] valid_out,
  output [WIDTH-1:0] ready_out
);

  logic valid_reg;
  logic ready_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      valid_reg <= 0;
      ready_reg <= 0;
    end else begin
      valid_reg <= valid_in;
      ready_reg <= ready_in;
    end
  end

  assign valid_out = valid_reg;
  assign ready_out = ready_reg;

endmodule
