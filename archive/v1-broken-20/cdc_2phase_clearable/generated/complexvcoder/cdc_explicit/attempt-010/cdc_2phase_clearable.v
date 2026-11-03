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
  logic src_clear_reg;
  logic src_clear_pending_reg;
  logic dst_clear_reg;
  logic dst_clear_pending_reg;
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;

  // Register for source domain
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= 0;
      src_valid_reg <= 0;
      src_ready_reg <= 0;
      src_clear_reg <= 0;
      src_clear_pending_reg <= 0;
    end else begin
      if (src_clear_reg) begin
        src_clear_reg <= 0;
        src_clear_pending_reg <= 0;
      end else if (src_valid_i && src_ready_i) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1;
      end
      src_ready_reg <= 1;
    end
  end

  // Register for destination domain
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= 0;
      dst_valid_reg <= 0;
      dst_ready_reg <= 0;
      dst_clear_reg <= 0;
      dst_clear_pending_reg <= 0;
    end else begin
      if (dst_clear_reg) begin
        dst_clear_reg <= 0;
        dst_clear_pending_reg <= 0;
      end else if (dst_ready_i && dst_valid_reg) begin
        dst_data_reg <= src_data_reg;
        dst_valid_reg <= 0;
      end
      dst_ready_reg <= 1;
    end
  end

  // Clear handling
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_reg <= 0;
    end else if (src_clear_i) begin
      src_clear_reg <= 1;
      src_clear_pending_reg <= 1;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_reg <= 0;
    end else if (dst_clear_i) begin
      dst_clear_reg <= 1;
      dst_clear_pending_reg <= 1;
    end
  end

  // Clear pending handling
  assign src_clear_pending_o = src_clear_pending_reg;
  assign dst_clear_pending_o = dst_clear_pending_reg;

  // Ready and valid logic
  assign src_ready_o = src_ready_reg;
  assign dst_valid_o = dst_valid_reg;

  // Data output
  assign dst_data_o = dst_data_reg;

endmodule
