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
  reg [WIDTH-1:0] data_s;
  reg send_phase_s;
  reg ack_phase_sync1, ack_phase_sync2;

  // Destination domain signals
  reg [WIDTH-1:0] data_d;
  reg send_phase_sync1, send_phase_sync2;
  reg ack_phase_d;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      data_s <= '0;
      send_phase_s <= 1'b0;
      ack_phase_sync1 <= 1'b0;
      ack_phase_sync2 <= 1'b0;
    end else begin
      // Synchronize ack_phase from destination
      ack_phase_sync1 <= ack_phase_d;
      ack_phase_sync2 <= ack_phase_sync1;

      // Handshake: capture data and toggle phase when valid and ready
      if (src_valid_i && src_ready_o) begin
        data_s <= src_data_i;
        send_phase_s <= ~send_phase_s;
      end
    end
  end

  // Ready is asserted when send_phase matches synchronized ack_phase
  assign src_ready_o = (send_phase_s == ack_phase_sync2);

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      send_phase_sync1 <= 1'b0;
      send_phase_sync2 <= 1'b0;
      ack_phase_d <= 1'b0;
      data_d <= '0;
    end else begin
      // Synchronize send_phase from source
      send_phase_sync1 <= send_phase_s;
      send_phase_sync2 <= send_phase_sync1;

      // Toggle ack when data is read
      if (dst_valid_o && dst_ready_i) begin
        ack_phase_d <= ~ack_phase_d;
      end

      // Capture data when phase changes
      if (send_phase_sync2 != ack_phase_d) begin
        data_d <= data_s;
      end
    end
  end

  // Valid is asserted when phases differ
  assign dst_valid_o = (send_phase_sync2 != ack_phase_d);
  assign dst_data_o = data_d;

endmodule
