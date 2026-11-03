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

  // Source side: capture data when valid and ready
  // Destination side: present data when valid and ready
  // Use a 2-phase handshake with a single-bit toggle for CDC

  // Source side registers
  reg [WIDTH-1:0] src_data_reg;
  reg             src_valid_reg;
  reg             src_ready_reg;

  // Destination side registers
  reg [WIDTH-1:0] dst_data_reg;
  reg             dst_valid_reg;
  reg             dst_ready_reg;

  // CDC: use a 2-phase toggle signal
  // src_toggle: toggles on each transfer from source to dest
  // dst_toggle: toggles on each acknowledgment from dest to source

  // Source side: toggle when data is accepted
  reg src_toggle;
  reg src_toggle_next;

  // Destination side: toggle when data is acknowledged
  reg dst_toggle;
  reg dst_toggle_next;

  // Synchronize src_toggle to dst domain
  reg [1:0] src_toggle_sync;
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      src_toggle_sync <= 2'b00;
    else
      src_toggle_sync <= {src_toggle_sync[0], src_toggle};
  end

  // Synchronize dst_toggle to src domain
  reg [1:0] dst_toggle_sync;
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      dst_toggle_sync <= 2'b00;
    else
      dst_toggle_sync <= {dst_toggle_sync[0], dst_toggle};
  end

  // Source side logic
  // src_ready_o is high when we can accept new data
  // We can accept new data when:
  //   - Not currently holding valid data (src_valid_reg is 0), OR
  //   - The destination has acknowledged the previous transfer
  //
  // Actually, let's think more carefully. We have a single buffer on the source side.
  // src_valid_reg indicates we have data pending.
  // src_ready_o should be high when we don't have pending data, OR when the pending data has been acknowledged.
  //
  // Let's use a simpler approach:
  // - src_valid_reg: 1 when we have data to send
  // - src_ready_o: 1 when we can accept new data (i.e., no pending data, or pending data has been acked)
  //
  // The toggle mechanism:
  // - src_toggle toggles each time we send data
  // - dst_toggle toggles each time we acknowledge
  // - When src_toggle != dst_toggle (after sync), it means there's a pending transfer
  //
  // Let's redefine:
  // - src_valid_reg: 1 when we have data pending to be sent
  // - src_ready_o: 1 when src_valid_reg is 0 (no pending data)
  //
  // When src_valid_i && src_ready_o:
  //   - Capture data
  //   - Set src_valid_reg = 1
  //   - Toggle src_toggle
  //
  // On destination side:
  // - Detect change in src_toggle_sync
  // - When detected, capture data (but data needs to be stable)
  // - Set dst_valid_reg = 1
  // - Toggle dst_toggle
  //
  // When dst_valid_i && dst_ready_i:
  //   - Clear dst_valid_reg
  //   - Toggle dst_toggle (acknowledge)
  //
  // Source side:
  // - When dst_toggle_sync changes (ack received), clear src_valid_reg

  // Let's use edge detection on the synchronized toggles

  // Source side: detect ack from destination
  wire src_ack_edge;
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      src_ack_edge <= 1'b0;
    else
      src_ack_edge <= (dst_toggle_sync[1] != dst_toggle_sync[0]);
  end

  // Destination side: detect new data from source
  wire dst_data_edge;
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      dst_data_edge <= 1'b0;
    else
      dst_data_edge <= (src_toggle_sync[1] != src_toggle_sync[0]);
  end

  // Source side state machine
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg  <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_toggle    <= 1'b0;
    end else begin
      // If we have valid data and receive ack, clear valid
      if (src_valid_reg && src_ack_edge) begin
        src_valid_reg <= 1'b0;
      end
      // If we can accept new data and source is valid, capture it
      else if (!src_valid_reg && src_valid_i) begin
        src_data_reg  <= src_data_i;
        src_valid_reg <= 1'b1;
        src_toggle    <= ~src_toggle;
      end
    end
  end

  // Source ready: can accept new data when no pending data
  assign src_ready_o = !src_valid_reg;

  // Destination side state machine
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg  <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      dst_toggle    <= 1'b0;
    end else begin
      // If we have valid data and destination is ready, clear valid and ack
      if (dst_valid_reg && dst_ready_i) begin
        dst_valid_reg <= 1'b0;
        dst_toggle    <= ~dst_toggle;
      end
      // If we detect new data from source, capture it
      else if (dst_data_edge) begin
        dst_data_reg  <= src_data_reg;
        dst_valid_reg <= 1'b1;
      end
    end
  end

  // Destination outputs
  assign dst_data_o  = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
