module cdc_2phase #(
  parameter WIDTH = 1
)(
  input                  src_rst_ni,
  input                  src_clk_i,
  input      [WIDTH-1:0] src_data_i,
  input                  src_valid_i,
  output                 src_ready_o,

  input                  dst_rst_ni,
  input                  dst_clk_i,
  output     [WIDTH-1:0] dst_data_o,
  output                 dst_valid_o,
  input                  dst_ready_i
);

  logic [WIDTH-1:0] data;
  logic             valid;
  logic             src_ready;

  // Synchronize src_valid_i to src_clk_i
  logic src_valid_sync;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_sync <= 1'b0;
    end else begin
      src_valid_sync <= src_valid_i;
    end
  end

  // Accept new data on src_clk_i
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready <= 1'b1;
      data     <= '0;
      valid    <= 1'b0;
    end else if (src_valid_sync && src_ready) begin
      src_ready <= 1'b0;
      data     <= src_data_i;
      valid    <= 1'b1;
    end else if (!valid) begin
      src_ready <= 1'b1;
    end
  end

  // Synchronize data and valid to dst_clk_i
  logic [WIDTH-1:0] data_sync;
  logic             valid_sync;
  logic             dst_valid;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      data_sync <= '0;
      valid_sync <= 1'b0;
      dst_valid  <= 1'b0;
    end else begin
      data_sync <= data;
      valid_sync <= valid;
      if (valid_sync && dst_ready_i) begin
        dst_valid  <= 1'b0;
      end else if (valid_sync) begin
        dst_valid  <= 1'b1;
      end
    end
  end

  // Generate dst_data_o and dst_valid_o
  always_comb begin
    dst_data_o  = data_sync;
    dst_valid_o = dst_valid;
  end

  // Generate src_ready_o
  always_comb begin
    src_ready_o = src_ready;
  end

endmodule
