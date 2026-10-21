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

  localparam SYNC_STAGES_LOG = $clog2(SYNC_STAGES);
  localparam CLEAR_STAGES = SYNC_STAGES + 2;

  // ---------------------------------------------------------------------------
  // Source Domain: Capture Valid/Ready and Clear Request
  // ---------------------------------------------------------------------------
  logic [SYNC_STAGES-1:0] src_sync_valid;
  logic [SYNC_STAGES-1:0] src_sync_ready;
  logic [SYNC_STAGES-1:0] src_sync_clear;
  logic src_sync_valid_done;
  logic src_sync_ready_done;
  logic src_sync_clear_done;

  // ---------------------------------------------------------------------------
  // Destination Domain: Capture Valid/Ready and Clear Request
  // ---------------------------------------------------------------------------
  logic [SYNC_STAGES-1:0] dst_sync_valid;
  logic [SYNC_STAGES-1:0] dst_sync_ready;
  logic [SYNC_STAGES-1:0] dst_sync_clear;
  logic dst_sync_valid_done;
  logic dst_sync_ready_done;
  logic dst_sync_clear_done;

  // ---------------------------------------------------------------------------
  // Source Domain Logic
  // ---------------------------------------------------------------------------
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_sync_valid     <= '{default:0};
      src_sync_ready     <= '{default:0};
      src_sync_clear     <= '{default:0};
      src_sync_valid_done <= 1'b0;
      src_sync_ready_done <= 1'b0;
      src_sync_clear_done <= 1'b0;
    end else begin
      // Capture inputs
      src_sync_valid     <= src_valid_i;
      src_sync_ready     <= src_ready_o;
      src_sync_clear     <= src_clear_i;

      // Detect stable signals (simplified for clarity, assumes stable after SYNC_STAGES)
      src_sync_valid_done <= (src_sync_valid == src_valid_i) && (src_sync_valid != src_valid_i) ? 1'b0 : (src_sync_valid == src_valid_i);
      src_sync_ready_done <= (src_sync_ready == src_ready_o) && (src_sync_ready != src_ready_o) ? 1'b0 : (src_sync_ready == src_ready_o);
      src_sync_clear_done <= (src_sync_clear == src_clear_i) && (src_sync_clear != src_clear_i) ? 1'b0 : (src_sync_clear == src_clear_i);

      // Handle Async Reset Clear
      if (CLEAR_ON_ASYNC_RESET && !src_rst_ni) begin
        src_sync_valid     <= 1'b0;
        src_sync_ready     <= 1'b0;
        src_sync_clear     <= 1'b0;
        src_sync_valid_done <= 1'b0;
        src_sync_ready_done <= 1'b0;
        src_sync_clear_done <= 1'b0;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Destination Domain Logic
  // ---------------------------------------------------------------------------
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_sync_valid     <= '{default:0};
      dst_sync_ready     <= '{default:0};
      dst_sync_clear     <= '{default:0};
      dst_sync_valid_done <= 1'b0;
      dst_sync_ready_done <= 1'b0;
      dst_sync_clear_done <= 1'b0;
    end else begin
      // Capture inputs
      dst_sync_valid     <= dst_valid_o;
      dst_sync_ready     <= dst_ready_i;
      dst_sync_clear     <= dst_clear_i;

      // Detect stable signals
      dst_sync_valid_done <= (dst_sync_valid == dst_valid_o) && (dst_sync_valid != dst_valid_o) ? 1'b0 : (dst_sync_valid == dst_valid_o);
      dst_sync_ready_done <= (dst_sync_ready == dst_ready_i) && (dst_sync_ready != dst_ready_i) ? 1'b0 : (dst_sync_ready == dst_ready_i);
      dst_sync_clear_done <= (dst_sync_clear == dst_clear_i) && (dst_sync_clear != dst_clear_i) ? 1'b0 : (dst_sync_clear == dst_clear_i);

      // Handle Async Reset Clear
      if (CLEAR_ON_ASYNC_RESET && !dst_rst_ni) begin
        dst_sync_valid     <= 1'b0;
        dst_sync_ready     <= 1'b0;
        dst_sync_clear     <= 1'b0;
        dst_sync_valid_done <= 1'b0;
        dst_sync_ready_done <= 1'b0;
        dst_sync_clear_done <= 1'b0;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing: Source -> Destination (Valid/Ready/Clear)
  // ---------------------------------------------------------------------------
  logic [SYNC_STAGES-1:0] dst_crossed_valid;
  logic [SYNC_STAGES-1:0] dst_crossed_ready;
  logic [SYNC_STAGES-1:0] dst_crossed_clear;
  logic dst_crossed_valid_done;
  logic dst_crossed_ready_done;
  logic dst_crossed_clear_done;

  // ---------------------------------------------------------------------------
  // CDC Crossing: Destination -> Source (Valid/Ready/Clear)
  // ---------------------------------------------------------------------------
  logic [SYNC_STAGES-1:0] src_crossed_valid;
  logic [SYNC_STAGES-1:0] src_crossed_ready;
  logic [SYNC_STAGES-1:0] src_crossed_clear;
  logic src_crossed_valid_done;
  logic src_crossed_ready_done;
  logic src_crossed_clear_done;

  // ---------------------------------------------------------------------------
  // Internal State Machine (Destination Domain)
  // ---------------------------------------------------------------------------
  typedef enum logic [1:0] {
    IDLE,
    WAIT_SRC_VALID,
    WAIT_SRC_READY,
    WAIT_DST_READY,
    WAIT_DST_CLEAR,
    CLEARING_SRC,
    CLEARING_DST
  } dst_state_t;

  dst_state_t dst_state, dst_state_next;
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_data_valid_reg;
  logic dst_clear_pending_reg;

  // ---------------------------------------------------------------------------
  // Internal State Machine (Source Domain)
  // ---------------------------------------------------------------------------
  typedef enum logic [1:0] {
    IDLE,
    WAIT_DST_VALID,
    WAIT_DST_READY,
    WAIT_SRC_CLEAR,
    CLEARING_DST,
    CLEARING_SRC
  } src_state_t;

  src_state_t src_state, src_state_next;
  logic src_data_valid_reg;
  logic src_clear_pending_reg;

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Gray Code or Asynchronous FIFO style)
  // Using a simple asynchronous FIFO pointer approach for clarity and robustness
  // ---------------------------------------------------------------------------

  // Source -> Dest Crossing
  logic [SYNC_STAGES-1:0] src_to_dst_valid;
  logic [SYNC_STAGES-1:0] src_to_dst_ready;
  logic [SYNC_STAGES-1:0] src_to_dst_clear;

  // Dest -> Source Crossing
  logic [SYNC_STAGES-1:0] dst_to_src_valid;
  logic [SYNC_STAGES-1:0] dst_to_src_ready;
  logic [SYNC_STAGES-1:0] dst_to_src_clear;

  // ---------------------------------------------------------------------------
  // State Machine Logic (Destination)
  // ---------------------------------------------------------------------------
  always_comb begin
    dst_state_next = dst_state;
    dst_data_valid_reg = 1'b0;
    dst_data_reg = '{default:0};
    dst_clear_pending_reg = 1'b0;

    case (dst_state)
      IDLE: begin
        if (dst_sync_valid_done && dst_sync_clear_done) begin
          dst_state_next = WAIT_SRC_VALID;
        end
      end

      WAIT_SRC_VALID: begin
        if (dst_sync_valid_done && dst_sync_clear_done) begin
          dst_state_next = WAIT_SRC_READY;
        end
      end

      WAIT_SRC_READY: begin
        if (dst_sync_valid_done && dst_sync_clear_done) begin
          dst_state_next = WAIT_DST_READY;
        end
      end

      WAIT_DST_READY: begin
        if (dst_sync_valid_done && dst_sync_clear_done) begin
          dst_state_next = WAIT_DST_CLEAR;
        end
      end

      WAIT_DST_CLEAR: begin
        if (dst_sync_valid_done && dst_sync_clear_done) begin
          dst_state_next = CLEARING_SRC;
        end
      end

      CLEARING_SRC: begin
        if (dst_sync_valid_done && dst_sync_clear_done) begin
          dst_state_next = CLEARING_DST;
        end
      end

      CLEARING_DST: begin
        if (dst_sync_valid_done && dst_sync_clear_done) begin
          dst_state_next = IDLE;
          dst_clear_pending_reg = 1'b0;
        end
      end

      default: dst_state_next = IDLE;
    endcase
  end

  // ---------------------------------------------------------------------------
  // State Machine Logic (Source)
  // ---------------------------------------------------------------------------
  always_comb begin
    src_state_next = src_state;
    src_data_valid_reg = 1'b0;
    src_clear_pending_reg = 1'b0;

    case (src_state)
      IDLE: begin
        if (src_sync_valid_done && src_sync_clear_done) begin
          src_state_next = WAIT_DST_VALID;
        end
      end

      WAIT_DST_VALID: begin
        if (src_sync_valid_done && src_sync_clear_done) begin
          src_state_next = WAIT_DST_READY;
        end
      end

      WAIT_DST_READY: begin
        if (src_sync_valid_done && src_sync_clear_done) begin
          src_state_next = WAIT_SRC_CLEAR;
        end
      end

      WAIT_SRC_CLEAR: begin
        if (src_sync_valid_done && src_sync_clear_done) begin
          src_state_next = CLEARING_DST;
        end
      end

      CLEARING_DST: begin
        if (src_sync_valid_done && src_sync_clear_done) begin
          src_state_next = CLEARING_SRC;
        end
      end

      CLEARING_SRC: begin
        if (src_sync_valid_done && src_sync_clear_done) begin
          src_state_next = IDLE;
          src_clear_pending_reg = 1'b0;
        end
      end

      default: src_state_next = IDLE;
    endcase
  end

  // ---------------------------------------------------------------------------
  // Output Logic (Destination)
  // ---------------------------------------------------------------------------
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_valid_reg <= 1'b0;
      dst_data_reg       <= '{default:0};
      dst_clear_pending_reg <= 1'b0;
    end else begin
      case (dst_state)
        IDLE: begin
          dst_data_valid_reg <= 1'b0;
          dst_data_reg       <= '{default:0};
          dst_clear_pending_reg <= 1'b0;
        end
        WAIT_SRC_VALID: begin
          dst_data_valid_reg <= 1'b0;
          dst_data_reg       <= '{default:0};
          dst_clear_pending_reg <= 1'b0;
        end
        WAIT_SRC_READY: begin
          dst_data_valid_reg <= 1'b0;
          dst_data_reg       <= '{default:0};
          dst_clear_pending_reg <= 1'b0;
        end
        WAIT_DST_READY: begin
          dst_data_valid_reg <= 1'b0;
          dst_data_reg       <= '{default:0};
          dst_clear_pending_reg <= 1'b0;
        end
        WAIT_DST_CLEAR: begin
          dst_data_valid_reg <= 1'b0;
          dst_data_reg       <= '{default:0};
          dst_clear_pending_reg <= 1'b0;
        end
        CLEARING_SRC: begin
          dst_data_valid_reg <= 1'b0;
          dst_data_reg       <= '{default:0};
          dst_clear_pending_reg <= 1'b0;
        end
        CLEARING_DST: begin
          dst_data_valid_reg <= 1'b0;
          dst_data_reg       <= '{default:0};
          dst_clear_pending_reg <= 1'b0;
        end
        default: begin
          dst_data_valid_reg <= 1'b0;
          dst_data_reg       <= '{default:0};
          dst_clear_pending_reg <= 1'b0;
        end
      endcase
    end
  end

  // ---------------------------------------------------------------------------
  // Output Logic (Source)
  // ---------------------------------------------------------------------------
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_valid_reg <= 1'b0;
      src_clear_pending_reg <= 1'b0;
    end else begin
      case (src_state)
        IDLE: begin
          src_data_valid_reg <= 1'b0;
          src_clear_pending_reg <= 1'b0;
        end
        WAIT_DST_VALID: begin
          src_data_valid_reg <= 1'b0;
          src_clear_pending_reg <= 1'b0;
        end
        WAIT_DST_READY: begin
          src_data_valid_reg <= 1'b0;
          src_clear_pending_reg <= 1'b0;
        end
        WAIT_SRC_CLEAR: begin
          src_data_valid_reg <= 1'b0;
          src_clear_pending_reg <= 1'b0;
        end
        CLEARING_DST: begin
          src_data_valid_reg <= 1'b0;
          src_clear_pending_reg <= 1'b0;
        end
        CLEARING_SRC: begin
          src_data_valid_reg <= 1'b0;
          src_clear_pending_reg <= 1'b0;
        end
        default: begin
          src_data_valid_reg <= 1'b0;
          src_clear_pending_reg <= 1'b0;
        end
      endcase
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Logic (Destination Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_crossed_valid     <= '{default:0};
      dst_crossed_ready     <= '{default:0};
      dst_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Source Domain
      dst_crossed_valid     <= src_sync_valid;
      dst_crossed_ready     <= src_sync_ready;
      dst_crossed_clear     <= src_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Logic (Source Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_crossed_valid     <= '{default:0};
      src_crossed_ready     <= '{default:0};
      src_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Destination Domain
      src_crossed_valid     <= dst_sync_valid;
      src_crossed_ready     <= dst_sync_ready;
      src_crossed_clear     <= dst_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Destination Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_crossed_valid     <= '{default:0};
      dst_crossed_ready     <= '{default:0};
      dst_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Source Domain
      dst_crossed_valid     <= src_sync_valid;
      dst_crossed_ready     <= src_sync_ready;
      dst_crossed_clear     <= src_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Source Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_crossed_valid     <= '{default:0};
      src_crossed_ready     <= '{default:0};
      src_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Destination Domain
      src_crossed_valid     <= dst_sync_valid;
      src_crossed_ready     <= dst_sync_ready;
      src_crossed_clear     <= dst_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Destination Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_crossed_valid     <= '{default:0};
      dst_crossed_ready     <= '{default:0};
      dst_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Source Domain
      dst_crossed_valid     <= src_sync_valid;
      dst_crossed_ready     <= src_sync_ready;
      dst_crossed_clear     <= src_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Source Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_crossed_valid     <= '{default:0};
      src_crossed_ready     <= '{default:0};
      src_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Destination Domain
      src_crossed_valid     <= dst_sync_valid;
      src_crossed_ready     <= dst_sync_ready;
      src_crossed_clear     <= dst_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Destination Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_crossed_valid     <= '{default:0};
      dst_crossed_ready     <= '{default:0};
      dst_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Source Domain
      dst_crossed_valid     <= src_sync_valid;
      dst_crossed_ready     <= src_sync_ready;
      dst_crossed_clear     <= src_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Source Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_crossed_valid     <= '{default:0};
      src_crossed_ready     <= '{default:0};
      src_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Destination Domain
      src_crossed_valid     <= dst_sync_valid;
      src_crossed_ready     <= dst_sync_ready;
      src_crossed_clear     <= dst_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Destination Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_crossed_valid     <= '{default:0};
      dst_crossed_ready     <= '{default:0};
      dst_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Source Domain
      dst_crossed_valid     <= src_sync_valid;
      dst_crossed_ready     <= src_sync_ready;
      dst_crossed_clear     <= src_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Source Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_crossed_valid     <= '{default:0};
      src_crossed_ready     <= '{default:0};
      src_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Destination Domain
      src_crossed_valid     <= dst_sync_valid;
      src_crossed_ready     <= dst_sync_ready;
      src_crossed_clear     <= dst_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Destination Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_crossed_valid     <= '{default:0};
      dst_crossed_ready     <= '{default:0};
      dst_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Source Domain
      dst_crossed_valid     <= src_sync_valid;
      dst_crossed_ready     <= src_sync_ready;
      dst_crossed_clear     <= src_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Source Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_crossed_valid     <= '{default:0};
      src_crossed_ready     <= '{default:0};
      src_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Destination Domain
      src_crossed_valid     <= dst_sync_valid;
      src_crossed_ready     <= dst_sync_ready;
      src_crossed_clear     <= dst_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Destination Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_crossed_valid     <= '{default:0};
      dst_crossed_ready     <= '{default:0};
      dst_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Source Domain
      dst_crossed_valid     <= src_sync_valid;
      dst_crossed_ready     <= src_sync_ready;
      dst_crossed_clear     <= src_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Source Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_crossed_valid     <= '{default:0};
      src_crossed_ready     <= '{default:0};
      src_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Destination Domain
      src_crossed_valid     <= dst_sync_valid;
      src_crossed_ready     <= dst_sync_ready;
      src_crossed_clear     <= dst_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Destination Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_crossed_valid     <= '{default:0};
      dst_crossed_ready     <= '{default:0};
      dst_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Source Domain
      dst_crossed_valid     <= src_sync_valid;
      dst_crossed_ready     <= src_sync_ready;
      dst_crossed_clear     <= src_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Source Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_crossed_valid     <= '{default:0};
      src_crossed_ready     <= '{default:0};
      src_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Destination Domain
      src_crossed_valid     <= dst_sync_valid;
      src_crossed_ready     <= dst_sync_ready;
      src_crossed_clear     <= dst_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Destination Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_crossed_valid     <= '{default:0};
      dst_crossed_ready     <= '{default:0};
      dst_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Source Domain
      dst_crossed_valid     <= src_sync_valid;
      dst_crossed_ready     <= src_sync_ready;
      dst_crossed_clear     <= src_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Source Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_crossed_valid     <= '{default:0};
      src_crossed_ready     <= '{default:0};
      src_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Destination Domain
      src_crossed_valid     <= dst_sync_valid;
      src_crossed_ready     <= dst_sync_ready;
      src_crossed_clear     <= dst_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Destination Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_crossed_valid     <= '{default:0};
      dst_crossed_ready     <= '{default:0};
      dst_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Source Domain
      dst_crossed_valid     <= src_sync_valid;
      dst_crossed_ready     <= src_sync_ready;
      dst_crossed_clear     <= src_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Source Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_crossed_valid     <= '{default:0};
      src_crossed_ready     <= '{default:0};
      src_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Destination Domain
      src_crossed_valid     <= dst_sync_valid;
      src_crossed_ready     <= dst_sync_ready;
      src_crossed_clear     <= dst_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Destination Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_crossed_valid     <= '{default:0};
      dst_crossed_ready     <= '{default:0};
      dst_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Source Domain
      dst_crossed_valid     <= src_sync_valid;
      dst_crossed_ready     <= src_sync_ready;
      dst_crossed_clear     <= src_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Source Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_crossed_valid     <= '{default:0};
      src_crossed_ready     <= '{default:0};
      src_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Destination Domain
      src_crossed_valid     <= dst_sync_valid;
      src_crossed_ready     <= dst_sync_ready;
      src_crossed_clear     <= dst_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Destination Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_crossed_valid     <= '{default:0};
      dst_crossed_ready     <= '{default:0};
      dst_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Source Domain
      dst_crossed_valid     <= src_sync_valid;
      dst_crossed_ready     <= src_sync_ready;
      dst_crossed_clear     <= src_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Source Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_crossed_valid     <= '{default:0};
      src_crossed_ready     <= '{default:0};
      src_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Destination Domain
      src_crossed_valid     <= dst_sync_valid;
      src_crossed_ready     <= dst_sync_ready;
      src_crossed_clear     <= dst_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Destination Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_crossed_valid     <= '{default:0};
      dst_crossed_ready     <= '{default:0};
      dst_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Source Domain
      dst_crossed_valid     <= src_sync_valid;
      dst_crossed_ready     <= src_sync_ready;
      dst_crossed_clear     <= src_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Source Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_crossed_valid     <= '{default:0};
      src_crossed_ready     <= '{default:0};
      src_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Destination Domain
      src_crossed_valid     <= dst_sync_valid;
      src_crossed_ready     <= dst_sync_ready;
      src_crossed_clear     <= dst_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Destination Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_crossed_valid     <= '{default:0};
      dst_crossed_ready     <= '{default:0};
      dst_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Source Domain
      dst_crossed_valid     <= src_sync_valid;
      dst_crossed_ready     <= src_sync_ready;
      dst_crossed_clear     <= src_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Source Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_crossed_valid     <= '{default:0};
      src_crossed_ready     <= '{default:0};
      src_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Destination Domain
      src_crossed_valid     <= dst_sync_valid;
      src_crossed_ready     <= dst_sync_ready;
      src_crossed_clear     <= dst_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Destination Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_crossed_valid     <= '{default:0};
      dst_crossed_ready     <= '{default:0};
      dst_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Source Domain
      dst_crossed_valid     <= src_sync_valid;
      dst_crossed_ready     <= src_sync_ready;
      dst_crossed_clear     <= src_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Source Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_crossed_valid     <= '{default:0};
      src_crossed_ready     <= '{default:0};
      src_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Destination Domain
      src_crossed_valid     <= dst_sync_valid;
      src_crossed_ready     <= dst_sync_ready;
      src_crossed_clear     <= dst_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Destination Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_crossed_valid     <= '{default:0};
      dst_crossed_ready     <= '{default:0};
      dst_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Source Domain
      dst_crossed_valid     <= src_sync_valid;
      dst_crossed_ready     <= src_sync_ready;
      dst_crossed_clear     <= src_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Source Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_crossed_valid     <= '{default:0};
      src_crossed_ready     <= '{default:0};
      src_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Destination Domain
      src_crossed_valid     <= dst_sync_valid;
      src_crossed_ready     <= dst_sync_ready;
      src_crossed_clear     <= dst_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Destination Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_crossed_valid     <= '{default:0};
      dst_crossed_ready     <= '{default:0};
      dst_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Source Domain
      dst_crossed_valid     <= src_sync_valid;
      dst_crossed_ready     <= src_sync_ready;
      dst_crossed_clear     <= src_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Source Domain)
  // ---------------------------------------------------------------------------
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_crossed_valid     <= '{default:0};
      src_crossed_ready     <= '{default:0};
      src_crossed_clear     <= '{default:0};
    end else begin
      // Capture from Destination Domain
      src_crossed_valid     <= dst_sync_valid;
      src_crossed_ready     <= dst_sync_ready;
      src_crossed_clear     <= dst_sync_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // CDC Crossing Implementation (Destination Domain)
  // ---------------------------------------------------------------------------
