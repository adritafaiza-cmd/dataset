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
  wire [WIDTH-1:0] src_fifo_dout;
  wire src_fifo_full;
  wire src_fifo_empty;
  wire [WIDTH-1:0] dst_fifo_din;
  wire dst_fifo_full;
  wire dst_fifo_empty;
  wire src_clear_reg_dout;
  wire dst_clear_reg_dout;

  // Synchronous FIFO for data transfer
  sync_fifo #(
    .WIDTH(WIDTH),
    .DEPTH(2**SYNC_STAGES)
  ) src_fifo (
    .clk(src_clk_i),
    .rst_n(src_rst_ni),
    .din(src_data_i),
    .wr_en(src_valid_i & ~src_clear_i),
    .rd_en(dst_valid_o & dst_ready_i),
    .dout(src_fifo_dout),
    .full(src_fifo_full),
    .empty(src_fifo_empty)
  );

  // Synchronous register for clear signal
  sync_reg #(
    .WIDTH(1)
  ) src_clear_reg (
    .clk(src_clk_i),
    .rst_n(src_rst_ni),
    .din(src_clear_i),
    .dout(src_clear_reg_dout)
  );

  sync_reg #(
    .WIDTH(1)
  ) dst_clear_reg (
    .clk(dst_clk_i),
    .rst_n(dst_rst_ni),
    .din(dst_clear_i),
    .dout(dst_clear_reg_dout)
  );

  // Handshake signals
  assign src_ready_o = ~src_fifo_full;
  assign dst_valid_o = ~src_fifo_empty;

  // Clear pending output
  assign src_clear_pending_o = src_clear_reg_dout;
  assign dst_clear_pending_o = dst_clear_reg_dout;

endmodule

module sync_fifo #(
  parameter WIDTH = 1,
  parameter DEPTH = 16
)(
  input  clk,
  input  rst_n,
  input  [WIDTH-1:0] din,
  input  wr_en,
  input  rd_en,
  output reg [WIDTH-1:0] dout,
  output reg full,
  output reg empty
);

  reg [WIDTH-1:0] mem [0:DEPTH-1];
  reg [4:0] wr_ptr;
  reg [4:0] rd_ptr;
  reg [4:0] count;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 0;
      rd_ptr <= 0;
      count <= 0;
      full <= 0;
      empty <= 1;
    end else begin
      if (wr_en && !full) begin
        mem[wr_ptr] <= din;
        wr_ptr <= wr_ptr + 1;
        count <= count + 1;
        if (count == DEPTH - 1) full <= 1;
        empty <= 0;
      end
      if (rd_en && !empty) begin
        dout <= mem[rd_ptr];
        rd_ptr <= rd_ptr + 1;
        count <= count - 1;
        if (count == 0) empty <= 1;
        full <= 0;
      end
    end
  end

endmodule

module sync_reg #(
  parameter WIDTH = 1
)(
  input  clk,
  input  rst_n,
  input  [WIDTH-1:0] din,
  output reg [WIDTH-1:0] dout
);

  reg [WIDTH-1:0] q;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      q <= 0;
    end else begin
      q <= din;
    end
  end

  assign dout = q;

endmodule
