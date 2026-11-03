module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // Internal signals for TX domain
  logic edge_i_reg;
  logic edge_i_sync;
  logic edge_i_reg_next;
  logic edge_i_pulse;

  // Internal signals for RX domain
  logic edge_o_pulse;
  logic edge_o_reg;

  // Internal signal for FIFO empty status
  logic fifo_empty;

  // Synchronize edge_i to clk_tx_i domain
  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      edge_i_reg <= 1'b0;
      edge_i_sync <= 1'b0;
      edge_i_reg_next <= 1'b0;
    end else begin
      edge_i_reg <= edge_i;
      edge_i_sync <= edge_i_reg;
      edge_i_reg_next <= edge_i_sync;
    end
  end

  // Detect rising edge on edge_i_sync to generate edge_i_pulse
  assign edge_i_pulse = edge_i_sync & ~edge_i_reg_next;

  // Instantiate asynchronous FIFO to transfer edge_i_pulse from TX domain to RX domain
  async_fifo fifo_inst (
    .clk_wr(clk_tx_i),
    .rstn_wr(rstn_tx_i),
    .data_in(edge_i_pulse),
    .wr_en(edge_i_pulse),
    .clk_rd(clk_rx_i),
    .rstn_rd(rstn_rx_i),
    .data_out(edge_o_pulse),
    .rd_en(edge_o_pulse),
    .empty(fifo_empty)
  );

  // Synchronize edge_o_pulse to clk_rx_i domain
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      edge_o_reg <= 1'b0;
    end else begin
      edge_o_reg <= edge_o_pulse;
    end
  end

  // Drive edge_o with edge_o_reg
  assign edge_o = edge_o_reg;

endmodule

// Asynchronous FIFO implementation
module async_fifo (
  input  logic clk_wr,
  input  logic rstn_wr,
  input  logic data_in,
  input  logic wr_en,
  input  logic clk_rd,
  input  logic rstn_rd,
  output logic data_out,
  input  logic rd_en,
  output logic empty
);

  // FIFO depth (2 entries for simplicity)
  localparam DEPTH = 2;
  localparam ADDR_WIDTH = $clog2(DEPTH);

  // FIFO memory
  logic [DEPTH-1:0] fifo_mem;
  logic [ADDR_WIDTH-1:0] wr_ptr_gray;
  logic [ADDR_WIDTH-1:0] rd_ptr_gray;
  logic [ADDR_WIDTH:0] wr_ptr_gray_sync;
  logic [ADDR_WIDTH:0] rd_ptr_gray_sync;
  logic [ADDR_WIDTH:0] wr_ptr_gray_sync_next;
  logic [ADDR_WIDTH:0] rd_ptr_gray_sync_next;

  // Gray code conversion functions
  function logic [ADDR_WIDTH:0] bin_to_gray (input logic [ADDR_WIDTH:0] bin);
    return bin ^ (bin >> 1);
  endfunction

  function logic [ADDR_WIDTH:0] gray_to_bin (input logic [ADDR_WIDTH:0] gray);
    logic [ADDR_WIDTH:0] bin;
    bin = gray;
    for (int i = ADDR_WIDTH-1; i >= 0; i--) begin
      bin[i] = bin[i+1] ^ gray[i];
    end
    return bin;
  endfunction

  // Write pointer logic
  always_ff @(posedge clk_wr or negedge rstn_wr) begin
    if (!rstn_wr) begin
      wr_ptr_gray <= '0;
    end else if (wr_en && !fifo_full) begin
      wr_ptr_gray <= wr_ptr_gray + 1'b1;
    end
  end

  // Read pointer logic
  always_ff @(posedge clk_rd or negedge rstn_rd) begin
    if (!rstn_rd) begin
      rd_ptr_gray <= '0;
    end else if (rd_en && !fifo_empty) begin
      rd_ptr_gray <= rd_ptr_gray + 1'b1;
    end
  end

  // Synchronize write pointer to read domain
  always_ff @(posedge clk_rd or negedge rstn_rd) begin
    if (!rstn_rd) begin
      wr_ptr_gray_sync <= '0;
      wr_ptr_gray_sync_next <= '0;
    end else begin
      wr_ptr_gray_sync <= bin_to_gray(wr_ptr_gray);
      wr_ptr_gray_sync_next <= wr_ptr_gray_sync;
    end
  end

  // Synchronize read pointer to write domain
  always_ff @(posedge clk_wr or negedge rstn_wr) begin
    if (!rstn_wr) begin
      rd_ptr_gray_sync <= '0;
      rd_ptr_gray_sync_next <= '0;
    end else begin
      rd_ptr_gray_sync <= bin_to_gray(rd_ptr_gray);
      rd_ptr_gray_sync_next <= rd_ptr_gray_sync;
    end
  end

  // FIFO full and empty conditions
  logic fifo_full;
  assign fifo_full = (wr_ptr_gray_sync_next == {~rd_ptr_gray_sync[ADDR_WIDTH], rd_ptr_gray_sync[ADDR_WIDTH-1:0]});
  assign empty = (wr_ptr_gray_sync == rd_ptr_gray_sync_next);

  // Write data to FIFO
  always_ff @(posedge clk_wr or negedge rstn_wr) begin
    if (!rstn_wr) begin
      fifo_mem <= '0;
    end else if (wr_en && !fifo_full) begin
      fifo_mem[wr_ptr_gray] <= data_in;
    end
  end

  // Read data from FIFO
  always_ff @(posedge clk_rd or negedge rstn_rd) begin
    if (!rstn_rd) begin
      data_out <= '0;
    end else if (rd_en && !fifo_empty) begin
      data_out <= fifo_mem[rd_ptr_gray];
    end
  end

endmodule
