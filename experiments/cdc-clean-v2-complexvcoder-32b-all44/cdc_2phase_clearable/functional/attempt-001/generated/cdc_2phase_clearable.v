module cdc_2phase_clearable #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3,
  parameter CLEAR_ON_ASYNC_RESET = 1
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  src_clear_i,
  output src_clear_pending_o,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,
  input  dst_rst_ni,
  input  dst_clk_i,
  input  dst_clear_i,
  output dst_clear_pending_o,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);

  // Internal signals
  logic src_rst_sync_o;
  logic dst_rst_sync_o;
  logic fifo_clear_i;
  logic fifo_clear_o;

  // Instantiate async_reset_synchronizer for source reset to destination clock domain
  async_reset_synchronizer #(
    .SYNC_STAGES(SYNC_STAGES)
  ) src_rst_sync (
    .async_in(src_rst_ni),
    .clk(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .async_out(src_rst_sync_o)
  );

  // Instantiate async_reset_synchronizer for destination reset to source clock domain
  async_reset_synchronizer #(
    .SYNC_STAGES(SYNC_STAGES)
  ) dst_rst_sync (
    .async_in(dst_rst_ni),
    .clk(src_clk_i),
    .rst_ni(src_rst_ni),
    .async_out(dst_rst_sync_o)
  );

  // Instantiate sync_fifo for data and handshake signals synchronization
  sync_fifo #(
    .WIDTH(WIDTH),
    .DEPTH(1),
    .SYNC_STAGES(SYNC_STAGES)
  ) fifo (
    .clk(src_clk_i),
    .rst_ni(src_rst_ni),
    .data_in(src_data_i),
    .valid_in(src_valid_i),
    .ready_out(src_ready_o),
    .clk_out(dst_clk_i),
    .rst_ni_out(dst_rst_sync_o),
    .data_out(dst_data_o),
    .valid_out(dst_valid_o),
    .ready_in(dst_ready_i),
    .clear_i(fifo_clear_i),
    .clear_o(fifo_clear_o)
  );

  // Instantiate clear_logic for source domain
  clear_logic src_clear_logic (
    .clk(src_clk_i),
    .rst_ni(src_rst_ni),
    .clear_i(src_clear_i),
    .clear_pending_o(src_clear_pending_o),
    .fifo_clear_i(fifo_clear_o),
    .fifo_clear_o(fifo_clear_i)
  );

  // Instantiate clear_logic for destination domain
  clear_logic dst_clear_logic (
    .clk(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .clear_i(dst_clear_i),
    .clear_pending_o(dst_clear_pending_o),
    .fifo_clear_i(fifo_clear_i),
    .fifo_clear_o(fifo_clear_o)
  );

endmodule

module async_reset_synchronizer #(
  parameter SYNC_STAGES = 3
)(
  input  async_in,
  input  clk,
  input  rst_ni,
  output async_out
);

  logic [SYNC_STAGES-1:0] sync_chain;

  always_ff @(posedge clk or negedge rst_ni) begin
    if (!rst_ni) begin
      sync_chain <= '0;
    end else begin
      sync_chain[0] <= async_in;
      for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
        sync_chain[i] <= sync_chain[i-1];
      end
    end
  end

  assign async_out = sync_chain[SYNC_STAGES-1];

endmodule

module sync_fifo #(
  parameter WIDTH = 1,
  parameter DEPTH = 1,
  parameter SYNC_STAGES = 3
)(
  input  clk,
  input  rst_ni,
  input  [WIDTH-1:0] data_in,
  input  valid_in,
  output ready_out,
  input  clk_out,
  input  rst_ni_out,
  output [WIDTH-1:0] data_out,
  output valid_out,
  input  ready_in,
  input  clear_i,
  input  clear_o
);

  logic [WIDTH-1:0] data_reg;
  logic valid_reg;
  logic ready_reg;

  // Source side logic
  always_ff @(posedge clk or negedge rst_ni) begin
    if (!rst_ni) begin
      data_reg <= '0;
      valid_reg <= 0;
    end else if (clear_i) begin
      data_reg <= '0;
      valid_reg <= 0;
    end else if (valid_in && ready_reg) begin
      data_reg <= data_in;
      valid_reg <= 1;
    end else if (ready_in) begin
      valid_reg <= 0;
    end
  end

  assign ready_out = !valid_reg || (ready_in && valid_in);

  // Destination side logic
  always_ff @(posedge clk_out or negedge rst_ni_out) begin
    if (!rst_ni_out) begin
      data_out <= '0;
      valid_out <= 0;
    end else if (clear_o) begin
      data_out <= '0;
      valid_out <= 0;
    end else if (valid_reg) begin
      data_out <= data_reg;
      valid_out <= 1;
    end else if (ready_in) begin
      valid_out <= 0;
    end
  end

  assign ready_reg = !valid_out || (ready_in && valid_in);

endmodule

module clear_logic (
  input  clk,
  input  rst_ni,
  input  clear_i,
  output clear_pending_o,
  input  fifo_clear_i,
  output fifo_clear_o
);

  logic clear_pending_reg;

  always_ff @(posedge clk or negedge rst_ni) begin
    if (!rst_ni) begin
      clear_pending_reg <= 0;
      fifo_clear_o <= 0;
    end else if (clear_i) begin
      clear_pending_reg <= 1;
      fifo_clear_o <= 1;
    end else if (fifo_clear_i) begin
      clear_pending_reg <= 0;
      fifo_clear_o <= 0;
    end
  end

  assign clear_pending_o = clear_pending_reg;

endmodule
