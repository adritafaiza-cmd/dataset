```systemverilog
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

  localparam NUM_SYNC = SYNC_STAGES;

  // State encoding for the handshake channel
  // IDLE: No data in flight
  // IN_FLIGHT: Data has been accepted by src and is being transferred to dst
  // CLEARING_SRC: Source side is flushing (waiting for dst to clear)
  // CLEARING_DST: Destination side is flushing (waiting for src to clear)
  // CLEAR_DONE: Both sides have finished clearing (transient state before IDLE)
  typedef enum logic [1:0] {
    IDLE,
    IN_FLIGHT,
    CLEARING_SRC,
    CLEARING_DST,
    CLEAR_DONE
  } t_state;

  // Source Domain Signals
  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic src_ready_reg;
  logic src_clear_pending;
  logic src_state;

  // Destination Domain Signals
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic dst_clear_pending;
  logic dst_state;

  // Cross-domain signals (registered in respective domains)
  logic src_valid_synced;
  logic src_ready_synced;
  logic dst_valid_synced;
  logic dst_ready_synced;
  logic src_clear_synced;
  logic dst_clear_synced;

  // ---------------------------------------------------------
  // Source Domain Logic
  // ---------------------------------------------------------
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_state <= IDLE;
      src_data_reg <= '0;
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b1;
      src_clear_pending <= 1'b0;
    end else begin
      // Handle async reset clearing if enabled
      if (CLEAR_ON_ASYNC_RESET && !src_rst_ni) begin
        src_state <= IDLE;
        src_data_reg <= '0;
        src_valid_reg <= 1'b0;
        src_ready_reg <= 1'b1;
        src_clear_pending <= 1'b0;
      end else begin
        // State Machine
        case (src_state)
          IDLE: begin
            if (src_valid_i && dst_ready_synced) begin
              src_state <= IN_FLIGHT;
              src_data_reg <= src_data_i;
              src_valid_reg <= 1'b1;
              src_ready_reg <= 1'b0;
            end else begin
              src_ready_reg <= 1'b1;
            end
          end

          IN_FLIGHT: begin
            if (src_clear_i) begin
              src_state <= CLEARING_SRC;
              src_clear_pending <= 1'b1;
            end else if (dst_ready_synced) begin
              src_state <= IDLE;
              src_valid_reg <= 1'b0;
              src_ready_reg <= 1'b1;
            end else begin
              src_ready_reg <= 1'b0;
            end
          end

          CLEARING_SRC: begin
            if (dst_clear_synced) begin
              src_state <= CLEAR_DONE;
              src_clear_pending <= 1'b0;
            end else begin
              src_clear_pending <= 1'b1;
            end
          end

          CLEAR_DONE: begin
            src_state <= IDLE;
            src_clear_pending <= 1'b0;
          end
        endcase
      end
    end
  end

  // ---------------------------------------------------------
  // Destination Domain Logic
  // ---------------------------------------------------------
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_state <= IDLE;
      dst_data_reg <= '0;
      dst_valid_reg <= 1'b0;
      dst_ready_reg <= 1'b1;
      dst_clear_pending <= 1'b0;
    end else begin
      // Handle async reset clearing if enabled
      if (CLEAR_ON_ASYNC_RESET && !dst_rst_ni) begin
        dst_state <= IDLE;
        dst_data_reg <= '0;
        dst_valid_reg <= 1'b0;
        dst_ready_reg <= 1'b1;
        dst_clear_pending <= 1'b0;
      end else begin
        // State Machine
        case (dst_state)
          IDLE: begin
            if (src_valid_synced && dst_ready_i) begin
              dst_state <= IN_FLIGHT;
              dst_data_reg <= src_data_reg;
              dst_valid_reg <= 1'b1;
              dst_ready_reg <= 1'b0;
            end else begin
              dst_ready_reg <= 1'b1;
            end
          end

          IN_FLIGHT: begin
            if (dst_clear_i) begin
              dst_state <= CLEARING_DST;
              dst_clear_pending <= 1'b1;
            end else if (dst_ready_i) begin
              dst_state <= IDLE;
              dst_valid_reg <= 1'b0;
              dst_ready_reg <= 1'b1;
            end else begin
              dst_ready_reg <= 1'b0;
            end
          end

          CLEARING_DST: begin
            if (src_clear_synced) begin
              dst_state <= CLEAR_DONE;
              dst_clear_pending <= 1'b0;
            end else begin
              dst_clear_pending <= 1'b1;
            end
          end

          CLEAR_DONE: begin
            dst_state <= IDLE;
            dst_clear_pending <= 1'b0;
          end
        endcase
      end
    end
  end

  // ---------------------------------------------------------
  // CDC Synchronization
  // ---------------------------------------------------------
  // Source signals to Destination (2-stage sync)
  genvar i;
  generate
    for (i = 0; i < NUM_SYNC; i = i + 1) begin : src_sync_stage
      logic src_sync_tmp;
      always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
          src_sync_tmp <= 1'b0;
        else
          src_sync_tmp <= src_valid_synced ? src_valid_synced : 1'b0;
      end
      if (i == 0)
        assign src_valid_synced = src_sync_tmp;
      else
        assign src_valid_synced = src_sync_tmp; // Reuse for clarity, logic is sequential
    end
  endgenerate

  // Corrected explicit 2-stage sync for clarity and robustness
  logic [NUM_SYNC-1:0] src_valid_pipe;
  logic [NUM_SYNC-1:0] src_ready_pipe;
  logic [NUM_SYNC-1:0] src_clear_pipe;
  logic [NUM_SYNC-1:0] dst_valid_pipe;
  logic [NUM_SYNC-1:0] dst_ready_pipe;
  logic [NUM_SYNC-1:0] dst_clear_pipe;

  // Source -> Dest Sync
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_pipe <= '0;
      src_ready_pipe <= '1;
      src_clear_pipe <= '0;
    end else begin
      src_valid_pipe[0] <= src_valid_i;
      src_ready_pipe[0] <= src_ready_o;
      src_clear_pipe[0] <= src_clear_i;
      for (i = 1; i < NUM_SYNC; i = i + 1) begin
        src_valid_pipe[i] <= src_valid_pipe[i-1];
        src_ready_pipe[i] <= src_ready_pipe[i-1];
        src_clear_pipe[i] <= src_clear_pipe[i-1];
      end
    end
  end

  // Dest -> Src Sync
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_valid_pipe <= '0;
      dst_ready_pipe <= '1;
      dst_clear_pipe <= '0;
    end else begin
      dst_valid_pipe[0] <= dst_valid_o;
      dst_ready_pipe[0] <= dst_ready_i;
      dst_clear_pipe[0] <= dst_clear_i;
      for (i = 1; i < NUM_SYNC; i = i + 1) begin
        dst_valid_pipe[i] <= dst_valid_pipe[i-1];
        dst_ready_pipe[i] <= dst_ready_pipe[i-1];
        dst_clear_pipe[i] <= dst_clear_pipe[i-1];
      end
    end
  end

  // Assignments after synchronization
  assign src_ready_o = src_ready_pipe[NUM_SYNC-1];
  assign dst_valid_o = dst_valid_pipe[NUM_SYNC-1];
  assign dst_ready_reg = dst_ready_pipe[NUM_SYNC-1]; // Used internally by dst logic
  assign src_clear_synced = src_clear_pipe[NUM_SYNC-1];
  assign dst_clear_synced = dst_clear_pipe[NUM_SYNC-1];

  // Output pending flags
  assign src_clear_pending_o = src_clear_pending;
  assign dst_clear_pending_o = dst_clear_pending;

  // Data output
  assign dst_data_o = dst_data_reg;

endmodule
```<|im_end|>
