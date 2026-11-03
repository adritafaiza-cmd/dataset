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

  // Source domain: hold payload and request signal
  reg [WIDTH-1:0] src_payload_reg;
  reg             src_req_reg;
  reg             src_ack_sync1;
  reg             src_ack_sync2;

  // Destination domain: synchronized request, payload, and ack
  reg             dst_req_sync1;
  reg             dst_req_sync2;
  reg [WIDTH-1:0] dst_payload_sync1;
  reg [WIDTH-1:0] dst_payload_sync2;
  reg [WIDTH-1:0] dst_payload_reg;
  reg             dst_ack_reg;
  reg             dst_valid_reg;

  // Source domain logic
  wire src_ack = src_ack_sync2;
  wire src_can_accept = ~src_req_reg | src_ack;

  assign src_ready_o = src_can_accept;

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_payload_reg <= {WIDTH{1'b0}};
      src_req_reg     <= 1'b0;
      src_ack_sync1   <= 1'b0;
      src_ack_sync2   <= 1'b0;
    end else begin
      // Synchronize ack from destination domain
      src_ack_sync1 <= dst_ack_reg;
      src_ack_sync2 <= src_ack_sync1;

      // Accept new data when valid and ready
      if (src_valid_i && src_can_accept) begin
        src_payload_reg <= src_data_i;
        src_req_reg     <= 1'b1;
      end else if (src_req_reg && src_ack) begin
        // Ack received, clear request
        src_req_reg <= 1'b0;
      end
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_req_sync1    <= 1'b0;
      dst_req_sync2    <= 1'b0;
      dst_payload_sync1 <= {WIDTH{1'b0}};
      dst_payload_sync2 <= {WIDTH{1'b0}};
      dst_payload_reg  <= {WIDTH{1'b0}};
      dst_ack_reg      <= 1'b0;
      dst_valid_reg    <= 1'b0;
    end else begin
      // Synchronize request from source domain
      dst_req_sync1 <= src_req_reg;
      dst_req_sync2 <= dst_req_sync1;

      // Synchronize payload (must be stable when req is high)
      dst_payload_sync1 <= src_payload_reg;
      dst_payload_sync2 <= dst_payload_sync1;

      // When request is detected and not already valid, capture payload
      if (dst_req_sync2 && !dst_valid_reg) begin
        dst_payload_reg <= dst_payload_sync2;
        dst_valid_reg   <= 1'b1;
        dst_ack_reg     <= 1'b1;
      end else if (dst_valid_reg && dst_ready_i) begin
        // Transfer complete, clear valid and ack
        dst_valid_reg <= 1'b0;
        dst_ack_reg   <= 1'b0;
      end
    end
  end

  assign dst_data_o  = dst_payload_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
