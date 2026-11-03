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
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic [WIDTH-1:0] dst_data_reg;
  logic src_ready_reg;
  logic fifo_read_en;
  logic fifo_write_en;
  logic fifo_empty;
  logic fifo_full;

  // FIFO
  fifo #(.WIDTH(WIDTH)) data_fifo (
    .data_in(src_data_i),
    .write_en(fifo_write_en),
    .read_en(fifo_read_en),
    .data_out(dst_data_o),
    .empty(fifo_empty),
    .full(fifo_full)
  );

  // Source handshake
  four_phase_handshake src_handshake (
    .valid_i(src_valid_i),
    .ready_o(src_ready_o)
  );

  // Destination handshake
  four_phase_handshake dst_handshake (
    .valid_i(dst_valid_o),
    .ready_o(dst_ready_i)
  );

  // Sync registers for clock domain crossing
  sync_reg valid_sync_src (
    .clk(src_clk_i),
    .rst_ni(src_rst_ni),
    .data_in(src_valid_i),
    .data_out(src_valid_reg)
  );

  sync_reg valid_sync_dst (
    .clk(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .data_in(dst_valid_o),
    .data_out(dst_valid_reg)
  );

  sync_reg ready_sync_src (
    .clk(src_clk_i),
    .rst_ni(src_rst_ni),
    .data_in(src_ready_i),
    .data_out(src_ready_reg)
  );

  sync_reg ready_sync_dst (
    .clk(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .data_in(dst_ready_i),
    .data_out(dst_ready_reg)
  );

  sync_reg data_sync_src (
    .clk(src_clk_i),
    .rst_ni(src_rst_ni),
    .data_in(src_data_i),
    .data_out(src_data_reg)
  );

  // Handshake logic
  assign fifo_write_en = src_ready_reg && src_valid_reg && !fifo_full;
  assign fifo_read_en = dst_valid_reg && dst_ready_reg && !fifo_empty;

  // Output logic
  assign dst_data_o = fifo_full ? RESET_MSG : dst_data_reg;

endmodule

module four_phase_handshake (
  input valid_i,
  output ready_o
);

  // Internal signals
  logic valid_sync;
  logic ready_sync;

  // Synchronization
  sync_reg valid_sync_reg (
    .clk(valid_i),
    .rst_ni(1'b1),
    .data_in(valid_i),
    .data_out(valid_sync)
  );

  // Handshake logic
  assign ready_o = valid_sync;

endmodule

module fifo #(
  parameter WIDTH = 1
)(
  input  [WIDTH-1:0] data_in,
  input  write_en,
  input  read_en,
  output [WIDTH-1:0] data_out,
  output empty,
  output full
);

  // Internal signals
  logic [WIDTH-1:0] mem [0:31];
  logic [4:0] read_ptr;
  logic [4:0] write_ptr;
  logic [4:0] count;

  // Write logic
  always_ff @(posedge write_en or negedge 1'b1) begin
    if (!write_en) begin
      write_ptr <= 0;
    end else begin
      mem[write_ptr] <= data_in;
      write_ptr <= write_ptr + 1;
    end
  end

  // Read logic
  always_ff @(posedge read_en or negedge 1'b1) begin
    if (!read_en) begin
      read_ptr <= 0;
    end else begin
      read_ptr <= read_ptr + 1;
    end
  end

  // Count logic
  always_ff @(posedge write_en or posedge read_en or negedge 1'b1) begin
    if (!write_en && !read_en) begin
      count <= 0;
    end else if (write_en && read_en) begin
      count <= count;
    end else if (write_en) begin
      count <= count + 1;
    end else if (read_en) begin
      count <= count - 1;
    end
  end

  // Output logic
  assign data_out = mem[read_ptr];
  assign empty = count == 0;
  assign full = count == 32;

endmodule

module sync_reg (
  input  clk,
  input  rst_ni,
  input  data_in,
  output data_out
);

  // Internal signals
  logic data_reg;

  // Synchronization logic
  always_ff @(posedge clk or negedge rst_ni) begin
    if (!rst_ni) begin
      data_reg <= 0;
    end else begin
      data_reg <= data_in;
    end
  end

  // Output logic
  assign data_out = data_reg;

endmodule
