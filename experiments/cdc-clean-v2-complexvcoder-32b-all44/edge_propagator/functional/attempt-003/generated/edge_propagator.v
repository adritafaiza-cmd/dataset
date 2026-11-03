module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  logic edge_detected_tx;
  logic edge_detected_rx;
  logic async_fifo_full;
  logic async_fifo_empty;

  edge_detector edge_detector_tx (
    .clk(clk_tx_i),
    .rstn(rstn_tx_i),
    .signal(edge_i),
    .edge_o(edge_detected_tx)
  );

  async_fifo async_fifo_inst (
    .clk_wr(clk_tx_i),
    .rstn_wr(rstn_tx_i),
    .din(edge_detected_tx),
    .full(async_fifo_full),
    .clk_rd(clk_rx_i),
    .rstn_rd(rstn_rx_i),
    .dout(edge_detected_rx),
    .empty(async_fifo_empty)
  );

  // Pulse stretcher to ensure edge_o is a single cycle pulse
  logic edge_o_reg;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      edge_o_reg <= 0;
      edge_o <= 0;
    end else begin
      edge_o_reg <= edge_detected_rx;
      edge_o <= edge_detected_rx & ~edge_o_reg;
    end
  end

endmodule

module edge_detector (
  input  logic clk,
  input  logic rstn,
  input  logic signal,
  output logic edge_o
);

  logic signal_reg;

  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      signal_reg <= 0;
      edge_o <= 0;
    end else begin
      signal_reg <= signal;
      edge_o <= signal & ~signal_reg;
    end
  end

endmodule

module async_fifo (
  input  logic clk_wr,
  input  logic rstn_wr,
  input  logic din,
  output logic full,
  input  logic clk_rd,
  input  logic rstn_rd,
  output logic dout,
  output logic empty
);

  logic [1:0] wr_ptr;
  logic [1:0] rd_ptr;
  logic [1:0] wr_ptr_gray;
  logic [1:0] rd_ptr_gray;
  logic [1:0] rd_ptr_gray_sync;
  logic [1:0] wr_ptr_gray_sync;
  logic fifo_mem [3:0];

  // Gray code conversion
  assign wr_ptr_gray = (wr_ptr >> 1) ^ wr_ptr;
  assign rd_ptr_gray = (rd_ptr >> 1) ^ rd_ptr;

  // Write pointer logic
  always_ff @(posedge clk_wr or negedge rstn_wr) begin
    if (!rstn_wr) begin
      wr_ptr <= 0;
      wr_ptr_gray_sync <= 0;
    end else begin
      if (!full) begin
        fifo_mem[wr_ptr] <= din;
        wr_ptr <= wr_ptr + 1;
      end
      wr_ptr_gray_sync <= wr_ptr_gray;
    end
  end

  // Read pointer logic
  always_ff @(posedge clk_rd or negedge rstn_rd) begin
    if (!rstn_rd) begin
      rd_ptr <= 0;
      rd_ptr_gray_sync <= 0;
    end else begin
      if (!empty) begin
        rd_ptr <= rd_ptr + 1;
      end
      rd_ptr_gray_sync <= rd_ptr_gray;
    end
  end

  // FIFO read data output
  always_ff @(posedge clk_rd or negedge rstn_rd) begin
    if (!rstn_rd) begin
      dout <= 0;
    end else begin
      dout <= fifo_mem[rd_ptr];
    end
  end

  // Full and empty conditions
  assign full = (wr_ptr_gray_sync == {~rd_ptr_gray[1], rd_ptr_gray[0]});
  assign empty = (wr_ptr_gray_sync == rd_ptr_gray_sync);

endmodule
