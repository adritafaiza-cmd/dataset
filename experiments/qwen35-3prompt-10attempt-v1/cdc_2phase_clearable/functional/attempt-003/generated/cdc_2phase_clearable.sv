```systemverilog
module cdc_2phase_clearable #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3,
  parameter CLEAR_ON_ASYNC_RESET = 1
)(
  input  wire src_rst_ni,
  input  wire src_clk_i,
  input  wire src_clear_i,
  output reg  src_clear_pending_o,
  input  wire [WIDTH-1:0] src_data_i,
  input  wire src_valid_i,
  output reg  src_ready_o,
  input  wire dst_rst_ni,
  input  wire dst_clk_i,
  input  wire dst_clear_i,
  output reg  dst_clear_pending_o,
  output reg  [WIDTH-1:0] dst_data_o,
  output reg  dst_valid_o,
  input  wire dst_ready_i
);

  localparam SYNC_STAGES_LOG = $clog2(SYNC_STAGES);

  // ------------------------------------------------------------------
  // Source Domain: Capture and Sync Valid/Ready/Clear
  // ------------------------------------------------------------------
  logic [SYNC_STAGES-1:0] src_valid_sync;
  logic [SYNC_STAGES-1:0] src_ready_sync;
  logic [SYNC_STAGES-1:0] src_clear_sync;
  logic src_valid_synced;
  logic src_ready_synced;
  logic src_clear_synced;

  // Async FIFO for Valid
  genvar i;
  for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_valid_sync
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
      if (!src_rst_ni)
        src_valid_sync[i] <= 1'b0;
      else
        src_valid_sync[i] <= src_valid_sync[i-1];
    end
  end

  // Async FIFO for Ready
  for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_ready_sync
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
      if (!src_rst_ni)
        src_ready_sync[i] <= 1'b0;
      else
        src_ready_sync[i] <= src_ready_sync[i-1];
    end
  end

  // Async FIFO for Clear
  for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_clear_sync
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
      if (!src_rst_ni)
        src_clear_sync[i] <= 1'b0;
      else
        src_clear_sync[i] <= src_clear_sync[i-1];
    end
  end

  assign src_valid_synced = src_valid_sync[SYNC_STAGES-1];
  assign src_ready_synced = src_ready_sync[SYNC_STAGES-1];
  assign src_clear_synced = src_clear_sync[SYNC_STAGES-1];

  // ------------------------------------------------------------------
  // Destination Domain: Capture and Sync Valid/Ready/Clear
  // ------------------------------------------------------------------
  logic [SYNC_STAGES-1:0] dst_valid_sync;
  logic [SYNC_STAGES-1:0] dst_ready_sync;
  logic [SYNC_STAGES-1:0] dst_clear_sync;
  logic dst_valid_synced;
  logic dst_ready_synced;
  logic dst_clear_synced;

  for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_dst_valid_sync
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
      if (!dst_rst_ni)
        dst_valid_sync[i] <= 1'b0;
      else
        dst_valid_sync[i] <= dst_valid_sync[i-1];
    end
  end

  for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_dst_ready_sync
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
      if (!dst_rst_ni)
        dst_ready_sync[i] <= 1'b0;
      else
        dst_ready_sync[i] <= dst_ready_sync[i-1];
    end
  end

  for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_dst_clear_sync
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
      if (!dst_rst_ni)
        dst_clear_sync[i] <= 1'b0;
      else
        dst_clear_sync[i] <= dst_clear_sync[i-1];
    end
  end

  assign dst_valid_synced = dst_valid_sync[SYNC_STAGES-1];
  assign dst_ready_synced = dst_ready_sync[SYNC_STAGES-1];
  assign dst_clear_synced = dst_clear_sync[SYNC_STAGES-1];

  // ------------------------------------------------------------------
  // CDC Logic: 2-Phase Handshake with Clear Support
  // ------------------------------------------------------------------
  // State Encoding:
  // 0: IDLE
  // 1: WAIT_DST_READY (Data sent, waiting for ready)
  // 2: CLEAR_SRC_PENDING (Clear requested, waiting for ack from dst)
  // 3: CLEAR_DST_PENDING (Clear ack sent, waiting for dst clear)
  // 4: CLEAR_DONE (Both sides clear, resetting to IDLE)

  logic [2:0] src_state;
  logic [2:0] dst_state;

  // Source State Machine
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_state <= 3'b000;
      src_clear_pending_o <= 1'b0;
    end else begin
      case (src_state)
        3'b000: // IDLE
          if (src_valid_synced && src_ready_synced)
            src_state <= 3'b001; // Move to WAIT_DST_READY
          else
            src_state <= 3'b000;
          
          // Clear Logic
          if (src_clear_synced) begin
            src_clear_pending_o <= 1'b1;
            src_state <= 3'b010; // Move to CLEAR_SRC_PENDING
          end

        3'b001: // WAIT_DST_READY (Data latched, waiting for ready)
          if (src_ready_synced) begin
            src_state <= 3'b000; // Return to IDLE
          end else if (src_clear_synced) begin
            src_clear_pending_o <= 1'b1;
            src_state <= 3'b010; // Move to CLEAR_SRC_PENDING
          end

        3'b010: // CLEAR_SRC_PENDING (Waiting for dst to acknowledge clear)
          if (dst_clear_synced) begin
            src_state <= 3'b000; // Return to IDLE
            src_clear_pending_o <= 1'b0;
          end else if (src_clear_synced) begin
            // If clear is still asserted, stay here or move to next phase if ack received
            // Logic: Once dst_clear_synced is high, we go to done/idle
            src_state <= 3'b000;
            src_clear_pending_o <= 1'b0;
          end

        3'b011: // CLEAR_ACK_SENT (Sent clear ack to dst, waiting for dst clear)
          if (dst_clear_synced) begin
            src_state <= 3'b000;
            src_clear_pending_o <= 1'b0;
          end

        3'b100: // CLEAR_DONE (Final state before reset/idle)
          src_state <= 3'b000;
          src_clear_pending_o <= 1'b0;

        default:
          src_state <= 3'b000;
      endcase
    end
  end

  // Destination State Machine
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_state <= 3'b000;
      dst_clear_pending_o <= 1'b0;
    end else begin
      case (dst_state)
        3'b000: // IDLE
          if (dst_valid_synced && dst_ready_synced)
            dst_state <= 3'b001; // Move to WAIT_SRC_DATA
          else
            dst_state <= 3'b000;
          
          // Clear Logic
          if (dst_clear_synced) begin
            dst_clear_pending_o <= 1'b1;
            dst_state <= 3'b010; // Move to CLEAR_SRC_PENDING
          end

        3'b001: // WAIT_SRC_DATA (Waiting for valid data)
          if (dst_valid_synced) begin
            dst_state <= 3'b010; // Move to DATA_RECEIVED
          end else if (dst_clear_synced) begin
            dst_clear_pending_o <= 1'b1;
            dst_state <= 3'b010; // Move to CLEAR_SRC_PENDING
          end

        3'b010: // DATA_RECEIVED (Data latched, waiting for ready)
          if (dst_ready_synced) begin
            dst_state <= 3'b000; // Return to IDLE
          end else if (dst_clear_synced) begin
            dst_clear_pending_o <= 1'b1;
            dst_state <= 3'b010; // Move to CLEAR_SRC_PENDING
          end

        3'b011: // CLEAR_SRC_PENDING (Waiting for src to acknowledge clear)
          if (src_clear_synced) begin
            dst_state <= 3'b000;
            dst_clear_pending_o <= 1'b0;
          end else if (dst_clear_synced) begin
            dst_state <= 3'b000;
            dst_clear_pending_o <= 1'b0;
          end

        3'b100: // CLEAR_ACK_SENT (Sent clear ack to src, waiting for src clear)
          if (src_clear_synced) begin
            dst_state <= 3'b000;
            dst_clear_pending_o <= 1'b0;
          end

        3'b101: // CLEAR_DONE (Final state)
          dst_state <= 3'b000;
          dst_clear_pending_o <= 1'b0;

        default:
          dst_state <= 3'b000;
      endcase
    end
  end

  // ------------------------------------------------------------------
  // Data Path and Output Logic
  // ------------------------------------------------------------------
  // Source Side Outputs
  assign src_ready_o = (src_state == 3'b000) || (src_state == 3'b001);
  // Note: In state 001 (WAIT_DST_READY), we have data but are waiting for ready.
  // Actually, standard 2-phase: 
  // State 000: Idle, ready=1
  // State 001: Data sent, ready=0 (waiting for dst ready)
  // Let's refine the logic based on standard handshake.
  
  // Refined Source Logic:
  // State 000 (IDLE): ready = 1
  // State 001 (DATA_SENT): ready = 0 (waiting for dst ready)
  // State 010 (CLEAR_SRC_PENDING): ready = 0 (channel isolated)
  // State 011 (CLEAR_ACK_SENT): ready = 0 (channel isolated)
  // State 100 (CLEAR_DONE): ready = 1

  always_comb begin
    src_ready_o = 1'b0;
    case (src_state)
      3'b000: src_ready_o = 1'b1;
      3'b001: src_ready_o = 1'b0;
      3'b010: src_ready_o = 1'b0;
      3'b011: src_ready_o = 1'b0;
      3'b100: src_ready_o = 1'b1;
      default: src_ready_o = 1'b0;
    endcase
  end

  // Data capture in source domain
  logic [WIDTH-1:0] src_data_latched;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      src_data_latched <= '{default: 0};
    else if (src_state == 3'b001 && src_valid_synced) begin
      src_data_latched <= src_data_i;
    end
  end

  // Destination Side Outputs
  // State 000 (IDLE): valid = 0
  // State 001 (WAIT_SRC_DATA): valid = 0
  // State 010 (DATA_RECEIVED): valid = 1, data = latched
  // State 011 (CLEAR_SRC_PENDING): valid = 0
  // State 100 (CLEAR_ACK_SENT): valid = 0
  // State 101 (CLEAR_DONE): valid = 0

  always_comb begin
    dst_valid_o = 1'b0;
    dst_data_o  = '{default: 0};
    case (dst_state)
      3'b000: dst_valid_o = 1'b0;
      3'b001: dst_valid_o = 1'b0;
      3'b010: dst_valid_o = 1'b1;
      3'b011: dst_valid_o = 1'b0;
      3'b100: dst_valid_o = 1'b0;
      3'b101: dst_valid_o = 1'b0;
      default: dst_valid_o = 1'b0;
    endcase
  end

  // Data capture in destination domain
  logic [WIDTH-1:0] dst_data_latched;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      dst_data_latched <= '{default: 0};
    else if (dst_state == 3'b010 && dst_valid_synced) begin
      dst_data_latched <= src_data_latched;
    end
  end

  assign dst_data_o = dst_data_latched;

  // ------------------------------------------------------------------
  // Cross-Domain Clear Acknowledgment Logic
  // ------------------------------------------------------------------
  // When Source requests clear (src_clear_synced), it waits for dst_clear_synced.
  // When Destination requests clear (dst_clear_synced), it waits for src_clear_synced.
  // This creates a mutual exclusion or coordinated flush.
  
  // Source State Machine Refinement for Clear Coordination
  // We need to ensure that if one side clears, the other acknowledges before returning to IDLE.
  
  // Re-implementing Source State Machine with explicit clear handshake
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_state <= 3'b000;
      src_clear_pending_o <= 1'b0;
    end else begin
      case (src_state)
        3'b000: // IDLE
          if (src_valid_synced && src_ready_synced)
            src_state <= 3'b001; // Send data
          else if (src_clear_synced)
            src_state <= 3'b010; // Request clear, wait for ack
          else
            src_state <= 3'b000;
          
          src_clear_pending_o <= (src_state == 3'b010) ? 1'b1 : 1'b0;

        3'b001: // DATA_SENT
          if (src_ready_synced)
            src_state <= 3'b000; // Complete transfer
          else if (src_clear_synced)
            src_state <= 3'b010; // Interrupt transfer, request clear
          else
            src_state <= 3'b001; // Wait for ready

        3'b010: // CLEAR_REQUESTED (Waiting for dst to clear)
          if (dst_clear_synced)
            src_state <= 3'b000; // Dst cleared, we are done clearing
          else if (src_clear_synced)
            src_state <= 3'b010; // Stay here until dst clears
          else
            src_state <= 3'b010; // Stay here

        3'b011: // CLEAR_ACK_SENT (Sent clear to dst, waiting for dst clear)
          if (dst_clear_synced)
            src_state <= 3'b000;
          else if (src_clear_synced)
            src_state <= 3'b011;
          else
            src_state <= 3'b011;

        3'b100: // CLEAR_DONE
          src_state <= 3'b000;
          src_clear_pending_o <= 1'b0;

        default:
          src_state <= 3'b000;
          src_clear_pending_o <= 1'b0;
      endcase
    end
  end

  // Re-implementing Destination State Machine with explicit clear handshake
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_state <= 3'b000;
      dst_clear_pending_o <= 1'b0;
    end else begin
      case (dst_state)
        3'b000: // IDLE
          if (dst_valid_synced && dst_ready_synced)
            dst_state <= 3'b001; // Request data
          else if (dst_clear_synced)
            dst_state <= 3'b010; // Request clear, wait for ack
          else
            dst_state <= 3'b000;
          
          dst_clear_pending_o <= (dst_state == 3'b010) ? 1'b1 : 1'b0;

        3'b001: // WAIT_DATA
          if (dst_valid_synced)
            dst_state <= 3'b010; // Data received
          else if (dst_clear_synced)
            dst_state <= 3'b010; // Interrupt, request clear
          else
            dst_state <= 3'b001; // Wait for data

        3'b010: // DATA_RECEIVED (Waiting for ready)
          if (dst_ready_synced)
            dst_state <= 3'b000; // Complete transfer
          else if (dst_clear_synced)
            dst_state <= 3'b010; // Interrupt transfer, request clear
          else
            dst_state <= 3'b010; // Wait for ready

        3'b011: // CLEAR_REQUESTED (Waiting for src to clear)
          if (src_clear_synced)
            dst_state <= 3'b000; // Src cleared, we are done clearing
          else if (dst_clear_synced)
            dst_state <= 3'b011; // Stay here until src clears
          else
            dst_state <= 3'b011;

        3'b100: // CLEAR_ACK_SENT (Sent clear to src, waiting for src clear)
          if (src_clear_synced)
            dst_state <= 3'b000;
          else if (dst_clear_synced)
            dst_state <= 3'b100;
          else
            dst_state <= 3'b100;

        3'b101: // CLEAR_DONE
          dst_state <= 3'b000;
          dst_clear_pending_o <= 1'b0;

        default:
          dst_state <= 3'b000;
          dst_clear_pending_o <= 1'b0;
      endcase
    end
  end

  // ------------------------------------------------------------------
  // Data Path Refinement
  // ------------------------------------------------------------------
  // Source Data Latching
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      src_data_latched <= '{default: 0};
    else if (src_state == 3'b001 && src_valid_synced) begin
      src_data_latched <= src_data_i;
    end
  end

  // Destination Data Latching
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      dst_data_latched <= '{default: 0};
    else if (dst_state == 3'b010 && dst_valid_synced) begin
      dst_data_latched <= src_data_latched;
    end
  end

  // Output Assignments
  always_comb begin
    src_ready_o = 1'b0;
    case (src_state)
      3'b000: src_ready_o = 1'b1;
      3'b001: src_ready_o = 1'b0;
      3'b010: src_ready_o = 1'b0;
      3'b011: src_ready_o = 1'b0;
      3'b100: src_ready_o = 1'b1;
      default: src_ready_o = 1'b0;
    endcase
  end

  always_comb begin
    dst_valid_o = 1'b0;
    dst_data_o  = '{default: 0};
    case (dst_state)
      3'b000: dst_valid_o = 1'b0;
      3'b001: dst_valid_o = 1'b0;
      3'b010: dst_valid_o = 1'b1;
      3'b011: dst_valid_o = 1'b0;
      3'b100: dst_valid_o = 1'b0;
      3'b101: dst_valid_o = 1'b0;
      default: dst_valid_o = 1'b0;
    endcase
  end

  assign dst_data_o = dst_data_latched;

endmodule
```<|im_end|>
