module cdc_2phase_clearable #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3,
  parameter CLEAR_ON_ASYNC_RESET = 1
)(
  input  logic src_rst_ni,
  input  logic src_clk_i,
  input  logic src_clear_i,
  output logic src_clear_pending_o,
  input  logic [WIDTH-1:0] src_data_i,
  input  logic src_valid_i,
  output logic src_ready_o,
  input  logic dst_rst_ni,
  input  logic dst_clk_i,
  input  logic dst_clear_i,
  output logic dst_clear_pending_o,
  output logic [WIDTH-1:0] dst_data_o,
  output logic dst_valid_o,
  input  logic dst_ready_i
);

  logic src_valid_sync;
  logic [WIDTH-1:0] src_data_sync;
  logic src_clear_sync;
  logic dst_clear_sync;
  logic src_valid_dst;
  logic [WIDTH-1:0] src_data_dst;
  logic dst_valid_sync;
  logic [WIDTH-1:0] dst_data_sync;
  logic dst_valid_dst;
  logic src_ready_sync;
  logic dst_ready_sync;

  // Synchronize src_valid and src_data to dst_clk_i
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync <= 1'b0;
      src_data_sync <= '0;
    end else if (dst_clear_i) begin
      src_valid_sync <= 1'b0;
      src_data_sync <= '0;
    end else if (dst_valid_sync && dst_ready_i) begin
      src_valid_sync <= 1'b0;
      src_data_sync <= '0;
    end else if (src_valid_dst && !dst_valid_sync) begin
      src_valid_sync <= 1'b1;
      src_data_sync <= src_data_dst;
    end
  end

  // Synchronize src_clear to dst_clk_i
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_clear_sync <= 1'b0;
    end else if (dst_clear_i) begin
      src_clear_sync <= 1'b0;
    end else if (src_clear_i) begin
      src_clear_sync <= 1'b1;
    end
  end

  // Synchronize dst_clear to src_clk_i
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_clear_sync <= 1'b0;
    end else if (src_clear_i) begin
      dst_clear_sync <= 1'b0;
    end else if (dst_clear_i) begin
      dst_clear_sync <= 1'b1;
    end
  end

  // Synchronize src_valid and src_data to src_clk_i
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_dst <= 1'b0;
      src_data_dst <= '0;
    end else if (src_clear_i) begin
      src_valid_dst <= 1'b0;
      src_data_dst <= '0;
    end else if (src_valid_i && src_ready_o) begin
      src_valid_dst <= 1'b0;
      src_data_dst <= '0;
    end else if (src_valid_i && !src_valid_dst) begin
      src_valid_dst <= 1'b1;
      src_data_dst <= src_data_i;
    end
  end

  // Synchronize dst_valid and dst_data to dst_clk_i
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_sync <= 1'b0;
      dst_data_sync <= '0;
    end else if (dst_clear_i) begin
      dst_valid_sync <= 1'b0;
      dst_data_sync <= '0;
    end else if (dst_valid_dst && dst_ready_i) begin
      dst_valid_sync <= 1'b0;
      dst_data_sync <= '0;
    end else if (src_valid_sync && !dst_valid_sync) begin
      dst_valid_sync <= 1'b1;
      dst_data_sync <= src_data_sync;
    end
  end

  // Synchronize dst_valid and dst_data to dst_clk_i
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_dst <= 1'b0;
      dst_data_o <= '0;
      dst_valid_o <= 1'b0;
    end else if (dst_clear_i) begin
      dst_valid_dst <= 1'b0;
      dst_data_o <= '0;
      dst_valid_o <= 1'b0;
    end else if (dst_valid_sync && dst_ready_i) begin
      dst_valid_dst <= 1'b0;
      dst_data_o <= '0;
      dst_valid_o <= 1'b0;
    end else if (dst_valid_sync && !dst_valid_dst) begin
      dst_valid_dst <= 1'b1;
      dst_data_o <= dst_data_sync;
      dst_valid_o <= 1'b1;
    end else if (!dst_valid_sync && dst_valid_dst) begin
      dst_valid_o <= 1'b0;
    end
  end

  // Generate src_ready
  always_comb begin
    if (src_clear_i || dst_clear_sync) begin
      src_ready_o = 1'b0;
    end else if (src_valid_dst) begin
      src_ready_o = 1'b0;
    end else begin
      src_ready_o = 1'b1;
    end
  end

  // Generate dst_clear_pending
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pending_o <= 1'b0;
    end else if (dst_clear_i) begin
      dst_clear_pending_o <= 1'b1;
    end else if (src_clear_sync && !dst_valid_sync) begin
      dst_clear_pending_o <= 1'b0;
    end
  end

  // Generate src_clear_pending
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pending_o <= 1'b0;
    end else if (src_clear_i) begin
      src_clear_pending_o <= 1'b1;
    end else if (dst_clear_sync && !src_valid_dst) begin
      src_clear_pending_o <= 1'b0;
    end
  end

  // Synchronize src_valid and src_data to dst_clk_i
  logic [SYNC_STAGES-1:0] src_valid_sync_reg;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync_reg <= '0;
    end else if (dst_clear_i) begin
      src_valid_sync_reg <= '0;
    end else begin
      src_valid_sync_reg <= {src_valid_sync_reg[SYNC_STAGES-2:0], src_valid_i};
    end
  end
  assign src_valid_sync = src_valid_sync_reg[SYNC_STAGES-1];

  // Synchronize src_data to dst_clk_i
  logic [WIDTH-1:0] src_data_sync_reg [SYNC_STAGES-1:0];
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_data_sync_reg <= '0;
    end else if (dst_clear_i) begin
      src_data_sync_reg <= '0;
    end else begin
      src_data_sync_reg[0] <= src_data_i;
      for (int i = 1; i < SYNC_STAGES; i++) begin
        src_data_sync_reg[i] <= src_data_sync_reg[i-1];
      end
    end
  end
  assign src_data_sync = src_data_sync_reg[SYNC_STAGES-1];

  // Synchronize dst_clear to src_clk_i
  logic [SYNC_STAGES-1:0] dst_clear_sync_reg;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_clear_sync_reg <= '0;
    end else if (src_clear_i) begin
      dst_clear_sync_reg <= '0;
    end else begin
      dst_clear_sync_reg <= {dst_clear_sync_reg[SYNC_STAGES-2:0], dst_clear_i};
    end
  end
  assign dst_clear_sync = dst_clear_sync_reg[SYNC_STAGES-1];

  // Synchronize src_clear to dst_clk_i
  logic [SYNC_STAGES-1:0] src_clear_sync_reg;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_clear_sync_reg <= '0;
    end else if (dst_clear_i) begin
      src_clear_sync_reg <= '0;
    end else begin
      src_clear_sync_reg <= {src_clear_sync_reg[SYNC_STAGES-2:0], src_clear_i};
    end
  end
  assign src_clear_sync = src_clear_sync_reg[SYNC_STAGES-1];

endmodule
