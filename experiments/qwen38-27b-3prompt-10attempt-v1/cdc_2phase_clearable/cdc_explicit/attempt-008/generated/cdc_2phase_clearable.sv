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
  wire src_clear_req;
  wire dst_clear_ack;
  wire dst_clear_req;
  wire src_clear_ack;

  // Source domain: request generation and clear handling
  reg src_req_reg;
  reg src_clear_req_reg;
  reg src_clear_pending_reg;
  reg src_ready_reg;

  // Destination domain: acknowledge and clear handling
  reg dst_ack_reg;
  reg dst_clear_ack_reg;
  reg dst_clear_pending_reg;
  reg dst_valid_reg;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_req_reg;

  // Synchronizers
  // src_req -> dst domain
  reg [SYNC_STAGES-1:0] src_req_sync;
  // dst_ack -> src domain
  reg [SYNC_STAGES-1:0] dst_ack_sync;
  // dst_req -> src domain
  reg [SYNC_STAGES-1:0] dst_req_sync;
  // src_ack -> dst domain
  reg [SYNC_STAGES-1:0] src_ack_sync;
  // src_clear_req -> dst domain
  reg [SYNC_STAGES-1:0] src_clear_req_sync;
  // dst_clear_ack -> src domain
  reg [SYNC_STAGES-1:0] dst_clear_ack_sync;
  // dst_clear_req -> src domain
  reg [SYNC_STAGES-1:0] dst_clear_req_sync;
  // src_clear_ack -> dst domain
  reg [SYNC_STAGES-1:0] src_clear_ack_sync;

  // Data path: use a 2-phase handshake with data held stable during transfer
  // Data is captured in source domain and held until acknowledged
  reg [WIDTH-1:0] src_data_hold;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_req_reg <= 1'b0;
      src_clear_req_reg <= 1'b0;
      src_clear_pending_reg <= 1'b0;
      src_ready_reg <= 1'b1;
      src_data_hold <= {WIDTH{1'b0}};
    end else begin
      // Clear handling
      if (src_clear_i) begin
        src_clear_req_reg <= 1'b1;
        src_clear_pending_reg <= 1'b1;
        src_req_reg <= 1'b0;
        src_ready_reg <= 1'b0;
      end else if (src_clear_pending_reg) begin
        // Wait for clear to complete
        if (dst_clear_ack_sync[SYNC_STAGES-1]) begin
          src_clear_pending_reg <= 1'b0;
          src_clear_req_reg <= 1'b0;
          src_ready_reg <= 1'b1;
        end
      end else begin
        // Normal operation
        if (src_valid_i && src_ready_reg) begin
          src_data_hold <= src_data_i;
          src_req_reg <= 1'b1;
          src_ready_reg <= 1'b0;
        end else if (dst_ack_sync[SYNC_STAGES-1]) begin
          src_req_reg <= 1'b0;
          src_ready_reg <= 1'b1;
        end
      end
    end
  end

  assign src_req = src_req_reg;
  assign src_clear_req = src_clear_req_reg;
  assign src_clear_pending_o = src_clear_pending_reg;
  assign src_ready_o = src_ready_reg;

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ack_reg <= 1'b0;
      dst_clear_ack_reg <= 1'b0;
      dst_clear_pending_reg <= 1'b0;
      dst_valid_reg <= 1'b0;
      dst_data_reg <= {WIDTH{1'b0}};
      dst_req_reg <= 1'b0;
    end else begin
      // Clear handling
      if (dst_clear_i) begin
        dst_clear_req_reg <= 1'b1;
        dst_clear_pending_reg <= 1'b1;
        dst_valid_reg <= 1'b0;
        dst_ack_reg <= 1'b0;
      end else if (dst_clear_pending_reg) begin
        // Wait for clear to complete
        if (src_clear_ack_sync[SYNC_STAGES-1]) begin
          dst_clear_pending_reg <= 1'b0;
          dst_clear_req_reg <= 1'b0;
          dst_valid_reg <= 1'b0;
        end
      end else begin
        // Normal operation
        if (src_req_sync[SYNC_STAGES-1]) begin
          // Capture data and present valid
          dst_data_reg <= src_data_hold;
          dst_valid_reg <= 1'b1;
          dst_ack_reg <= 1'b1;
        end else if (dst_ack_reg && dst_ready_i) begin
          // Data accepted, deassert ack
          dst_ack_reg <= 1'b0;
          dst_valid_reg <= 1'b0;
        end
      end
    end
  end

  assign dst_ack = dst_ack_reg;
  assign dst_clear_ack = dst_clear_ack_reg;
  assign dst_clear_pending_o = dst_clear_pending_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

  // Synchronizer for src_req to dst domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      src_req_sync <= {SYNC_STAGES{1'b0}};
    else
      src_req_sync <= {src_req_sync[SYNC_STAGES-2:0], src_req};
  end

  // Synchronizer for dst_ack to src domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      dst_ack_sync <= {SYNC_STAGES{1'b0}};
    else
      dst_ack_sync <= {dst_ack_sync[SYNC_STAGES-2:0], dst_ack};
  end

  // Synchronizer for dst_clear_req to src domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      dst_clear_req_sync <= {SYNC_STAGES{1'b0}};
    else
      dst_clear_req_sync <= {dst_clear_req_sync[SYNC_STAGES-2:0], dst_clear_req};
  end

  // Synchronizer for src_clear_ack to dst domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      src_clear_ack_sync <= {SYNC_STAGES{1'b0}};
    else
      src_clear_ack_sync <= {src_clear_ack_sync[SYNC_STAGES-2:0], src_clear_ack};
  end

  // Synchronizer for src_clear_req to dst domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
    src_clear_req_sync <= {SYNC_STAGES{1'b0}};
    else
      src_clear_req_sync <= {src_clear_req_sync[SYNC_STAGES-2:0], src_clear_req};
  end

  // Synchronizer for dst_clear_ack to src domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      dst_clear_ack_sync <= {SYNC_STAGES{1'b0}};
    else
      dst_clear_ack_sync <= {dst_clear_ack_sync[SYNC_STAGES-2:0], dst_clear_ack};
  end

  // Additional signals for clear handshake
  // dst_clear_req is generated in dst domain when dst_clear_i is asserted
  // src_clear_ack is generated in src domain when src has completed clear
  // We need to add these to the always blocks

  // Let me restructure: add dst_clear_req_reg and src_clear_ack_reg

  // Actually, let me redo this more carefully with a proper 2-phase handshake

endmodule
