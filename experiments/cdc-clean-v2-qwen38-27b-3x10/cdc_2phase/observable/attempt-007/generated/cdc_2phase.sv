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

  // Source side: capture data and generate a pulse when valid and ready
  // Destination side: detect pulse edge and hold data until accepted

  // Source side registers
  reg [WIDTH-1:0] src_data_reg;
  reg             src_valid_reg;
  reg             src_ready_reg;

  // Pulse generation: we use a simple handshake
  // src_ready_o is high when we can accept new data
  // We accept data when src_valid_i && src_ready_o
  // After accepting, we need to notify the destination

  // Let's use a 2-phase handshake with a "request" pulse
  // Source: when src_valid_i && src_ready_o, latch data and assert req
  // Destination: detect rising edge of req, latch data, assert valid
  // When dst_ready_i && dst_valid_o, deassert valid and allow req to deassert

  // Actually, let's use a simpler approach:
  // Source side:
  //   - src_ready_o = ~src_valid_reg (can accept when no pending)
  //   - When src_valid_i && src_ready_o: latch src_data_i into src_data_reg, set src_valid_reg=1
  //   - Generate a pulse to destination when src_valid_reg transitions 0->1
  //
  // Destination side:
  //   - Detect rising edge of the pulse (synchronized)
  //   - On rising edge: latch data (synchronized), set dst_valid_o=1
  //   - When dst_ready_i && dst_valid_o: clear dst_valid_o, and signal back to source to clear src_valid_reg
  //
  // But we need to handle the backpressure: source should not accept new data until destination has accepted.
  // So src_ready_o should be ~src_valid_reg, and src_valid_reg is cleared when destination accepts.

  // Let's use a 2-phase handshake with request and acknowledge:
  // Source: req goes high when data is ready
  // Destination: detects req rising edge, latches data, sets valid
  // When dst_ready_i && dst_valid_o: dst sends ack
  // Source: detects ack rising edge, clears req (src_valid_reg)

  // This is a standard 2-phase handshake.

  // Source side
  reg [WIDTH-1:0] src_data_reg;
  reg             src_req;       // request signal
  reg             src_ack_sync1; // synchronized ack
  reg             src_ack_sync2;

  // Destination side
  reg [WIDTH-1:0] dst_data_reg;
  reg             dst_valid_reg;
  reg             dst_req_sync1; // synchronized req
  reg             dst_req_sync2;
  reg             dst_req_sync3; // for edge detection
  reg             dst_ack;       // acknowledge signal

  // Source side logic
  // src_ready_o: can accept new data when not in a pending transfer
  assign src_ready_o = ~src_req;

  // Latch data and assert req when valid and ready
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_req      <= 1'b0;
      src_ack_sync1 <= 1'b0;
      src_ack_sync2 <= 1'b0;
    end else begin
      // Synchronize ack
      src_ack_sync1 <= dst_ack;
      src_ack_sync2 <= src_ack_sync1;

      // Assert req when valid and ready
      if (src_valid_i && ~src_req) begin
        src_data_reg <= src_data_i;
        src_req      <= 1'b1;
      end

      // Deassert req when ack is detected (rising edge of ack)
      if (src_req && src_ack_sync2 && ~src_ack_sync1) begin
        src_req <= 1'b0;
      end
    end
  end

  // Destination side logic
  // Synchronize req
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_req_sync1 <= 1'b0;
      dst_req_sync2 <= 1'b0;
      dst_req_sync3 <= 1'b0;
      dst_data_reg  <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      dst_ack       <= 1'b0;
    end else begin
      // Synchronize req
      dst_req_sync1 <= src_req;
      dst_req_sync2 <= dst_req_sync1;
      dst_req_sync3 <= dst_req_sync2;

      // Detect rising edge of req
      if (dst_req_sync2 && ~dst_req_sync3) begin
        // Latch data and set valid
        dst_data_reg  <= src_data_reg;
        dst_valid_reg <= 1'b1;
        dst_ack       <= 1'b1;
      end

      // Clear valid and ack when ready
      if (dst_valid_reg && dst_ready_i) begin
        dst_valid_reg <= 1'b0;
        dst_ack       <= 1'b0;
      end
    end
  end

  assign dst_data_o  = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
