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
  logic src_valid_sync_ff;
  logic src_valid_sync_ff2;
  logic src_valid_sync_ff3;
  logic src_clear_sync;
  logic src_clear_sync_ff;
  logic src_clear_sync_ff2;
  logic src_clear_sync_ff3;

  logic dst_valid_sync;
  logic dst_valid_sync_ff;
  logic dst_valid_sync_ff2;
  logic dst_valid_sync_ff3;
  logic dst_clear_sync;
  logic dst_clear_sync_ff;
  logic dst_clear_sync_ff2;
  logic dst_clear_sync_ff3;

  logic src_valid_ff;
  logic src_valid_ff2;
  logic src_valid_ff3;
  logic src_valid_ff4;
  logic src_valid_ff5;

  logic dst_valid_ff;
  logic dst_valid_ff2;
  logic dst_valid_ff3;
  logic dst_valid_ff4;
  logic dst_valid_ff5;

  logic src_clear_ff;
  logic src_clear_ff2;
  logic src_clear_ff3;
  logic src_clear_ff4;
  logic src_clear_ff5;

  logic dst_clear_ff;
  logic dst_clear_ff2;
  logic dst_clear_ff3;
  logic dst_clear_ff4;
  logic dst_clear_ff5;

  logic src_data_ff;
  logic src_data_ff2;
  logic src_data_ff3;
  logic src_data_ff4;
  logic src_data_ff5;

  logic dst_data_ff;
  logic dst_data_ff2;
  logic dst_data_ff3;
  logic dst_data_ff4;
  logic dst_data_ff5;

  logic src_ready_ff;
  logic dst_valid_ff6;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_sync <= 1'b0;
      src_valid_sync_ff <= 1'b0;
      src_valid_sync_ff2 <= 1'b0;
      src_valid_sync_ff3 <= 1'b0;
      src_clear_sync <= 1'b0;
      src_clear_sync_ff <= 1'b0;
      src_clear_sync_ff2 <= 1'b0;
      src_clear_sync_ff3 <= 1'b0;
    end else begin
      src_valid_sync <= src_valid_i;
      src_valid_sync_ff <= src_valid_sync;
      src_valid_sync_ff2 <= src_valid_sync_ff;
      src_valid_sync_ff3 <= src_valid_sync_ff2;
      src_clear_sync <= src_clear_i;
      src_clear_sync_ff <= src_clear_sync;
      src_clear_sync_ff2 <= src_clear_sync_ff;
      src_clear_sync_ff3 <= src_clear_sync_ff2;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_sync <= 1'b0;
      dst_valid_sync_ff <= 1'b0;
      dst_valid_sync_ff2 <= 1'b0;
      dst_valid_sync_ff3 <= 1'b0;
      dst_clear_sync <= 1'b0;
      dst_clear_sync_ff <= 1'b0;
      dst_clear_sync_ff2 <= 1'b0;
      dst_clear_sync_ff3 <= 1'b0;
    end else begin
      dst_valid_sync <= dst_valid_o;
      dst_valid_sync_ff <= dst_valid_sync;
      dst_valid_sync_ff2 <= dst_valid_sync_ff;
      dst_valid_sync_ff3 <= dst_valid_sync_ff2;
      dst_clear_sync <= dst_clear_i;
      dst_clear_sync_ff <= dst_clear_sync;
      dst_clear_sync_ff2 <= dst_clear_sync_ff;
      dst_clear_sync_ff3 <= dst_clear_sync_ff2;
    end
  end

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_ff <= 1'b0;
      src_valid_ff2 <= 1'b0;
      src_valid_ff3 <= 1'b0;
      src_valid_ff4 <= 1'b0;
      src_valid_ff5 <= 1'b0;
      src_clear_ff <= 1'b0;
      src_clear_ff2 <= 1'b0;
      src_clear_ff3 <= 1'b0;
      src_clear_ff4 <= 1'b0;
      src_clear_ff5 <= 1'b0;
      src_data_ff <= '0;
      src_data_ff2 <= '0;
      src_data_ff3 <= '0;
      src_data_ff4 <= '0;
      src_data_ff5 <= '0;
      src_ready_ff <= 1'b0;
    end else begin
      src_valid_ff <= src_valid_i;
      src_valid_ff2 <= src_valid_ff;
      src_valid_ff3 <= src_valid_ff2;
      src_valid_ff4 <= src_valid_ff3;
      src_valid_ff5 <= src_valid_ff4;
      src_clear_ff <= src_clear_i;
      src_clear_ff2 <= src_clear_ff;
      src_clear_ff3 <= src_clear_ff2;
      src_clear_ff4 <= src_clear_ff3;
      src_clear_ff5 <= src_clear_ff4;
      src_data_ff <= src_data_i;
      src_data_ff2 <= src_data_ff;
      src_data_ff3 <= src_data_ff2;
      src_data_ff4 <= src_data_ff3;
      src_data_ff5 <= src_data_ff4;
      src_ready_ff <= (src_valid_i && src_ready_o) || (src_clear_i && src_clear_pending_o);
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_ff <= 1'b0;
      dst_valid_ff2 <= 1'b0;
      dst_valid_ff3 <= 1'b0;
      dst_valid_ff4 <= 1'b0;
      dst_valid_ff5 <= 1'b0;
      dst_clear_ff <= 1'b0;
      dst_clear_ff2 <= 1'b0;
      dst_clear_ff3 <= 1'b0;
      dst_clear_ff4 <= 1'b0;
      dst_clear_ff5 <= 1'b0;
      dst_data_ff <= '0;
      dst_data_ff2 <= '0;
      dst_data_ff3 <= '0;
      dst_data_ff4 <= '0;
      dst_data_ff5 <= '0;
      dst_valid_ff6 <= 1'b0;
    end else begin
      dst_valid_ff <= dst_valid_o;
      dst_valid_ff2 <= dst_valid_ff;
      dst_valid_ff3 <= dst_valid_ff2;
      dst_valid_ff4 <= dst_valid_ff3;
      dst_valid_ff5 <= dst_valid_ff4;
      dst_clear_ff <= dst_clear_i;
      dst_clear_ff2 <= dst_clear_ff;
      dst_clear_ff3 <= dst_clear_ff2;
      dst_clear_ff4 <= dst_clear_ff3;
      dst_clear_ff5 <= dst_clear_ff4;
      dst_data_ff <= dst_data_o;
      dst_data_ff2 <= dst_data_ff;
      dst_data_ff3 <= dst_data_ff2;
      dst_data_ff4 <= dst_data_ff3;
      dst_data_ff5 <= dst_data_ff4;
      dst_valid_ff6 <= dst_valid_ff5;
    end
  end

  assign src_ready_o = (src_clear_i && src_clear_pending_o) || (src_valid_i && src_ready_ff);
  assign dst_valid_o = dst_valid_ff6;
  assign dst_data_o = dst_data_ff5;
  assign src_clear_pending_o = src_clear_ff5;
  assign dst_clear_pending_o = dst_clear_ff5;

endmodule
