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

  // Internal signals for the four-phase handshake
  reg [1:0] phase_src;
  reg [1:0] phase_dst;

  // FIFO signals
  reg [WIDTH-1:0] fifo_data;
  reg fifo_valid;
  reg fifo_ready;

  // Data and control registers for crossing the clock domains
  reg [WIDTH-1:0] data_reg;
  reg valid_reg;
  reg ready_reg;

  // Source side logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      phase_src <= 2'b00;
      src_ready_o <= 1'b0;
      fifo_data <= RESET_MSG;
      fifo_valid <= 1'b0;
    end else begin
      // Update phase
      if (fifo_ready && src_valid_i) begin
        phase_src <= phase_src + 1'b1;
      end

      // Update FIFO
      if (fifo_ready && src_valid_i) begin
        fifo_data <= src_data_i;
        fifo_valid <= 1'b1;
      end

      // Update ready signal
      src_ready_o <= fifo_ready;
    end
  end

  // FIFO logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      phase_dst <= 2'b00;
      fifo_ready <= 1'b0;
      data_reg <= RESET_MSG;
      valid_reg <= 1'b0;
      ready_reg <= 1'b0;
    end else begin
      // Update phase
      if (valid_reg && dst_ready_i) begin
        phase_dst <= phase_dst + 1'b1;
      end

      // Update FIFO ready signal
      fifo_ready <= (phase_src != phase_dst);

      // Update data and valid signals for destination
      if (fifo_valid && (phase_src == phase_dst)) begin
        data_reg <= fifo_data;
        valid_reg <= 1'b1;
        fifo_valid <= 1'b0;
      end

      // Update ready signal
      ready_reg <= (phase_src != phase_dst);
    end
  end

  // Destination side logic
  assign dst_data_o = data_reg;
  assign dst_valid_o = valid_reg;

endmodule
