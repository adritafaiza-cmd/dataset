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
  wire src_clr_active;
  wire dst_clr_active;

  // Source domain clear logic
  reg src_clear_pending_r;
  assign src_clear_pending_o = src_clear_pending_r;

  // Destination domain clear logic
  reg dst_clear_pending_r;
  assign dst_clear_pending_o = dst_clear_pending_r;

  // Determine if clear is active (either local clear or async reset if enabled)
  wire src_clr_req = src_clear_i | (CLEAR_ON_ASYNC_RESET && !src_rst_ni);
  wire dst_clr_req = dst_clear_i | (CLEAR_ON_ASYNC_RESET && !dst_rst_ni);

  // Source domain: clear pending state machine
  // When src_clr_req is high, we enter clear pending state
  // We exit when we know the destination has acknowledged the clear
  // For simplicity, we use a handshake: source asserts clear, destination acknowledges

  // Let's use a simpler approach:
  // Source side: when clear is requested, set pending, wait for dst to finish clear
  // Destination side: when clear is requested, set pending, wait for src to finish clear

  // Actually, let's think about this more carefully.
  // The clear operation needs to:
  // 1. Isolate the channel (stop accepting new data)
  // 2. Drop in-flight data
  // 3. Return both sides to idle

  // We'll use a two-phase clear handshake:
  // - Source asserts src_clear_pending_o when clear is requested
  // - Destination asserts dst_clear_pending_o when clear is requested
  // - Both sides wait for the other to complete

  // For the actual data path, we'll use a simple FIFO-like structure with CDC

  // Source domain: hold data and valid
  reg [WIDTH-1:0] src_data_r;
  reg src_valid_r;
  reg src_ready_r;

  // Destination domain: hold data and valid
  reg [WIDTH-1:0] dst_data_r;
  reg dst_valid_r;

  // CDC synchronizers for valid signal
  reg [SYNC_STAGES-1:0] src_valid_sync;
  reg [SYNC_STAGES-1:0] dst_valid_sync;

  // CDC synchronizers for ready signal
  reg [SYNC_STAGES-1:0] dst_ready_sync;
  reg [SYNC_STAGES-1:0] src_ready_sync;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_r <= {WIDTH{1'b0}};
      src_valid_r <= 1'b0;
      src_ready_r <= 1'b1;
      src_clear_pending_r <= 1'b0;
      src_valid_sync <= {SYNC_STAGES{1'b0}};
      src_ready_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      // Handle clear
      if (src_clr_req) begin
        src_clear_pending_r <= 1'b1;
        src_valid_r <= 1'b0;
        src_ready_r <= 1'b0;
      end else if (src_clear_pending_r) begin
        // Wait for destination to finish clear
        // We need to know when destination is done
        // For now, we'll use a simple timeout or handshake
        // Let's use the dst_clear_pending_o synchronized to src domain
        if (dst_clear_pending_sync[SYNC_STAGES-1] == 1'b0) begin
          src_clear_pending_r <= 1'b0;
          src_ready_r <= 1'b1;
        end
      end else begin
        // Normal operation
        if (src_valid_i && src_ready_r) begin
          src_data_r <= src_data_i;
          src_valid_r <= 1'b1;
          src_ready_r <= 1'b0;
        end else if (!src_valid_r && dst_ready_sync[SYNC_STAGES-1]) begin
          src_ready_r <= 1'b1;
        end
      end
    end
  end

  // Synchronize src_valid_r to destination domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      src_valid_sync <= {src_valid_sync[SYNC_STAGES-2:0], src_valid_r};
    end
  end

  // Synchronize dst_ready to source domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_ready_sync <= {dst_ready_sync[SYNC_STAGES-2:0], dst_ready_i};
    end
  end

  // Synchronize dst_clear_pending to source domain
  reg [SYNC_STAGES-1:0] dst_clear_pending_sync;
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_clear_pending_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_clear_pending_sync <= {dst_clear_pending_sync[SYNC_STAGES-2:0], dst_clear_pending_r};
    end
  end

  // Synchronize src_clear_pending to destination domain
  reg [SYNC_STAGES-1:0] src_clear_pending_sync;
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_clear_pending_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      src_clear_pending_sync <= {src_clear_pending_sync[SYNC_STAGES-2:0], src_clear_pending_r};
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_r <= {WIDTH{1'b0}};
      dst_valid_r <= 1'b0;
      dst_clear_pending_r <= 1'b0;
      dst_valid_sync <= {SYNC_STAGES{1'b0}};
      dst_ready_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      // Handle clear
      if (dst_clr_req) begin
        dst_clear_pending_r <= 1'b1;
        dst_valid_r <= 1'b0;
      end else if (dst_clear_pending_r) begin
        // Wait for source to finish clear
        if (src_clear_pending_sync[SYNC_STAGES-1] == 1'b0) begin
          dst_clear_pending_r <= 1'b0;
        end
      end else begin
        // Normal operation
        if (src_valid_sync[SYNC_STAGES-1] && !dst_valid_r) begin
          dst_data_r <= src_data_r;
          dst_valid_r <= 1'b1;
        end else if (dst_valid_r && dst_ready_i) begin
          dst_valid_r <= 1'b0;
        end
      end
    end
  end

  // Synchronize dst_valid_r to source domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_valid_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_valid_sync <= {dst_valid_sync[SYNC_STAGES-2:0], dst_valid_r};
    end
  end

  // Synchronize src_ready to destination domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_ready_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      src_ready_sync <= {src_ready_sync[SYNC_STAGES-2:0], src_ready_r};
    end
  end

  // Outputs
  assign src_ready_o = src_ready_r;
  assign dst_data_o = dst_data_r;
  assign dst_valid_o = dst_valid_r;

endmodule
