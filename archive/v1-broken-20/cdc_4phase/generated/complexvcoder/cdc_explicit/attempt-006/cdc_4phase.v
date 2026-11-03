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
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic [1:0] src_phase;
  logic [1:0] dst_phase;
  logic src_reset_flag;
  logic dst_reset_flag;

  // Source domain logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b1;
      src_reset_flag <= 1'b1;
    end else begin
      src_data_reg <= src_data_i;
      src_valid_reg <= src_valid_i;
      src_ready_reg <= dst_ready_i;
      src_reset_flag <= 1'b0;
    end
  end

  // Destination domain logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      dst_ready_reg <= 1'b1;
      dst_reset_flag <= 1'b1;
    end else begin
      dst_data_reg <= src_data_reg;
      dst_valid_reg <= src_valid_reg;
      dst_ready_reg <= src_ready_reg;
      dst_reset_flag <= 1'b0;
    end
  end

  // Phase logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_phase <= 2'b00;
    end else begin
      src_phase <= src_phase + 1;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_phase <= 2'b00;
    end else begin
      dst_phase <= dst_phase + 1;
    end
  end

  // Output logic
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;
  assign src_ready_o = src_ready_reg;

  // Reset handling
  assign dst_ready_reg = SEND_RESET_MSG ? 1'b0 : dst_ready_i;
  assign src_ready_o = SEND_RESET_MSG ? 1'b0 : src_ready_reg;

endmodule
