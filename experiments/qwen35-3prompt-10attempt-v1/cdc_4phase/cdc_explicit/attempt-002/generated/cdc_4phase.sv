```systemverilog
module cdc_4phase #(
  parameter WIDTH = 1,
  parameter DECOUPLED = 1,
  parameter SEND_RESET_MSG = 0,
  parameter [WIDTH-1:0] RESET_MSG = {WIDTH{1'b0}}
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

  // ---------------------------------------------------------------------------
  // Source Domain Logic
  // ---------------------------------------------------------------------------
  // State Machine for Source Side (4-Phase Handshake)
  // States:
  //   IDLE     : Waiting for valid
  //   WAIT_RDY : Valid asserted, waiting for ready
  //   GRANT    : Ready asserted, waiting for valid (to accept next)
  //   WAIT_VLD : Valid asserted again (for next item), waiting for ready
  
  localparam IDLE = 2'b00;
  localparam WAIT_RDY = 2'b01;
  localparam GRANT = 2'b10;
  localparam WAIT_VLD = 2'b11;

  logic [1:0] src_state;
  logic src_valid_next;
  logic src_ready_next;
  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;

  // Reset Synchronization for Source Domain
  logic src_rst_n_sync;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      src_rst_n_sync <= 1'b0;
    else
      src_rst_n_sync <= 1'b1;
  end

  always_ff @(posedge src_clk_i or negedge src_rst_n_sync) begin
    if (!src_rst_n_sync) begin
      src_state <= IDLE;
      src_valid_reg <= 1'b0;
      src_data_reg <= {WIDTH{1'b0}};
    end else begin
      case (src_state)
        IDLE: begin
          if (src_valid_i) begin
            src_valid_reg <= 1'b1;
            src_data_reg <= src_data_i;
            src_state <= WAIT_RDY;
          end
        end
        WAIT_RDY: begin
          if (src_ready_o) begin
            src_state <= GRANT;
          end
        end
        GRANT: begin
          if (src_valid_i) begin
            src_valid_reg <= 1'b1;
            src_data_reg <= src_data_i;
            src_state <= WAIT_VLD;
          end
        end
        WAIT_VLD: begin
          if (src_ready_o) begin
            src_state <= IDLE;
            src_valid_reg <= 1'b0;
          end
        end
      endcase
    end
  end

  // Output assignments for Source Domain
  assign src_ready_o = (src_state == WAIT_RDY) || (src_state == GRANT);
  assign src_valid_next = (src_state == IDLE) || (src_state == GRANT);

  // ---------------------------------------------------------------------------
  // Destination Domain Logic
  // ---------------------------------------------------------------------------
  // State Machine for Destination Side (4-Phase Handshake)
  // States:
  //   IDLE     : Waiting for valid
  //   WAIT_VLD : Valid asserted, waiting for data to be stable (internal)
  //   GRANT    : Ready asserted, waiting for valid (to accept next)
  //   WAIT_RDY : Valid asserted again (for next item), waiting for ready
  
  localparam DST_IDLE = 2'b00;
  localparam DST_WAIT_VLD = 2'b01;
  localparam DST_GRANT = 2'b10;
  localparam DST_WAIT_RDY = 2'b11;

  logic [1:0] dst_state;
  logic dst_valid_next;
  logic dst_ready_next;
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_reg;

  // Reset Synchronization for Destination Domain
  logic dst_rst_n_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      dst_rst_n_sync <= 1'b0;
    else
      dst_rst_n_sync <= 1'b1;
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_n_sync) begin
    if (!dst_rst_n_sync) begin
      dst_state <= DST_IDLE;
      dst_valid_reg <= 1'b0;
      dst_data_reg <= {WIDTH{1'b0}};
    end else begin
      case (dst_state)
        DST_IDLE: begin
          if (dst_valid_i) begin
            dst_valid_reg <= 1'b1;
            dst_data_reg <= dst_data_i;
            dst_state <= DST_WAIT_VLD;
          end
        end
        DST_WAIT_VLD: begin
          if (dst_ready_i) begin
            dst_state <= DST_GRANT;
          end
        end
        DST_GRANT: begin
          if (dst_valid_i) begin
            dst_valid_reg <= 1'b1;
            dst_data_reg <= dst_data_i;
            dst_state <= DST_WAIT_RDY;
          end
        end
        DST_WAIT_RDY: begin
          if (dst_ready_i) begin
            dst_state <= DST_IDLE;
            dst_valid_reg <= 1'b0;
          end
        end
      endcase
    end
  end

  // Output assignments for Destination Domain
  assign dst_ready_next = (dst_state == DST_WAIT_VLD) || (dst_state == DST_GRANT);
  assign dst_valid_next = (dst_state == DST_IDLE) || (dst_state == DST_GRANT);

  // ---------------------------------------------------------------------------
  // Cross-Domain Transfers (Asynchronous)
  // ---------------------------------------------------------------------------
  // Transfer src_ready_o to dst_clk_i domain
  logic [2:0] src_ready_sync;
  logic src_ready_synced;
  
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      src_ready_sync <= 3'b000;
    else
      src_ready_sync <= {src_ready_sync[1:0], src_ready_o};
  end
  assign src_ready_synced = src_ready_sync[2];

  // Transfer dst_valid_i to src_clk_i domain
  logic [2:0] dst_valid_sync;
  logic dst_valid_synced;
  
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      dst_valid_sync <= 3'b000;
    else
      dst_valid_sync <= {dst_valid_sync[1:0], dst_valid_i};
  end
  assign dst_valid_synced = dst_valid_sync[2];

  // Transfer dst_data_i to src_clk_i domain (only when valid)
  logic [WIDTH-1:0] dst_data_sync;
  logic dst_data_valid_sync;
  
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      dst_data_sync <= {WIDTH{1'b0}};
    else
      dst_data_sync <= dst_data_i;
  end
  assign dst_data_valid_sync = dst_valid_synced;

  // ---------------------------------------------------------------------------
  // Final Output Logic
  // ---------------------------------------------------------------------------
  // dst_valid_o and dst_data_o are driven by the destination domain logic
  // but must be stable while dst_valid_o is high and dst_ready_i is low.
  // The state machine ensures dst_data_reg is stable during DST_WAIT_VLD.
  
  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o = dst_data_reg;

  // src_ready_o is driven by the source domain logic
  // but must be stable while src_valid_o is high and src_ready_i is low.
  // The state machine ensures src_ready_o is stable during WAIT_RDY and GRANT.

endmodule
```<|im_end|>
