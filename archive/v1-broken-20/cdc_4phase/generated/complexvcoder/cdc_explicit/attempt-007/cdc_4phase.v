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
  logic [WIDTH-1:0] dst_data_reg;
  logic src_valid_reg;
  logic dst_ready_reg;
  logic reset_flag;

  // Source FIFO
  logic src_fif_full;
  logic src_fif_empty;
  logic src_fif_read;

  // Destination FIFO
  logic dst_fif_full;
  logic dst_fif_empty;
  logic dst_fif_write;

  // Handshake signals
  logic handshake_ready;
  logic handshake_valid;

  // Reset handler
  logic reset_handshake;

  // Instantiate FIFOs
  fifo #(.WIDTH(WIDTH)) src_fif (
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .data_i(src_data_i),
    .valid_i(src_valid_i),
    .ready_o(src_ready_o),
    .full_o(src_fif_full),
    .empty_o(src_fif_empty),
    .read_o(src_fif_read),
    .data_o(src_data_reg)
  );

  fifo #(.WIDTH(WIDTH)) dst_fif (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .data_i(dst_data_reg),
    .valid_i(handshake_valid),
    .ready_o(handshake_ready),
    .full_o(dst_fif_full),
    .empty_o(dst_fif_empty),
    .read_o(dst_fif_write),
    .data_o(dst_data_o)
  );

  // Handshake logic
  assign handshake_valid = ~src_fif_empty & dst_ready_i;
  assign handshake_ready = ~dst_fif_full & src_valid_reg;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
    end else begin
      src_valid_reg <= src_valid_i & handshake_ready;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_reg <= 1'b0;
    end else begin
      dst_ready_reg <= dst_ready_i & handshake_valid;
    end
  end

  // Reset handler
  reset_handler #(.WIDTH(WIDTH), .SEND_RESET_MSG(SEND_RESET_MSG), .RESET_MSG(RESET_MSG)) reset_handler_inst (
    .src_rst_ni(src_rst_ni),
    .dst_rst_ni(dst_rst_ni),
    .send_reset_msg(SEND_RESET_MSG),
    .reset_msg(RESET_MSG),
    .reset_flag(reset_flag)
  );

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_o <= 1'b1;
    end else begin
      src_ready_o <= ~src_fif_full & handshake_ready;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_o <= 1'b0;
    end else begin
      dst_valid_o <= ~dst_fif_empty & handshake_valid;
    end
  end

endmodule
