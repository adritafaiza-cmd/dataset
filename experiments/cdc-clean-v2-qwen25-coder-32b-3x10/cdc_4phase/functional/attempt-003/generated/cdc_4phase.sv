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

  // Source domain signals
  logic [WIDTH-1:0] src_data_sync;
  logic src_valid_sync;
  logic src_ready_sync;

  // Destination domain signals
  logic [WIDTH-1:0] dst_data_sync;
  logic dst_valid_sync;
  logic dst_ready_sync;

  // Synchronization FIFO
  logic [WIDTH-1:0] fifo [3:0];
  logic [1:0] wr_ptr, rd_ptr;
  logic wr_en, rd_en;
  logic fifo_full, fifo_empty;

  // Source domain
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_o <= 1'b0;
      src_data_sync <= RESET_MSG;
      src_valid_sync <= SEND_RESET_MSG;
    end else begin
      if (wr_en && !fifo_full) begin
        fifo[wr_ptr] <= src_data_i;
        src_ready_o <= DECOUPLED || fifo_empty;
      end else begin
        src_ready_o <= DECOUPLED || fifo_empty;
      end
      src_data_sync <= fifo[wr_ptr];
      src_valid_sync <= !fifo_empty;
    end
  end

  // Destination domain
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o <= RESET_MSG;
      dst_valid_o <= SEND_RESET_MSG;
      dst_ready_sync <= 1'b0;
    end else begin
      if (rd_en && !fifo_empty) begin
        dst_data_o <= fifo[rd_ptr];
        dst_valid_o <= 1'b1;
      end else if (dst_ready_i) begin
        dst_valid_o <= 1'b0;
      end
      dst_ready_sync <= dst_ready_i;
    end
  end

  // Write pointer logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      wr_ptr <= 2'b00;
    end else if (wr_en && !fifo_full) begin
      wr_ptr <= wr_ptr + 1'b1;
    end
  end

  // Read pointer logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      rd_ptr <= 2'b00;
    end else if (rd_en && !fifo_empty) begin
      rd_ptr <= rd_ptr + 1'b1;
    end
  end

  // FIFO full and empty flags
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      fifo_full <= 1'b0;
      fifo_empty <= 1'b1;
    end else begin
      if (wr_en && !fifo_full && (wr_ptr == rd_ptr - 1)) begin
        fifo_full <= 1'b1;
        fifo_empty <= 1'b0;
      end else if (rd_en && !fifo_empty && (wr_ptr == rd_ptr)) begin
        fifo_full <= 1'b0;
        fifo_empty <= 1'b1;
      end else if (wr_en && !fifo_full) begin
        fifo_empty <= 1'b0;
      end else if (rd_en && !fifo_empty) begin
        fifo_full <= 1'b0;
      end
    end
  end

  // Write enable logic
  assign wr_en = src_valid_i && src_ready_o;

  // Read enable logic
  assign rd_en = dst_valid_o && dst_ready_i;

endmodule
