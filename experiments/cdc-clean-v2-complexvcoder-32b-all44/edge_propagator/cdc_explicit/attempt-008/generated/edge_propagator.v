module edge_propagator (
  input  logic clk_tx_i,
  input  logic rstn_tx_i,
  input  logic edge_i,
  input  logic clk_rx_i,
  input  logic rstn_rx_i,
  output logic edge_o
);

  // Internal signals for TX domain
  logic edge_reg;
  logic edge_last;
  logic edge_pulse;

  // Internal signals for RX domain
  logic edge_pulse_rx;
  logic edge_o_reg;
  logic edge_o_last;

  // Register edge_i into edge_reg on rising edge of clk_tx_i
  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      edge_reg <= 1'b0;
    end else begin
      edge_reg <= edge_i;
    end
  end

  // Register edge_reg into edge_last on rising edge of clk_tx_i
  always_ff @(posedge clk_tx_i or negedge rstn_tx_i) begin
    if (!rstn_tx_i) begin
      edge_last <= 1'b0;
    end else begin
      edge_last <= edge_reg;
    end
  end

  // Generate edge_pulse when there is a rising edge on edge_i
  assign edge_pulse = edge_reg & ~edge_last;

  // Instantiate the asynchronous FIFO to transfer edge_pulse from TX domain to RX domain
  async_fifo fifo_tx_to_rx (
    .clk_wr  (clk_tx_i),
    .rstn_wr (rstn_tx_i),
    .din     (edge_pulse),
    .clk_rd  (clk_rx_i),
    .rstn_rd (rstn_rx_i),
    .dout    (edge_pulse_rx)
  );

  // Register edge_pulse_rx into edge_o_reg on rising edge of clk_rx_i
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      edge_o_reg <= 1'b0;
    end else begin
      edge_o_reg <= edge_pulse_rx;
    end
  end

  // Register edge_o_reg into edge_o_last on rising edge of clk_rx_i
  always_ff @(posedge clk_rx_i or negedge rstn_rx_i) begin
    if (!rstn_rx_i) begin
      edge_o_last <= 1'b0;
    end else begin
      edge_o_last <= edge_o_reg;
    end
  end

  // Generate edge_o when there is a rising edge on edge_pulse_rx
  assign edge_o = edge_o_reg & ~edge_o_last;

endmodule

// Asynchronous FIFO module for crossing clock domains
module async_fifo (
  input  logic clk_wr,
  input  logic rstn_wr,
  input  logic din,
  input  logic clk_rd,
  input  logic rstn_rd,
  output logic dout
);

  // FIFO depth and address width
  localparam DEPTH = 16;
  localparam AW = $clog2(DEPTH);

  // FIFO memory
  logic [DEPTH-1:0] mem;

  // Write and read pointers
  logic [AW:0] wr_ptr;
  logic [AW:0] rd_ptr;

  // FIFO flags
  logic full;
  logic empty;

  // FIFO write logic
  always_ff @(posedge clk_wr or negedge rstn_wr) begin
    if (!rstn_wr) begin
      wr_ptr <= '0;
      full   <= '0;
    end else if (!full) begin
      if (din) begin
        mem[wr_ptr[AW-1:0]] <= din;
        wr_ptr <= wr_ptr + 1;
        full   <= (wr_ptr[AW-1:0] == rd_ptr[AW-1:0]) & wr_ptr[AW] != rd_ptr[AW];
      end
    end
  end

  // FIFO read logic
  always_ff @(posedge clk_rd or negedge rstn_rd) begin
    if (!rstn_rd) begin
      rd_ptr <= '0;
      empty  <= '1;
    end else if (!empty) begin
      rd_ptr <= rd_ptr + 1;
      empty  <= (wr_ptr[AW-1:0] == rd_ptr[AW-1:0]) & wr_ptr[AW] == rd_ptr[AW];
    end
  end

  // FIFO output
  assign dout = mem[rd_ptr[AW-1:0]];

endmodule
