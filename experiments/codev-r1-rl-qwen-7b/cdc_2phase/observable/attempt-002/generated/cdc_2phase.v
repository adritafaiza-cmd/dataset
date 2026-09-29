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
  reg [WIDTH-1:0] src_data_reg;
  reg src_toggle;
  reg dst_toggle_sync1, dst_toggle_sync2;

  // Destination domain signals
  reg dst_toggle;
  reg [WIDTH-1:0] dst_data_reg;
  reg src_toggle_sync1, src_toggle_sync2;

  // Synchronize dst_toggle to source domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_toggle_sync1 <= 0;
      dst_toggle_sync2 <= 0;
    end else begin
      dst_toggle_sync1 <= dst_toggle;
      dst_toggle_sync2 <= dst_toggle_sync1;
    end
  end

  // Source logic: capture data and toggle when valid and ready
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= 0;
      src_toggle <= 0;
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_data_reg <= src_data_i;
        src_toggle <= ~src_toggle;
      end
    end
  end

  assign src_ready_o = (dst_toggle_sync2 == src_toggle);

  // Destination logic: synchronize toggle and handle data transfer
  // Synchronize src_toggle to destination domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_toggle_sync1 <= 0;
      src_toggle_sync2 <= 0;
    end else begin
      src_toggle_sync1 <= src_toggle;
      src_toggle_sync2 <= src_toggle_sync1;
    end
  end

  // Destination valid is when the toggle has changed (data available)
  wire dst_valid = (src_toggle_sync2 != dst_toggle);

  // Capture data and toggle ack when valid and ready
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= 0;
      dst_toggle <= 0;
    end else begin
      if (dst_valid && dst_ready_i) begin
        dst_data_reg <= src_data_reg;
        dst_toggle <= ~dst_toggle;
      end
    end
  end

  assign dst_valid_o = dst_valid;
  assign dst_data_o = dst_data_reg;

endmodule
