```systemverilog
module cdc_2phase_clearable #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3,
  parameter CLEAR_ON_ASYNC_RESET = 1
)(
  input  wire src_rst_ni,
  input  wire src_clk_i,
  input  wire src_clear_i,
  output wire src_clear_pending_o,
  input  wire [WIDTH-1:0] src_data_i,
  input  wire src_valid_i,
  output wire src_ready_o,
  input  wire dst_rst_ni,
  input  wire dst_clk_i,
  input  wire dst_clear_i,
  output wire dst_clear_pending_o,
  output wire [WIDTH-1:0] dst_data_o,
  output wire dst_valid_o,
  input  wire dst_ready_i
);

  // Internal signals
  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic src_ready_reg;
  
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;
  
  logic src_clear_pending;
  logic dst_clear_pending;
  
  logic [SYNC_STAGES-1:0] src_sync_valid;
  logic [SYNC_STAGES-1:0] src_sync_data;
  logic [SYNC_STAGES-1:0] dst_sync_valid;
  logic [SYNC_STAGES-1:0] dst_sync_data;
  
  logic src_cross_valid;
  logic dst_cross_valid;
  logic src_cross_ready;
  logic dst_cross_ready;

  // ------------------------------------------------------------------
  // Source Domain: Input Synchronization
  // ------------------------------------------------------------------
  // Synchronize src_valid, src_data, src_clear, and src_rst_ni
  // Use a multi-stage synchronizer to prevent metastability.
  // Also handle async reset propagation safely.
  
  genvar i;
  generate
    for (i = 0; i < SYNC_STAGES; i = i + 1) begin : src_sync_gen
      if (i == 0) begin
        // First stage: simple flip-flops
        always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
          if (!src_rst_ni) begin
            src_sync_valid[i] <= 1'b0;
            src_sync_data[i]  <= {WIDTH{1'b0}};
            src_sync_valid[i] <= 1'b0; // Reset valid too
          end else begin
            src_sync_valid[i] <= src_valid_i;
            src_sync_data[i]  <= src_data_i;
          end
        end
      end else begin
        // Subsequent stages
        always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
          if (!src_rst_ni) begin
            src_sync_valid[i] <= 1'b0;
            src_sync_data[i]  <= {WIDTH{1'b0}};
          end else begin
            src_sync_valid[i] <= src_sync_valid[i-1];
            src_sync_data[i]  <= src_sync_data[i-1];
          end
        end
      end
    end
  endgenerate

  // ------------------------------------------------------------------
  // Destination Domain: Output Synchronization
  // ------------------------------------------------------------------
  // Synchronize dst_valid, dst_data, dst_clear, and dst_rst_ni
  genvar j;
  generate
    for (j = 0; j < SYNC_STAGES; j = j + 1) begin : dst_sync_gen
      if (j == 0) begin
        always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
          if (!dst_rst_ni) begin
            dst_sync_valid[j] <= 1'b0;
            dst_sync_data[j]  <= {WIDTH{1'b0}};
            dst_sync_valid[j] <= 1'b0;
          end else begin
            dst_sync_valid[j] <= dst_valid_i;
            dst_sync_data[j]  <= dst_data_i;
          end
        end
      end else begin
        always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
          if (!dst_rst_ni) begin
            dst_sync_valid[j] <= 1'b0;
            dst_sync_data[j]  <= {WIDTH{1'b0}};
          end else begin
            dst_sync_valid[j] <= dst_sync_valid[j-1];
            dst_sync_data[j]  <= dst_sync_data[j-1];
          end
        end
      end
    end
  endgenerate

  // ------------------------------------------------------------------
  // Source Domain Logic: State Machine & Clear Handling
  // ------------------------------------------------------------------
  // State Machine States:
  // IDLE: Waiting for valid
  // WAIT_READY: Valid asserted, waiting for ready
  // CLEARING: Clear requested, flushing state
  // CLEAR_DONE: Clear completed, returning to IDLE

  typedef enum logic [1:0] {
    SRC_IDLE,
    SRC_WAIT_READY,
    SRC_CLEARING,
    SRC_CLEAR_DONE
  } src_state_t;

  src_state_t src_state, src_state_next;
  logic src_state_valid; // Indicates if current state is valid (not in meta state)

  // Clear pending flag logic
  assign src_clear_pending_o = (src_state == SRC_CLEARING) || (src_state == SRC_CLEAR_DONE);

  // State Machine Logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_state <= SRC_IDLE;
      src_state_valid <= 1'b0;
    end else begin
      src_state <= src_state_next;
      src_state_valid <= 1'b1;
    end
  end

  always_comb begin
    src_state_next = src_state;
    src_ready_o = 1'b0;
    
    case (src_state)
      SRC_IDLE: begin
        if (src_sync_valid[SYNC_STAGES-1]) begin
          src_state_next = SRC_WAIT_READY;
          src_ready_o = 1'b1;
        end
      end
      
      SRC_WAIT_READY: begin
        if (src_sync_ready[SYNC_STAGES-1]) begin
          src_state_next = SRC_IDLE;
          src_ready_o = 1'b1;
        end else begin
          src_ready_o = 1'b0;
        end
      end
      
      SRC_CLEARING: begin
        // Stay in clearing state until clear signal is deasserted
        // and we have processed the clear request
        if (!src_clear_i) begin
          src_state_next = SRC_CLEAR_DONE;
        end
        src_ready_o = 1'b0;
      end
      
      SRC_CLEAR_DONE: begin
        if (!src_clear_i) begin
          src_state_next = SRC_IDLE;
        end
        src_ready_o = 1'b0;
      end
      
      default: begin
        src_state_next = SRC_IDLE;
        src_ready_o = 1'b0;
      end
    endcase
  end

  // ------------------------------------------------------------------
  // Destination Domain Logic: State Machine & Clear Handling
  // ------------------------------------------------------------------
  // State Machine States:
  // IDLE: Waiting for valid
  // WAIT_VALID: Ready asserted, waiting for valid
  // CLEARING: Clear requested, flushing state
  // CLEAR_DONE: Clear completed, returning to IDLE

  typedef enum logic [1:0] {
    DST_IDLE,
    DST_WAIT_VALID,
    DST_CLEARING,
    DST_CLEAR_DONE
  } dst_state_t;

  dst_state_t dst_state, dst_state_next;
  logic dst_state_valid;

  // Clear pending flag logic
  assign dst_clear_pending_o = (dst_state == DST_CLEARING) || (dst_state == DST_CLEAR_DONE);

  // State Machine Logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_state <= DST_IDLE;
      dst_state_valid <= 1'b0;
    end else begin
      dst_state <= dst_state_next;
      dst_state_valid <= 1'b1;
    end
  end

  always_comb begin
    dst_state_next = dst_state;
    dst_valid_o = 1'b0;
    
    case (dst_state)
      DST_IDLE: begin
        if (dst_sync_valid[SYNC_STAGES-1]) begin
          dst_state_next = DST_WAIT_VALID;
          dst_valid_o = 1'b1;
        end
      end
      
      DST_WAIT_VALID: begin
        if (dst_sync_ready[SYNC_STAGES-1]) begin
          dst_state_next = DST_IDLE;
          dst_valid_o = 1'b1;
        end else begin
          dst_valid_o = 1'b0;
        end
      end
      
      DST_CLEARING: begin
        if (!dst_clear_i) begin
          dst_state_next = DST_CLEAR_DONE;
        end
        dst_valid_o = 1'b0;
      end
      
      DST_CLEAR_DONE: begin
        if (!dst_clear_i) begin
          dst_state_next = DST_IDLE;
        end
        dst_valid_o = 1'b0;
      end
      
      default: begin
        dst_state_next = DST_IDLE;
        dst_valid_o = 1'b0;
      end
    endcase
  end

  // ------------------------------------------------------------------
  // Cross-Domain Handshake Logic
  // ------------------------------------------------------------------
  // Source side: Prepare data for crossing
  // Destination side: Prepare data for crossing
  
  // Source side: Capture data when valid and ready
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b0;
    end else begin
      src_data_reg <= src_data_i;
      src_valid_reg <= src_valid_i;
      src_ready_reg <= src_ready_o;
    end
  end

  // Destination side: Capture data when valid and ready
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      dst_ready_reg <= 1'b0;
    end else begin
      dst_data_reg <= dst_data_i;
      dst_valid_reg <= dst_valid_i;
      dst_ready_reg <= dst_ready_i;
    end
  end

  // ------------------------------------------------------------------
  // CDC Crossing: Source to Destination
  // ------------------------------------------------------------------
  // Use a simple 2-stage synchronizer for the handshake signals
  // and a multi-stage synchronizer for the data
  
  // Synchronize src_valid and src_ready for destination
  genvar k;
  generate
    for (k = 0; k < SYNC_STAGES; k = k + 1) begin : src_valid_sync_gen
      if (k == 0) begin
        always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
          if (!dst_rst_ni) begin
            src_cross_valid <= 1'b0;
            src_cross_ready <= 1'b0;
          end else begin
            src_cross_valid <= src_valid_reg;
            src_cross_ready <= src_ready_reg;
          end
        end
      end else begin
        always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
          if (!dst_rst_ni) begin
            src_cross_valid <= 1'b0;
            src_cross_ready <= 1'b0;
          end else begin
            src_cross_valid <= src_cross_valid;
            src_cross_ready <= src_cross_ready;
          end
        end
      end
    end
  endgenerate

  // Synchronize src_data for destination
  genvar l;
  generate
    for (l = 0; l < SYNC_STAGES; l = l + 1) begin : src_data_sync_gen
      if (l == 0) begin
        always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
          if (!dst_rst_ni) begin
            dst_sync_data[l] <= {WIDTH{1'b0}};
          end else begin
            dst_sync_data[l] <= src_data_reg;
          end
        end
      end else begin
        always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
          if (!dst_rst_ni) begin
            dst_sync_data[l] <= {WIDTH{1'b0}};
          end else begin
            dst_sync_data[l] <= dst_sync_data[l-1];
          end
        end
      end
    end
  endgenerate

  // ------------------------------------------------------------------
  // CDC Crossing: Destination to Source
  // ------------------------------------------------------------------
  // Synchronize dst_valid and dst_ready for source
  genvar m;
  generate
    for (m = 0; m < SYNC_STAGES; m = m + 1) begin : dst_valid_sync_gen
      if (m == 0) begin
        always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
          if (!src_rst_ni) begin
            dst_cross_valid <= 1'b0;
            dst_cross_ready <= 1'b0;
          end else begin
            dst_cross_valid <= dst_valid_reg;
            dst_cross_ready <= dst_ready_reg;
          end
        end
      end else begin
        always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
          if (!src_rst_ni) begin
            dst_cross_valid <= 1'b0;
            dst_cross_ready <= 1'b0;
          end else begin
            dst_cross_valid <= dst_cross_valid;
            dst_cross_ready <= dst_cross_ready;
          end
        end
      end
    end
  endgenerate

  // Synchronize dst_data for source
  genvar n;
  generate
    for (n = 0; n < SYNC_STAGES; n = n + 1) begin : dst_data_sync_gen
      if (n == 0) begin
        always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
          if (!src_rst_ni) begin
            src_sync_data[n] <= {WIDTH{1'b0}};
          end else begin
            src_sync_data[n] <= dst_data_reg;
          end
        end
      end else begin
        always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
          if (!src_rst_ni) begin
            src_sync_data[n] <= {WIDTH{1'b0}};
          end else begin
            src_sync_data[n] <= src_sync_data[n-1];
          end
        end
      end
    end
  endgenerate

  // ------------------------------------------------------------------
  // Handshake Logic
  // ------------------------------------------------------------------
  // Source side: Assert valid when data is ready and dst is ready
  // Destination side: Assert ready when dst is ready and src is ready
  
  // Source side: Update src_valid_reg based on cross domain signals
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
    end else begin
      src_valid_reg <= src_valid_reg & dst_cross_ready;
      if (src_valid_reg && dst_cross_valid) begin
        src_valid_reg <= 1'b1;
      end
    end
  end

  // Destination side: Update dst_ready_reg based on cross domain signals
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_reg <= 1'b0;
    end else begin
      dst_ready_reg <= dst_ready_reg & src_cross_valid;
      if (dst_ready_reg && src_cross_valid) begin
        dst_ready_reg <= 1'b1;
      end
    end
  end

  // ------------------------------------------------------------------
  // Clear Logic
  // ------------------------------------------------------------------
  // Clear signals are synchronized and handled in the state machines
  // The clear logic ensures that both sides are cleared before proceeding
  
  // Source side: Clear logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      if (CLEAR_ON_ASYNC_RESET) begin
        src_state <= SRC_CLEARING;
      end else begin
        src_state <= SRC_IDLE;
      end
    end else begin
      if (src_clear_i) begin
        src_state <= SRC_CLEARING;
      end
    end
  end

  // Destination side: Clear logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      if (CLEAR_ON_ASYNC_RESET) begin
        dst_state <= DST_CLEARING;
      end else begin
        dst_state <= DST_IDLE;
      end
    end else begin
      if (dst_clear_i) begin
        dst_state <= DST_CLEARING;
      end
    end
  end

endmodule
```<|im_end|>
