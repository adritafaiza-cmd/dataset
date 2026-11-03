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

  localparam int NUM_STAGES = SYNC_STAGES + 1;

  // Signals for source side
  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic src_ready_reg;
  logic src_clear_reg;
  logic src_clear_done;
  logic src_clear_ack;

  // Signals for destination side
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic dst_clear_reg;
  logic dst_clear_done;
  logic dst_clear_ack;

  // Registers for synchronization
  logic [WIDTH-1:0] sync_src_data [NUM_STAGES-1:0];
  logic sync_src_valid [NUM_STAGES-1:0];
  logic sync_src_ready [NUM_STAGES-1:0];
  logic sync_dst_data [NUM_STAGES-1:0];
  logic sync_dst_valid [NUM_STAGES-1:0];
  logic sync_dst_ready [NUM_STAGES-1:0];

  // Clear pending flags
  logic src_clear_pending;
  logic dst_clear_pending;

  // Synchronization logic
  generate
    for (genvar i = 0; i < NUM_STAGES; i++) begin : sync_gen
      if (i == 0) begin
        sync_src_data[i] <= src_data_i;
        sync_src_valid[i] <= src_valid_i;
        sync_src_ready[i] <= src_ready_reg;
        sync_dst_data[i] <= dst_data_reg;
        sync_dst_valid[i] <= dst_valid_reg;
        sync_dst_ready[i] <= dst_ready_i;
      end else begin
        sync_src_data[i] <= sync_src_data[i-1];
        sync_src_valid[i] <= sync_src_valid[i-1];
        sync_src_ready[i] <= sync_src_ready[i-1];
        sync_dst_data[i] <= sync_dst_data[i-1];
        sync_dst_valid[i] <= sync_dst_valid[i-1];
        sync_dst_ready[i] <= sync_dst_ready[i-1];
      end
    end
  endgenerate

  // Source side logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= 0;
      src_valid_reg <= 0;
      src_ready_reg <= 0;
      src_clear_reg <= 0;
      src_clear_done <= 0;
      src_clear_ack <= 0;
    end else begin
      src_data_reg <= sync_src_data[NUM_STAGES-1];
      src_valid_reg <= sync_src_valid[NUM_STAGES-1];
      src_ready_reg <= sync_dst_ready[NUM_STAGES-1];
      src_clear_reg <= src_clear_i;
      if (src_clear_i && src_clear_ack) begin
        src_clear_done <= 1;
      end else if (src_clear_done && src_clear_i) begin
        src_clear_done <= 0;
      end
    end
  end

  // Destination side logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= 0;
      dst_valid_reg <= 0;
      dst_ready_reg <= 0;
      dst_clear_reg <= 0;
      dst_clear_done <= 0;
      dst_clear_ack <= 0;
    end else begin
      dst_data_reg <= sync_dst_data[NUM_STAGES-1];
      dst_valid_reg <= sync_dst_valid[NUM_STAGES-1];
      dst_ready_reg <= sync_src_ready[NUM_STAGES-1];
      dst_clear_reg <= dst_clear_i;
      if (dst_clear_i && dst_clear_ack) begin
        dst_clear_done <= 1;
      end else if (dst_clear_done && dst_clear_i) begin
        dst_clear_done <= 0;
      end
    end
  end

  // Clear handshake logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pending <= 0;
    end else begin
      src_clear_pending <= src_clear_i && !src_clear_done;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pending <= 0;
    end else begin
      dst_clear_pending <= dst_clear_i && !dst_clear_done;
    end
  end

  assign src_clear_pending_o = src_clear_pending;
  assign dst_clear_pending_o = dst_clear_pending;

  // Clear acknowledgment logic
  assign src_clear_ack = dst_clear_ack && dst_clear_done;
  assign dst_clear_ack = src_clear_ack && src_clear_done;

  // Data forwarding logic
  assign dst_data_o = src_data_reg;
  assign dst_valid_o = src_valid_reg && dst_ready_i;
  assign src_ready_o = dst_valid_reg && src_ready_reg;

endmodule
