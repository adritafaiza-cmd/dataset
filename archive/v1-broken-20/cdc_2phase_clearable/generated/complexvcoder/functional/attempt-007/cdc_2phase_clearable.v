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

  // Internal signals
  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic src_ready_reg;
  logic [SYNC_STAGES-1:0] src_valid_sync;
  logic [SYNC_STAGES-1:0] src_ready_sync;
  logic [SYNC_STAGES-1:0] dst_valid_sync;
  logic [SYNC_STAGES-1:0] dst_ready_sync;
  logic [SYNC_STAGES-1:0] src_clear_sync;
  logic [SYNC_STAGES-1:0] dst_clear_sync;
  logic [SYNC_STAGES-1:0] src_clear_pending;
  logic [SYNC_STAGES-1:0] dst_clear_pending;
  logic src_clear_done;
  logic dst_clear_done;

  // Synchronizers for source signals
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_sync <= {SYNC_STAGES{1'b0}};
      src_ready_sync <= {SYNC_STAGES{1'b0}};
      src_data_reg <= {WIDTH{1'b0}};
    end else begin
      src_valid_sync <= {src_valid_reg, src_valid_sync[SYNC_STAGES-2:0]};
      src_ready_sync <= {src_ready_reg, src_ready_sync[SYNC_STAGES-2:0]};
      src_data_reg <= src_data_i;
    end
  end

  // Synchronizers for destination signals
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_sync <= {SYNC_STAGES{1'b0}};
      dst_ready_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_valid_sync <= {dst_valid_sync[SYNC_STAGES-2:0], dst_valid_i};
      dst_ready_sync <= {dst_ready_sync[SYNC_STAGES-2:0], dst_ready_i};
    end
  end

  // Synchronizers for clear signals
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      src_clear_sync <= {src_clear_i, src_clear_sync[SYNC_STAGES-2:0]};
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_clear_sync <= {dst_clear_i, dst_clear_sync[SYNC_STAGES-2:0]};
    end
  end

  // Clear pending signals
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pending <= {SYNC_STAGES{1'b0}};
    end else begin
      src_clear_pending <= {src_clear_pending[SYNC_STAGES-2:0], (src_clear_i | src_clear_sync[SYNC_STAGES-2])};
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pending <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_clear_pending <= {dst_clear_pending[SYNC_STAGES-2:0], (dst_clear_i | dst_clear_sync[SYNC_STAGES-2])};
    end
  end

  // Clear done signals
  assign src_clear_done = ~src_clear_pending[SYNC_STAGES-1];
  assign dst_clear_done = ~dst_clear_pending[SYNC_STAGES-1];

  // Clear logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_reg <= 1'b0;
    end else if (src_clear_i | src_clear_sync[SYNC_STAGES-1]) begin
      src_ready_reg <= 1'b0;
    end else if (src_valid_i && src_ready_i) begin
      src_ready_reg <= 1'b1;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
    end else if (dst_clear_i | dst_clear_sync[SYNC_STAGES-1]) begin
      dst_valid_reg <= 1'b0;
    end else if (dst_valid_sync[SYNC_STAGES-2] && dst_ready_i) begin
      dst_valid_reg <= 1'b1;
    end
  end

  // Output logic
  assign src_ready_o = src_ready_reg;
  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o = src_data_reg;

  // Clear pending outputs
  assign src_clear_pending_o = src_clear_pending[SYNC_STAGES-1];
  assign dst_clear_pending_o = dst_clear_pending[SYNC_STAGES-1];

endmodule
