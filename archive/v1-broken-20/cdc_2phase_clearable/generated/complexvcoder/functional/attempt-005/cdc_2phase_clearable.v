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
  logic [WIDTH-1:0] sync_src_data [0:SYNC_STAGES-1];
  logic sync_src_valid [0:SYNC_STAGES-1];
  logic sync_src_ready [0:SYNC_STAGES-1];
  logic [WIDTH-1:0] sync_dst_data [0:SYNC_STAGES-1];
  logic sync_dst_valid [0:SYNC_STAGES-1];
  logic sync_dst_ready [0:SYNC_STAGES-1];
  logic src_clear_pending;
  logic dst_clear_pending;
  logic clear_done;

  // Clear logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pending <= 1'b0;
    end else begin
      if (src_clear_i && !src_clear_pending) begin
        src_clear_pending <= 1'b1;
      end else if (src_clear_pending && clear_done) begin
        src_clear_pending <= 1'b0;
      end
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pending <= 1'b0;
    end else begin
      if (dst_clear_i && !dst_clear_pending) begin
        dst_clear_pending <= 1'b1;
      end else if (dst_clear_pending && clear_done) begin
        dst_clear_pending <= 1'b0;
      end
    end
  end

  // Clear done signal generation
  assign clear_done = src_clear_pending && dst_clear_pending;

  // Sync src signals
  sync_ff #(.WIDTH(WIDTH), .STAGES(SYNC_STAGES)) src_sync (
    .clk(src_clk_i),
    .rst_n(src_rst_ni),
    .data_i(src_data_i),
    .valid_i(src_valid_i),
    .ready_o(src_ready_o),
    .data_o(sync_src_data),
    .valid_o(sync_src_valid),
    .ready_i(sync_src_ready)
  );

  // Sync dst signals
  sync_ff #(.WIDTH(WIDTH), .STAGES(SYNC_STAGES)) dst_sync (
    .clk(dst_clk_i),
    .rst_n(dst_rst_ni),
    .data_i(sync_dst_data[SYNC_STAGES-1]),
    .valid_i(sync_dst_valid[SYNC_STAGES-1]),
    .ready_o(sync_dst_ready[SYNC_STAGES-1]),
    .data_o(dst_data_o),
    .valid_o(dst_valid_o),
    .ready_i(dst_ready_i)
  );

  // Forward src signals to dst
  assign sync_dst_data[0] = sync_src_data[SYNC_STAGES-1];
  assign sync_dst_valid[0] = sync_src_valid[SYNC_STAGES-1];
  assign sync_dst_ready[0] = src_clear_pending ? 1'b0 : dst_ready_i;

  // Forward dst signals to src
  assign sync_src_ready[SYNC_STAGES-1] = dst_clear_pending ? 1'b0 : src_ready_o;

  // Clear pending outputs
  assign src_clear_pending_o = src_clear_pending;
  assign dst_clear_pending_o = dst_clear_pending;

endmodule

module sync_ff #(
  parameter WIDTH = 1,
  parameter STAGES = 3
)(
  input  clk,
  input  rst_n,
  input  [WIDTH-1:0] data_i,
  input  valid_i,
  output ready_o,
  output [WIDTH-1:0] data_o,
  output valid_o,
  input  ready_i
);

  logic [WIDTH-1:0] shift_reg [0:STAGES-1];
  logic [STAGES-1:0] valid_reg;
  logic [STAGES-1:0] ready_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      valid_reg <= {STAGES{1'b0}};
      ready_reg <= {STAGES{1'b0}};
      data_reg <= {STAGES{0}};
    end else begin
      valid_reg <= {ready_reg[STAGES-2:0], valid_i};
      ready_reg <= {ready_i, ready_reg[STAGES-1:1]};
      data_reg <= {shift_reg[STAGES-2:0], data_i};
    end
  end

  assign data_o = shift_reg[STAGES-1];
  assign valid_o = valid_reg[STAGES-1];
  assign ready_o = ready_reg[0];

endmodule
