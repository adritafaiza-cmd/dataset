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

  // Source domain: register data and valid when accepted
  // Destination domain: register data and valid when received

  // We use a 4-phase handshake with a FIFO of depth 1 (or 2 if DECOUPLED)
  // For simplicity and safety, we'll use a single-entry buffer with proper CDC.

  // Source side state
  reg [WIDTH-1:0] src_data_r;
  reg src_valid_r;
  reg src_ready_r;

  // Destination side state
  reg [WIDTH-1:0] dst_data_r;
  reg dst_valid_r;
  reg dst_ready_r;

  // CDC synchronization signals
  // We need to cross: src_valid -> dst, dst_ready -> src
  // And data must be stable when valid is asserted.

  // For 4-phase handshake:
  // 1. src_valid goes high (with data stable)
  // 2. dst sees valid, latches data, asserts dst_ready
  // 3. src sees dst_ready, deasserts src_valid
  // 4. dst sees src_valid deasserted, deasserts dst_ready

  // Let's implement this with proper synchronizers.

  // Source domain registers
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_r  <= {WIDTH{1'b0}};
      src_valid_r <= 1'b0;
      src_ready_r <= 1'b1;
    end else begin
      // Accept data when valid and ready
      if (src_valid_i && src_ready_r) begin
        src_data_r  <= src_data_i;
        src_valid_r <= 1'b1;
        src_ready_r <= 1'b0;
      end else if (!src_valid_r && dst_ready_int) begin
        // Previous transfer complete, ready for new
        src_ready_r <= 1'b1;
      end else if (src_valid_r && dst_ready_int) begin
        // Complete the handshake: deassert valid
        src_valid_r <= 1'b0;
        src_ready_r <= 1'b1;
      end
    end
  end

  // Destination domain registers
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_r  <= {WIDTH{1'b0}};
      dst_valid_r <= 1'b0;
      dst_ready_r <= 1'b1;
    end else begin
      // When valid is seen from source, latch data and assert ready
      if (src_valid_int && !dst_valid_r) begin
        dst_data_r  <= src_data_int;
        dst_valid_r <= 1'b1;
        dst_ready_r <= 1'b0;
      end else if (dst_valid_r && dst_ready_i) begin
        // Destination consumed the data
        dst_valid_r <= 1'b0;
        dst_ready_r <= 1'b1;
      end else if (!dst_valid_r && !src_valid_int) begin
        // Ensure ready is high when no valid
        dst_ready_r <= 1'b1;
      end
    end
  end

  // Synchronizers for src_valid -> dst domain
  reg [1:0] src_valid_sync;
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      src_valid_sync <= 2'b00;
    else
      src_valid_sync <= {src_valid_sync[0], src_valid_r};
  end
  wire src_valid_int = src_valid_sync[1];

  // Synchronizers for dst_ready -> src domain
  reg [1:0] dst_ready_sync;
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      dst_ready_sync <= 2'b00;
    else
      dst_ready_sync <= {dst_ready_sync[0], dst_ready_r};
  end
  wire dst_ready_int = dst_ready_sync[1];

  // Data synchronization: data must be stable when valid is high
  // We use a multi-bit synchronizer with a valid qualifier
  // Since data is stable when src_valid_r is high, we can use a simple approach:
  // Latch data in dst domain when src_valid_int transitions from 0 to 1

  reg [WIDTH-1:0] src_data_sync;
  reg src_data_valid_sync;

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_data_sync     <= {WIDTH{1'b0}};
      src_data_valid_sync <= 1'b0;
    end else begin
      // When src_valid_int goes high, capture the data
      if (src_valid_int && !src_data_valid_sync) begin
        src_data_sync     <= src_data_r;
        src_data_valid_sync <= 1'b1;
      end else if (!src_valid_int) begin
        src_data_valid_sync <= 1'b0;
      end
    end
  end

  wire [WIDTH-1:0] src_data_int = src_data_sync;

  // Outputs
  assign src_ready_o = src_ready_r;
  assign dst_data_o  = dst_data_r;
  assign dst_valid_o = dst_valid_r;

endmodule
