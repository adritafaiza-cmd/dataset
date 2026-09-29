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
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  reg src_ready_reg;

  // Destination domain registers
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;

  // Synchronizers for destination's ready
  reg dst_ready_sync1, dst_ready_sync2;

  // Synchronizers for valid from source to destination
  reg src_valid_sync1, src_valid_sync2;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 0;
      src_data_reg <= SEND_RESET_MSG ? RESET_MSG : {WIDTH{1'b0}};
      dst_ready_sync1 <= 0;
      dst_ready_sync2 <= 0;
      src_valid_sync1 <= 0;
      src_valid_sync2 <= 0;
    end else begin
      // Synchronize dst_ready_i to source domain
      dst_ready_sync1 <= dst_ready_i;
      dst_ready_sync2 <= dst_ready_sync1;

      // Synchronize valid from destination to source
      src_valid_sync1 <= src_valid_reg;
      src_valid_sync2 <= src_valid_sync1;

      // Source logic
      if (src_valid_reg && dst_ready_sync2) begin
        // Deassert valid and ready
        src_valid_reg <= 0;
      end else if (src_valid_i && src_ready_o) begin
        // Capture data and set valid
        src_data_reg <= src_data_i;
        src_valid_reg <= 1;
      end
    end
  end

  // Determine src_ready_o based on DECOUPLED and state
  assign src_ready_o = DECOUPLED ? 1 : !src_valid_reg;

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 0;
      dst_data_reg <= SEND_RESET_MSG ? RESET_MSG : {WIDTH{1'b0}};
    end else begin
      // Capture data when valid is synchronized
      if (src_valid_sync2) begin
        dst_data_reg <= src_data_reg;
        dst_valid_reg <= 1;
      end else if (dst_valid_reg && dst_ready_i) begin
        dst_valid_reg <= 0;
      end
    end
  end

  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
