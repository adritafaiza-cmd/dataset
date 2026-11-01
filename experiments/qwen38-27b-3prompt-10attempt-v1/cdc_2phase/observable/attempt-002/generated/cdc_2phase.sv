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
  // Destination side: release when ready
  // Use a 2-phase handshake: request (src->dst) and ack (dst->src)
  // Each signal is synchronized to the other clock domain.

  // Source domain registers
  reg [WIDTH-1:0] src_data_reg;
  reg             src_req;       // request to destination
  reg             src_ack_sync;  // synchronized ack from destination
  reg             src_ack_d;     // previous ack for edge detection

  // Destination domain registers
  reg [WIDTH-1:0] dst_data_reg;
  reg             dst_ack;       // acknowledge to source
  reg             dst_req_sync;  // synchronized request from source
  reg             dst_req_d;     // previous request for edge detection

  // Synchronizers: 2-flop synchronizers for each crossing signal

  // src_req crosses from src_clk to dst_clk
  reg [1:0] req_sync_ff;
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      req_sync_ff <= 2'b00;
    else
      req_sync_ff <= {req_sync_ff[0], src_req};
  end
  wire dst_req_sync = req_sync_ff[1];

  // dst_ack crosses from dst_clk to src_clk
  reg [1:0] ack_sync_ff;
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      ack_sync_ff <= 2'b00;
    else
      ack_sync_ff <= {ack_sync_ff[0], dst_ack};
  end
  wire src_ack_sync = ack_sync_ff[1];

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_req      <= 1'b0;
      src_ack_d    <= 1'b0;
    end else begin
      // Detect rising edge of ack
      if (src_ack_sync && !src_ack_d) begin
        // Ack received, clear request
        src_req <= 1'b0;
      end else if (src_valid_i && !src_req) begin
        // New valid data, no pending request
        src_data_reg <= src_data_i;
        src_req      <= 1'b1;
      end
      src_ack_d <= src_ack_sync;
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= {WIDTH{1'b0}};
      dst_ack      <= 1'b0;
      dst_req_d    <= 1'b0;
    end else begin
      // Detect rising edge of request
      if (dst_req_sync && !dst_req_d) begin
        // New request, capture data and acknowledge
        dst_data_reg <= src_data_reg;
        dst_ack      <= 1'b1;
      end else if (dst_ack && dst_ready_i) begin
        // Data consumed, clear ack
        dst_ack <= 1'b0;
      end
      dst_req_d <= dst_req_sync;
    end
  end

  // Outputs
  assign src_ready_o = !src_req;
  assign dst_data_o  = dst_data_reg;
  assign dst_valid_o = dst_ack;

endmodule
