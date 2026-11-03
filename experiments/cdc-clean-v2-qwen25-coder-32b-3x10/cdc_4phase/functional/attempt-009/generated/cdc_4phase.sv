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
  logic src_ready;
  logic [1:0] src_phase;

  // Destination domain signals
  logic [WIDTH-1:0] dst_data_sync;
  logic dst_valid;
  logic [1:0] dst_phase;

  // Synchronization FIFO
  logic [WIDTH-1:0] fifo [3:0];
  logic [1:0] fifo_wr_ptr;
  logic [1:0] fifo_rd_ptr;
  logic fifo_full;
  logic fifo_empty;

  // Source domain logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_phase <= 2'b00;
      src_valid_sync <= 1'b0;
      src_data_sync <= {WIDTH{1'b0}};
    end else begin
      src_phase <= src_phase + 1'b1;
      if (src_valid_i && src_ready) begin
        src_valid_sync <= 1'b1;
        src_data_sync <= src_data_i;
      end else if (fifo_full) begin
        src_valid_sync <= 1'b0;
      end
    end
  end

  // Cross-domain synchronization for src_valid_sync and src_data_sync
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_phase <= 2'b00;
      dst_valid <= 1'b0;
      dst_data_sync <= {WIDTH{1'b0}};
    end else begin
      dst_phase <= dst_phase + 1'b1;
      if (dst_phase != src_phase) begin
        dst_valid <= src_valid_sync;
        dst_data_sync <= src_data_sync;
      end
    end
  end

  // FIFO write logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      fifo_wr_ptr <= 2'b00;
      fifo_full <= 1'b0;
    end else begin
      if (dst_valid && !fifo_full) begin
        fifo[fifo_wr_ptr] <= dst_data_sync;
        fifo_wr_ptr <= fifo_wr_ptr + 1'b1;
        fifo_full <= (fifo_wr_ptr == fifo_rd_ptr);
      end
    end
  end

  // FIFO read logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      fifo_rd_ptr <= 2'b00;
      fifo_empty <= 1'b1;
      dst_data_o <= SEND_RESET_MSG ? RESET_MSG : {WIDTH{1'b0}};
      dst_valid_o <= SEND_RESET_MSG;
    end else begin
      if (dst_ready_i && !fifo_empty) begin
        fifo_rd_ptr <= fifo_rd_ptr + 1'b1;
        fifo_empty <= (fifo_wr_ptr == fifo_rd_ptr);
      end
      if (!fifo_empty) begin
        dst_data_o <= fifo[fifo_rd_ptr];
        dst_valid_o <= 1'b1;
      end else if (SEND_RESET_MSG) begin
        dst_data_o <= RESET_MSG;
        dst_valid_o <= 1'b1;
      end else begin
        dst_valid_o <= 1'b0;
      end
    end
  end

  // Source ready logic
  always_comb begin
    if (DECOUPLED) begin
      src_ready = !fifo_full;
    end else begin
      src_ready = !fifo_full && (!dst_valid_o || dst_ready_i);
    end
  end

  assign src_ready_o = src_ready;

endmodule
