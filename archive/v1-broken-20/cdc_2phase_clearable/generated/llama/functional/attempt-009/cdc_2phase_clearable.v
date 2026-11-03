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
  logic src_clear_pulse;
  logic src_clear_pulse_r;
  logic dst_valid_pulse;
  logic dst_valid_pulse_r;
  logic dst_clear_pulse;
  logic dst_clear_pulse_r;

  logic src_clear_pending;
  logic dst_clear_pending;

  logic src_valid_out;
  logic src_valid_out_r;
  logic [WIDTH-1:0] src_data_out;
  logic [WIDTH-1:0] src_data_out_r;
  logic dst_valid_out;
  logic dst_valid_out_r;
  logic [WIDTH-1:0] dst_data_out;
  logic [WIDTH-1:0] dst_data_out_r;

  // Source domain
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_sync <= 1'b0;
      src_data_sync <= '0;
      src_clear_sync <= 1'b0;
      src_valid_pulse <= 1'b0;
      src_clear_pulse <= 1'b0;
      src_clear_pending <= 1'b0;
      src_valid_out <= 1'b0;
      src_data_out <= '0;
    end else if (src_clear_i) begin
      src_valid_sync <= 1'b0;
      src_data_sync <= '0;
      src_clear_sync <= 1'b1;
      src_valid_pulse <= 1'b0;
      src_clear_pulse <= 1'b1;
      src_clear_pending <= 1'b1;
      src_valid_out <= 1'b0;
      src_data_out <= '0;
    end else if (src_valid_i && src_ready_o) begin
      src_valid_sync <= 1'b1;
      src_data_sync <= src_data_i;
      src_clear_sync <= 1'b0;
      src_valid_pulse <= 1'b1;
      src_clear_pulse <= 1'b0;
      src_clear_pending <= 1'b0;
      src_valid_out <= 1'b1;
      src_data_out <= src_data_i;
    end else begin
      src_valid_sync <= src_valid_sync_r;
      src_data_sync <= src_data_sync_r;
      src_clear_sync <= src_clear_sync_r;
      src_valid_pulse <= src_valid_pulse_r;
      src_clear_pulse <= src_clear_pulse_r;
      src_clear_pending <= src_clear_pending_r;
      src_valid_out <= src_valid_out_r;
      src_data_out <= src_data_out_r;
    end
  end

  assign src_ready_o =!src_valid_sync || src_clear_sync;

  // Synchronization
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync_r <= 1'b0;
      src_data_sync_r <= '0;
      src_clear_sync_r <= 1'b0;
      src_valid_pulse_r <= 1'b0;
      src_clear_pulse_r <= 1'b0;
      src_clear_pending_r <= 1'b0;
      src_valid_out_r <= 1'b0;
      src_data_out_r <= '0;
    end else begin
      src_valid_sync_r <= src_valid_sync;
      src_data_sync_r <= src_data_sync;
      src_clear_sync_r <= src_clear_sync;
      src_valid_pulse_r <= src_valid_pulse;
      src_clear_pulse_r <= src_clear_pulse;
      src_clear_pending_r <= src_clear_pending;
      src_valid_out_r <= src_valid_out;
      src_data_out_r <= src_data_out;
    end
  end

  // Destination domain
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_sync <= 1'b0;
      dst_data_sync <= '0;
      dst_clear_sync <= 1'b0;
      dst_valid_pulse <= 1'b0;
      dst_clear_pulse <= 1'b0;
      dst_clear_pending <= 1'b0;
      dst_valid_out <= 1'b0;
      dst_data_out <= '0;
    end else if (dst_clear_i) begin
      dst_valid_sync <= 1'b0;
      dst_data_sync <= '0;
      dst_clear_sync <= 1'b1;
      dst_valid_pulse <= 1'b0;
      dst_clear_pulse <= 1'b1;
      dst_clear_pending <= 1'b1;
      dst_valid_out <= 1'b0;
      dst_data_out <= '0;
    end else if (src_valid_sync_r && dst_ready_i) begin
      dst_valid_sync <= 1'b1;
      dst_data_sync <= src_data_sync_r;
      dst_clear_sync <= 1'b0;
      dst_valid_pulse <= 1'b1;
      dst_clear_pulse <= 1'b0;
      dst_clear_pending <= 1'b0;
      dst_valid_out <= 1'b1;
      dst_data_out <= src_data_sync_r;
    end else begin
      dst_valid_sync <= dst_valid_sync_r;
      dst_data_sync <= dst_data_sync_r;
      dst_clear_sync <= dst_clear_sync_r;
      dst_valid_pulse <= dst_valid_pulse_r;
      dst_clear_pulse <= dst_clear_pulse_r;
      dst_clear_pending <= dst_clear_pending_r;
      dst_valid_out <= dst_valid_out_r;
      dst_data_out <= dst_data_out_r;
    end
  end

  assign dst_valid_o = dst_valid_sync &&!dst_clear_sync;

  // Synchronization
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_valid_sync_r <= 1'b0;
      dst_data_sync_r <= '0;
      dst_clear_sync_r <= 1'b0;
      dst_valid_pulse_r <= 1'b0;
      dst_clear_pulse_r <= 1'b0;
      dst_clear_pending_r <= 1'b0;
      dst_valid_out_r <= 1'b0;
      dst_data_out_r <= '0;
    end else begin
      dst_valid_sync_r <= dst_valid_sync;
      dst_data_sync_r <= dst_data_sync;
      dst_clear_sync_r <= dst_clear_sync;
      dst_valid_pulse_r <= dst_valid_pulse;
      dst_clear_pulse_r <= dst_clear_pulse;
      dst_clear_pending_r <= dst_clear_pending;
      dst_valid_out_r <= dst_valid_out;
      dst_data_out_r <= dst_data_out;
    end
  end

  assign src_clear_pending_o = src_clear_pending;
  assign dst_clear_pending_o = dst_clear_pending;
  assign dst_data_o = dst_data_sync;

  // Clear logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pending <= 1'b0;
    end else if (src_clear_i) begin
      src_clear_pending <= 1'b1;
    end else if (src_clear_sync_r && src_valid_pulse_r) begin
      src_clear_pending <= 1'b0;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pending <= 1'b0;
    end else if (dst_clear_i) begin
      dst_clear_pending <= 1'b1;
    end else if (dst_clear_sync_r && dst_valid_pulse_r) begin
      dst_clear_pending <= 1'b0;
    end
  end

  // Reset logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_sync <= 1'b0;
      src_data_sync <= '0;
      src_clear_sync <= 1'b0;
      src_valid_pulse <= 1'b0;
      src_clear_pulse <= 1'b0;
      src_clear_pending <= 1'b0;
      src_valid_out <= 1'b0;
      src_data_out <= '0;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_sync <= 1'b0;
      dst_data_sync <= '0;
      dst_clear_sync <= 1'b0;
      dst_valid_pulse <= 1'b0;
      dst_clear_pulse <= 1'b0;
      dst_clear_pending <= 1'b0;
      dst_valid_out <= 1'b0;
      dst_data_out <= '0;
    end
  end

endmodule
