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

  // Helper modules
  logic [WIDTH-1:0] src_sync_data;
  logic [WIDTH-1:0] dst_sync_data;
  logic src_valid_reg, src_ready_reg;
  logic dst_valid_reg, dst_ready_reg;
  logic [WIDTH-1:0] src_data_reg;
  logic [WIDTH-1:0] dst_data_reg;
  logic [WIDTH-1:0] fifo_data;
  logic fifo_full, fifo_empty;

  // Source handshake
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b0;
      src_data_reg <= {WIDTH{1'b0}};
    end else begin
      src_valid_reg <= src_valid_i;
      src_ready_reg <= src_ready_o;
      if (src_valid_i && src_ready_o)
        src_data_reg <= src_data_i;
    end
  end

  // Destination handshake
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
      dst_ready_reg <= 1'b0;
      dst_data_reg <= {WIDTH{1'b0}};
    end else begin
      dst_valid_reg <= dst_valid_o;
      dst_ready_reg <= dst_ready_i;
      if (dst_valid_i && dst_ready_i)
        dst_data_reg <= dst_data_i;
    end
  end

  // Synchronous FIFO
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      fifo_data <= {WIDTH{1'b0}};
      fifo_full <= 1'b0;
      fifo_empty <= 1'b1;
    end else begin
      if (src_valid_reg && src_ready_reg && !fifo_full)
        fifo_data <= src_data_reg;
      fifo_full <= (fifo_data != {WIDTH{1'b0}}) && !fifo_empty;
      fifo_empty <= fifo_data == {WIDTH{1'b0}};
    end
  end

  // Data transfer logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_sync_data <= {WIDTH{1'b0}};
    end else begin
      if (!fifo_empty && dst_ready_i)
        dst_sync_data <= fifo_data;
    end
  end

  // Output logic
  assign src_ready_o = !fifo_full;
  assign dst_valid_o = !fifo_empty;
  assign dst_data_o = dst_sync_data;

endmodule
