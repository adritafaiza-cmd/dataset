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
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic [WIDTH-1:0] dst_data_reg;
  logic src_clear_reg;
  logic dst_clear_reg;
  logic [SYNC_STAGES-1:0] src_clear_pending;
  logic [SYNC_STAGES-1:0] dst_clear_pending;
  logic src_clear_complete;
  logic dst_clear_complete;
  logic src_reset_pending;
  logic dst_reset_pending;

  // Synchronizers for source signals
  logic [WIDTH-1:0] src_data_sync [SYNC_STAGES-1:0];
  logic src_valid_sync [SYNC_STAGES-1:0];
  logic src_ready_sync [SYNC_STAGES-1:0];

  // Synchronizers for destination signals
  logic [WIDTH-1:0] dst_data_sync [SYNC_STAGES-1:0];
  logic dst_valid_sync [SYNC_STAGES-1:0];
  logic dst_ready_sync [SYNC_STAGES-1:0];

  // Register the source signals
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni || (CLEAR_ON_ASYNC_RESET && dst_clear_i)) begin
      src_data_reg <= 0;
      src_valid_reg <= 0;
      src_ready_reg <= 0;
      src_clear_complete <= 0;
      src_reset_pending <= 1;
    end else begin
      src_data_reg <= src_data_i;
      src_valid_reg <= src_valid_i;
      src_ready_reg <= src_ready_o;
      src_clear_complete <= 1;
      src_reset_pending <= 0;
    end
  end

  // Synchronize the source signals to the destination clock domain
  generate
    for (genvar i = 0; i < SYNC_STAGES; i++) begin : src_sync_gen
      always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
          src_data_sync[i] <= 0;
          src_valid_sync[i] <= 0;
          src_ready_sync[i] <= 0;
        end else begin
          src_data_sync[i] <= src_data_reg;
          src_valid_sync[i] <= src_valid_reg;
          src_ready_sync[i] <= src_ready_reg;
        end
      end
    end
  endgenerate

  // Register the destination signals
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni || (CLEAR_ON_ASYNC_RESET && src_clear_i)) begin
      dst_valid_reg <= 0;
      dst_ready_reg <= 0;
      dst_data_reg <= 0;
      dst_clear_complete <= 0;
      dst_reset_pending <= 1;
    end else begin
      dst_valid_reg <= dst_valid_i;
      dst_ready_reg <= dst_ready_i;
      dst_data_reg <= dst_data_i;
      dst_clear_complete <= 1;
      dst_reset_pending <= 0;
    end
  end

  // Synchronize the destination signals to the source clock domain
  generate
    for (genvar i = 0; i < SYNC_STAGES; i++) begin : dst_sync_gen
      always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
          dst_data_sync[i] <= 0;
          dst_valid_sync[i] <= 0;
          dst_ready_sync[i] <= 0;
        end else begin
          dst_data_sync[i] <= dst_data_reg;
          dst_valid_sync[i] <= dst_valid_reg;
          dst_ready_sync[i] <= dst_ready_reg;
        end
      end
    end
  endgenerate

  // Generate clear pending signals
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pending <= 0;
    end else begin
      if (src_clear_i) begin
        src_clear_pending <= {SYNC_STAGES{1'b1}};
      end else begin
        src_clear_pending <= src_clear_pending << 1;
      end
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pending <= 0;
    end else begin
      if (dst_clear_i) begin
        dst_clear_pending <= {SYNC_STAGES{1'b1}};
      end else begin
        dst_clear_pending <= dst_clear_pending << 1;
      end
    end
  end

  // Generate clear complete signals
  assign src_clear_complete = src_clear_pending[0];
  assign dst_clear_complete = dst_clear_pending[0];

  // Generate clear pending outputs
  assign src_clear_pending_o = src_clear_complete;
  assign dst_clear_pending_o = dst_clear_complete;

  // Generate ready outputs
  assign src_ready_o = src_clear_complete && src_ready_reg;
  assign dst_ready_o = dst_clear_complete && dst_ready_reg;

  // Generate valid outputs
  assign dst_valid_o = dst_clear_complete && dst_valid_reg;

  // Generate data outputs
  assign dst_data_o = dst_clear_complete ? 0 : dst_data_reg;

endmodule
