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

  // Internal signals
  reg [WIDTH-1:0] data_sync_ff [1:0];
  reg valid_sync_ff [1:0];
  reg src_ready_ff;
  reg [WIDTH-1:0] dst_data_ff;
  reg dst_valid_ff;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_ff <= 1'b0;
    end else begin
      // Accept new data if ready and valid
      if (src_ready_ff && src_valid_i) begin
        src_ready_ff <= 1'b0;
      end else if (!dst_valid_ff) begin
        src_ready_ff <= 1'b1;
      end
    end
  end

  // Data and valid synchronization
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      data_sync_ff[0] <= {WIDTH{1'b0}};
      data_sync_ff[1] <= {WIDTH{1'b0}};
      valid_sync_ff[0] <= 1'b0;
      valid_sync_ff[1] <= 1'b0;
    end else begin
      data_sync_ff[0] <= src_data_i;
      data_sync_ff[1] <= data_sync_ff[0];
      valid_sync_ff[0] <= src_ready_ff & src_valid_i;
      valid_sync_ff[1] <= valid_sync_ff[0];
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_ff <= {WIDTH{1'b0}};
      dst_valid_ff <= 1'b0;
    end else begin
      if (valid_sync_ff[1] && !dst_valid_ff) begin
        dst_data_ff <= data_sync_ff[1];
        dst_valid_ff <= 1'b1;
      end else if (dst_valid_ff && dst_ready_i) begin
        dst_valid_ff <= 1'b0;
      end
    end
  end

  // Assign outputs
  assign src_ready_o = src_ready_ff;
  assign dst_data_o = dst_data_ff;
  assign dst_valid_o = dst_valid_ff;

endmodule
