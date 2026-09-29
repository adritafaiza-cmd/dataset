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

  // Source domain signals
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  reg [SYNC_STAGES-1:0] dst_ready_sync;
  reg src_clear_pending;

  // Destination domain signals
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  reg [SYNC_STAGES-1:0] src_valid_sync;
  reg [SYNC_STAGES-1:0] src_clear_sync;
  reg dst_clear_pending;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 0;
      src_data_reg <= 0;
      dst_ready_sync <= 0;
      src_clear_pending <= 0;
    end else begin
      dst_ready_sync <= {dst_ready_sync[SYNC_STAGES-2:0], dst_ready_i};

      if (src_clear_i || src_clear_pending || (CLEAR_ON_ASYNC_RESET && !src_rst_ni)) begin
        src_valid_reg <= 0;
        src_data_reg <= 0;
        src_clear_pending <= 1;
      end else if (src_valid_reg && dst_ready_sync[SYNC_STAGES-1]) begin
        src_valid_reg <= 0;
        src_clear_pending <= 0;
      end else if (src_valid_i && src_ready_o) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1;
      end
    end
  end

  assign src_ready_o = !src_valid_reg;

  // Synchronize src_valid and data to destination domain
  always @(posedge dst_clk_i) begin
    src_valid_sync <= {src_valid_sync[SYNC_STAGES-2:0], src_valid_reg};
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 0;
      dst_data_reg <= 0;
      dst_clear_pending <= 0;
    end else begin
      src_clear_sync <= {src_clear_sync[SYNC_STAGES-2:0], src_clear_i};

      if (dst_clear_i || dst_clear_pending || (CLEAR_ON_ASYNC_RESET && !dst_rst_ni)) begin
        dst_valid_reg <= 0;
        dst_data_reg <= 0;
        dst_clear_pending <= 1;
      end else if (dst_valid_reg && dst_ready_i) begin
        dst_valid_reg <= 0;
        dst_clear_pending <= 0;
      end else if (src_valid_sync[SYNC_STAGES-1] && dst_ready_i) begin
        dst_data_reg <= src_data_reg;
        dst_valid_reg <= 1;
      end
    end
  end

  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o = dst_data_reg;

  // Clear pending assignments
  assign src_clear_pending_o = src_clear_pending;
  assign dst_clear_pending_o = dst_clear_pending;

endmodule
