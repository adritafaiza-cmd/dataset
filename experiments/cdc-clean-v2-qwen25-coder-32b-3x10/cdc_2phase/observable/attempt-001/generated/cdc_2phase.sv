module cdc_2phase #(
  parameter WIDTH = 1
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

  // Source side signals
  logic [WIDTH-1:0] src_data_sync;
  logic src_valid_sync;
  logic src_ready;

  // Destination side signals
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_reg;

  // Synchronization FIFO
  logic [WIDTH-1:0] sync_fifo [1:0];
  logic [1:0] sync_fifo_wr_ptr;
  logic [1:0] sync_fifo_rd_ptr;
  logic sync_fifo_full;
  logic sync_fifo_empty;

  // Source side synchronization
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_sync <= '0;
      src_valid_sync <= '0;
    end else begin
      src_data_sync <= src_data_i;
      src_valid_sync <= src_valid_i;
    end
  end

  // Source side ready signal
  assign src_ready_o = src_ready;

  // Source side write to synchronization FIFO
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      sync_fifo_wr_ptr <= '0;
    end else if (src_valid_sync && !sync_fifo_full) begin
      sync_fifo_wr_ptr <= sync_fifo_wr_ptr + 1;
      sync_fifo[sync_fifo_wr_ptr] <= src_data_sync;
    end
  end

  // Destination side read from synchronization FIFO
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      sync_fifo_rd_ptr <= '0;
    end else if (dst_ready_i && !sync_fifo_empty) begin
      sync_fifo_rd_ptr <= sync_fifo_rd_ptr + 1;
    end
  end

  // Synchronization FIFO flags
  assign sync_fifo_full = (sync_fifo_wr_ptr == sync_fifo_rd_ptr + 2'b10);
  assign sync_fifo_empty = (sync_fifo_wr_ptr == sync_fifo_rd_ptr);

  // Destination side data and valid signals
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= '0;
      dst_valid_reg <= '0;
    end else if (dst_ready_i && !sync_fifo_empty) begin
      dst_data_reg <= sync_fifo[sync_fifo_rd_ptr];
      dst_valid_reg <= 1'b1;
    end else if (dst_ready_i) begin
      dst_valid_reg <= 1'b0;
    end
  end

  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

  // Source side ready signal
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready <= '0;
    end else begin
      src_ready <= !sync_fifo_full;
    end
  end

endmodule
