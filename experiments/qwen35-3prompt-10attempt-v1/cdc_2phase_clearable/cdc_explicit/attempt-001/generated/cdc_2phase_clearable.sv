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

  // Internal signals for CDC crossing
  logic [WIDTH-1:0] src_data_synced;
  logic src_valid_synced;
  logic src_clear_synced;
  logic dst_clear_synced;
  logic dst_valid_synced;
  logic dst_ready_synced;
  logic dst_data_synced;
  logic dst_clear_pending_synced;
  logic src_clear_pending_synced;

  // State machine states
  typedef enum logic [1:0] {
    IDLE,
    SRC_WAIT_READY,
    DST_WAIT_VALID,
    CLEAR_SRC,
    CLEAR_DST
  } fsm_state_t;

  fsm_state_t src_state, dst_state;

  // Source Domain Logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_state <= IDLE;
      src_clear_pending_o <= CLEAR_ON_ASYNC_RESET;
      src_ready_o <= 1'b0;
    end else begin
      case (src_state)
        IDLE: begin
          if (src_clear_i) begin
            src_state <= CLEAR_SRC;
            src_clear_pending_o <= 1'b1;
          end else if (src_valid_i && dst_ready_i) begin
            src_state <= SRC_WAIT_READY;
            src_ready_o <= 1'b1;
          end else begin
            src_state <= IDLE;
            src_ready_o <= 1'b0;
          end
        end

        SRC_WAIT_READY: begin
          if (src_clear_i) begin
            src_state <= CLEAR_SRC;
            src_clear_pending_o <= 1'b1;
          end else if (dst_ready_i) begin
            src_state <= IDLE;
            src_ready_o <= 1'b0;
          end else begin
            src_state <= SRC_WAIT_READY;
            src_ready_o <= 1'b1;
          end
        end

        CLEAR_SRC: begin
          if (src_clear_i) begin
            src_state <= CLEAR_SRC;
            src_clear_pending_o <= 1'b1;
          end else begin
            src_state <= IDLE;
            src_clear_pending_o <= 1'b0;
            src_ready_o <= 1'b0;
          end
        end
      endcase
    end
  end

  // Destination Domain Logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_state <= IDLE;
      dst_clear_pending_o <= CLEAR_ON_ASYNC_RESET;
      dst_valid_o <= 1'b0;
      dst_data_o <= '0;
    end else begin
      case (dst_state)
        IDLE: begin
          if (dst_clear_i) begin
            dst_state <= CLEAR_DST;
            dst_clear_pending_o <= 1'b1;
          end else if (src_valid_synced && dst_ready_synced) begin
            dst_state <= DST_WAIT_VALID;
            dst_valid_o <= 1'b1;
            dst_data_o <= src_data_synced;
          end else begin
            dst_state <= IDLE;
            dst_valid_o <= 1'b0;
            dst_data_o <= '0;
          end
        end

        DST_WAIT_VALID: begin
          if (dst_clear_i) begin
            dst_state <= CLEAR_DST;
            dst_clear_pending_o <= 1'b1;
          end else if (src_valid_synced && dst_ready_synced) begin
            dst_state <= IDLE;
            dst_valid_o <= 1'b0;
            dst_data_o <= '0;
          end else begin
            dst_state <= DST_WAIT_VALID;
            dst_valid_o <= 1'b1;
            dst_data_o <= src_data_synced;
          end
        end

        CLEAR_DST: begin
          if (dst_clear_i) begin
            dst_state <= CLEAR_DST;
            dst_clear_pending_o <= 1'b1;
          end else begin
            dst_state <= IDLE;
            dst_clear_pending_o <= 1'b0;
            dst_valid_o <= 1'b0;
            dst_data_o <= '0;
          end
        end
      endcase
    end
  end

  // CDC Crossing: Source to Destination
  // Use FIFO-like synchronization for multi-bit data and control signals
  logic [SYNC_STAGES-1:0] src_data_fifo;
  logic [SYNC_STAGES-1:0] src_valid_fifo;
  logic [SYNC_STAGES-1:0] src_clear_fifo;
  logic [SYNC_STAGES-1:0] dst_clear_fifo;
  logic [SYNC_STAGES-1:0] dst_valid_fifo;
  logic [SYNC_STAGES-1:0] dst_ready_fifo;
  logic [SYNC_STAGES-1:0] dst_data_fifo;
  logic [SYNC_STAGES-1:0] dst_clear_pending_fifo;
  logic [SYNC_STAGES-1:0] src_clear_pending_fifo;

  // Source Domain: Write to FIFOs
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_fifo <= '{default: '0};
      src_valid_fifo <= '{default: 1'b0};
      src_clear_fifo <= '{default: 1'b0};
      src_clear_pending_fifo <= '{default: 1'b0};
    end else begin
      src_data_fifo <= src_data_fifo[SYNC_STAGES-2:0] ? src_data_fifo[SYNC_STAGES-2:0] : src_data_i;
      src_valid_fifo <= src_valid_fifo[SYNC_STAGES-2:0] ? src_valid_fifo[SYNC_STAGES-2:0] : src_valid_i;
      src_clear_fifo <= src_clear_fifo[SYNC_STAGES-2:0] ? src_clear_fifo[SYNC_STAGES-2:0] : src_clear_i;
      src_clear_pending_fifo <= src_clear_pending_fifo[SYNC_STAGES-2:0] ? src_clear_pending_fifo[SYNC_STAGES-2:0] : src_clear_pending_o;
    end
  end

  // Destination Domain: Read from FIFOs
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_fifo <= '{default: '0};
      dst_valid_fifo <= '{default: 1'b0};
      dst_ready_fifo <= '{default: 1'b0};
      dst_clear_fifo <= '{default: 1'b0};
      dst_clear_pending_fifo <= '{default: 1'b0};
    end else begin
      dst_data_fifo <= dst_data_fifo[SYNC_STAGES-2:0] ? dst_data_fifo[SYNC_STAGES-2:0] : src_data_synced;
      dst_valid_fifo <= dst_valid_fifo[SYNC_STAGES-2:0] ? dst_valid_fifo[SYNC_STAGES-2:0] : src_valid_synced;
      dst_ready_fifo <= dst_ready_fifo[SYNC_STAGES-2:0] ? dst_ready_fifo[SYNC_STAGES-2:0] : dst_ready_i;
      dst_clear_fifo <= dst_clear_fifo[SYNC_STAGES-2:0] ? dst_clear_fifo[SYNC_STAGES-2:0] : dst_clear_i;
      dst_clear_pending_fifo <= dst_clear_pending_fifo[SYNC_STAGES-2:0] ? dst_clear_pending_fifo[SYNC_STAGES-2:0] : dst_clear_pending_o;
    end
  end

  // CDC Crossing: Destination to Source
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_synced <= 1'b0;
      dst_ready_synced <= 1'b0;
      dst_data_synced <= '0;
      dst_clear_synced <= 1'b0;
      dst_clear_pending_synced <= 1'b0;
    end else begin
      dst_valid_synced <= dst_valid_fifo[0];
      dst_ready_synced <= dst_ready_fifo[0];
      dst_data_synced <= dst_data_fifo[0];
      dst_clear_synced <= dst_clear_fifo[0];
      dst_clear_pending_synced <= dst_clear_pending_fifo[0];
    end
  end

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_synced <= '0;
      src_valid_synced <= 1'b0;
      src_clear_synced <= 1'b0;
      src_clear_pending_synced <= 1'b0;
    end else begin
      src_data_synced <= src_data_fifo[0];
      src_valid_synced <= src_valid_fifo[0];
      src_clear_synced <= src_clear_fifo[0];
      src_clear_pending_synced <= src_clear_pending_fifo[0];
    end
  end

  // Assign outputs based on synchronized signals
  assign src_ready_o = src_state == IDLE && src_valid_i && dst_ready_synced;
  assign dst_valid_o = dst_state == IDLE && src_valid_synced && dst_ready_i;
  assign dst_data_o = src_data_synced;
  assign dst_clear_pending_o = dst_clear_pending_synced;
  assign src_clear_pending_o = src_clear_pending_synced;

endmodule
```<|im_end|>
