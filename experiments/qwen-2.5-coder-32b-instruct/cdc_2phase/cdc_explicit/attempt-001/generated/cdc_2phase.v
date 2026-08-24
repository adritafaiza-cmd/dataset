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

  // Intermediate signals
  logic [WIDTH-1:0] meta_data;
  logic             meta_valid;
  logic             sync_valid;

  // Source side
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      meta_data  <= '0;
      meta_valid <= 1'b0;
    end else if (src_valid_i && src_ready_o) begin
      meta_data  <= src_data_i;
      meta_valid <= 1'b1;
    end
  end

  // Synchronizer for meta_valid
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      sync_valid <= 1'b0;
    end else begin
      sync_valid <= meta_valid;
    end
  end

  // Destination side
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o  <= '0;
      dst_valid_o <= 1'b0;
    end else if (sync_valid && !dst_valid_o) begin
      dst_data_o  <= meta_data;
      dst_valid_o <= 1'b1;
    end else if (dst_valid_o && dst_ready_i) begin
      dst_valid_o <= 1'b0;
    end
  end

  // Source ready signal
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_o <= 1'b0;
    end else begin
      src_ready_o <= !sync_valid;
    end
  end

endmodule
