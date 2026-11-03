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

  // Source domain state
  reg [WIDTH-1:0] src_data_reg;
  reg             src_valid_reg;
  reg             src_ack_reg;
  reg             src_ack_sync1;
  reg             src_ack_sync2;

  // Destination domain state
  reg [WIDTH-1:0] dst_data_reg;
  reg             dst_valid_reg;
  reg             dst_req_reg;
  reg             dst_req_sync1;
  reg             dst_req_sync2;

  // Synchronized signals
  wire src_ack_synced = src_ack_sync2;
  wire dst_req_synced = dst_req_sync2;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg  <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_ack_reg   <= 1'b0;
      src_ack_sync1 <= 1'b0;
      src_ack_sync2 <= 1'b0;
    end else begin
      src_ack_sync1 <= src_ack_sync2;
      src_ack_sync2 <= dst_req_synced;

      if (src_valid_i && src_ready_o) begin
        src_data_reg  <= src_data_i;
        src_valid_reg <= 1'b1;
        src_ack_reg   <= 1'b0;
      end else if (src_valid_reg && src_ack_synced) begin
        src_valid_reg <= 1'b0;
        src_ack_reg   <= 1'b1;
      end
    end
  end

  assign src_ready_o = !src_valid_reg || src_ack_synced;

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg  <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      dst_req_reg   <= 1'b0;
      dst_req_sync1 <= 1'b0;
      dst_req_sync2 <= 1'b0;
    end else begin
      dst_req_sync1 <= dst_req_sync2;
      dst_req_sync2 <= src_valid_reg;

      if (dst_valid_reg && dst_ready_i) begin
        dst_valid_reg <= 1'b0;
        dst_req_reg   <= 1'b1;
      end else if (!dst_valid_reg && dst_req_synced) begin
        dst_data_reg  <= src_data_reg;
        dst_valid_reg <= 1'b1;
        dst_req_reg   <= 1'b0;
      end
    end
  end

  assign dst_data_o  = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
