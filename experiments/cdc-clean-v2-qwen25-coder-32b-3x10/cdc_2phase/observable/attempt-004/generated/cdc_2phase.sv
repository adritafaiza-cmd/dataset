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

  // Source side signals
  logic [WIDTH-1:0] src_data_sync;
  logic src_valid_sync;
  logic src_ready;

  // Destination side signals
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_reg;

  // Synchronization registers for crossing from src_clk_i to dst_clk_i
  logic [WIDTH-1:0] sync_data [2];
  logic sync_valid [2];

  // Source side logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_sync <= '0;
      src_valid_sync <= '0;
    end else begin
      src_data_sync <= src_data_i;
      src_valid_sync <= src_valid_i;
    end
  end

  assign src_ready_o = src_ready;

  // Synchronization logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      sync_data[0] <= '0;
      sync_data[1] <= '0;
      sync_valid[0] <= '0;
      sync_valid[1] <= '0;
    end else begin
      sync_data[0] <= src_data_sync;
      sync_data[1] <= sync_data[0];
      sync_valid[0] <= src_valid_sync;
      sync_valid[1] <= sync_valid[0];
    end
  end

  // Destination side logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= '0;
      dst_valid_reg <= '0;
      src_ready <= '0;
    end else begin
      if (dst_ready_i && dst_valid_reg) begin
        dst_valid_reg <= '0;
        src_ready <= '1;
      end else if (sync_valid[1] && !dst_valid_reg) begin
        dst_data_reg <= sync_data[1];
        dst_valid_reg <= '1;
        src_ready <= '0;
      end else begin
        src_ready <= '0;
      end
    end
  end

  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
