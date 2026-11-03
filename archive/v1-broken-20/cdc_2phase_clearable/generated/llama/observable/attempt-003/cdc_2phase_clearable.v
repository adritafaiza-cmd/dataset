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
  logic src_valid_reg;
  logic src_clear_sync;
  logic src_clear_reg;
  logic src_clear_pending_reg;
  logic [WIDTH-1:0] src_data_reg;

  logic dst_valid_sync;
  logic dst_valid_reg;
  logic dst_clear_sync;
  logic dst_clear_reg;
  logic dst_clear_pending_reg;
  logic [WIDTH-1:0] dst_data_reg;

  logic src_ready_int;
  logic dst_valid_int;

  // Source clock domain
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
      src_clear_reg <= 1'b0;
      src_clear_pending_reg <= 1'b0;
      src_data_reg <= '0;
    end else begin
      src_valid_reg <= src_valid_i &&!src_clear_i;
      src_clear_reg <= src_clear_i;
      src_clear_pending_reg <= src_clear_i || src_clear_pending_reg;
      if (src_clear_i) begin
        src_data_reg <= '0;
      end else if (src_valid_i &&!src_ready_int) begin
        src_data_reg <= src_data_i;
      end
    end
  end

  assign src_ready_o = src_ready_int;
  assign src_clear_pending_o = src_clear_pending_reg;

  // Synchronize signals from source clock domain to destination clock domain
  logic [SYNC_STAGES-1:0] src_valid_sync_reg;
  logic [SYNC_STAGES-1:0] src_clear_sync_reg;
  logic [WIDTH-1:0] src_data_sync_reg;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync_reg <= '0;
      src_clear_sync_reg <= '0;
      src_data_sync_reg <= '0;
    end else begin
      src_valid_sync_reg[0] <= src_valid_reg;
      src_clear_sync_reg[0] <= src_clear_reg;
      src_data_sync_reg <= src_data_reg;
      for (int i = 1; i < SYNC_STAGES; i++) begin
        src_valid_sync_reg[i] <= src_valid_sync_reg[i-1];
        src_clear_sync_reg[i] <= src_clear_sync_reg[i-1];
      end
    end
  end
  assign src_valid_sync = src_valid_sync_reg[SYNC_STAGES-1];
  assign src_clear_sync = src_clear_sync_reg[SYNC_STAGES-1];

  // Destination clock domain
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
      dst_clear_reg <= 1'b0;
      dst_clear_pending_reg <= 1'b0;
      dst_data_reg <= '0;
    end else begin
      dst_valid_reg <= src_valid_sync &&!dst_clear_i;
      dst_clear_reg <= dst_clear_i;
      dst_clear_pending_reg <= dst_clear_i || dst_clear_pending_reg;
      if (dst_clear_i) begin
        dst_data_reg <= '0;
      end else if (src_valid_sync &&!dst_valid_int) begin
        dst_data_reg <= src_data_sync_reg;
      end
    end
  end

  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_clear_pending_o = dst_clear_pending_reg;

  // Synchronize signals from destination clock domain to source clock domain
  logic dst_ready_sync;
  logic dst_clear_sync;
  logic [SYNC_STAGES-1:0] dst_ready_sync_reg;
  logic [SYNC_STAGES-1:0] dst_clear_sync_reg;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_sync_reg <= '0;
      dst_clear_sync_reg <= '0;
    end else begin
      dst_ready_sync_reg[0] <= dst_ready_i;
      dst_clear_sync_reg[0] <= dst_clear_i;
      for (int i = 1; i < SYNC_STAGES; i++) begin
        dst_ready_sync_reg[i] <= dst_ready_sync_reg[i-1];
        dst_clear_sync_reg[i] <= dst_clear_sync_reg[i-1];
      end
    end
  end
  assign dst_ready_sync = dst_ready_sync_reg[SYNC_STAGES-1];
  assign dst_clear_sync = dst_clear_sync_reg[SYNC_STAGES-1];

  assign src_ready_int = dst_ready_sync &&!dst_clear_sync;
  assign dst_valid_int = dst_valid_reg &&!dst_clear_reg;

endmodule
