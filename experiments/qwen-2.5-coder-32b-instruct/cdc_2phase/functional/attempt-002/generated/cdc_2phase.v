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

  // Internal signals
  logic [WIDTH-1:0] data_sync;
  logic             valid_sync;
  logic             valid_meta;

  // Source side logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_o <= 1'b0;
      valid_sync  <= 1'b0;
    end else begin
      if (src_valid_i && src_ready_o) begin
        valid_sync <= 1'b1;
        data_sync  <= src_data_i;
      end else if (valid_meta) begin
        valid_sync <= 1'b;
      end
      src_ready_o <= !valid_sync;
    end
  end

  // Clock domain crossing for valid signal
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      valid_meta <= 1'b0;
      dst_valid_o <= 1'b0;
    end else begin
      valid_meta  <= valid_sync;
      dst_valid_o <= valid_meta;
    end
  end

  // Destination side logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o <= '0;
    end else if (dst_valid_o && dst_ready_i) begin
      dst_data_o <= data_sync;
    end
  end

endmodule
