module cdc_2phase_clearable #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3,
  parameter CLEAR_ON_ASYNC_RESET = 1
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  src_clear_i,
  output src_clear_pending_o,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,
  input  dst_rst_ni,
  input  dst_clk_i,
  input  dst_clear_i,
  output dst_clear_pending_o,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);

  // Source side signals
  logic [WIDTH-1:0] src_data_sync;
  logic src_valid_sync;
  logic src_ready_sync;
  logic src_clear_sync;
  logic src_clear_pending;

  // Destination side signals
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_reg;
  logic dst_ready_sync;
  logic dst_clear_sync;
  logic dst_clear_pending;

  // Synchronization FIFO
  logic [WIDTH-1:0] fifo_data [0:SYNC_STAGES-1];
  logic fifo_valid [0:SYNC_STAGES-1];
  logic fifo_ready [0:SYNC_STAGES-1];

  // Source side synchronization
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_sync <= '0;
      src_valid_sync <= '0;
      src_ready_sync <= '0;
      src_clear_sync <= '0;
      src_clear_pending <= '0;
    end else begin
      src_data_sync <= src_data_i;
      src_valid_sync <= src_valid_i;
      src_ready_sync <= fifo_ready[0];
      src_clear_sync <= src_clear_i;
      if (src_clear_i) begin
        src_clear_pending <= '1;
      end else if (src_clear_pending && !src_clear_sync) begin
        src_clear_pending <= '0;
      end
    end
  end

  // Destination side synchronization
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= '0;
      dst_valid_reg <= '0;
      dst_ready_sync <= '0;
      dst_clear_sync <= '0;
      dst_clear_pending <= '0;
    end else begin
      dst_data_reg <= fifo_data[SYNC_STAGES-1];
      dst_valid_reg <= fifo_valid[SYNC_STAGES-1];
      dst_ready_sync <= src_ready_sync;
      dst_clear_sync <= dst_clear_i;
      if (dst_clear_i) begin
        dst_clear_pending <= '1;
      end else if (dst_clear_pending && !dst_clear_sync) begin
        dst_clear_pending <= '0;
      end
    end
  end

  // FIFO synchronization stages
  genvar i;
  generate
    for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_sync_stages
      always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
          fifo_data[i] <= '0;
          fifo_valid[i] <= '0;
        end else begin
          if (i == 0) begin
            fifo_data[i] <= src_data_sync;
            fifo_valid[i] <= src_valid_sync;
          end else begin
            fifo_data[i] <= fifo_data[i-1];
            fifo_valid[i] <= fifo_valid[i-1];
          end
        end
      end

      always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
          fifo_ready[i] <= '0;
        end else begin
          if (i == 0) begin
            fifo_ready[i] <= dst_ready_i;
          end else begin
            fifo_ready[i] <= fifo_ready[i-1];
          end
        end
      end
    end
  endgenerate

  // Clear handling
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pending_o <= '0;
    end else begin
      src_clear_pending_o <= src_clear_pending;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pending_o <= '0;
    end else begin
      dst_clear_pending_o <= dst_clear_pending;
    end
  end

  // Output assignments
  assign src_ready_o = src_ready_sync;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
