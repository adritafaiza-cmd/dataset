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

  // Source domain registers
  reg [WIDTH-1:0] data_reg;
  reg src_valid_reg;
  reg ack_sync1, ack_sync2;

  // Destination domain registers
  reg [WIDTH-1:0] data_reg_dst;
  reg dst_valid_reg;
  reg src_valid_sync1, src_valid_sync2;
  reg dst_ack_reg;

  // Synchronize ack from destination to source domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      ack_sync1 <= 0;
      ack_sync2 <= 0;
    end else begin
      ack_sync1 <= dst_ack_reg;
      ack_sync2 <= ack_sync1;
    end
  end

  // Source domain ready logic
  generate
    if (DECOUPLED) begin
      assign src_ready_o = 1;
    end else begin
      assign src_ready_o = !src_valid_reg;
    end
  endgenerate

  // Source domain data capture
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 0;
      data_reg <= 0;
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_valid_reg <= 1;
        data_reg <= src_data_i;
      end else if (ack_sync2) begin
        src_valid_reg <= 0;
      end
    end
  end

  // Synchronize src_valid_reg to destination domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync1 <= 0;
      src_valid_sync2 <= 0;
    end else begin
      src_valid_sync1 <= src_valid_reg;
      src_valid_sync2 <= src_valid_sync1;
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      if (SEND_RESET_MSG) begin
        data_reg_dst <= RESET_MSG;
        dst_valid_reg <= 1;
      end else begin
        data_reg_dst <= 0;
        dst_valid_reg <= 0;
      end
      dst_ack_reg <= 0;
    end else begin
      dst_ack_reg <= 0;
      // Capture data from source domain
      if (src_valid_sync2 && !dst_valid_reg) begin
        data_reg_dst <= data_reg;
        dst_valid_reg <= 1;
      end
      // Read data and send ack
      if (dst_valid_reg && dst_ready_i) begin
        dst_valid_reg <= 0;
        dst_ack_reg <= 1;
      end
    end
  end

  // Output assignments
  assign dst_data_o = data_reg_dst;
  assign dst_valid_o = dst_valid_reg;

endmodule
