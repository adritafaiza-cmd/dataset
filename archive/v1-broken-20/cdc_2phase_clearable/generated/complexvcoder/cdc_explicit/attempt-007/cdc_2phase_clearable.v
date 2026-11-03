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
  logic src_clear_reg;
  logic dst_clear_reg;
  logic clear_done;
  logic [SYNC_STAGES-1:0] src_valid_sync;
  logic [SYNC_STAGES-1:0] src_clear_sync;
  logic [SYNC_STAGES-1:0] dst_clear_sync;
  logic [SYNC_STAGES-1:0] dst_valid_sync;
  logic [SYNC_STAGES-1:0] dst_ready_sync;
  logic src_clear_pending;
  logic dst_clear_pending;

  // Synchronizer for source signals
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
      src_data_reg <= {WIDTH{1'b0}};
      src_ready_reg <= 1'b0;
      src_clear_reg <= 1'b0;
    end else begin
      src_valid_reg <= src_valid_i;
      src_data_reg <= src_data_i;
      src_ready_reg <= src_ready_o;
      src_clear_reg <= src_clear_i;
    end
  end

  generate
    generate
      for (genvar i = 0; i < SYNC_STAGES; i++) begin : src_valid_sync_gen
        assign src_valid_sync[i] = src_valid_reg;
        assign src_clear_sync[i] = src_clear_reg;
      end
    endgenerate
  endgenerate

  // Synchronizer for destination signals
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_sync <= {SYNC_STAGES{1'b0}};
      dst_ready_sync <= {SYNC_STAGES{1'b0}};
      dst_clear_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_valid_sync <= {dst_valid_sync[SYNC_STAGES-2:0], dst_valid_i};
      dst_ready_sync <= {dst_ready_sync[SYNC_STAGES-2:0], dst_ready_i};
      dst_clear_sync <= {dst_clear_sync[SYNC_STAGES-2:0], dst_clear_i};
    end
  end

  generate
    generate
      for (genvar i = 0; i < SYNC_STAGES; i++) begin : dst_valid_sync_gen
        assign dst_valid_o = dst_valid_sync[i];
        assign dst_ready_o = dst_ready_sync[i];
        assign dst_clear_o = dst_clear_sync[i];
      end
    endgenerate
  endgenerate

  // Clear logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pending <= 1'b0;
    end else begin
      if (src_clear_reg || (CLEAR_ON_ASYNC_RESET && !src_rst_ni)) begin
        src_clear_pending <= 1'b1;
      end else if (src_clear_sync[SYNC_STAGES-1]) begin
        src_clear_pending <= 1'b0;
      end
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pending <= 1'b0;
    end else begin
      if (dst_clear_reg || (CLEAR_ON_ASYNC_RESET && !dst_rst_ni)) begin
        dst_clear_pending <= 1'b1;
      end else if (dst_clear_sync[SYNC_STAGES-1]) begin
        dst_clear_pending <= 1'b0;
      end
    end
  end

  assign src_clear_pending_o = src_clear_pending;
  assign dst_clear_pending_o = dst_clear_pending;

endmodule
