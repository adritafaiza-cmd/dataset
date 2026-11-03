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
  reg src_clear_synced;
  reg dst_clear_synced;
  reg src_valid_synced;
  reg [WIDTH-1:0] src_data_synced;
  reg src_handshake;
  reg dst_handshake;
  reg src_clear_pending;
  reg dst_clear_pending;
  reg dst_valid;
  reg [WIDTH-1:0] dst_data;

  // Synchronize clear signals
  sync_cell sync_cell_src_clear (
    .async_in(src_clear_i),
    .clk(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .sync_out(src_clear_synced)
  );

  sync_cell sync_cell_dst_clear (
    .async_in(dst_clear_i),
    .clk(src_clk_i),
    .rst_ni(src_rst_ni),
    .sync_out(dst_clear_synced)
  );

  // Source clock domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pending <= 0;
      src_valid_synced <= 0;
      src_data_synced <= 0;
      src_handshake <= 0;
    end else begin
      // Clear pending logic
      if (src_clear_i) begin
        src_clear_pending <= 1;
      end
      if (src_clear_synced) begin
        src_clear_pending <= 0;
      end

      // Data and valid synchronization
      if (src_valid_i && src_ready_o) begin
        src_valid_synced <= src_valid_i;
        src_data_synced <= src_data_i;
      end

      // Ready signal generation
      src_ready_o <= !src_valid_i || dst_handshake;

      // Handshake handling
      if (src_handshake) begin
        src_valid_synced <= 0;
        src_handshake <= 0;
      end
    end
  end

  // Destination clock domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pending <= 0;
      dst_valid <= 0;
      dst_data <= 0;
      dst_handshake <= 0;
    end else begin
      // Clear pending logic
      if (dst_clear_i) begin
        dst_clear_pending <= 1;
      end
      if (dst_clear_synced) begin
        dst_clear_pending <= 0;
      end

      // Data and valid transfer
      if (src_valid_synced && dst_ready_i) begin
        dst_valid <= src_valid_synced;
        dst_data <= src_data_synced;
        dst_handshake <= 1;
      end

      // Valid output signal
      dst_valid_o <= dst_valid;

      // Data output signal
      dst_data_o <= dst_data;

      // Clear valid signal after handshake
      if (dst_ready_i) begin
        dst_valid <= 0;
      end

      // Clear handshake signal
      if (dst_handshake) begin
        dst_handshake <= 0;
      end
    end
  end

  // Clear pending outputs
  assign src_clear_pending_o = src_clear_pending;
  assign dst_clear_pending_o = dst_clear_pending;

endmodule

module sync_cell (
  input  async_in,
  input  clk,
  input  rst_ni,
  output sync_out
);

  reg [SYNC_STAGES-1:0] sync_reg;

  always @(posedge clk or negedge rst_ni) begin
    if (!rst_ni) begin
      sync_reg <= 0;
    end else begin
      sync_reg[0] <= async_in;
      for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
        sync_reg[i] <= sync_reg[i-1];
      end
    end
  end

  assign sync_out = sync_reg[SYNC_STAGES-1];

endmodule
