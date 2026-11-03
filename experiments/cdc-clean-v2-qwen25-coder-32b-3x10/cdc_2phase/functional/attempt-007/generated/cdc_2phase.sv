module cdc_2phase #(
  parameter WIDTH = 1
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,
  input  dst_rst_ni,
  input  dst_clk_i,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);

  // Source domain signals
  logic [WIDTH-1:0] src_data_sync;
  logic src_valid_sync;
  logic src_ready;

  // Destination domain signals
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_reg;
  logic dst_ready_sync;

  // Synchronizers
  logic [1:0] src_valid_sync_ff;
  logic [1:0] dst_ready_sync_ff;

  // Source domain logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_sync_ff <= 2'b00;
      src_ready <= 1'b0;
    end else begin
      src_valid_sync_ff <= {src_valid_sync_ff[0], src_valid_i};
      src_ready <= ~src_valid_sync_ff[1] & ~src_valid_sync_ff[0];
    end
  end

  assign src_valid_sync = src_valid_sync_ff[1];
  assign src_ready_o = src_ready;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_sync <= '0;
    end else if (src_ready & src_valid_i) begin
      src_data_sync <= src_data_i;
    end
  end

  // Destination domain logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_sync_ff <= 2'b00;
      dst_valid_reg <= 1'b0;
      dst_data_reg <= '0;
    end else begin
      dst_ready_sync_ff <= {dst_ready_sync_ff[0], dst_ready_i};
      if (dst_ready_sync & ~dst_valid_reg) begin
        dst_valid_reg <= src_valid_sync;
        dst_data_reg <= src_data_sync;
      end else if (dst_ready_sync & dst_valid_reg) begin
        dst_valid_reg <= 1'b0;
      end
    end
  end

  assign dst_ready_sync = dst_ready_sync_ff[1];
  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o = dst_data_reg;

endmodule
