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
  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic src_ready_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic [WIDTH-1:0] dst_data_reg;
  logic src_clear_reg;
  logic dst_clear_reg;
  logic src_clear_pending;
  logic dst_clear_pending;
  logic src_clear_complete;
  logic dst_clear_complete;
  logic [SYNC_STAGES-1:0] src_sync_valid;
  logic [SYNC_STAGES-1:0] src_sync_ready;
  logic [SYNC_STAGES-1:0] dst_sync_valid;
  logic [SYNC_STAGES-1:0] dst_sync_ready;

  // Clear flags
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_reg <= 1'b0;
    end else begin
      src_clear_reg <= src_clear_i;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_reg <= 1'b0;
    end else begin
      dst_clear_reg <= dst_clear_i;
    end
  end

  // Clear pending flags
  assign src_clear_pending_o = src_clear_pending;
  assign dst_clear_pending_o = dst_clear_pending;

  // Clear completion logic
  assign src_clear_complete = src_clear_reg && !src_clear_i;
  assign dst_clear_complete = dst_clear_reg && !dst_clear_i;

  // Clear pending logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pending <= 1'b0;
    end else begin
      if (src_clear_complete) begin
        src_clear_pending <= 1'b0;
      end else begin
        src_clear_pending <= 1'b1;
      end
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pending <= 1'b0;
    end else begin
      if (dst_clear_complete) begin
        dst_clear_pending <= 1'b0;
      end else begin
        dst_clear_pending <= 1'b1;
      end
    end
  end

  // Data synchronization
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b0;
    end else begin
      if (src_valid_i && src_ready_i && !src_clear_reg) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1'b1;
      end else begin
        src_valid_reg <= 1'b0;
      end
      src_ready_reg <= dst_ready_i;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      dst_ready_reg <= 1'b0;
    end else begin
      if (src_valid_reg && src_ready_reg && !dst_clear_reg) begin
        dst_data_reg <= src_data_reg;
        dst_valid_reg <= 1'b1;
      end else begin
        dst_valid_reg <= 1'b0;
      end
      dst_ready_reg <= 1'b1;
    end
  end

  // Output assignments
  assign src_ready_o = dst_ready_i;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
