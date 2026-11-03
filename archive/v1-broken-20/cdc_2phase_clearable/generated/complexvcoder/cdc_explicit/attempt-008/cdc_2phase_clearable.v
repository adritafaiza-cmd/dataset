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
  logic [WIDTH-1:0] src_sync_data;
  logic src_sync_valid;
  logic src_sync_ready;
  logic [WIDTH-1:0] dst_sync_data;
  logic dst_sync_valid;
  logic dst_sync_ready;
  logic handshake_src_valid;
  logic handshake_src_ready;
  logic handshake_dst_valid;
  logic handshake_dst_ready;
  logic handshake_src_clear_pending;
  logic handshake_dst_clear_pending;

  // Synchronization modules
  sync_module #(.WIDTH(WIDTH), .SYNC_STAGES(SYNC_STAGES)) src_sync (
    .clk(src_clk_i),
    .rst_ni(src_rst_ni),
    .data_i(src_data_i),
    .valid_i(src_valid_i),
    .ready_o(src_ready_o)
  );

  sync_module #(.WIDTH(WIDTH), .SYNC_STAGES(SYNC_STAGES)) dst_sync (
    .clk(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .data_o(dst_data_o),
    .valid_o(dst_valid_o),
    .ready_i(dst_ready_i)
  );

  // Clear modules
  clear_module src_clear (
    .clear_i(src_clear_i),
    .clear_pending_o(src_clear_pending_o)
  );

  clear_module dst_clear (
    .clear_i(dst_clear_i),
    .clear_pending_o(dst_clear_pending_o)
  );

  // Handshake module
  handshake_module handshake (
    .src_valid_i(src_sync_valid),
    .src_ready_o(src_sync_ready),
    .dst_valid_o(dst_sync_valid),
    .dst_ready_i(dst_sync_ready),
    .src_clear_pending_o(handshake_src_clear_pending),
    .dst_clear_pending_o(handshake_dst_clear_pending)
  );

endmodule

module sync_module #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3
)(
  input  clk,
  input  rst_ni,
  input  [WIDTH-1:0] data_i,
  input  valid_i,
  output data_o,
  output valid_o,
  output ready_o
);

  logic [WIDTH-1:0] shift_reg [SYNC_STAGES-1:0];
  logic [SYNC_STAGES-1:0] valid_reg;
  logic [SYNC_STAGES-1:0] ready_reg;

  always_ff @(posedge clk or negedge rst_ni) begin
    if (!rst_ni) begin
      shift_reg <= '{default: 0};
      valid_reg <= '{default: 0};
      ready_reg <= '{default: 0};
    end else begin
      if (valid_i && ready_reg[0]) begin
        shift_reg[0] <= data_i;
        valid_reg[0] <= 1;
      end

      for (int i = 0; i < SYNC_STAGES-1; i++) begin
        shift_reg[i+1] <= shift_reg[i];
        valid_reg[i+1] <= valid_reg[i];
      end

      ready_reg[SYNC_STAGES-1] <= valid_reg[SYNC_STAGES-2];
      valid_o <= valid_reg[SYNC_STAGES-1];
      data_o <= shift_reg[SYNC_STAGES-1];
    end
  end

  assign ready_o = ready_reg[SYNC_STAGES-1];

endmodule

module clear_module (
  input  clear_i,
  output clear_pending_o
);

  logic clear_pending;

  always_ff @(posedge clear_i or posedge clear_pending) begin
    if (clear_i)
      clear_pending <= 1;
    else if (clear_pending)
      clear_pending <= 0;
  end

  assign clear_pending_o = clear_pending;

endmodule

module handshake_module (
  input  src_valid_i,
  input  src_ready_o,
  input  dst_valid_o,
  input  dst_ready_i,
  output src_clear_pending_o,
  output dst_clear_pending_o
);

  logic src_clear_pending;
  logic dst_clear_pending;

  always_ff @(posedge src_valid_i or posedge src_clear_pending) begin
    if (src_valid_i)
      src_clear_pending <= 1;
    else if (src_clear_pending)
      src_clear_pending <= 0;
  end

  always_ff @(posedge dst_valid_o or posedge dst_clear_pending) begin
    if (dst_valid_o)
      dst_clear_pending <= 1;
    else if (dst_clear_pending)
      dst_clear_pending <= 0;
  end

  assign src_clear_pending_o = src_clear_pending;
  assign dst_clear_pending_o = dst_clear_pending;

endmodule
