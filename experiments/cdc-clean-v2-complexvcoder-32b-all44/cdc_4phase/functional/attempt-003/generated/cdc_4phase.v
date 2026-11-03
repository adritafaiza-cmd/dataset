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

  // Internal signals
  reg [WIDTH-1:0] src_data_ff;
  reg src_valid_ff;
  reg src_ready_ff;
  reg [WIDTH-1:0] dst_data_ff;
  reg dst_valid_ff;
  reg src_reset_msg_sent;
  reg dst_reset_msg_sent;

  // Source clock domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_ff <= {WIDTH{1'b0}};
      src_valid_ff <= 0;
      src_ready_ff <= 0;
      src_reset_msg_sent <= 0;
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_data_ff <= src_data_i;
        src_valid_ff <= 1;
        src_ready_ff <= 0;
      end
      if (DECOUPLED || src_ready_ff) begin
        src_ready_o <= 1;
      end else begin
        src_ready_o <= 0;
      end
      if (SEND_RESET_MSG && !src_reset_msg_sent) begin
        src_data_ff <= RESET_MSG;
        src_valid_ff <= 1;
        src_reset_msg_sent <= 1;
      end
    end
  end

  // Destination clock domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_ff <= {WIDTH{1'b0}};
      dst_valid_ff <= 0;
      dst_reset_msg_sent <= 0;
    end else begin
      if (dst_valid_ff && dst_ready_i) begin
        dst_valid_ff <= 0;
        dst_reset_msg_sent <= 0;
      end
      if (!dst_valid_ff || !dst_ready_i) begin
        if (src_valid_ff) begin
          dst_data_ff <= src_data_ff;
          dst_valid_ff <= 1;
          src_valid_ff <= 0;
        end
      end
      if (SEND_RESET_MSG && !dst_reset_msg_sent && !src_valid_ff) begin
        dst_data_ff <= RESET_MSG;
        dst_valid_ff <= 1;
        dst_reset_msg_sent <= 1;
      end
    end
  end

  // Outputs
  assign dst_data_o = dst_data_ff;
  assign dst_valid_o = dst_valid_ff;

endmodule
