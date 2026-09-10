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

  logic src_clear_sync;
  logic src_clear_sync_2;
  logic dst_clear_sync;
  logic dst_clear_sync_2;

  logic src_valid_sync;
  logic [WIDTH-1:0] src_data_sync;
  logic src_valid_sync_2;
  logic [WIDTH-1:0] src_data_sync_2;

  logic dst_valid_sync;
  logic [WIDTH-1:0] dst_data_sync;
  logic dst_valid_sync_2;
  logic [WIDTH-1:0] dst_data_sync_2;

  logic src_clear_pending;
  logic dst_clear_pending;

  logic src_valid_reg;
  logic [WIDTH-1:0] src_data_reg;
  logic dst_valid_reg;
  logic [WIDTH-1:0] dst_data_reg;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_sync <= 1'b0;
      src_clear_sync_2 <= 1'b0;
      src_valid_sync <= 1'b0;
      src_data_sync <= '0;
      src_valid_sync_2 <= 1'b0;
      src_data_sync_2 <= '0;
      src_clear_pending <= 1'b0;
      src_valid_reg <= 1'b0;
      src_data_reg <= '0;
    end else begin
      src_clear_sync <= src_clear_i;
      src_clear_sync_2 <= src_clear_sync;
      src_valid_sync <= src_valid_i;
      src_data_sync <= src_data_i;
      src_valid_sync_2 <= src_valid_sync;
      src_data_sync_2 <= src_data_sync;
      src_clear_pending <= src_clear_i || src_clear_sync || src_clear_sync_2;
      if (src_clear_i || src_clear_sync || src_clear_sync_2) begin
        src_valid_reg <= 1'b0;
        src_data_reg <= '0;
      end else if (src_valid_i && src_ready_o) begin
        src_valid_reg <= 1'b1;
        src_data_reg <= src_data_i;
      end
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_sync <= 1'b0;
      dst_clear_sync_2 <= 1'b0;
      dst_valid_sync <= 1'b0;
      dst_data_sync <= '0;
      dst_valid_sync_2 <= 1'b0;
      dst_data_sync_2 <= '0;
      dst_clear_pending <= 1'b0;
      dst_valid_reg <= 1'b0;
      dst_data_reg <= '0;
    end else begin
      dst_clear_sync <= dst_clear_i;
      dst_clear_sync_2 <= dst_clear_sync;
      dst_valid_sync <= src_valid_sync_2;
      dst_data_sync <= src_data_sync_2;
      dst_valid_sync_2 <= dst_valid_sync;
      dst_data_sync_2 <= dst_data_sync;
      dst_clear_pending <= dst_clear_i || dst_clear_sync || dst_clear_sync_2;
      if (dst_clear_i || dst_clear_sync || dst_clear_sync_2) begin
        dst_valid_reg <= 1'b0;
        dst_data_reg <= '0;
      end else if (dst_valid_sync && dst_ready_i) begin
        dst_valid_reg <= 1'b1;
        dst_data_reg <= dst_data_sync;
      end
    end
  end

  assign src_ready_o = !(src_valid_reg && !dst_valid_sync) && !src_clear_pending;
  assign dst_valid_o = dst_valid_reg && !dst_clear_pending;
  assign dst_data_o = dst_data_reg;

  assign src_clear_pending_o = src_clear_pending;
  assign dst_clear_pending_o = dst_clear_pending;

endmodule
