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
  logic src_valid_sync_rr;
  logic [WIDTH-1:0] src_data_sync;
  logic [WIDTH-1:0] src_data_sync_r;
  logic [WIDTH-1:0] src_data_sync_rr;
  logic src_clear_sync;
  logic src_clear_sync_r;
  logic src_clear_sync_rr;
  logic src_clear_pending;
  logic dst_clear_sync;
  logic dst_clear_sync_r;
  logic dst_clear_sync_rr;
  logic dst_valid_sync;
  logic dst_valid_sync_r;
  logic dst_valid_sync_rr;
  logic [WIDTH-1:0] dst_data_sync;
  logic [WIDTH-1:0] dst_data_sync_r;
  logic [WIDTH-1:0] dst_data_sync_rr;
  logic dst_clear_pending;
  logic src_valid_reg;
  logic src_valid_reg_r;
  logic dst_valid_reg;
  logic dst_valid_reg_r;
  logic src_ready_reg;
  logic dst_ready_reg;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_sync <= 1'b0;
      src_valid_sync_r <= 1'b0;
      src_valid_sync_rr <= 1'b0;
      src_data_sync <= '0;
      src_data_sync_r <= '0;
      src_data_sync_rr <= '0;
      src_clear_sync <= 1'b0;
      src_clear_sync_r <= 1'b0;
      src_clear_sync_rr <= 1'b0;
      src_clear_pending <= 1'b0;
      src_valid_reg <= 1'b0;
      src_valid_reg_r <= 1'b0;
      src_ready_reg <= 1'b0;
    end else begin
      src_valid_sync <= src_valid_i;
      src_valid_sync_r <= src_valid_sync;
      src_valid_sync_rr <= src_valid_sync_r;
      src_data_sync <= src_data_i;
      src_data_sync_r <= src_data_sync;
      src_data_sync_rr <= src_data_sync_r;
      src_clear_sync <= src_clear_i;
      src_clear_sync_r <= src_clear_sync;
      src_clear_sync_rr <= src_clear_sync_r;
      src_clear_pending <= src_clear_i || src_clear_sync || src_clear_sync_r;
      src_valid_reg <= src_valid_sync &&!src_clear_pending;
      src_valid_reg_r <= src_valid_reg;
      src_ready_reg <=!src_valid_reg_r || dst_ready_i;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_sync <= 1'b0;
      dst_clear_sync_r <= 1'b0;
      dst_clear_sync_rr <= 1'b0;
      dst_valid_sync <= 1'b0;
      dst_valid_sync_r <= 1'b0;
      dst_valid_sync_rr <= 1'b0;
      dst_data_sync <= '0;
      dst_data_sync_r <= '0;
      dst_data_sync_rr <= '0;
      dst_clear_pending <= 1'b0;
      dst_valid_reg <= 1'b0;
      dst_valid_reg_r <= 1'b0;
      dst_ready_reg <= 1'b0;
    end else begin
      dst_clear_sync <= dst_clear_i;
      dst_clear_sync_r <= dst_clear_sync;
      dst_clear_sync_rr <= dst_clear_sync_r;
      dst_valid_sync <= src_valid_sync_rr;
      dst_valid_sync_r <= dst_valid_sync;
      dst_valid_sync_rr <= dst_valid_sync_r;
      dst_data_sync <= src_data_sync_rr;
      dst_data_sync_r <= dst_data_sync;
      dst_data_sync_rr <= dst_data_sync_r;
      dst_clear_pending <= dst_clear_i || dst_clear_sync || dst_clear_sync_r;
      dst_valid_reg <= dst_valid_sync &&!dst_clear_pending;
      dst_valid_reg_r <= dst_valid_reg;
      dst_ready_reg <=!dst_valid_reg_r;
    end
  end

  assign src_ready_o = src_ready_reg;
  assign dst_valid_o = dst_valid_reg_r;
  assign dst_data_o = dst_data_sync_rr;
  assign src_clear_pending_o = src_clear_pending;
  assign dst_clear_pending_o = dst_clear_pending;

endmodule
