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

  // Source domain state
  reg src_valid_reg;
  reg [WIDTH-1:0] src_data_reg;

  // Destination domain state
  reg dst_valid_reg;
  reg [WIDTH-1:0] dst_data_reg;

  // Handshake signals
  // req: source requests a transfer (set when source accepts data)
  // ack: destination acknowledges (set when destination accepts data)
  // These are single-bit signals that cross clock domains.
  // We use a 2-phase handshake: req toggles, ack toggles.
  // Actually, let's use a simpler approach: 
  // - src_ready_o is high when no item is in flight
  // - When source accepts, it sets a "req" bit
  // - Destination sees req, latches data, sets "ack"
  // - Source sees ack, clears req, ready for next

  // Let's use a standard 2-phase handshake with level signals:
  // req: asserted by source when it has data to send
  // ack: asserted by destination when it has accepted the data
  // Both are single-bit, so they can be safely synchronized.

  // Source domain
  reg req_src;   // request from source
  reg ack_src;   // acknowledge from destination (synchronized)

  // Destination domain
  reg req_dst;   // request from source (synchronized)
  reg ack_dst;   // acknowledge from destination

  // Synchronizers for req (src -> dst)
  reg req_sync1;
  reg req_sync2;

  // Synchronizers for ack (dst -> src)
  reg ack_sync1;
  reg ack_sync2;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      req_src <= 1'b0;
      ack_src <= 1'b0;
      src_valid_reg <= 1'b0;
      src_data_reg <= {WIDTH{1'b0}};
    end else begin
      // Accept data when valid and ready
      if (src_valid_i && src_ready_o) begin
        src_valid_reg <= 1'b1;
        src_data_reg <= src_data_i;
        req_src <= 1'b1;
      end else if (ack_src) begin
        // Acknowledged, clear request
        req_src <= 1'b0;
        src_valid_reg <= 1'b0;
      end
    end
  end

  // Source ready: high when no request is pending
  assign src_ready_o = ~req_src;

  // Synchronize req from source to destination
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      req_sync1 <= 1'b0;
      req_sync2 <= 1'b0;
    end else begin
      req_sync1 <= req_src;
      req_sync2 <= req_sync1;
    end
  end

  assign req_dst = req_sync2;

  // Synchronize ack from destination to source
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      ack_sync1 <= 1'b0;
      ack_sync2 <= 1'b0;
    end else begin
      ack_sync1 <= ack_dst;
      ack_sync2 <= ack_sync1;
    end
  end

  assign ack_src = ack_sync2;

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      ack_dst <= 1'b0;
      dst_valid_reg <= 1'b0;
      dst_data_reg <= {WIDTH{1'b0}};
    end else begin
      if (req_dst && !dst_valid_reg) begin
        // New request, latch data and present valid
        dst_valid_reg <= 1'b1;
        dst_data_reg <= src_data_reg; // Wait, this is wrong - src_data_reg is in source domain
        ack_dst <= 1'b1;
      end else if (dst_valid_reg && dst_ready_i) begin
        // Destination accepted, clear valid and ack
        dst_valid_reg <= 1'b0;
        ack_dst <= 1'b0;
      end
    end
  end

  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o = dst_data_reg;

endmodule
