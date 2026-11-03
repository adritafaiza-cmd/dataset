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

  localparam STAGE_WIDTH = SYNC_STAGES + 1;

  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic src_ready_reg;
  logic src_clear_reg;
  logic [STAGE_WIDTH-1:0] src_clear_pending;
  logic [STAGE_WIDTH-1:0] dst_clear_pending;
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_reg;

  logic [SYNC_STAGES-1:0] src_valid_sync;
  logic [SYNC_STAGES-1:0] src_ready_sync;
  logic [SYNC_STAGES-1:0] src_clear_sync;
  logic [SYNC_STAGES-1:0] dst_valid_sync;
  logic [SYNC_STAGES-1:0] dst_ready_sync;

  logic [SYNC_STAGES-1:0] src_clear_pending_sync;
  logic [SYNC_STAGES-1:0] dst_clear_pending_sync;

  logic [SYNC_STAGES-1:0] src_clear_active;
  logic [SYNC_STAGES-1:0] dst_clear_active;

  logic src_clear_active_reg;
  logic dst_clear_active_reg;

  logic src_clear_finished;
  logic dst_clear_finished;

  logic [SYNC_STAGES-1:0] src_clear_finished_sync;
  logic [SYNC_STAGES-1:0] dst_clear_finished_sync;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= 0;
      src_valid_reg <= 0;
      src_ready_reg <= 0;
      src_clear_reg <= 0;
      src_clear_pending <= 0;
      src_clear_active <= 0;
      src_clear_active_reg <= 0;
      src_clear_finished <= 0;
    end else begin
      src_data_reg <= src_data_i;
      src_valid_reg <= src_valid_i;
      src_ready_reg <= dst_ready_i;
      src_clear_reg <= src_clear_i;
      src_clear_active <= src_clear_active | src_clear_reg;
      src_clear_active_reg <= src_clear_active;
      src_clear_finished <= src_clear_active_reg & ~src_clear_reg;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= 0;
      dst_valid_reg <= 0;
      dst_clear_reg <= 0;
      dst_clear_pending <= 0;
      dst_clear_active <= 0;
      dst_clear_active_reg <= 0;
      dst_clear_finished <= 0;
    end else begin
      dst_data_reg <= src_data_reg;
      dst_valid_reg <= src_valid_reg;
      dst_clear_reg <= dst_clear_i;
      dst_clear_active <= dst_clear_active | dst_clear_reg;
      dst_clear_active_reg <= dst_clear_active;
      dst_clear_finished <= dst_clear_active_reg & ~dst_clear_reg;
    end
  end

  generate
    for (genvar i = 0; i < SYNC_STAGES; i++) begin : sync_stages
      always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
          src_valid_sync[i] <= 0;
          src_ready_sync[i] <= 0;
          src_clear_sync[i] <= 0;
          src_clear_pending_sync[i] <= 0;
        end else begin
          src_valid_sync[i] <= src_valid_reg;
          src_ready_sync[i] <= src_ready_reg;
          src_clear_sync[i] <= src_clear_reg;
          src_clear_pending_sync[i] <= src_clear_active_reg;
        end
      end

      always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
          dst_valid_sync[i] <= 0;
          dst_ready_sync[i] <= 0;
          dst_clear_sync[i] <= 0;
          dst_clear_pending_sync[i] <= 0;
        end else begin
          dst_valid_sync[i] <= src_valid_reg;
          dst_ready_sync[i] <= src_ready_reg;
          dst_clear_sync[i] <= src_clear_reg;
          dst_clear_pending_sync[i] <= src_clear_active_reg;
        end
      end
    end
  endgenerate

  assign src_ready_o = src_ready_sync[SYNC_STAGES-1];
  assign dst_valid_o = dst_valid_sync[SYNC_STAGES-1];
  assign src_clear_pending_o = src_clear_pending_sync[SYNC_STAGES-1];
  assign dst_clear_pending_o = dst_clear_pending_sync[SYNC_STAGES-1];

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_finished_sync <= 0;
    end else begin
      src_clear_finished_sync <= src_clear_finished;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_finished_sync <= 0;
    end else begin
      dst_clear_finished_sync <= dst_clear_finished;
    end
  end

endmodule
