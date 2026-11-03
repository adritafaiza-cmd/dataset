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
  wire src_req;
  wire dst_ack;
  wire dst_req;
  wire src_ack;

  // Source domain: request generation and acknowledge synchronization
  // Destination domain: acknowledge generation and request synchronization

  // Source domain state
  reg src_req_reg;
  reg [WIDTH-1:0] src_data_reg;
  reg src_data_valid;

  // Destination domain state
  reg dst_req_reg;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_data_valid;

  // Clear state machines
  reg src_clear_active;
  reg dst_clear_active;

  // Synchronizer for src_req to dst domain
  reg [SYNC_STAGES-1:0] src_req_sync;
  wire src_req_synced = src_req_sync[SYNC_STAGES-1];

  // Synchronizer for dst_ack to src domain
  reg [SYNC_STAGES-1:0] dst_ack_sync;
  wire dst_ack_synced = dst_ack_sync[SYNC_STAGES-1];

  // Synchronizer for dst_req to src domain
  reg [SYNC_STAGES-1:0] dst_req_sync;
  wire dst_req_synced = dst_req_sync[SYNC_STAGES-1];

  // Synchronizer for src_ack to dst domain
  reg [SYNC_STAGES-1:0] src_ack_sync;
  wire src_ack_synced = src_ack_sync[SYNC_STAGES-1];

  // Synchronizer for src_clear to dst domain
  reg [SYNC_STAGES-1:0] src_clear_sync;
  wire src_clear_synced = src_clear_sync[SYNC_STAGES-1];

  // Synchronizer for dst_clear to src domain
  reg [SYNC_STAGES-1:0] dst_clear_sync;
  wire dst_clear_synced = dst_clear_sync[SYNC_STAGES-1];

  // Synchronizer for src_clear_pending to dst domain
  reg [SYNC_STAGES-1:0] src_clear_pending_sync;
  wire src_clear_pending_synced = src_clear_pending_sync[SYNC_STAGES-1];

  // Synchronizer for dst_clear_pending to src domain
  reg [SYNC_STAGES-1:0] dst_clear_pending_sync;
  wire dst_clear_pending_synced = dst_clear_pending_sync[SYNC_STAGES-1];

  // Synchronizer for src_data to dst domain (multi-bit, needs careful handling)
  // We use a two-phase handshake where data is stable when request is high
  // The destination captures data when it sees the request edge

  // Source domain: generate request
  // src_req is high when we have data to send and haven't been acknowledged yet
  assign src_req = src_req_reg;

  // Source domain: acknowledge from destination
  assign src_ack = src_ack_synced;

  // Destination domain: generate acknowledge
  // dst_ack is high when we've accepted the data
  assign dst_ack = dst_ack_synced ? 1'b0 : dst_req_reg;

  // Wait, let me reconsider the two-phase handshake.
  // In a two-phase handshake:
  // - Request goes high to indicate data is available
  // - Acknowledge goes high to indicate data has been accepted
  // - Request goes low after acknowledge
  // - Acknowledge goes low after request goes low

  // Let me redesign this more carefully.

  // Source domain:
  // - src_req_reg: request signal to destination
  // - src_data_reg: data to send
  // - src_data_valid: indicates data is valid
  // - src_ack_synced: acknowledge from destination (synchronized)

  // Destination domain:
  // - dst_req_synced: request from source (synchronized)
  // - dst_data_reg: captured data
  // - dst_data_valid: indicates data is valid
  // - dst_ack_reg: acknowledge signal to source

  // Let me use a simpler approach with explicit state machines.

  // Source domain state machine
  typedef enum logic [1:0] {
    SRC_IDLE,
    SRC_WAIT_ACK,
    SRC_CLEARING
  } src_state_t;

  src_state_t src_state;
  src_state_t src_state_next;

  // Destination domain state machine
  typedef enum logic [1:0] {
    DST_IDLE,
    DST_WAIT_ACK,
    DST_CLEARING
  } dst_state_t;

  dst_state_t dst_state;
  dst_state_t dst_state_next;

  // Source domain: request and data
  reg src_req_out;
  reg [WIDTH-1:0] src_data_out;

  // Destination domain: acknowledge
  reg dst_ack_out;

  // Source domain: acknowledge from destination
  reg [SYNC_STAGES-1:0] dst_ack_sync_reg;
  wire dst_ack_synced_wire = dst_ack_sync_reg[SYNC_STAGES-1];

  // Destination domain: request from source
  reg [SYNC_STAGES-1:0] src_req_sync_reg;
  wire src_req_synced_wire = src_req_sync_reg[SYNC_STAGES-1];

  // Source domain: clear from destination
  reg [SYNC_STAGES-1:0] dst_clear_sync_reg;
  wire dst_clear_synced_wire = dst_clear_sync_reg[SYNC_STAGES-1];

  // Destination domain: clear from source
  reg [SYNC_STAGES-1:0] src_clear_sync_reg;
  wire src_clear_synced_wire = src_clear_sync_reg[SYNC_STAGES-1];

  // Source domain: clear pending
  reg src_clear_pending_reg;

  // Destination domain: clear pending
  reg dst_clear_pending_reg;

  // Synchronize src_clear_pending to dst domain
  reg [SYNC_STAGES-1:0] src_clear_pending_sync_reg;
  wire src_clear_pending_synced_wire = src_clear_pending_sync_reg[SYNC_STAGES-1];

  // Synchronize dst_clear_pending to src domain
  reg [SYNC_STAGES-1:0] dst_clear_pending_sync_reg;
  wire dst_clear_pending_synced_wire = dst_clear_pending_sync_reg[SYNC_STAGES-1];

  // Source domain clocked logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_state <= SRC_IDLE;
      src_req_out <= 1'b0;
      src_data_out <= {WIDTH{1'b0}};
      src_clear_pending_reg <= 1'b0;
      dst_ack_sync_reg <= {SYNC_STAGES{1'b0}};
      dst_clear_sync_reg <= {SYNC_STAGES{1'b0}};
      dst_clear_pending_sync_reg <= {SYNC_STAGES{1'b0}};
    end else begin
      // Synchronizers
      dst_ack_sync_reg <= {dst_ack_sync_reg[SYNC_STAGES-2:0], dst_ack_out};
      dst_clear_sync_reg <= {dst_clear_sync_reg[SYNC_STAGES-2:0], dst_clear_i};
      dst_clear_pending_sync_reg <= {dst_clear_pending_sync_reg[SYNC_STAGES-2:0], dst_clear_pending_reg};

      // State machine
      src_state <= src_state_next;

      // Request and data
      case (src_state)
        SRC_IDLE: begin
          if (src_valid_i && !src_clear_i && !dst_clear_synced_wire) begin
            src_req_out <= 1'b1;
            src_data_out <= src_data_i;
          end else begin
            src_req_out <= 1'b0;
          end
        end
        SRC_WAIT_ACK: begin
          if (dst_ack_synced_wire) begin
            src_req_out <= 1'b0;
          end else begin
            src_req_out <= 1'b1;
          end
        end
        SRC_CLEARING: begin
          src_req_out <= 1'b0;
        end
        default: begin
          src_req_out <= 1'b0;
        end
      endcase

      // Clear pending
      if (src_clear_i || dst_clear_synced_wire) begin
        src_clear_pending_reg <= 1'b1;
      end else if (src_state == SRC_IDLE && !src_req_out) begin
        src_clear_pending_reg <= 1'b0;
      end
    end
  end

  // Source domain: next state
  always @(*) begin
    src_state_next = src_state;
    case (src_state)
      SRC_IDLE: begin
        if (src_valid_i && !src_clear_i && !dst_clear_synced_wire) begin
          src_state_next = SRC_WAIT_ACK;
        end else if (src_clear_i || dst_clear_synced_wire) begin
          src_state_next = SRC_CLEARING;
        end
      end
      SRC_WAIT_ACK: begin
        if (dst_ack_synced_wire) begin
          src_state_next = SRC_IDLE;
        end else if (src_clear_i || dst_clear_synced_wire) begin
          src_state_next = SRC_CLEARING;
        end
      end
      SRC_CLEARING: begin
        if (!src_req_out && !dst_clear_synced_wire && !src_clear_i) begin
          src_state_next = SRC_IDLE;
        end
      end
      default: begin
        src_state_next = SRC_IDLE;
      end
    endcase
  end

  // Source domain outputs
  assign src_ready_o = (src_state == SRC_IDLE) && !src_clear_i && !dst_clear_synced_wire;
  assign src_clear_pending_o = src_clear_pending_reg;

  // Destination domain clocked logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_state <= DST_IDLE;
      dst_ack_out <= 1'b0;
      dst_data_reg <= {WIDTH{1'b0}};
      dst_data_valid <= 1'b0;
      dst_clear_pending_reg <= 1'b0;
      src_req_sync_reg <= {SYNC_STAGES{1'b0}};
      src_clear_sync_reg <= {SYNC_STAGES{1'b0}};
      src_clear_pending_sync_reg <= {SYNC_STAGES{1'b0}};
    end else begin
      // Synchronizers
      src_req_sync_reg <= {src_req_sync_reg[SYNC_STAGES-2:0], src_req_out};
      src_clear_sync_reg <= {src_clear_sync_reg[SYNC_STAGES-2:0], src_clear_i};
      src_clear_pending_sync_reg <= {src_clear_pending_sync_reg[SYNC_STAGES-2:0], src_clear_pending_reg};

      // State machine
      dst_state <= dst_state_next;

      // Acknowledge
      case (dst_state)
        DST_IDLE: begin
          if (src_req_synced_wire && !dst_clear_i && !src_clear_synced_wire) begin
            dst_ack_out <= 1'b1;
            dst_data_reg <= src_data_out;
            dst_data_valid <= 1'b1;
          end else begin
            dst_ack_out <= 1'b0;
          end
        end
        DST_WAIT_ACK: begin
          if (dst_ready_i) begin
            dst_ack_out <= 1'b0;
            dst_data_valid <= 1'b0;
          end else begin
            dst_ack_out <= 1'b1;
          end
        end
        DST_CLEARING: begin
          dst_ack_out <= 1'b0;
          dst_data_valid <= 1'b0;
        end
        default: begin
          dst_ack_out <= 1'b0;
        end
      endcase

      // Clear pending
      if (dst_clear_i || src_clear_synced_wire) begin
        dst_clear_pending_reg <= 1'b1;
      end else if (dst_state == DST_IDLE && !dst_ack_out) begin
        dst_clear_pending_reg <= 1'b0;
      end
    end
  end

  // Destination domain: next state
  always @(*) begin
    dst_state_next = dst_state;
    case (dst_state)
      DST_IDLE: begin
        if (src_req_synced_wire && !dst_clear_i && !src_clear_synced_wire) begin
          dst_state_next = DST_WAIT_ACK;
        end else if (dst_clear_i || src_clear_synced_wire) begin
          dst_state_next = DST_CLEARING;
        end
      end
      DST_WAIT_ACK: begin
        if (dst_ready_i) begin
          dst_state_next = DST_IDLE;
        end else if (dst_clear_i || src_clear_synced_wire) begin
          dst_state_next = DST_CLEARING;
        end
      end
      DST_CLEARING: begin
        if (!dst_ack_out && !src_clear_synced_wire && !dst_clear_i) begin
          dst_state_next = DST_IDLE;
        end
      end
      default: begin
        dst_state_next = DST_IDLE;
      end
    endcase
  end

  // Destination domain outputs
  assign dst_valid_o = dst_data_valid;
  assign dst_data_o = dst_data_reg;
  assign dst_clear_pending_o = dst_clear_pending_reg;

endmodule
