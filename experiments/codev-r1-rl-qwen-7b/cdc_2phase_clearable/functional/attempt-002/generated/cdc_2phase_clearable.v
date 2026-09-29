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

  // Source domain signals
  reg src_clear_req;
  reg [SYNC_STAGES-1:0] dst_clear_sync;
  wire dst_clear_ack = dst_clear_sync[SYNC_STAGES-1];

  // Destination domain signals
  reg dst_clear_req;
  reg [SYNC_STAGES-1:0] src_clear_sync;
  wire src_clear_ack = src_clear_sync[SYNC_STAGES-1];

  // Two-phase handshake registers
  reg valid_reg;
  reg [WIDTH-1:0] data_reg;
  reg toggle_reg;

  // Synchronization to destination
  reg [SYNC_STAGES-1:0] sync_valid_dst;
  reg [SYNC_STAGES-1:0] sync_toggle_dst;

  // Destination domain registers
  reg dst_valid_reg;
  reg [WIDTH-1:0] dst_data_reg;

  // Source clear pending
  assign src_clear_pending_o = src_clear_req;

  // Destination clear pending
  assign dst_clear_pending_o = dst_clear_req;

  // Source ready logic
  assign src_ready_o = !src_clear_req && !valid_reg;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_req <= 0;
      valid_reg <= 0;
      data_reg <= 0;
      toggle_reg <= 0;
    end else begin
      // Synchronize dst_clear_ack
      dst_clear_sync <= {dst_clear_sync[SYNC_STAGES-2:0], dst_clear_ack};

      // Source clear request
      if (src_clear_i && !src_clear_req) begin
        src_clear_req <= 1;
      end else if (dst_clear_ack) begin
        src_clear_req <= 0;
      end

      // Two-phase handshake
      if (src_clear_req) begin
        valid_reg <= 0;
        toggle_reg <= 0;
      end else if (src_valid_i && src_ready_o) begin
        valid_reg <= 1;
        data_reg <= src_data_i;
        toggle_reg <= ~toggle_reg;
      end
    end
  end

  // Synchronize valid and toggle to destination
  always @(posedge dst_clk_i) begin
    if (!dst_rst_ni) begin
      sync_valid_dst <= 0;
      sync_toggle_dst <= 0;
    end else begin
      sync_valid_dst <= {sync_valid_dst[SYNC_STAGES-2:0], valid_reg};
      sync_toggle_dst <= {sync_toggle_dst[SYNC_STAGES-2:0], toggle_reg};
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_req <= 0;
      src_clear_sync <= 0;
      dst_valid_reg <= 0;
      dst_data_reg <= 0;
    end else begin
      // Synchronize src_clear_req
      src_clear_sync <= {src_clear_sync[SYNC_STAGES-2:0], src_clear_req};

      // Destination clear request
      if (src_clear_sync[SYNC_STAGES-1] && !dst_clear_req) begin
        dst_clear_req <= 1;
      end else if (dst_clear_ack) begin
        dst_clear_req <= 0;
      end

      // Synchronize dst_clear_ack
      dst_clear_sync <= {dst_clear_sync[SYNC_STAGES-2:0], dst_clear_ack};

      // Data capture and handshake
      if (dst_clear_req) begin
        dst_valid_reg <= 0;
      end else if (sync_valid_dst[SYNC_STAGES-1] != sync_toggle_dst[SYNC_STAGES-1]) begin
        dst_valid_reg <= 1;
        dst_data_reg <= data_reg;
      end else if (dst_ready_i) begin
        dst_valid_reg <= 0;
      end
    end
  end

  // Output assignments
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
