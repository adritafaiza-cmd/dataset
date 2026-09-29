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

  reg [WIDTH-1:0] data_reg;
  reg send;

  // Synchronize send to destination
  reg send_sync1, send_sync2;

  // Synchronize ack to source
  reg ack_sync1, ack_sync2;
  reg ack;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      data_reg <= 0;
      send <= 0;
    end else if (src_valid_i && src_ready_o) begin
      data_reg <= src_data_i;
      send <= ~send;
    end
  end

  // Source ready is when send matches ack_sync2
  assign src_ready_o = (send == ack_sync2);

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      send_sync1 <= 0;
      send_sync2 <= 0;
      ack <= 0;
    end else begin
      send_sync1 <= send;
      send_sync2 <= send_sync1;
      if (send_sync2 != send_sync1 && dst_ready_i && dst_valid_o) begin
        ack <= ~ack;
      end
    end
  end

  // Synchronize ack to source
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      ack_sync1 <= 0;
      ack_sync2 <= 0;
    end else begin
      ack_sync1 <= ack;
      ack_sync2 <= ack_sync1;
    end
  end

  // Assign outputs
  assign dst_valid_o = (send_sync2 != send_sync1);
  assign dst_data_o = data_reg;

endmodule
