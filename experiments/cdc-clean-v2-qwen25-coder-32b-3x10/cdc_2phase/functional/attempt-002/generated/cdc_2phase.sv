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
  logic src_ready_ff;

  // Destination domain signals
  logic [WIDTH-1:0] dst_data_ff;
  logic dst_valid_ff;
  logic dst_ready_ff;

  // Synchronization flops
  logic [1:0] sync_valid;
  logic [1:0] sync_ready;

  // Source domain logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_ff <= '0;
      src_valid_ff <= 1'b0;
      src_ready_ff <= 1'b0;
    end else begin
      // Accept new data if ready and valid
      if (src_ready_ff && src_valid_i) begin
        src_data_ff <= src_data_i;
        src_valid_ff <= 1'b1;
      end else if (dst_ready_ff) begin
        src_valid_ff <= 1'b0;
      end
      // Update ready signal based on destination domain
      src_ready_ff <= ~src_valid_ff || dst_ready_ff;
    end
  end

  // Synchronize valid signal to destination domain
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      sync_valid <= 2'b00;
    end else begin
      sync_valid <= {sync_valid[0], src_valid_ff};
    end
  end

  // Destination domain logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_ff <= '0;
      dst_valid_ff <= 1'b0;
      dst_ready_ff <= 1'b0;
    end else begin
      // Accept data from source if not already valid
      if (!dst_valid_ff && sync_valid[1]) begin
        dst_data_ff <= src_data_ff;
        dst_valid_ff <= 1'b1;
      end else if (dst_ready_i) begin
        dst_valid_ff <= 1'b0;
      end
      // Update ready signal based on source domain
      dst_ready_ff <= ~dst_valid_ff || sync_ready[1];
    end
  end

  // Synchronize ready signal to source domain
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      sync_ready <= 2'b00;
    end else begin
      sync_ready <= {sync_ready[0], dst_ready_i};
    end
  end

  // Output assignments
  assign src_ready_o = src_ready_ff;
  assign dst_data_o = dst_data_ff;
  assign dst_valid_o = dst_valid_ff;

endmodule
