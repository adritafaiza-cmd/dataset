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
  logic fifo_full;
  logic fifo_empty;
  logic [WIDTH-1:0] fifo_data;
  logic rd_en;
  logic reset_handshake;

  // Submodule instances
  sync_fifo #(
    .WIDTH(WIDTH)
  ) fifo (
    .clk(src_clk_i),
    .rst_ni(src_rst_ni),
    .wr_en(src_valid_i),
    .wr_data(src_data_i),
    .rd_en(dst_ready_i),
    .fifo_full(fifo_full),
    .fifo_empty(fifo_empty),
    .fifo_data(fifo_data)
  );

  reset_handler #(
    .WIDTH(WIDTH),
    .SEND_RESET_MSG(SEND_RESET_MSG),
    .RESET_MSG(RESET_MSG)
  ) reset_handler (
    .clk(src_clk_i),
    .rst_ni(src_rst_ni),
    .reset_handshake(reset_handshake)
  );

  // Assignments
  assign src_ready_o = fifo_full || !DECOUPLED || reset_handshake;
  assign dst_valid_o = !fifo_empty;
  assign dst_data_o = fifo_data;

endmodule

module sync_fifo #(
  parameter WIDTH = 1
)(
  input  clk,
  input  rst_ni,
  input  wr_en,
  input  [WIDTH-1:0] wr_data,
  input  rd_en,
  output fifo_full,
  output fifo_empty,
  output reg [WIDTH-1:0] fifo_data
);

  // Internal signals
  logic [WIDTH-1:0] mem [0:1];
  reg [1:0] wr_ptr, rd_ptr;

  // FIFO logic
  always_ff @(posedge clk or negedge rst_ni) begin
    if (!rst_ni) begin
      wr_ptr <= 0;
      rd_ptr <= 0;
      fifo_full <= 0;
      fifo_empty <= 1;
      fifo_data <= 0;
    end else begin
      if (wr_en && !fifo_full) begin
        mem[wr_ptr] <= wr_data;
        wr_ptr <= wr_ptr + 1;
        fifo_full <= (wr_ptr == rd_ptr);
        fifo_empty <= 0;
      end else if (rd_en && !fifo_empty) begin
        fifo_data <= mem[rd_ptr];
        rd_ptr <= rd_ptr + 1;
        fifo_full <= 0;
        fifo_empty <= (wr_ptr == rd_ptr);
      end
    end
  end

endmodule

module reset_handler #(
  parameter WIDTH = 1,
  parameter SEND_RESET_MSG = 0,
  parameter [WIDTH-1:0] RESET_MSG = {WIDTH{1'b0}}
)(
  input  clk,
  input  rst_ni,
  output reset_handshake
);

  // Internal signals
  logic rst_reg;

  // Reset handling logic
  always_ff @(posedge clk or negedge rst_ni) begin
    if (!rst_ni) begin
      rst_reg <= 0;
      reset_handshake <= 0;
    end else begin
      rst_reg <= rst_ni;
      if (!rst_ni) begin
        reset_handshake <= SEND_RESET_MSG ? 1 : 0;
      end else begin
        reset_handshake <= 0;
      end
    end
  end

endmodule
