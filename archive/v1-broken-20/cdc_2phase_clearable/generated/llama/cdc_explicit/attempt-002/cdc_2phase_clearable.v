module cdc_2phase_clearable #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3,
  parameter CLEAR_ON_ASYNC_RESET = 1
)(
  input  logic src_rst_ni,
  input  logic src_clk_i,
  input  logic src_clear_i,
  output logic src_clear_pending_o,
  input  logic [WIDTH-1:0] src_data_i,
  input  logic src_valid_i,
  output logic src_ready_o,
  input  logic dst_rst_ni,
  input  logic dst_clk_i,
  input  logic dst_clear_i,
  output logic dst_clear_pending_o,
  output logic [WIDTH-1:0] dst_data_o,
  output logic dst_valid_o,
  input  logic dst_ready_i
);

  logic src_valid_sync;
  logic src_valid_sync_r;
  logic [WIDTH-1:0] src_data_sync;
  logic [WIDTH-1:0] src_data_sync_r;
  logic src_clear_sync;
  logic src_clear_sync_r;
  logic dst_valid_sync;
  logic dst_valid_sync_r;
  logic [WIDTH-1:0] dst_data_sync;
  logic [WIDTH-1:0] dst_data_sync_r;
  logic dst_clear_sync;
  logic dst_clear_sync_r;

  logic src_valid_pulse;
  logic src_valid_pulse_r;
  logic dst_valid_pulse;
  logic dst_valid_pulse_r;

  logic src_clear_pulse;
  logic src_clear_pulse_r;
  logic dst_clear_pulse;
  logic dst_clear_pulse_r;

  logic src_valid_out;
  logic src_valid_out_r;
  logic [WIDTH-1:0] src_data_out;
  logic [WIDTH-1:0] src_data_out_r;
  logic dst_valid_out;
  logic dst_valid_out_r;
  logic [WIDTH-1:0] dst_data_out;
  logic [WIDTH-1:0] dst_data_out_r;

  logic src_ready_out;
  logic src_ready_out_r;
  logic dst_ready_out;
  logic dst_ready_out_r;

  logic src_clear_pending;
  logic dst_clear_pending;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_sync <= 1'b0;
      src_data_sync <= '0;
      src_clear_sync <= 1'b0;
      src_valid_pulse <= 1'b0;
      src_clear_pulse <= 1'b0;
      src_valid_out <= 1'b0;
      src_data_out <= '0;
      src_ready_out <= 1'b0;
      src_clear_pending <= 1'b0;
    end else begin
      src_valid_sync <= src_valid_i;
      src_data_sync <= src_data_i;
      src_clear_sync <= src_clear_i;
      src_valid_pulse <= src_valid_i &&!src_valid_sync_r;
      src_clear_pulse <= src_clear_i &&!src_clear_sync_r;
      if (src_clear_i) begin
        src_valid_out <= 1'b0;
        src_data_out <= '0;
        src_ready_out <= 1'b0;
      end else if (src_valid_i && src_ready_out_r) begin
        src_valid_out <= 1'b1;
        src_data_out <= src_data_i;
      end
      src_clear_pending <= src_clear_i || src_clear_pending_r;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_sync <= 1'b0;
      dst_data_sync <= '0;
      dst_clear_sync <= 1'b0;
      dst_valid_pulse <= 1'b0;
      dst_clear_pulse <= 1'b0;
      dst_valid_out <= 1'b0;
      dst_data_out <= '0;
      dst_ready_out <= 1'b0;
      dst_clear_pending <= 1'b0;
    end else begin
      dst_valid_sync <= dst_valid_o;
      dst_data_sync <= dst_data_o;
      dst_clear_sync <= dst_clear_i;
      dst_valid_pulse <= dst_valid_o &&!dst_valid_sync_r;
      dst_clear_pulse <= dst_clear_i &&!dst_clear_sync_r;
      if (dst_clear_i) begin
        dst_valid_out <= 1'b0;
        dst_data_out <= '0;
        dst_ready_out <= 1'b0;
      end else if (dst_valid_o && dst_ready_out_r) begin
        dst_valid_out <= 1'b1;
        dst_data_out <= dst_data_o;
      end
      dst_clear_pending <= dst_clear_i || dst_clear_pending_r;
    end
  end

  always_ff @(posedge src_clk_i) begin
    src_valid_sync_r <= src_valid_sync;
    src_data_sync_r <= src_data_sync;
    src_clear_sync_r <= src_clear_sync;
    src_valid_pulse_r <= src_valid_pulse;
    src_clear_pulse_r <= src_clear_pulse;
    src_valid_out_r <= src_valid_out;
    src_data_out_r <= src_data_out;
    src_ready_out_r <= src_ready_out;
    src_clear_pending_r <= src_clear_pending;
  end

  always_ff @(posedge dst_clk_i) begin
    dst_valid_sync_r <= dst_valid_sync;
    dst_data_sync_r <= dst_data_sync;
    dst_clear_sync_r <= dst_clear_sync;
    dst_valid_pulse_r <= dst_valid_pulse;
    dst_clear_pulse_r <= dst_clear_pulse;
    dst_valid_out_r <= dst_valid_out;
    dst_data_out_r <= dst_data_out;
    dst_ready_out_r <= dst_ready_out;
    dst_clear_pending_r <= dst_clear_pending;
  end

  // CDC
  logic [SYNC_STAGES-1:0] src_valid_cdc;
  logic [SYNC_STAGES-1:0] src_data_cdc;
  logic [SYNC_STAGES-1:0] src_clear_cdc;
  logic [SYNC_STAGES-1:0] dst_valid_cdc;
  logic [SYNC_STAGES-1:0] dst_data_cdc;
  logic [SYNC_STAGES-1:0] dst_clear_cdc;

  always_ff @(posedge src_clk_i) begin
    src_valid_cdc[0] <= src_valid_out;
    src_data_cdc[0] <= src_data_out;
    src_clear_cdc[0] <= src_clear_pending;
    for (int i = 1; i < SYNC_STAGES; i++) begin
      src_valid_cdc[i] <= src_valid_cdc[i-1];
      src_data_cdc[i] <= src_data_cdc[i-1];
      src_clear_cdc[i] <= src_clear_cdc[i-1];
    end
  end

  always_ff @(posedge dst_clk_i) begin
    dst_valid_cdc[0] <= dst_valid_out;
    dst_data_cdc[0] <= dst_data_out;
    dst_clear_cdc[0] <= dst_clear_pending;
    for (int i = 1; i < SYNC_STAGES; i++) begin
      dst_valid_cdc[i] <= dst_valid_cdc[i-1];
      dst_data_cdc[i] <= dst_data_cdc[i-1];
      dst_clear_cdc[i] <= dst_clear_cdc[i-1];
    end
  end

  assign src_ready_o = src_ready_out;
  assign dst_data_o = dst_data_cdc[SYNC_STAGES-1];
  assign dst_valid_o = dst_valid_cdc[SYNC_STAGES-1];
  assign src_clear_pending_o = src_clear_cdc[SYNC_STAGES-1];
  assign dst_clear_pending_o = dst_clear_cdc[SYNC_STAGES-1];

endmodule
