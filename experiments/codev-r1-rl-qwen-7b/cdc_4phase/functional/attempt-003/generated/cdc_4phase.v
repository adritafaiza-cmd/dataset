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
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  reg ack_sync1, ack_sync2;

  // Synchronizers for ack from destination to source
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      ack_sync1 <= 0;
      ack_sync2 <= 0;
    end else begin
      ack_sync1 <= dst_ack;
      ack_sync2 <= ack_sync1;
    end
  end

  // Source ready logic
  generate if (DECOUPLED) begin
    assign src_ready_o = 1;
  end else begin
    assign src_ready_o = !src_valid_reg || ack_sync2;
  end endgenerate

  // Capture data when handshake occurs
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 0;
      src_data_reg <= RESET_MSG;
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1;
      end else if (ack_sync2) begin
        src_valid_reg <= 0;
      end
    end
  end

  // Synchronize src_valid_reg to destination domain
  reg rqst_sync1, rqst_sync2;
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      rqst_sync1 <= 0;
      rqst_sync2 <= 0;
    end else begin
      rqst_sync1 <= src_valid_reg;
      rqst_sync2 <= rqst_sync1;
    end
  end

  // Destination domain signals
  reg dst_ack;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;

  // Generate ack when data is read
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ack <= 0;
    end else begin
      dst_ack <= dst_valid_o && dst_ready_i;
    end
  end

  // Handle SEND_RESET_MSG and normal operation
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 0;
      dst_data_reg <= RESET_MSG;
    end else begin
      if (SEND_RESET_MSG) begin
        // After reset, send RESET_MSG once
        if (!dst_valid_reg) begin
          dst_valid_reg <= 1;
          dst_data_reg <= RESET_MSG;
        end
      end else begin
        if (dst_valid_reg && dst_ready_i) begin
          dst_valid_reg <= 0;
        end else if (rqst_sync2 && !dst_valid_reg) begin
          dst_valid_reg <= 1;
          dst_data_reg <= src_data_reg;
        end
      end
    end
  end

  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o = dst_data_reg;

endmodule
