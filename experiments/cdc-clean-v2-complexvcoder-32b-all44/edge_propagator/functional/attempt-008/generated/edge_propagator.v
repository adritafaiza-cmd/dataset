module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // Internal signal to store the output from the async FIFO
  logic fifo_out;

  // Instantiate the async FIFO
  async_fifo #(
    .WIDTH(1)
  ) async_fifo_inst (
    .clk_wr(clk_tx_i),
    .rstn_wr(rstn_tx_i),
    .data_in(edge_i),
    .clk_rd(clk_rx_i),
    .rstn_rd(rstn_rx_i),
    .data_out(fifo_out)
  );

  // Register the fifo_out to generate a pulse on edge_o
  logic edge_o_reg;

  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      edge_o_reg <= 1'b0;
      edge_o <= 1'b0;
    end else begin
      edge_o_reg <= fifo_out;
      edge_o <= fifo_out & ~edge_o_reg; // Generate a pulse on the rising edge of fifo_out
    end
  end

endmodule

module async_fifo #(
  parameter WIDTH = 8
) (
  input  logic clk_wr,
  input  logic rstn_wr,
  input  logic [WIDTH-1:0] data_in,
  input  logic clk_rd,
  input  logic rstn_rd,
  output logic [WIDTH-1:0] data_out
);

  localparam DEPTH = 4; // Depth of the FIFO
  localparam ADDR_WIDTH = $clog2(DEPTH);

  logic [WIDTH-1:0] mem [0:DEPTH-1];
  logic [ADDR_WIDTH:0] wr_ptr_gray, rd_ptr_gray;
  logic [ADDR_WIDTH:0] wr_ptr_gray_sync, rd_ptr_gray_sync;

  // Write pointer logic
  logic [ADDR_WIDTH:0] wr_ptr_bin, wr_ptr_bin_next;
  always_ff @(posedge clk_wr or negedge rstn_wr) begin
    if (!rstn_wr) begin
      wr_ptr_bin <= '0;
      wr_ptr_gray <= '0;
    end else begin
      wr_ptr_bin <= wr_ptr_bin_next;
      wr_ptr_gray <= wr_ptr_bin_next ^ (wr_ptr_bin_next >> 1);
    end
  end

  // Read pointer logic
  logic [ADDR_WIDTH:0] rd_ptr_bin, rd_ptr_bin_next;
  always_ff @(posedge clk_rd or negedge rstn_rd) begin
    if (!rstn_rd) begin
      rd_ptr_bin <= '0;
      rd_ptr_gray <= '0;
    end else begin
      rd_ptr_bin <= rd_ptr_bin_next;
      rd_ptr_gray <= rd_ptr_bin_next ^ (rd_ptr_bin_next >> 1);
    end
  end

  // Sync write pointer to read clock domain
  always_ff @(posedge clk_rd or negedge rstn_rd) begin
    if (!rstn_rd) begin
      wr_ptr_gray_sync <= '0;
    end else begin
      wr_ptr_gray_sync <= wr_ptr_gray;
    end
  end

  // Sync read pointer to write clock domain
  always_ff @(posedge clk_wr or negedge rstn_wr) begin
    if (!rstn_wr) begin
      rd_ptr_gray_sync <= '0;
    end else begin
      rd_ptr_gray_sync <= rd_ptr_gray;
    end
  end

  // Write pointer binary conversion
  always_comb begin
    wr_ptr_bin_next = wr_ptr_bin + 1;
  end

  // Read pointer binary conversion
  always_comb begin
    rd_ptr_bin_next = rd_ptr_bin + 1;
  end

  // Write enable
  logic wr_en;
  assign wr_en = (wr_ptr_gray_sync[ADDR_WIDTH:ADDR_WIDTH-1] != rd_ptr_gray[ADDR_WIDTH:ADDR_WIDTH-1]);

  // Read enable
  logic rd_en;
  assign rd_en = (wr_ptr_gray[ADDR_WIDTH:ADDR_WIDTH-1] != rd_ptr_gray_sync[ADDR_WIDTH:ADDR_WIDTH-1]);

  // Memory write
  always_ff @(posedge clk_wr) begin
    if (wr_en) begin
      mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= data_in;
    end
  end

  // Memory read
  always_ff @(posedge clk_rd) begin
    if (rd_en) begin
      data_out <= mem[rd_ptr_bin[ADDR_WIDTH-1:0]];
    end
  end

endmodule
