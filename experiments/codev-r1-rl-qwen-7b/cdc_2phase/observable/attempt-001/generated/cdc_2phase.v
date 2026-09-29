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
  reg [WIDTH-1:0] data_reg;
  reg valid_toggle;
  reg ack_toggle_sync1, ack_toggle_sync2;

  // Synchronize ack_toggle from destination
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      ack_toggle_sync1 <= 0;
      ack_toggle_sync2 <= 0;
    end else begin
      ack_toggle_sync1 <= ack_toggle;
      ack_toggle_sync2 <= ack_toggle_sync1;
    end
  end

  // src_ready_o is when valid_toggle and ack_toggle_sync are same (buffer empty)
  assign src_ready_o = (valid_toggle == ack_toggle_sync2);

  // Update data_reg and toggle when data is accepted
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      data_reg <= 0;
      valid_toggle <= 0;
    end else begin
      if (src_valid_i && src_ready_o) begin
        data_reg <= src_data_i;
        valid_toggle <= ~valid_toggle;
      end
    end
  end

  // Destination domain signals
  reg ack_toggle;
  reg sync_toggle1, sync_toggle2;

  // Synchronize valid_toggle from source
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      sync_toggle1 <= 0;
      sync_toggle2 <= 0;
    end else begin
      sync_toggle1 <= valid_toggle;
      sync_toggle2 <= sync_toggle1;
    end
  end

  // Detect toggle to know data is available
  wire data_available = (sync_toggle2 != sync_toggle1);

  // Read data when data_available and dst_ready_i is high
  // Once read, toggle ack_toggle
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o <= 0;
      ack_toggle <= 0;
    end else begin
      if (data_available && dst_ready_i) begin
        dst_data_o <= data_reg;
        ack_toggle <= ~ack_toggle;
      end
    end
  end

  // Assign valid and output
  assign dst_valid_o = data_available;

endmodule
