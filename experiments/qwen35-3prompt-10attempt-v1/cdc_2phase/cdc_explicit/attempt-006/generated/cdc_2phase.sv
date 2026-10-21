module cdc_2phase #(
  parameter WIDTH = 1
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
  logic src_valid_reg;
  logic src_ready_reg;
  logic [WIDTH-1:0] src_data_reg;

  // Destination domain signals
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic [WIDTH-1:0] dst_data_reg;

  // State machine for the handshake
  typedef enum logic [1:0] {
    IDLE,
    WAIT_DST_READY
  } state_t;

  state_t state_reg;
  logic state_next;

  // Synchronize src_valid_i to destination clock domain
  logic src_valid_synced;
  logic [1:0] src_valid_sync_cnt;

  // Synchronize dst_ready_i to source clock domain
  logic dst_ready_synced;
  logic [1:0] dst_ready_sync_cnt;

  // Synchronize resets
  logic src_rst_n_synced;
  logic dst_rst_n_synced;

  // ------------------------------------------------------------------
  // Reset Synchronization
  // ------------------------------------------------------------------
  always_ff @(posedge src_clk_i or posedge src_rst_ni) begin
    if (!src_rst_ni)
      src_rst_n_synced <= 1'b1;
    else
      src_rst_n_synced <= src_rst_n_synced;
  end

  always_ff @(posedge dst_clk_i or posedge dst_rst_ni) begin
    if (!dst_rst_ni)
      dst_rst_n_synced <= 1'b1;
    else
      dst_rst_n_synced <= dst_rst_n_synced;
  end

  // ------------------------------------------------------------------
  // Signal Synchronization
  // ------------------------------------------------------------------
  // Synchronize src_valid_i to dst_clk_i
  always_ff @(posedge dst_clk_i or posedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync_cnt <= 2'b00;
      src_valid_synced  <= 1'b0;
    end else begin
      src_valid_sync_cnt <= src_valid_sync_cnt + 1'b1;
      if (src_valid_sync_cnt[1:0] == 2'b11)
        src_valid_synced <= src_valid_i;
      else
        src_valid_synced <= 1'b0;
    end
  end

  // Synchronize dst_ready_i to src_clk_i
  always_ff @(posedge src_clk_i or posedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_sync_cnt <= 2'b00;
      dst_ready_synced   <= 1'b0;
    end else begin
      dst_ready_sync_cnt <= dst_ready_sync_cnt + 1'b1;
      if (dst_ready_sync_cnt[1:0] == 2'b11)
        dst_ready_synced <= dst_ready_i;
      else
        dst_ready_synced <= 1'b0;
    end
  end

  // ------------------------------------------------------------------
  // State Machine Logic
  // ------------------------------------------------------------------
  always_ff @(posedge src_clk_i or posedge src_rst_ni) begin
    if (!src_rst_ni)
      state_reg <= IDLE;
    else
      state_reg <= state_next;
  end

  always_comb begin
    state_next = state_reg;
    src_ready_o = 1'b0;
    dst_valid_o = 1'b0;
    dst_data_o  = {WIDTH{1'b0}};

    case (state_reg)
      IDLE: begin
        // Check if we have a valid source item and destination is ready
        if (src_valid_i && dst_ready_synced) begin
          state_next = WAIT_DST_READY;
          src_ready_o = 1'b1;
        end else begin
          src_ready_o = 1'b0;
        end
      end

      WAIT_DST_READY: begin
        // Hold the item and wait for destination to be ready
        if (dst_ready_synced) begin
          state_next = IDLE;
          src_ready_o = 1'b1;
        end else begin
          src_ready_o = 1'b0;
        end
      end
    endcase
  end

  // ------------------------------------------------------------------
  // Data Transfer Logic
  // ------------------------------------------------------------------
  // Capture source data when transitioning to WAIT_DST_READY
  always_ff @(posedge src_clk_i or posedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
    end else begin
      // Capture data when entering WAIT_DST_READY state
      if (state_reg == IDLE && src_valid_i && dst_ready_synced) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1'b1;
      end else if (state_reg == WAIT_DST_READY && dst_ready_synced) begin
        // Clear after successful transfer
        src_data_reg <= {WIDTH{1'b0}};
        src_valid_reg <= 1'b0;
      end else begin
        // Hold values
        src_data_reg <= src_data_reg;
        src_valid_reg <= src_valid_reg;
      end
    end
  end

  // Drive destination outputs based on synchronized state
  always_ff @(posedge dst_clk_i or posedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
      dst_data_reg  <= {WIDTH{1'b0}};
    end else begin
      // Drive valid and data when we have a pending item
      if (src_valid_reg) begin
        dst_valid_reg <= 1'b1;
        dst_data_reg  <= src_data_reg;
      end else begin
        dst_valid_reg <= 1'b0;
        dst_data_reg  <= {WIDTH{1'b0}};
      end
    end
  end

endmodule<|im_end|>
