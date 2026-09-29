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
  reg dst_ready_sync1, dst_ready_sync2;

  // Destination domain signals
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  reg src_valid_sync1, src_valid_sync2;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 0;
      src_data_reg <= RESET_MSG;
      dst_ready_sync1 <= 0;
      dst_ready_sync2 <= 0;
    end else begin
      // Synchronize dst_ready_i
      dst_ready_sync1 <= dst_ready_i;
      dst_ready_sync2 <= dst_ready_sync1;

      if (src_valid_i && dst_ready_sync2) begin
        src_valid_reg <= 1;
        src_data_reg <= src_data_i;
      end else if (src_valid_reg && dst_ready_sync2) begin
        src_valid_reg <= 0;
      end
    end
  end

  assign src_ready_o = !src_valid_reg;

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 0;
      dst_data_reg <= RESET_MSG;
      src_valid_sync1 <= 0;
      src_valid_sync2 <= 0;
    end else begin
      // Synchronize src_valid_reg
      src_valid_sync1 <= src_valid_reg;
      src_valid_sync2 <= src_valid_sync1;

      if (src_valid_sync2 && dst_ready_i) begin
        dst_data_reg <= src_data_reg;
        dst_valid_reg <= 1;
      end else if (dst_ready_i) begin
        dst_valid_reg <= 0;
      end
    end
  end

  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o = dst_data_reg;

endmodule
