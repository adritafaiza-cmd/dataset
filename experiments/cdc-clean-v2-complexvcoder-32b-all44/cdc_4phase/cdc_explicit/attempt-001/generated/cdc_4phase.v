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
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  reg src_ready_int;
  reg phase0, phase1, phase2, phase3;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  reg reset_msg_sent;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_ready_int <= 1'b0;
    end else begin
      if (src_valid_i && src_ready_int) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1'b1;
      end else if (dst_ready_i && dst_valid_o) begin
        src_valid_reg <= 1'b0;
      end
      if (DECOUPLED || !src_valid_reg) begin
        src_ready_int <= 1'b1;
      end else begin
        src_ready_int <= 1'b0;
      end
    end
  end

  assign src_ready_o = src_ready_int;

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      phase0 <= 1'b0;
      phase1 <= 1'b0;
      phase2 <= 1'b0;
      phase3 <= 1'b0;
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      reset_msg_sent <= 1'b0;
    end else begin
      phase0 <= src_valid_reg;
      phase1 <= phase0;
      phase2 <= phase1;
      phase3 <= phase2;

      if (phase3) begin
        dst_data_reg <= src_data_reg;
        dst_valid_reg <= 1'b1;
      end

      if (dst_ready_i && dst_valid_reg) begin
        dst_valid_reg <= 1'b0;
      end

      if (SEND_RESET_MSG && !dst_rst_ni && !reset_msg_sent) begin
        dst_data_reg <= RESET_MSG;
        dst_valid_reg <= 1'b1;
        reset_msg_sent <= 1'b1;
      end

      if (dst_ready_i && dst_valid_reg && (dst_data_reg == RESET_MSG)) begin
        reset_msg_sent <= 1'b0;
      end
    end
  end

  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
