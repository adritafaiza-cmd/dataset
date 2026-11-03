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
  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic [2:0] phase;
  logic [WIDTH-1:0] dst_data_reg;

  // Reset handling
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_o <= 1'b0;
      phase <= 3'b000;
    end else begin
      src_ready_o <= (phase == 3'b001);
      if (src_valid_i && src_ready_o) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1'b1;
        phase <= 3'b001;
      end
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_o <= 1'b0;
      dst_data_o <= RESET_MSG;
    end else begin
      if (SEND_RESET_MSG) begin
        dst_valid_o <= 1'b1;
        dst_data_o <= RESET_MSG;
      end else begin
        dst_valid_o <= (phase == 3'b010);
        if (dst_valid_o && dst_ready_i) begin
          phase <= 3'b010;
        end
      end
    end
  end

  // Handshake logic
  always_ff @(posedge src_clk_i) begin
    if (src_valid_reg && dst_ready_reg && phase == 3'b001) begin
      dst_valid_reg <= 1'b1;
      dst_data_reg <= src_data_reg;
      phase <= 3'b010;
    end else if (dst_valid_reg && dst_ready_i && phase == 3'b010) begin
      dst_valid_reg <= 1'b0;
      phase <= 3'b011;
    end else if (phase == 3'b011) begin
      phase <= 3'b000;
    end
  end

  // Output logic
  assign dst_data_o = (phase == 3'b010) ? dst_data_reg : RESET_MSG;
  assign dst_ready_reg = (phase == 3'b010) && dst_ready_i;

endmodule
