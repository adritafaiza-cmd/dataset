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
  logic [WIDTH-1:0] src_data_ff;
  logic src_valid_ff;
  logic src_ready;

  // Destination domain signals
  logic [WIDTH-1:0] dst_data_ff;
  logic dst_valid;
  logic dst_ready_ff;

  // Synchronization flops
  logic [1:0] sync_valid;
  logic [1:0] sync_ready;

  // Source domain logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_ff <= '0;
      src_valid_ff <= '0;
      src_ready <= '1;
    end else begin
      if (src_ready && src_valid_i) begin
        src_data_ff <= src_data_i;
        src_valid_ff <= '1;
        src_ready <= '0;
      end else if (sync_valid[1]) begin
        src_valid_ff <= '0;
        src_ready <= '1;
      end
    end
  end

  // Synchronize src_valid_ff to dst_clk_i
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      sync_valid <= '0;
    end else begin
      sync_valid[0] <= src_valid_ff;
      sync_valid[1] <= sync_valid[0];
    end
  end

  // Destination domain logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_ff <= '0;
      dst_valid <= '0;
      dst_ready_ff <= '1;
    end else begin
      if (dst_ready_i && dst_valid) begin
        dst_valid <= '0;
        dst_ready_ff <= '1;
      end else if (sync_valid[1] && !dst_valid) begin
        dst_data_ff <= src_data_ff;
        dst_valid <= '1;
        dst_ready_ff <= '0;
      end
    end
  end

  // Synchronize dst_ready_ff to src_clk_i
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      sync_ready <= '0;
    end else begin
      sync_ready[0] <= dst_ready_ff;
      sync_ready[1] <= sync_ready[0];
    end
  end

  // Assign outputs
  assign src_ready_o = sync_ready[1];
  assign dst_data_o = dst_data_ff;
  assign dst_valid_o = dst_valid;

endmodule
