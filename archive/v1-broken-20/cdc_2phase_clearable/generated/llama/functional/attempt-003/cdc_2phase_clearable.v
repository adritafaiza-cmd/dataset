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
  logic src_ready_sync;
  logic [WIDTH-1:0] src_data_sync;
  logic dst_valid_sync;
  logic dst_ready_sync;
  logic [WIDTH-1:0] dst_data_sync;

  logic src_clear_sync;
  logic dst_clear_sync;

  logic src_clear_pending_sync;
  logic dst_clear_pending_sync;

  logic src_valid_reg;
  logic src_ready_reg;
  logic [WIDTH-1:0] src_data_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic [WIDTH-1:0] dst_data_reg;

  logic src_valid_pulse;
  logic dst_valid_pulse;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_sync <= 1'b0;
      src_ready_sync <= 1'b0;
      src_data_sync <= '0;
      src_clear_sync <= 1'b0;
      src_clear_pending_sync <= 1'b0;
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b0;
      src_data_reg <= '0;
    end else begin
      src_valid_sync <= src_valid_i;
      src_ready_sync <= src_ready_o;
      src_data_sync <= src_data_i;
      src_clear_sync <= src_clear_i;
      src_clear_pending_sync <= src_clear_pending_o;
      if (src_clear_sync) begin
        src_valid_reg <= 1'b0;
        src_ready_reg <= 1'b0;
        src_data_reg <= '0;
      end else if (src_valid_i && src_ready_o) begin
        src_valid_reg <= 1'b1;
        src_ready_reg <= 1'b1;
        src_data_reg <= src_data_i;
      end
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_sync <= 1'b0;
      dst_ready_sync <= 1'b0;
      dst_data_sync <= '0;
      dst_clear_sync <= 1'b0;
      dst_clear_pending_sync <= 1'b0;
      dst_valid_reg <= 1'b0;
      dst_ready_reg <= 1'b0;
      dst_data_reg <= '0;
    end else begin
      dst_valid_sync <= dst_valid_o;
      dst_ready_sync <= dst_ready_i;
      dst_data_sync <= dst_data_o;
      dst_clear_sync <= dst_clear_i;
      dst_clear_pending_sync <= dst_clear_pending_o;
      if (dst_clear_sync) begin
        dst_valid_reg <= 1'b0;
        dst_ready_reg <= 1'b0;
        dst_data_reg <= '0;
      end else if (dst_valid_o && dst_ready_i) begin
        dst_valid_reg <= 1'b1;
        dst_ready_reg <= 1'b1;
        dst_data_reg <= dst_data_o;
      end
    end
  end

  logic [SYNC_STAGES-1:0] src_valid_pulse_sync;
  logic [SYNC_STAGES-1:0] dst_valid_pulse_sync;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_pulse_sync <= '0;
    end else begin
      src_valid_pulse_sync[0] <= src_valid_i && src_ready_o;
      for (int i = 1; i < SYNC_STAGES; i++) begin
        src_valid_pulse_sync[i] <= src_valid_pulse_sync[i-1];
      end
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_pulse_sync <= '0;
    end else begin
      dst_valid_pulse_sync[0] <= dst_valid_o && dst_ready_i;
      for (int i = 1; i < SYNC_STAGES; i++) begin
        dst_valid_pulse_sync[i] <= dst_valid_pulse_sync[i-1];
      end
    end
  end

  assign src_valid_pulse = src_valid_pulse_sync[SYNC_STAGES-1];
  assign dst_valid_pulse = dst_valid_pulse_sync[SYNC_STAGES-1];

  logic src_clear_pulse;
  logic dst_clear_pulse;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pulse <= 1'b0;
    end else begin
      src_clear_pulse <= src_clear_i;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pulse <= 1'b0;
    end else begin
      dst_clear_pulse <= dst_clear_i;
    end
  end

  assign src_clear_pending_o = src_clear_sync || src_clear_pending_sync;
  assign dst_clear_pending_o = dst_clear_sync || dst_clear_pending_sync;

  assign src_ready_o =!src_valid_reg || src_clear_sync;
  assign dst_valid_o = dst_valid_reg &&!dst_clear_sync;

  assign dst_data_o = dst_data_reg;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
    end else if (src_clear_sync) begin
      src_valid_reg <= 1'b0;
    end else if (src_valid_i && src_ready_o) begin
      src_valid_reg <= 1'b1;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
    end else if (dst_clear_sync) begin
      dst_valid_reg <= 1'b0;
    end else if (dst_valid_o && dst_ready_i) begin
      dst_valid_reg <= 1'b1;
    end
  end

endmodule
