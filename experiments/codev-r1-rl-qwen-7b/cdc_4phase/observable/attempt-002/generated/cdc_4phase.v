module cdc_4phase #(
  parameter WIDTH = 1,
  parameter DECOUPLED = 1,
  parameter SEND_RESET_MSG = 0,
  parameter [WIDTH-1:0] RESET_MSG = {WIDTH{1'b0}}
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
  reg src_req;
  reg [WIDTH-1:0] src_data_reg;

  // Synchronizers for ack
  reg dst_ack_sync1, dst_ack_sync2;

  // Synchronize ack from destination
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ack_sync1 <= 0;
      dst_ack_sync2 <= 0;
    end else begin
      dst_ack_sync1 <= dst_ack;
      dst_ack_sync2 <= dst_ack_sync1;
    end
  end

  // Generate src_req and data_reg
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_req <= 0;
      src_data_reg <= RESET_MSG;
    end else begin
      if (SEND_RESET_MSG && !src_req) begin
        src_req <= 1;
        src_data_reg <= RESET_MSG;
      end else if (src_valid_i && src_ready_o) begin
        src_req <= 1;
        src_data_reg <= src_data_i;
      end else if (src_req && dst_ack_sync2) begin
        src_req <= 0;
      end
    end
  end

  assign src_ready_o = !src_req;

  // Destination domain signals
  reg src_req_sync1, src_req_sync2;
  reg dst_ack;
  reg [WIDTH-1:0] dst_data_reg;

  // Synchronize src_req
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_req_sync1 <= 0;
      src_req_sync2 <= 0;
    end else begin
      src_req_sync1 <= src_req;
      src_req_sync2 <= src_req_sync1;
    end
  end

  // Capture data and generate ack
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ack <= 0;
      dst_data_reg <= RESET_MSG;
    end else begin
      if (src_req_sync2 && !dst_ack && dst_ready_i) begin
        dst_data_reg <= src_data_reg;
        dst_ack <= 1;
      end else if (!src_req_sync2 && dst_ack) begin
        dst_ack <= 0;
      end
    end
  end

  // Assign outputs
  assign dst_valid_o = dst_ack;
  assign dst_data_o = dst_data_reg;

endmodule
