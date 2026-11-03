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
  logic src_valid_sync;
  logic src_clear_sync;
  logic src_clear_pending;
  logic src_ready;
  logic [WIDTH-1:0] src_data_reg;

  // Destination side signals
  logic dst_valid_sync;
  logic dst_clear_sync;
  logic dst_clear_pending;
  logic dst_ready;
  logic [WIDTH-1:0] dst_data_reg;

  // Synchronization FIFO
  logic [WIDTH-1:0] sync_fifo [0:SYNC_STAGES-1];
  logic [SYNC_STAGES-1:0] sync_valid;
  logic [SYNC_STAGES-1:0] sync_clear;

  // Source side synchronization
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_sync <= 0;
      src_clear_sync <= 0;
    end else begin
      src_valid_sync <= src_valid_i;
      src_clear_sync <= src_clear_i;
    end
  end

  // Destination side synchronization
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_sync <= 0;
      dst_clear_sync <= 0;
    end else begin
      dst_valid_sync <= sync_valid[SYNC_STAGES-1];
      dst_clear_sync <= sync_clear[SYNC_STAGES-1];
    end
  end

  // Synchronization FIFO logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      sync_fifo <= '{default: 0};
      sync_valid <= '{default: 0};
      sync_clear <= '{default: 0};
    end else begin
      if (src_valid_i && src_ready) begin
        sync_fifo[0] <= src_data_i;
        sync_valid[0] <= 1;
        sync_clear[0] <= src_clear_i;
      end else if (sync_valid[0]) begin
        for (int i = 0; i < SYNC_STAGES-1; i++) begin
          sync_fifo[i+1] <= sync_fifo[i];
          sync_valid[i+1] <= sync_valid[i];
          sync_clear[i+1] <= sync_clear[i];
        end
      end
    end
  end

  // Source side clear logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pending <= 0;
    end else begin
      if (src_clear_i) begin
        src_clear_pending <= 1;
      end else if (sync_clear[SYNC_STAGES-1]) begin
        src_clear_pending <= 0;
      end
    end
  end

  // Destination side clear logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pending <= 0;
    end else begin
      if (dst_clear_i) begin
        dst_clear_pending <= 1;
      end else if (sync_clear[SYNC_STAGES-1]) begin
        dst_clear_pending <= 0;
      end
    end
  end

  // Source side ready logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready <= 0;
    end else begin
      if (src_clear_i) begin
        src_ready <= 0;
      end else if (!sync_valid[SYNC_STAGES-1]) begin
        src_ready <= 1;
      end
    end
  end

  // Destination side valid logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_o <= 0;
      dst_data_o <= 0;
    end else begin
      if (dst_clear_i) begin
        dst_valid_o <= 0;
      end else if (dst_ready_i && dst_valid_sync) begin
        dst_valid_o <= 0;
      end else if (dst_valid_sync) begin
        dst_valid_o <= 1;
        dst_data_o <= sync_fifo[SYNC_STAGES-1];
      end
    end
  end

  // Destination side ready logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready <= 0;
    end else begin
      if (dst_clear_i) begin
        dst_ready <= 0;
      end else if (dst_ready_i && dst_valid_sync) begin
        dst_ready <= 1;
      end else begin
        dst_ready <= 0;
      end
    end
  end

  // Clear pending outputs
  assign src_clear_pending_o = src_clear_pending;
  assign dst_clear_pending_o = dst_clear_pending;

  // Ready output
  assign src_ready_o = src_ready;

endmodule
