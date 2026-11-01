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

  // Internal signals
  wire [WIDTH-1:0] src_data_reg;
  wire src_valid_reg;
  wire src_ready_int;
  wire dst_valid_int;
  wire dst_ready_int;
  wire [WIDTH-1:0] dst_data_int;

  // Source side: register data and valid, generate ready
  // Four-phase handshake:
  //   Phase 0: valid=0, ready=0 (idle)
  //   Phase 1: valid=1, ready=0 (data presented)
  //   Phase 2: valid=1, ready=1 (acknowledged)
  //   Phase 3: valid=0, ready=1 (deasserting)
  //   Back to Phase 0

  // Source side logic
  reg [WIDTH-1:0] src_data_r;
  reg src_valid_r;
  reg src_ready_r;

  // Destination side logic
  reg [WIDTH-1:0] dst_data_r;
  reg dst_valid_r;
  reg dst_ready_r;

  // Synchronizers for crossing from src to dst
  // We need to synchronize src_valid and src_data to dst domain
  // And synchronize dst_ready to src domain

  // Synchronize src_valid to dst domain
  reg [1:0] src_valid_sync;
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      src_valid_sync <= 2'b00;
    else
      src_valid_sync <= {src_valid_sync[0], src_valid_r};
  end

  // Synchronize src_data to dst domain
  // Data is stable when valid is high, so we can sample it
  reg [WIDTH-1:0] src_data_sync;
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      src_data_sync <= {WIDTH{1'b0}};
    else if (src_valid_sync[1] && !src_valid_sync[0])
      src_data_sync <= src_data_r;
  end

  // Synchronize dst_ready to src domain
  reg [1:0] dst_ready_sync;
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      dst_ready_sync <= 2'b00;
    else
      dst_ready_sync <= {dst_ready_sync[0], dst_ready_r};
  end

  // Source side state machine
  // src_ready_o is driven by the source side
  // We use a simple approach:
  // - src_ready is high when we are not in the middle of a transfer
  // - When src_valid_i is high and src_ready is high, we latch the data
  // - We assert src_valid_r to indicate data is available to the destination
  // - We deassert src_valid_r when dst_ready is high (synchronized)

  // For DECOUPLED mode, we add a FIFO buffer
  // For non-DECOUPLED mode, we use a simple handshake

  // Let's implement a simple 4-phase handshake with optional decoupling

  // Source side:
  // - Latch data when src_valid_i && src_ready_o
  // - Assert src_valid_r to send to destination
  // - Wait for dst_ready (synchronized) to deassert src_valid_r
  // - src_ready_o is high when not sending (src_valid_r is low)

  // Destination side:
  // - Detect rising edge of synchronized src_valid
  // - Latch data
  // - Assert dst_valid_r
  // - Wait for dst_ready_i to deassert dst_valid_r
  // - dst_ready_r is high when not receiving (dst_valid_r is low)

  // Source side logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_r  <= SEND_RESET_MSG ? RESET_MSG : {WIDTH{1'b0}};
      src_valid_r <= 1'b0;
      src_ready_r <= 1'b0;
    end else begin
      if (!src_valid_r) begin
        // Not currently sending, can accept new data
        src_ready_r <= 1'b1;
        if (src_valid_i) begin
          src_data_r  <= src_data_i;
          src_valid_r <= 1'b1;
          src_ready_r <= 1'b0;
        end
      end else begin
        // Currently sending, wait for dst_ready
        src_ready_r <= 1'b0;
        if (dst_ready_sync[1]) begin
          src_valid_r <= 1'b0;
          src_ready_r <= 1'b1;
        end
      end
    end
  end

  // Destination side logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_r  <= SEND_RESET_MSG ? RESET_MSG : {WIDTH{1'b0}};
      dst_valid_r <= 1'b0;
      dst_ready_r <= 1'b0;
    end else begin
      if (!dst_valid_r) begin
        // Not currently presenting data, can accept new data
        dst_ready_r <= 1'b1;
        if (src_valid_sync[1] && !src_valid_sync[0]) begin
          dst_data_r  <= src_data_sync;
          dst_valid_r <= 1'b1;
          dst_ready_r <= 1'b0;
        end
      end else begin
        // Currently presenting data, wait for dst_ready_i
        dst_ready_r <= 1'b0;
        if (dst_ready_i) begin
          dst_valid_r <= 1'b0;
          dst_ready_r <= 1'b1;
        end
      end
    end
  end

  // Outputs
  assign src_ready_o = src_ready_r;
  assign dst_data_o  = dst_data_r;
  assign dst_valid_o = dst_valid_r;

endmodule
