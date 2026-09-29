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

  // Source domain variables
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  reg src_toggle;

  // Synchronization of toggle in destination domain
  reg [1:0] sync_toggle;

  // Destination domain variables
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  reg dst_toggle;

  // Synchronization of toggle in source domain
  reg [1:0] sync_toggle_src;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_toggle <= 0;
      src_valid_reg <= 0;
      src_data_reg <= 0;
    end else begin
      // Capture data when valid and ready
      if (src_valid_i && src_ready_o) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1;
      end

      // Toggle and clear valid when ack received
      if (src_valid_reg && (sync_toggle[1] == src_toggle)) begin
        src_toggle <= ~src_toggle;
        src_valid_reg <= 0;
      end
    end
  end

  assign src_ready_o = !src_valid_reg;

  // Synchronize toggle to destination domain
  always @(posedge dst_clk_i) begin
    sync_toggle <= {sync_toggle[0], src_toggle};
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_toggle <= 0;
      dst_valid_reg <= 0;
      dst_data_reg <= 0;
    end else begin
      // Capture data when toggle changes
      if (sync_toggle[1] != dst_toggle) begin
        dst_data_reg <= src_data_reg;
        dst_valid_reg <= 1;
        dst_toggle <= sync_toggle[1];
      end

      // Clear valid when data is accepted
      if (dst_valid_reg && dst_ready_i) begin
        dst_valid_reg <= 0;
      end
    end
  end

  // Assign outputs
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

  // Synchronize destination's toggle back to source domain
  always @(posedge src_clk_i) begin
    sync_toggle_src <= {sync_toggle_src[0], dst_toggle};
  end

endmodule
