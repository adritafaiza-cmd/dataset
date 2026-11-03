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

  // Syncer for source domain
  logic src_valid_sync_o;
  logic src_ready_sync_o;
  logic [WIDTH-1:0] src_data_sync_o;
  logic src_clear_pending_o;

  sync #(
    .WIDTH(WIDTH),
    .SYNC_STAGES(SYNC_STAGES)
  ) src_sync (
    .rst_n(src_rst_ni),
    .clk(src_clk_i),
    .clear(src_clear_i),
    .valid_in(src_valid_i),
    .data_in(src_data_i),
    .valid_out(src_valid_sync_o),
    .ready_out(src_ready_sync_o),
    .data_out(src_data_sync_o),
    .clear_pending_o(src_clear_pending_o)
  );

  // Syncer for destination domain
  logic dst_valid_sync_o;
  logic dst_ready_sync_o;
  logic [WIDTH-1:0] dst_data_sync_o;
  logic dst_clear_pending_o;

  sync #(
    .WIDTH(WIDTH),
    .SYNC_STAGES(SYNC_STAGES)
  ) dst_sync (
    .rst_n(dst_rst_ni),
    .clk(dst_clk_i),
    .clear(dst_clear_i),
    .valid_in(dst_valid_i),
    .data_in(dst_data_i),
    .valid_out(dst_valid_sync_o),
    .ready_out(dst_ready_sync_o),
    .data_out(dst_data_sync_o),
    .clear_pending_o(dst_clear_pending_o)
  );

  // Handshake logic for source side
  logic src_buffer_ready;

  handshake src_handshake (
    .valid_in(src_valid_sync_o),
    .ready_out(src_ready_sync_o),
    .clear_pending_o(src_clear_pending_o),
    .ready(src_buffer_ready)
  );

  // Handshake logic for destination side
  logic dst_buffer_ready;

  handshake dst_handshake (
    .valid_in(dst_valid_sync_o),
    .ready_out(dst_ready_sync_o),
    .clear_pending_o(dst_clear_pending_o),
    .ready(dst_buffer_ready)
  );

  // Buffer to hold data between clocks
  logic [WIDTH-1:0] buffer_data;
  logic buffer_valid;
  logic buffer_ready;

  buffer #(
    .WIDTH(WIDTH)
  ) buffer (
    .data_in(src_data_sync_o),
    .valid_in(src_valid_sync_o),
    .ready(src_buffer_ready),
    .data_out(dst_data_sync_o),
    .valid_out(dst_valid_sync_o),
    .ready_in(dst_buffer_ready),
    .clear(src_clear_i || dst_clear_i),
    .full(src_ready_sync_o),
    .empty(dst_valid_sync_o)
  );

  // Assign outputs
  assign src_ready_o = src_buffer_ready;
  assign dst_data_o = dst_data_sync_o;
  assign dst_valid_o = dst_valid_sync_o;
  assign dst_clear_pending_o = dst_clear_pending_o;

endmodule

module sync #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3
)(
  input  rst_n,
  input  clk,
  input  clear,
  input  valid_in,
  input  [WIDTH-1:0] data_in,
  output valid_out,
  output ready_out,
  output [WIDTH-1:0] data_out,
  output clear_pending_o
);

  logic [WIDTH-1:0] shift_reg [0:SYNC_STAGES-1];
  logic valid_reg [0:SYNC_STAGES-1];
  logic ready_reg [0:SYNC_STAGES-1];
  logic clear_pending;

  assign data_out = shift_reg[0];
  assign valid_out = valid_reg[0];
  assign ready_out = ready_reg[0];
  assign clear_pending_o = clear_pending;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      shift_reg <= '{default: 0};
      valid_reg <= '{default: 0};
      ready_reg <= '{default: 0};
      clear_pending <= 0;
    end else begin
      if (clear) begin
        shift_reg <= '{default: 0};
        valid_reg <= '{default: 0};
        ready_reg <= '{default: 0};
        clear_pending <= 0;
      end else begin
        shift_reg <= {shift_reg[SYNC_STAGES-2:0], data_in};
        valid_reg <= {valid_reg[SYNC_STAGES-2:0], valid_in};
        ready_reg <= {ready_reg[SYNC_STAGES-2:0], ready_reg[SYNC_STAGES-1]};
        clear_pending <= valid_reg[SYNC_STAGES-1] && ready_reg[SYNC_STAGES-1];
      end
    end
  end

endmodule

module handshake (
  input  valid_in,
  input  ready_out,
  output clear_pending_o,
  output ready
);

  logic valid_reg;
  logic ready_reg;
  logic clear_pending;

  assign clear_pending_o = clear_pending;
  assign ready = ready_reg;

  always_ff @(posedge valid_in or negedge ready_out) begin
    if (!ready_out) begin
      valid_reg <= 0;
      ready_reg <= 0;
      clear_pending <= 0;
    end else begin
      valid_reg <= valid_in;
      ready_reg <= ready_out;
      clear_pending <= 0;
    end
  end

endmodule

module buffer #(
  parameter WIDTH = 1
)(
  input  [WIDTH-1:0] data_in,
  input  valid_in,
  input  ready,
  output [WIDTH-1:0] data_out,
  output valid_out,
  input  ready_in,
  input  clear,
  output full,
  output empty
);

  logic [WIDTH-1:0] buffer_reg;
  logic valid_reg;
  logic full_reg;
  logic empty_reg;

  assign data_out = buffer_reg;
  assign valid_out = valid_reg;
  assign full = full_reg;
  assign empty = empty_reg;

  always_ff @(posedge ready or negedge clear) begin
    if (!clear) begin
      buffer_reg <= data_in;
      valid_reg <= valid_in;
      full_reg <= valid_in && !ready;
      empty_reg <= !valid_in;
    end else begin
      buffer_reg <= 0;
      valid_reg <= 0;
      full_reg <= 0;
      empty_reg <= 1;
    end
  end

endmodule
