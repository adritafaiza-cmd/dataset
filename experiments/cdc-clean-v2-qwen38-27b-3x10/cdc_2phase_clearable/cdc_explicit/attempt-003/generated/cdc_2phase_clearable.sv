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

  // Source domain: request generation
  reg src_req_reg;
  reg src_ack_reg;
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;

  // Destination domain: acknowledge generation
  reg dst_ack_reg;
  reg src_req_reg_dst;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  reg dst_req_reg;
  reg src_ack_reg_dst;

  // Clear state machines
  reg src_clear_active;
  reg dst_clear_active;

  // Synchronizers for request (src -> dst)
  reg [SYNC_STAGES-1:0] src_req_sync;

  // Synchronizers for acknowledge (dst -> src)
  reg [SYNC_STAGES-1:0] dst_ack_sync;

  // Synchronizers for destination request (dst -> src)
  reg [SYNC_STAGES-1:0] dst_req_sync;

  // Synchronizers for source acknowledge (src -> dst)
  reg [SYNC_STAGES-1:0] src_ack_sync;

  // Synchronizers for data (src -> dst) - multi-bit, need to be stable
  reg [WIDTH-1:0] src_data_sync [0:SYNC_STAGES-1];

  // Synchronizers for clear signals
  reg [SYNC_STAGES-1:0] src_clear_sync;
  reg [SYNC_STAGES-1:0] dst_clear_sync;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_req_reg <= 1'b0;
      src_ack_reg <= 1'b0;
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_clear_active <= 1'b0;
    end else begin
      // Handle clear
      if (src_clear_i) begin
        src_clear_active <= 1'b1;
        src_req_reg <= 1'b0;
        src_ack_reg <= 1'b0;
        src_valid_reg <= 1'b0;
      end else if (src_clear_active) begin
        // Wait for dst to acknowledge the clear
        if (dst_ack_sync[SYNC_STAGES-1]) begin
          src_clear_active <= 1'b0;
        end
      end else begin
        // Normal operation
        if (src_valid_i && src_ready_o) begin
          src_data_reg <= src_data_i;
          src_valid_reg <= 1'b1;
          src_req_reg <= 1'b1;
        end else if (dst_ack_sync[SYNC_STAGES-1]) begin
          // Acknowledge received, clear request
          src_req_reg <= 1'b0;
          src_valid_reg <= 1'b0;
        end
      end
    end
  end

  // Source ready: can accept new data if not in clear and no outstanding request
  assign src_ready_o = !src_clear_active && !src_req_reg;

  // Source clear pending
  assign src_clear_pending_o = src_clear_active;

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ack_reg <= 1'b0;
      src_req_reg_dst <= 1'b0;
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      dst_req_reg <= 1'b0;
      src_ack_reg_dst <= 1'b0;
      dst_clear_active <= 1'b0;
    end else begin
      // Handle clear
      if (dst_clear_i) begin
        dst_clear_active <= 1'b1;
        dst_ack_reg <= 1'b0;
        dst_valid_reg <= 1'b0;
        dst_req_reg <= 1'b0;
      end else if (dst_clear_active) begin
        // Wait for src to acknowledge the clear
        if (src_ack_sync[SYNC_STAGES-1]) begin
          dst_clear_active <= 1'b0;
        end
      end else begin
        // Normal operation
        if (src_req_sync[SYNC_STAGES-1]) begin
          // Request received, capture data and acknowledge
          dst_data_reg <= src_data_sync[SYNC_STAGES-1];
          dst_valid_reg <= 1'b1;
          dst_ack_reg <= 1'b1;
        end else if (dst_valid_reg && dst_ready_i) begin
          // Data consumed, clear valid
          dst_valid_reg <= 1'b0;
          dst_ack_reg <= 1'b0;
        end
      end
    end
  end

  // Destination clear pending
  assign dst_clear_pending_o = dst_clear_active;

  // Destination outputs
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

  // Synchronizers
  // src_req: src -> dst
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_req_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      src_req_sync <= {src_req_sync[SYNC_STAGES-2:0], src_req};
    end
  end

  // dst_ack: dst -> src
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ack_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_ack_sync <= {dst_ack_sync[SYNC_STAGES-2:0], dst_ack};
    end
  end

  // dst_req: dst -> src (for clear coordination)
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_req_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_req_sync <= {dst_req_sync[SYNC_STAGES-2:0], dst_req};
    end
  end

  // src_ack: src -> dst (for clear coordination)
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_ack_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      src_ack_sync <= {src_ack_sync[SYNC_STAGES-2:0], src_ack};
    end
  end

  // Data synchronizer: src_data is stable when src_req is high
  // We synchronize the data along with the request
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      for (int i = 0; i < SYNC_STAGES; i = i + 1) begin
        src_data_sync[i] <= {WIDTH{1'b0}};
      end
    end else begin
      src_data_sync[0] <= src_data_reg;
      for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
        src_data_sync[i] <= src_data_sync[i-1];
      end
    end
  end

  // Clear signal synchronizers
  // src_clear: src -> dst
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_clear_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      src_clear_sync <= {src_clear_sync[SYNC_STAGES-2:0], src_clear_i};
    end
  end

  // dst_clear: dst -> src
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_clear_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_clear_sync <= {dst_clear_sync[SYNC_STAGES-2:0], dst_clear_i};
    end
  end

  // Assign internal request/acknowledge signals
  assign src_req = src_req_reg;
  assign dst_ack = dst_ack_reg;
  assign dst_req = dst_req_reg;
  assign src_ack = src_ack_reg;

  // Update dst_req_reg and src_ack_reg for clear coordination
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_req_reg <= 1'b0;
    end else begin
      if (dst_clear_i) begin
        dst_req_reg <= 1'b1;
      end else if (src_ack_sync[SYNC_STAGES-1]) begin
        dst_req_reg <= 1'b0;
      end
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ack_reg <= 1'b0;
    end else begin
      if (src_clear_i) begin
        src_ack_reg <= 1'b1;
      end else if (dst_req_sync[SYNC_STAGES-1]) begin
        src_ack_reg <= 1'b0;
      end
    end
  end

endmodule
