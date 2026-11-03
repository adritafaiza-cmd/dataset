module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // Internal signals
  logic edge_i_dff;
  logic edge_i_sync;
  logic edge_o_sync;
  logic edge_o_dff;

  // Register edge_i in the TX domain to create edge_i_dff
  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      edge_i_dff <= 1'b0;
    end else begin
      edge_i_dff <= edge_i;
    end
  end

  // Synchronize edge_i_dff to the TX domain to create edge_i_sync
  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      edge_i_sync <= 1'b0;
    end else begin
      edge_i_sync <= edge_i_dff;
    end
  end

  // Instantiate async_fifo to transfer edge_i_sync from the TX domain to the RX domain
  async_fifo async_fifo_inst (
    .clk_wr(clk_tx_i),
    .rstn_wr(rstn_tx_i),
    .data_in(edge_i_sync),
    .clk_rd(clk_rx_i),
    .rstn_rd(rstn_rx_i),
    .data_out(edge_o_sync)
  );

  // Register the output of the FIFO in the RX domain to create edge_o_sync
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      edge_o_dff <= 1'b0;
    end else begin
      edge_o_dff <= edge_o_sync;
    end
  end

  // Drive edge_o with edge_o_sync, ensuring a single pulse is generated for each edge in the TX domain
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      edge_o <= 1'b0;
    end else begin
      edge_o <= edge_o_sync & ~edge_o_dff;
    end
  end

endmodule

module async_fifo (
  input  logic clk_wr,
  input  logic rstn_wr,
  input  logic data_in,
  input  logic clk_rd,
  input  logic rstn_rd,
  output logic data_out
);

  // FIFO parameters and internal signals
  localparam DEPTH = 2; // Minimum depth of 2 for safe async FIFO
  logic [DEPTH-1:0] fifo_mem;
  logic [$clog2(DEPTH):0] wr_ptr, rd_ptr;
  logic [$clog2(DEPTH):0] wr_ptr_gray, rd_ptr_gray;
  logic [$clog2(DEPTH):0] wr_ptr_gray_sync, rd_ptr_gray_sync;

  // Write pointer logic
  always_ff @(posedge clk_wr or negedge rstn_wr) begin
    if (!rstn_wr) begin
      wr_ptr <= '0;
    end else begin
      wr_ptr <= wr_ptr + 1'b1;
    end
  end

  // Gray code conversion for write pointer
  assign wr_ptr_gray = wr_ptr ^ (wr_ptr >> 1);

  // Synchronize write pointer gray code to read domain
  always_ff @(posedge clk_rd or negedge rstn_rd) begin
    if (!rstn_rd) begin
      wr_ptr_gray_sync <= '0;
    end else begin
      wr_ptr_gray_sync <= wr_ptr_gray;
    end
  end

  // Read pointer logic
  always_ff @(posedge clk_rd or negedge rstn_rd) begin
    if (!rstn_rd) begin
      rd_ptr <= '0;
    end else if (data_out) begin
      rd_ptr <= rd_ptr + 1'b1;
    end
  end

  // Gray code conversion for read pointer
  assign rd_ptr_gray = rd_ptr ^ (rd_ptr >> 1);

  // Synchronize read pointer gray code to write domain
  always_ff @(posedge clk_wr or negedge rstn_wr) begin
    if (!rstn_wr) begin
      rd_ptr_gray_sync <= '0;
    end else begin
      rd_ptr_gray_sync <= rd_ptr_gray;
    end
  end

  // FIFO write logic
  always_ff @(posedge clk_wr or negedge rstn_wr) begin
    if (!rstn_wr) begin
      fifo_mem <= '0;
    end else begin
      fifo_mem[wr_ptr[$clog2(DEPTH)-1:0]] <= data_in;
    end
  end

  // FIFO read logic
  always_ff @(posedge clk_rd or negedge rstn_rd) begin
    if (!rstn_rd) begin
      data_out <= 1'b0;
    end else begin
      data_out <= fifo_mem[rd_ptr[$clog2(DEPTH)-1:0]];
    end
  end

  // FIFO empty and full flags (not used here but useful for debugging)
  // logic fifo_empty;
  // logic fifo_full;

  // assign fifo_empty = (wr_ptr_gray_sync == rd_ptr_gray);
  // assign fifo_full = (wr_ptr_gray_sync[$clog2(DEPTH):1] == rd_ptr_gray[$clog2(DEPTH):1]) & (wr_ptr_gray_sync[0] != rd_ptr_gray[0]);

endmodule
