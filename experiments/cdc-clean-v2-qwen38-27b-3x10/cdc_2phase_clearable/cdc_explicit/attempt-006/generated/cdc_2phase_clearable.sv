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
  wire [WIDTH-1:0] src_data_reg;
  wire [WIDTH-1:0] dst_data_reg;
  wire src_clear_pending_int;
  wire dst_clear_pending_int;

  // Source domain: request generation and data holding
  // Two-phase handshake: src drives req, dst drives ack
  // src drives req high to send, waits for ack high, then req low, waits for ack low

  // Source side state machine
  // States: IDLE (req=0, ack=0), REQ_HIGH (req=1, ack=0), WAIT_ACK (req=1, ack=1), REQ_LOW (req=0, ack=1)
  // Simplified: use req and ack signals directly

  // Source domain registers
  reg [WIDTH-1:0] src_data_hold;
  reg src_req_reg;
  reg src_ack_sync_reg; // synchronized ack from dst
  reg src_clear_pending_reg;
  reg src_isolated_reg;

  // Destination domain registers
  reg [WIDTH-1:0] dst_data_hold;
  reg dst_req_sync_reg; // synchronized req from src
  reg dst_ack_reg;
  reg dst_clear_pending_reg;
  reg dst_isolated_reg;
  reg dst_valid_reg;

  // Synchronizers for req (src -> dst)
  reg [SYNC_STAGES-1:0] req_sync;
  // Synchronizers for ack (dst -> src)
  reg [SYNC_STAGES-1:0] ack_sync;

  // Synchronizers for clear pending (src -> dst)
  reg [SYNC_STAGES-1:0] src_clear_pending_sync;
  // Synchronizers for clear pending (dst -> src)
  reg [SYNC_STAGES-1:0] dst_clear_pending_sync;

  // Synchronizers for data (src -> dst) - data is held stable during transfer
  reg [SYNC_STAGES-1:0][WIDTH-1:0] data_sync;

  // Synchronizers for dst_clear (dst -> src)
  reg [SYNC_STAGES-1:0] dst_clear_sync;
  // Synchronizers for src_clear (src -> dst)
  reg [SYNC_STAGES-1:0] src_clear_sync;

  // Synchronizers for dst_ready (dst -> src)
  reg [SYNC_STAGES-1:0] dst_ready_sync;

  // Generate synchronizers
  genvar i;
  generate
    for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_sync
      if (i == 0) begin : gen_first
        always @(posedge dst_clk_i or negedge dst_rst_ni) begin
          if (!dst_rst_ni)
            req_sync[0] <= 1'b0;
          else
            req_sync[0] <= src_req_reg;
        end
        always @(posedge dst_clk_i or negedge dst_rst_ni) begin
          if (!dst_rst_ni)
            data_sync[0] <= {WIDTH{1'b0}};
          else
            data_sync[0] <= src_data_hold;
        end
        always @(posedge dst_clk_i or negedge dst_rst_ni) begin
          if (!dst_rst_ni)
            src_clear_pending_sync[0] <= 1'b0;
          else
            src_clear_pending_sync[0] <= src_clear_pending_reg;
        end
        always @(posedge dst_clk_i or negedge dst_rst_ni) begin
          if (!dst_rst_ni)
            src_clear_sync[0] <= 1'b0;
          else
            src_clear_sync[0] <= src_clear_i;
        end
      end else begin : gen_rest
        always @(posedge dst_clk_i or negedge dst_rst_ni) begin
          if (!dst_rst_ni)
            req_sync[i] <= 1'b0;
          else
            req_sync[i] <= req_sync[i-1];
        end
        always @(posedge dst_clk_i or negedge dst_rst_ni) begin
          if (!dst_rst_ni)
            data_sync[i] <= {WIDTH{1'b0}};
          else
            data_sync[i] <= data_sync[i-1];
        end
        always @(posedge dst_clk_i or negedge dst_rst_ni) begin
          if (!dst_rst_ni)
            src_clear_pending_sync[i] <= 1'b0;
          else
            src_clear_pending_sync[i] <= src_clear_pending_sync[i-1];
        end
        always @(posedge dst_clk_i or negedge dst_rst_ni) begin
          if (!dst_rst_ni)
            src_clear_sync[i] <= 1'b0;
          else
            src_clear_sync[i] <= src_clear_sync[i-1];
        end
      end
    endfor
  endgenerate

  generate
    for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_ack_sync
      if (i == 0) begin : gen_first
        always @(posedge src_clk_i or negedge src_rst_ni) begin
          if (!src_rst_ni)
            ack_sync[0] <= 1'b0;
          else
            ack_sync[0] <= dst_ack_reg;
        end
        always @(posedge src_clk_i or negedge src_rst_ni) begin
          if (!src_rst_ni)
            dst_clear_pending_sync[0] <= 1'b0;
          else
            dst_clear_pending_sync[0] <= dst_clear_pending_reg;
        end
        always @(posedge src_clk_i or negedge src_rst_ni) begin
          if (!src_rst_ni)
            dst_clear_sync[0] <= 1'b0;
          else
            dst_clear_sync[0] <= dst_clear_i;
        end
        always @(posedge src_clk_i or negedge src_rst_ni) begin
          if (!src_rst_ni)
            dst_ready_sync[0] <= 1'b0;
          else
            dst_ready_sync[0] <= dst_ready_i;
        end
      end else begin : gen_rest
        always @(posedge src_clk_i or negedge src_rst_ni) begin
          if (!src_rst_ni)
            ack_sync[i] <= 1'b0;
          else
            ack_sync[i] <= ack_sync[i-1];
        end
        always @(posedge src_clk_i or negedge src_rst_ni) begin
          if (!src_rst_ni)
            dst_clear_pending_sync[i] <= 1'b0;
          else
            dst_clear_pending_sync[i] <= dst_clear_pending_sync[i-1];
        end
        always @(posedge src_clk_i or negedge src_rst_ni) begin
          if (!src_rst_ni)
            dst_clear_sync[i] <= 1'b0;
          else
            dst_clear_sync[i] <= dst_clear_sync[i-1];
        end
        always @(posedge src_clk_i or negedge src_rst_ni) begin
          if (!src_rst_ni)
            dst_ready_sync[i] <= 1'b0;
          else
            dst_ready_sync[i] <= dst_ready_sync[i-1];
        end
      end
    endfor
  endgenerate

  // Synchronized signals
  wire req_synced = req_sync[SYNC_STAGES-1];
  wire [WIDTH-1:0] data_synced = data_sync[SYNC_STAGES-1];
  wire src_clear_pending_synced = src_clear_pending_sync[SYNC_STAGES-1];
  wire src_clear_synced = src_clear_sync[SYNC_STAGES-1];
  wire ack_synced = ack_sync[SYNC_STAGES-1];
  wire dst_clear_pending_synced = dst_clear_pending_sync[SYNC_STAGES-1];
  wire dst_clear_synced = dst_clear_sync[SYNC_STAGES-1];
  wire dst_ready_synced = dst_ready_sync[SYNC_STAGES-1];

  // Source domain logic
  // src_ready_o: high when source can accept new data
  // src can accept when: not in transfer, not clearing, dst is ready (synchronized)
  
  // Two-phase handshake states:
  // State 0: req=0, ack=0 (idle)
  // State 1: req=1, ack=0 (request sent, waiting for ack)
  // State 2: req=1, ack=1 (ack received, waiting to deassert req)
  // State 3: req=0, ack=1 (req deasserted, waiting for ack to deassert)

  // src_req_reg is the request signal driven to dst
  // ack_synced is the synchronized acknowledge from dst

  // Source state machine
  // We track the handshake state implicitly using src_req_reg and ack_synced

  // src_ready_o: can accept new data when in idle state (req=0, ack=0) and not clearing
  wire src_idle = (~src_req_reg) & (~ack_synced);
  wire src_in_transfer = src_req_reg | ack_synced;

  // Clear logic: when src_clear_i or dst_clear_synced is asserted, initiate clear
  wire src_clear_active = src_clear_i | dst_clear_synced;

  // src_clear_pending_o: high until clear is complete
  // Clear is complete when both sides are back to idle

  // Source domain: drive req and data
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_req_reg <= 1'b0;
      src_data_hold <= {WIDTH{1'b0}};
      src_clear_pending_reg <= 1'b0;
      src_isolated_reg <= 1'b0;
    end else begin
      // Handle clear
      if (src_clear_active) begin
        // Isolate: stop accepting new data, drive req low
        src_isolated_reg <= 1'b1;
        src_clear_pending_reg <= 1'b1;
        src_req_reg <= 1'b0;
      end else if (src_isolated_reg) begin
        // In clear mode: wait for ack to go low, then deassert clear pending
        if (~ack_synced) begin
          // Ack is low, clear is complete
          src_isolated_reg <= 1'b0;
          src_clear_pending_reg <= 1'b0;
        end
      end else begin
        // Normal operation
        if (src_idle && src_valid_i && dst_ready_synced) begin
          // Accept new data, start transfer
          src_data_hold <= src_data_i;
          src_req_reg <= 1'b1;
        end else if (src_req_reg && ack_synced) begin
          // Ack received, deassert req
          src_req_reg <= 1'b0;
        end
      end
    end
  end

  // src_ready_o: high when can accept new data
  assign src_ready_o = src_idle & ~src_isolated_reg & ~src_clear_active;

  // src_clear_pending_o
  assign src_clear_pending_o = src_clear_pending_reg;

  // Destination domain logic
  // dst_ack_reg: acknowledge signal driven to src
  // dst_valid_o: valid signal to destination
  // dst_data_o: data output

  // dst sees req_synced and data_synced
  // When req_synced goes high, capture data and assert ack
  // When req_synced goes low, deassert ack

  // dst_clear_active: when dst_clear_i or src_clear_synced is asserted
  wire dst_clear_active = dst_clear_i | src_clear_synced;

  // dst_clear_pending_o: high until clear is complete
  // Clear is complete when req_synced is low and ack is low

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ack_reg <= 1'b0;
      dst_data_hold <= {WIDTH{1'b0}};
      dst_clear_pending_reg <= 1'b0;
      dst_isolated_reg <= 1'b0;
      dst_valid_reg <= 1'b0;
    end else begin
      // Handle clear
      if (dst_clear_active) begin
        // Isolate: stop presenting valid, drive ack low
        dst_isolated_reg <= 1'b1;
        dst_clear_pending_reg <= 1'b1;
        dst_ack_reg <= 1'b0;
        dst_valid_reg <= 1'b0;
      end else if (dst_isolated_reg) begin
        // In clear mode: wait for req to go low, then deassert clear pending
        if (~req_synced) begin
          // Req is low, clear is complete
          dst_isolated_reg <= 1'b0;
          dst_clear_pending_reg <= 1'b0;
        end
      end else begin
        // Normal operation
        if (req_synced && ~dst_ack_reg) begin
          // Request received, capture data and assert ack
          dst_data_hold <= data_synced;
          dst_ack_reg <= 1'b1;
          dst_valid_reg <= 1'b1;
        end else if (~req_synced && dst_ack_reg) begin
          // Request deasserted, deassert ack
          dst_ack_reg <= 1'b0;
          dst_valid_reg <= 1'b0;
        end else if (dst_valid_reg && dst_ready_i) begin
          // Data accepted by destination
          dst_valid_reg <= 1'b0;
        end
      end
    end
  end

  // dst_valid_o: valid when data is available and not being cleared
  assign dst_valid_o = dst_valid_reg & ~dst_isolated_reg & ~dst_clear_active;

  // dst_data_o: data output
  assign dst_data_o = dst_data_hold;

  // dst_clear_pending_o
  assign dst_clear_pending_o = dst_clear_pending_reg;

endmodule
