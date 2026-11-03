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
  logic clear_req;
  logic clear_ack;
  logic [SYNC_STAGES-1:0] src_sync_valid;
  logic [SYNC_STAGES-1:0] src_sync_ready;
  logic [SYNC_STAGES-1:0] dst_sync_valid;
  logic [SYNC_STAGES-1:0] dst_sync_ready;

  // Sync src signals to dst clock domain
  generate
    for (genvar i = 0; i < SYNC_STAGES; i++) begin : src_sync
      always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
          src_sync_valid[i] <= 1'b0;
          src_sync_ready[i] <= 1'b0;
        end else begin
          src_sync_valid[i] <= src_valid_reg;
          src_sync_ready[i] <= dst_ready_reg;
        end
      end
    end
  endgenerate

  // Sync dst signals to src clock domain
  generate
    for (genvar i = 0; i < SYNC_STAGES; i++) begin : dst_sync
      always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
          dst_sync_valid[i] <= 1'b0;
          dst_sync_ready[i] <= 1'b0;
        end else begin
          dst_sync_valid[i] <= dst_valid_reg;
          dst_sync_ready[i] <= src_ready_reg;
        end
      end
    end
  endgenerate

  // Logic to handle clear request
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      clear_req <= 1'b0;
      clear_ack <= 1'b0;
    end else begin
      if (src_clear_i) begin
        clear_req <= 1'b1;
        clear_ack <= 1'b0;
      end else if (clear_ack) begin
        clear_req <= 1'b0;
        clear_ack <= 1'b0;
      end else begin
        clear_req <= 1'b0;
        clear_ack <= 1'b1;
      end
    end
  end

  // Logic to handle clear pending
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pending_o <= 1'b0;
    end else begin
      if (clear_req && !clear_ack) begin
        src_clear_pending_o <= 1'b1;
      end else begin
        src_clear_pending_o <= 1'b0;
      end
    end
  end

  // Logic to handle data transfer
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= 0;
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b0;
    end else begin
      if (src_valid_i && src_ready_reg && !clear_req) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1'b1;
        src_ready_reg <= 1'b0;
      end else if (dst_sync_valid[SYNC_STAGES-1] && dst_sync_ready[SYNC_STAGES-1]) begin
        src_valid_reg <= 1'b0;
        src_ready_reg <= 1'b1;
      end else begin
        src_ready_reg <= 1'b0;
      end
    end
  end

  // Logic to handle dst data and valid
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o <= 0;
      dst_valid_o <= 1'b0;
      dst_ready_reg <= 1'b0;
    end else begin
      if (src_sync_valid[SYNC_STAGES-1] && src_sync_ready[SYNC_STAGES-1]) begin
        dst_data_o <= src_data_reg;
        dst_valid_o <= 1'b1;
        dst_ready_reg <= 1'b0;
      end else if (dst_ready_i && dst_valid_o) begin
        dst_valid_o <= 1'b0;
        dst_ready_reg <= 1'b1;
      end else begin
        dst_ready_reg <= 1'b0;
      end
    end
  end

endmodule
