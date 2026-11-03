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

  logic src_valid_synced;
  logic src_valid_synced_ff;
  logic [WIDTH-1:0] src_data_synced;
  logic [WIDTH-1:0] src_data_synced_ff;
  logic src_clear_synced;
  logic src_clear_synced_ff;
  logic dst_valid_synced;
  logic dst_valid_synced_ff;
  logic [WIDTH-1:0] dst_data_synced;
  logic [WIDTH-1:0] dst_data_synced_ff;
  logic dst_clear_synced;
  logic dst_clear_synced_ff;

  logic src_valid_ff;
  logic src_valid_ff2;
  logic [WIDTH-1:0] src_data_ff;
  logic [WIDTH-1:0] src_data_ff2;
  logic src_clear_ff;
  logic src_clear_ff2;

  logic dst_valid_ff;
  logic dst_valid_ff2;
  logic [WIDTH-1:0] dst_data_ff;
  logic [WIDTH-1:0] dst_data_ff2;
  logic dst_clear_ff;
  logic dst_clear_ff2;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_ff <= 1'b0;
      src_data_ff <= '0;
      src_clear_ff <= 1'b0;
    end else begin
      src_valid_ff <= src_valid_i;
      src_data_ff <= src_data_i;
      src_clear_ff <= src_clear_i;
    end
  end

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_ff2 <= 1'b0;
      src_data_ff2 <= '0;
      src_clear_ff2 <= 1'b0;
    end else begin
      src_valid_ff2 <= src_valid_ff;
      src_data_ff2 <= src_data_ff;
      src_clear_ff2 <= src_clear_ff;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_ff <= 1'b0;
      dst_data_ff <= '0;
      dst_clear_ff <= 1'b0;
    end else begin
      dst_valid_ff <= dst_valid_o;
      dst_data_ff <= dst_data_o;
      dst_clear_ff <= dst_clear_i;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_ff2 <= 1'b0;
      dst_data_ff2 <= '0;
      dst_clear_ff2 <= 1'b0;
    end else begin
      dst_valid_ff2 <= dst_valid_ff;
      dst_data_ff2 <= dst_data_ff;
      dst_clear_ff2 <= dst_clear_ff;
    end
  end

  // Source to Destination Sync
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_synced <= 1'b0;
      src_data_synced <= '0;
      src_clear_synced <= 1'b0;
    end else begin
      src_valid_synced <= src_valid_ff2;
      src_data_synced <= src_data_ff2;
      src_clear_synced <= src_clear_ff2;
    end
  end

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_synced_ff <= 1'b0;
      src_data_synced_ff <= '0;
      src_clear_synced_ff <= 1'b0;
    end else begin
      src_valid_synced_ff <= src_valid_synced;
      src_data_synced_ff <= src_data_synced;
      src_clear_synced_ff <= src_clear_synced;
    end
  end

  // Destination to Source Sync
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_synced <= 1'b0;
      dst_data_synced <= '0;
      dst_clear_synced <= 1'b0;
    end else begin
      dst_valid_synced <= dst_valid_ff2;
      dst_data_synced <= dst_data_ff2;
      dst_clear_synced <= dst_clear_ff2;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_synced_ff <= 1'b0;
      dst_data_synced_ff <= '0;
      dst_clear_synced_ff <= 1'b0;
    end else begin
      dst_valid_synced_ff <= dst_valid_synced;
      dst_data_synced_ff <= dst_data_synced;
      dst_clear_synced_ff <= dst_clear_synced;
    end
  end

  // Source Side
  logic src_valid_pulse;
  logic src_valid_pulse_ff;
  logic src_clear_pulse;
  logic src_clear_pulse_ff;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_pulse <= 1'b0;
      src_clear_pulse <= 1'b0;
    end else begin
      src_valid_pulse <= src_valid_i && !src_valid_ff;
      src_clear_pulse <= src_clear_i && !src_clear_ff;
    end
  end

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_pulse_ff <= 1'b0;
      src_clear_pulse_ff <= 1'b0;
    end else begin
      src_valid_pulse_ff <= src_valid_pulse;
      src_clear_pulse_ff <= src_clear_pulse;
    end
  end

  assign src_ready_o = (src_clear_i || src_clear_synced_ff) ? 1'b0 : (src_valid_synced_ff && dst_valid_synced_ff) ? 1'b0 : 1'b1;
  assign src_clear_pending_o = src_clear_i || src_clear_synced_ff;

  // Destination Side
  logic dst_valid_pulse;
  logic dst_valid_pulse_ff;
  logic dst_clear_pulse;
  logic dst_clear_pulse_ff;

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_pulse <= 1'b0;
      dst_clear_pulse <= 1'b0;
    end else begin
      dst_valid_pulse <= dst_valid_o && !dst_valid_ff;
      dst_clear_pulse <= dst_clear_i && !dst_clear_ff;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_pulse_ff <= 1'b0;
      dst_clear_pulse_ff <= 1'b0;
    end else begin
      dst_valid_pulse_ff <= dst_valid_pulse;
      dst_clear_pulse_ff <= dst_clear_pulse;
    end
  end

  assign dst_valid_o = (dst_clear_i || dst_clear_synced_ff) ? 1'b0 : (dst_valid_synced_ff && src_valid_synced_ff) ? 1'b1 : 1'b0;
  assign dst_clear_pending_o = dst_clear_i || dst_clear_synced_ff;

  // CDC
  logic [SYNC_STAGES-1:0] src_valid_cdc;
  logic [SYNC_STAGES-1:0] src_data_cdc;
  logic [SYNC_STAGES-1:0] src_clear_cdc;

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_cdc <= '0;
      src_data_cdc <= '0;
      src_clear_cdc <= '0;
    end else begin
      src_valid_cdc[0] <= src_valid_synced;
      src_data_cdc[0] <= src_data_synced;
      src_clear_cdc[0] <= src_clear_synced;
      for (int i = 1; i < SYNC_STAGES; i++) begin
        src_valid_cdc[i] <= src_valid_cdc[i-1];
        src_data_cdc[i] <= src_data_cdc[i-1];
        src_clear_cdc[i] <= src_clear_cdc[i-1];
      end
    end
  end

  assign dst_data_o = src_data_cdc[SYNC_STAGES-1];
  assign dst_valid_synced_ff = src_valid_cdc[SYNC_STAGES-1];
  assign dst_clear_synced_ff = src_clear_cdc[SYNC_STAGES-1];

  logic [SYNC_STAGES-1:0] dst_valid_cdc;
  logic [SYNC_STAGES-1:0] dst_data_cdc;
  logic [SYNC_STAGES-1:0] dst_clear_cdc;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_valid_cdc <= '0;
      dst_data_cdc <= '0;
      dst_clear_cdc <= '0;
    end else begin
      dst_valid_cdc[0] <= dst_valid_ff;
      dst_data_cdc[0] <= dst_data_ff;
      dst_clear_cdc[0] <= dst_clear_ff;
      for (int i = 1; i < SYNC_STAGES; i++) begin
        dst_valid_cdc[i] <= dst_valid_cdc[i-1];
        dst_data_cdc[i] <= dst_data_cdc[i-1];
        dst_clear_cdc[i] <= dst_clear_cdc[i-1];
      end
    end
  end

  assign src_valid_synced_ff = dst_valid_cdc[SYNC_STAGES-1];
  assign src_data_synced_ff = dst_data_cdc[SYNC_STAGES-1];
  assign src_clear_synced_ff = dst_clear_cdc[SYNC_STAGES-1];

endmodule
