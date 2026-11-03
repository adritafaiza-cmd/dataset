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

  // Internal signals
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  reg src_ready_reg;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  reg dst_ready_reg;
  reg handshake_reg;

  // Source clock domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= 0;
      src_valid_reg <= 0;
      src_ready_reg <= 0;
      handshake_reg <= 0;
    end else begin
      if (src_ready_reg && src_valid_i) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1;
      end else if (handshake_reg && dst_ready_i) begin
        src_valid_reg <= 0;
      end
      if (src_rst_ni) begin
        src_ready_o <= 0;
      end else if (handshake_reg && dst_ready_i) begin
        src_ready_o <= 0;
      end else begin
        src_ready_o <= 1;
      end
    end
  end

  // Destination clock domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= 0;
      dst_valid_reg <= 0;
      dst_ready_reg <= 0;
    end else begin
      if (dst_valid_o && dst_ready_i) begin
        dst_valid_reg <= 0;
      end
      if (dst_ready_i && !dst_valid_reg) begin
        dst_data_reg <= src_data_reg;
        dst_valid_reg <= 1;
      end
      if (dst_ready_i && handshake_reg) begin
        dst_valid_reg <= 1;
      end
      if (dst_ready_i && !handshake_reg && src_valid_i) begin
        dst_valid_reg <= 0;
      end
    end
  end

endmodule
