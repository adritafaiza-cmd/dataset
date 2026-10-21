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

  // ------------------------------------------------------------------
  // Source Domain: Capture Valid/Ready and Clear Request
  // ------------------------------------------------------------------
  logic [SYNC_STAGES-1:0] src_valid_reg;
  logic [SYNC_STAGES-1:0] src_ready_reg;
  logic [SYNC_STAGES-1:0] src_clear_reg;
  logic src_valid_sync;
  logic src_ready_sync;
  logic src_clear_sync;
  logic src_clear_pending;

  // Synchronize src_valid
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      src_valid_reg <= '{default: 0};
    else
      src_valid_reg <= {src_valid_reg[SYNC_STAGES-2:0], src_valid_i};
  end

  // Synchronize src_ready
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      src_ready_reg <= '{default: 0};
    else
      src_ready_reg <= {src_ready_reg[SYNC_STAGES-1:0], dst_ready_i};
  end

  // Synchronize src_clear
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      src_clear_reg <= '{default: 0};
    else
      src_clear_reg <= {src_clear_reg[SYNC_STAGES-1:0], src_clear_i};
  end

  // Extract sync signals
  assign src_valid_sync = src_valid_reg[SYNC_STAGES-1];
  assign src_ready_sync = src_ready_reg[SYNC_STAGES-1];
  assign src_clear_sync = src_clear_reg[SYNC_STAGES-1];

  // Determine if source side is pending clear
  // Pending if clear was requested and we haven't finished the handshake yet.
  // We consider it pending until the next cycle after the clear handshake completes.
  assign src_clear_pending = src_clear_sync && (src_valid_sync | src_ready_sync);

  // ------------------------------------------------------------------
  // Destination Domain: Capture Valid/Ready and Clear Request
  // ------------------------------------------------------------------
  logic [SYNC_STAGES-1:0] dst_valid_reg;
  logic [SYNC_STAGES-1:0] dst_ready_reg;
  logic [SYNC_STAGES-1:0] dst_clear_reg;
  logic dst_valid_sync;
  logic dst_ready_sync;
  logic dst_clear_sync;
  logic dst_clear_pending;

  // Synchronize dst_valid (from src)
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      dst_valid_reg <= '{default: 0};
    else
      dst_valid_reg <= {dst_valid_reg[SYNC_STAGES-2:0], src_valid_sync};
  end

  // Synchronize dst_ready
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      dst_ready_reg <= '{default: 0};
    else
      dst_ready_reg <= {dst_ready_reg[SYNC_STAGES-1:0], dst_ready_i};
  end

  // Synchronize dst_clear
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      dst_clear_reg <= '{default: 0};
    else
      dst_clear_reg <= {dst_clear_reg[SYNC_STAGES-1:0], dst_clear_i};
  end

  // Extract sync signals
  assign dst_valid_sync = dst_valid_reg[SYNC_STAGES-1];
  assign dst_ready_sync = dst_ready_reg[SYNC_STAGES-1];
  assign dst_clear_sync = dst_clear_reg[SYNC_STAGES-1];

  // Determine if destination side is pending clear
  assign dst_clear_pending = dst_clear_sync && (dst_valid_sync | dst_ready_sync);

  // ------------------------------------------------------------------
  // Cross-Domain Handshake Logic
  // ------------------------------------------------------------------
  // State Machine for the channel
  // States: IDLE, WAIT_SRC_VALID, WAIT_DST_READY, CLEARING_SRC, CLEARING_DST
  
  logic [2:0] state;
  parameter IDLE = 3'd0;
  parameter WAIT_SRC_VALID = 3'd1;
  parameter WAIT_DST_READY = 3'd2;
  parameter CLEARING_SRC = 3'd3;
  parameter CLEARING_DST = 3'd4;

  logic [WIDTH-1:0] data_buffer;
  logic data_valid_internal;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      state <= IDLE;
      data_buffer <= '{default: 0};
      data_valid_internal <= 1'b0;
    end else begin
      case (state)
        IDLE: begin
          if (src_valid_sync && src_ready_sync) begin
            state <= WAIT_DST_READY;
            data_buffer <= src_data_i;
            data_valid_internal <= 1'b1;
          end else if (src_clear_sync) begin
            state <= CLEARING_SRC;
          end else begin
            state <= IDLE;
          end
        end

        WAIT_DST_READY: begin
          if (src_ready_sync) begin
            state <= IDLE;
            data_valid_internal <= 1'b0;
          end else if (src_clear_sync) begin
            state <= CLEARING_SRC;
          end else begin
            state <= WAIT_DST_READY;
          end
        end

        CLEARING_SRC: begin
          if (src_ready_sync) begin
            state <= CLEARING_DST;
          end else if (src_clear_sync) begin
            state <= CLEARING_SRC;
          end else begin
            state <= IDLE;
          end
        end

        CLEARING_DST: begin
          if (dst_ready_sync) begin
            state <= IDLE;
            data_valid_internal <= 1'b0;
          end else if (dst_clear_sync) begin
            state <= CLEARING_DST;
          end else begin
            state <= IDLE;
          end
        end

        default: state <= IDLE;
      endcase
    end
  end

  // ------------------------------------------------------------------
  // Output Logic
  // ------------------------------------------------------------------
  // Source Ready
  assign src_ready_o = (state == IDLE) ? 1'b1 : 1'b0;

  // Source Clear Pending Output
  assign src_clear_pending_o = src_clear_pending;

  // Destination Valid and Data
  assign dst_valid_o = (state == WAIT_SRC_VALID) && dst_valid_sync;
  assign dst_data_o = data_buffer;

  // Destination Clear Pending Output
  assign dst_clear_pending_o = dst_clear_pending;

  // ------------------------------------------------------------------
  // Backpressure Generation
  // ------------------------------------------------------------------
  // src_ready_o is driven by the FSM state.
  // dst_ready_i is captured in dst_ready_reg.
  
  // Note: The FSM logic above handles the handshake implicitly.
  // When in IDLE, src_ready_o is 1.
  // When in WAIT_DST_READY, src_ready_o is 0 (waiting for dst to accept).
  // When clearing, src_ready_o is 0 until the clear handshake completes.

endmodule
```<|im_end|>
