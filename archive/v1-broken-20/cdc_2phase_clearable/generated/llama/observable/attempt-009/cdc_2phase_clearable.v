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

  logic src_valid_sync;
  logic src_valid_sync_prev;
  logic src_valid_pulse;
  logic src_clear_sync;
  logic src_clear_sync_prev;
  logic src_clear_pulse;

  logic [WIDTH-1:0] src_data_sync;
  logic [WIDTH-1:0] src_data_sync_prev;

  logic dst_valid_sync;
  logic dst_valid_sync_prev;
  logic dst_valid_pulse;
  logic dst_clear_sync;
  logic dst_clear_sync_prev;
  logic dst_clear_pulse;

  logic [WIDTH-1:0] dst_data_sync;
  logic [WIDTH-1:0] dst_data_sync_prev;

  logic src_valid_reg;
  logic src_valid_reg_prev;
  logic src_valid_pulse_reg;
  logic src_clear_reg;
  logic src_clear_reg_prev;
  logic src_clear_pulse_reg;

  logic [WIDTH-1:0] src_data_reg;
  logic [WIDTH-1:0] src_data_reg_prev;

  logic dst_valid_reg;
  logic dst_valid_reg_prev;
  logic dst_valid_pulse_reg;
  logic dst_clear_reg;
  logic dst_clear_reg_prev;
  logic dst_clear_pulse_reg;

  logic [WIDTH-1:0] dst_data_reg;
  logic [WIDTH-1:0] dst_data_reg_prev;

  logic src_clear_pending_reg;
  logic dst_clear_pending_reg;

  assign src_clear_pending_o = src_clear_pending_reg;
  assign dst_clear_pending_o = dst_clear_pending_reg;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_sync <= 1'b0;
      src_valid_sync_prev <= 1'b0;
      src_valid_pulse <= 1'b0;
      src_clear_sync <= 1'b0;
      src_clear_sync_prev <= 1'b0;
      src_clear_pulse <= 1'b0;
      src_data_sync <= '0;
      src_data_sync_prev <= '0;
      src_valid_reg <= 1'b0;
      src_valid_reg_prev <= 1'b0;
      src_valid_pulse_reg <= 1'b0;
      src_clear_reg <= 1'b0;
      src_clear_reg_prev <= 1'b0;
      src_clear_pulse_reg <= 1'b0;
      src_data_reg <= '0;
      src_data_reg_prev <= '0;
      src_clear_pending_reg <= 1'b0;
    end else begin
      src_valid_sync <= src_valid_i;
      src_valid_sync_prev <= src_valid_sync;
      src_valid_pulse <= src_valid_i && !src_valid_sync_prev;
      src_clear_sync <= src_clear_i;
      src_clear_sync_prev <= src_clear_sync;
      src_clear_pulse <= src_clear_i && !src_clear_sync_prev;
      src_data_sync <= src_data_i;
      src_data_sync_prev <= src_data_sync;
      src_valid_reg <= src_valid_sync;
      src_valid_reg_prev <= src_valid_reg;
      src_valid_pulse_reg <= src_valid_pulse;
      src_clear_reg <= src_clear_sync;
      src_clear_reg_prev <= src_clear_reg;
      src_clear_pulse_reg <= src_clear_pulse;
      src_data_reg <= src_data_sync;
      src_data_reg_prev <= src_data_reg;
      src_clear_pending_reg <= src_clear_pulse_reg;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_sync <= 1'b0;
      dst_valid_sync_prev <= 1'b0;
      dst_valid_pulse <= 1'b0;
      dst_clear_sync <= 1'b0;
      dst_clear_sync_prev <= 1'b0;
      dst_clear_pulse <= 1'b0;
      dst_data_sync <= '0;
      dst_data_sync_prev <= '0;
      dst_valid_reg <= 1'b0;
      dst_valid_reg_prev <= 1'b0;
      dst_valid_pulse_reg <= 1'b0;
      dst_clear_reg <= 1'b0;
      dst_clear_reg_prev <= 1'b0;
      dst_clear_pulse_reg <= 1'b0;
      dst_data_reg <= '0;
      dst_data_reg_prev <= '0;
      dst_clear_pending_reg <= 1'b0;
    end else begin
      dst_valid_sync <= dst_valid_o;
      dst_valid_sync_prev <= dst_valid_sync;
      dst_valid_pulse <= dst_valid_o && !dst_valid_sync_prev;
      dst_clear_sync <= dst_clear_i;
      dst_clear_sync_prev <= dst_clear_sync;
      dst_clear_pulse <= dst_clear_i && !dst_clear_sync_prev;
      dst_data_sync <= dst_data_o;
      dst_data_sync_prev <= dst_data_sync;
      dst_valid_reg <= dst_valid_sync;
      dst_valid_reg_prev <= dst_valid_reg;
      dst_valid_pulse_reg <= dst_valid_pulse;
      dst_clear_reg <= dst_clear_sync;
      dst_clear_reg_prev <= dst_clear_reg;
      dst_clear_pulse_reg <= dst_clear_pulse;
      dst_data_reg <= dst_data_sync;
      dst_data_reg_prev <= dst_data_reg;
      dst_clear_pending_reg <= dst_clear_pulse_reg;
    end
  end

  logic [SYNC_STAGES-1:0] src_valid_sync_chain;
  logic [SYNC_STAGES-1:0] src_clear_sync_chain;

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync_chain <= '0;
      src_clear_sync_chain <= '0;
    end else begin
      src_valid_sync_chain[0] <= src_valid_sync;
      src_clear_sync_chain[0] <= src_clear_sync;
      for (int i = 1; i < SYNC_STAGES; i++) begin
        src_valid_sync_chain[i] <= src_valid_sync_chain[i-1];
        src_clear_sync_chain[i] <= src_clear_sync_chain[i-1];
      end
    end
  end

  logic [SYNC_STAGES-1:0] dst_valid_sync_chain;
  logic [SYNC_STAGES-1:0] dst_clear_sync_chain;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_valid_sync_chain <= '0;
      dst_clear_sync_chain <= '0;
    end else begin
      dst_valid_sync_chain[0] <= dst_valid_sync;
      dst_clear_sync_chain[0] <= dst_clear_sync;
      for (int i = 1; i < SYNC_STAGES; i++) begin
        dst_valid_sync_chain[i] <= dst_valid_sync_chain[i-1];
        dst_clear_sync_chain[i] <= dst_clear_sync_chain[i-1];
      end
    end
  end

  assign src_ready_o = !src_clear_sync && (dst_ready_i || !dst_valid_sync_chain[SYNC_STAGES-1]);
  assign dst_valid_o = !dst_clear_sync && src_valid_sync_chain[SYNC_STAGES-1];
  assign dst_data_o = src_data_sync_chain[SYNC_STAGES-1];

endmodule
