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
  wire [WIDTH-1:0] dst_data_reg;
  wire dst_ready_int;

  // Source domain: register data and valid when accepted
  // Destination domain: register data and valid for output

  // We use a 4-phase handshake with a FIFO-like approach.
  // For simplicity and correctness, we use a single-entry buffer with
  // proper CDC synchronization.

  // Source side:
  // - src_ready_o is high when we can accept new data
  // - When src_valid_i && src_ready_o, we latch data and signal to destination

  // Destination side:
  // - dst_valid_o is high when we have data to present
  // - When dst_valid_o && dst_ready_i, we consume the data and signal back to source

  // We'll use a 2-stage synchronizer for each control signal crossing.

  // Source domain registers
  reg [WIDTH-1:0] src_data_latch;
  reg src_valid_latch;
  reg src_ready_reg;
  reg src_pending;  // indicates data has been sent to destination, waiting for ack

  // Destination domain registers
  reg [WIDTH-1:0] dst_data_latch;
  reg dst_valid_latch;
  reg dst_ready_reg;
  reg dst_pending;  // indicates data has been consumed, waiting for ack

  // Synchronizer signals
  wire src_to_dst_valid;
  wire [WIDTH-1:0] src_to_dst_data;
  wire dst_to_src_ready;

  // Source to destination: valid and data
  // We need to synchronize the valid signal and ensure data is stable
  // Use a 2-stage synchronizer for valid, and data is captured when valid is synchronized

  // For data integrity, we use a technique where data is only changed when
  // the handshake is not in progress, or we use a FIFO approach.

  // Let's use a simpler approach: a single-entry buffer with 4-phase handshake.
  // The key insight is that in a 4-phase handshake, the data is stable during
  // the entire transfer, so we can use a simple synchronizer for the control
  // signals and ensure data is only updated when safe.

  // Source domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_latch <= {WIDTH{1'b0}};
      src_valid_latch <= 1'b0;
      src_ready_reg <= 1'b1;
      src_pending <= 1'b0;
    end else begin
      if (src_valid_i && src_ready_reg) begin
        // Accept data
        src_data_latch <= src_data_i;
        src_valid_latch <= 1'b1;
        src_ready_reg <= 1'b0;
        src_pending <= 1'b1;
      end else if (src_pending && dst_to_src_ready) begin
        // Destination has acknowledged, ready for next
        src_valid_latch <= 1'b0;
        src_ready_reg <= 1'b1;
        src_pending <= 1'b0;
      end
    end
  end

  assign src_ready_o = src_ready_reg;

  // Synchronize src_valid_latch to destination domain
  reg [1:0] src_valid_sync;
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync <= 2'b00;
    end else begin
      src_valid_sync <= {src_valid_sync[0], src_valid_latch};
    end
  end

  // Synchronize data: we need to capture data when it's stable
  // Since data is only changed when src_valid_latch goes from 0 to 1,
  // and we only read it when src_valid_sync[1] is high (meaning it's been
  // stable for at least 2 dst_clk cycles), we can safely use the data.
  // But we need to ensure the data is synchronized properly.
  // Use a 2-stage synchronizer for each bit of data.

  reg [1:0][WIDTH-1:0] src_data_sync;
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_data_sync <= '0;
    end else begin
      src_data_sync[0] <= src_data_latch;
      src_data_sync[1] <= src_data_sync[0];
    end
  end

  // Destination domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_latch <= {WIDTH{1'b0}};
      dst_valid_latch <= 1'b0;
      dst_ready_reg <= 1'b1;
      dst_pending <= 1'b0;
    end else begin
      if (src_valid_sync[1] && dst_ready_reg) begin
        // Data is available and we're ready
        dst_data_latch <= src_data_sync[1];
        dst_valid_latch <= 1'b1;
        dst_ready_reg <= 1'b0;
        dst_pending <= 1'b1;
      end else if (dst_pending && dst_ready_i) begin
        // Destination has consumed the data
        dst_valid_latch <= 1'b0;
        dst_ready_reg <= 1'b1;
        dst_pending <= 1'b0;
      end
    end
  end

  assign dst_data_o = dst_data_latch;
  assign dst_valid_o = dst_valid_latch;

  // Synchronize dst_ready_reg to source domain
  reg [1:0] dst_ready_sync;
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_sync <= 2'b00;
    end else begin
      dst_ready_sync <= {dst_ready_sync[0], dst_ready_reg};
    end
  end

  assign dst_to_src_ready = dst_ready_sync[1];

endmodule
