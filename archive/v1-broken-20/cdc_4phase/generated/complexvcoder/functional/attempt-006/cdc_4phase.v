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
  logic src_ready_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_next;
  logic dst_ready_next;
  logic src_ready_next;
  logic reset_msg_valid;

  // Source register
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 0;
      src_ready_reg <= 0;
    end else begin
      src_data_reg <= src_data_i;
      src_valid_reg <= src_valid_i;
      src_ready_reg <= src_ready_next;
    end
  end

  // Destination register
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 0;
      dst_ready_reg <= 0;
    end else begin
      dst_data_reg <= dst_data_next;
      dst_valid_reg <= dst_valid_next;
      dst_ready_reg <= dst_ready_i;
    end
  end

  // Next state logic
  always_comb begin
    src_ready_next = 0;
    dst_valid_next = 0;
    dst_data_next = {WIDTH{1'b0}};

    if (src_valid_i && src_ready_reg) begin
      dst_valid_next = 1;
      dst_data_next = src_data_i;
    end

    if (dst_valid_reg && dst_ready_i) begin
      dst_valid_next = 0;
    end

    if (!src_rst_ni || !dst_rst_ni) begin
      src_ready_next = 0;
      dst_valid_next = 0;
    end

    if (SEND_RESET_MSG && !dst_rst_ni) begin
      dst_valid_next = 1;
      dst_data_next = RESET_MSG;
    end

    if (!DECOUPLED) begin
      src_ready_next = dst_ready_reg;
    end
  end

  // Output logic
  assign src_ready_o = src_ready_next;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
