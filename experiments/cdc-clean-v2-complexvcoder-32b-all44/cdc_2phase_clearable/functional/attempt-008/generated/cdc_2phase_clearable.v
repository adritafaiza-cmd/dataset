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
  logic src_rst_sync_o;
  logic dst_rst_sync_o;
  logic src_clear_req;
  logic src_clear_ack;
  logic dst_clear_req;
  logic dst_clear_ack;

  // Instantiate the reset synchronizers
  async_reset_synchronizer #(
    .SYNC_STAGES(SYNC_STAGES)
  ) src_rst_sync (
    .async_rst_ni(src_rst_ni),
    .sync_clk_i(dst_clk_i),
    .sync_rst_no(src_rst_sync_o)
  );

  async_reset_synchronizer #(
    .SYNC_STAGES(SYNC_STAGES)
  ) dst_rst_sync (
    .async_rst_ni(dst_rst_ni),
    .sync_clk_i(src_clk_i),
    .sync_rst_no(dst_rst_sync_o)
  );

  // Instantiate the FIFO
  sync_fifo #(
    .WIDTH(WIDTH)
  ) fifo (
    .src_clk_i(src_clk_i),
    .src_rst_ni(src_rst_ni),
    .src_data_i(src_data_i),
    .src_valid_i(src_valid_i),
    .src_ready_o(src_ready_o),
    .dst_clk_i(dst_clk_i),
    .dst_rst_ni(dst_rst_ni),
    .dst_data_o(dst_data_o),
    .dst_valid_o(dst_valid_o),
    .dst_ready_i(dst_ready_i)
  );

  // Instantiate the clear logic for source and destination
  clear_logic src_clear_logic (
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .clear_i(src_clear_i),
    .clear_pending_o(src_clear_pending_o),
    .clear_req(src_clear_req),
    .clear_ack(src_clear_ack)
  );

  clear_logic dst_clear_logic (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .clear_i(dst_clear_i),
    .clear_pending_o(dst_clear_pending_o),
    .clear_req(dst_clear_req),
    .clear_ack(dst_clear_ack)
  );

  // Instantiate the clear handshake
  clear_handshake clear_handshake (
    .src_clk_i(src_clk_i),
    .src_rst_ni(src_rst_ni),
    .src_clear_req(src_clear_req),
    .src_clear_ack(src_clear_ack),
    .dst_clk_i(dst_clk_i),
    .dst_rst_ni(dst_rst_ni),
    .dst_clear_req(dst_clear_req),
    .dst_clear_ack(dst_clear_ack)
  );

endmodule

// Synchronize an active-low reset signal between two asynchronous clocks.
module async_reset_synchronizer #(
  parameter SYNC_STAGES = 3
)(
  input  async_rst_ni,
  input  sync_clk_i,
  output sync_rst_no
);

  logic [SYNC_STAGES-1:0] sync_chain;

  always_ff @(posedge sync_clk_i) begin
    sync_chain[0] <= async_rst_ni;
    for (int i = 1; i < SYNC_STAGES; i++) begin
      sync_chain[i] <= sync_chain[i-1];
    end
  end

  assign sync_rst_no = sync_chain[SYNC_STAGES-1];

endmodule

// Synchronous FIFO for data transfer between two clocks.
module sync_fifo #(
  parameter WIDTH = 1
)(
  input  src_clk_i,
  input  src_rst_ni,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,
  input  dst_clk_i,
  input  dst_rst_ni,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);

  logic [WIDTH-1:0] data_reg;
  logic valid_reg;

  // Source side
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      data_reg <= '0;
      valid_reg <= 0;
    end else if (src_valid_i && src_ready_o) begin
      data_reg <= src_data_i;
      valid_reg <= 1;
    end else if (dst_ready_i && valid_reg) begin
      valid_reg <= 0;
    end
  end

  // Destination side
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o <= '0;
      dst_valid_o <= 0;
    end else if (src_valid_i && src_ready_o) begin
      dst_data_o <= src_data_i;
      dst_valid_o <= 1;
    end else if (dst_ready_i && valid_reg) begin
      dst_data_o <= data_reg;
      dst_valid_o <= 1;
    end else if (dst_ready_i) begin
      dst_valid_o <= 0;
    end
  end

  // Ready signals
  assign src_ready_o = ~valid_reg;

endmodule

// Handle clear requests and generate clear pending signal.
module clear_logic (
  input  clk_i,
  input  rst_ni,
  input  clear_i,
  output clear_pending_o,
  output clear_req,
  input  clear_ack
);

  logic clear_req_reg;
  logic clear_pending_reg;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      clear_req_reg <= 0;
      clear_pending_reg <= 0;
    end else begin
      if (clear_i && !clear_pending_reg) begin
        clear_req_reg <= 1;
        clear_pending_reg <= 1;
      end else if (clear_ack) begin
        clear_req_reg <= 0;
      end
    end
  end

  assign clear_req = clear_req_reg;
  assign clear_pending_o = clear_pending_reg;

endmodule

// Coordinate clear requests between source and destination.
module clear_handshake (
  input  src_clk_i,
  input  src_rst_ni,
  input  src_clear_req,
  output src_clear_ack,
  input  dst_clk_i,
  input  dst_rst_ni,
  input  dst_clear_req,
  output dst_clear_ack
);

  logic src_clear_req_sync;
  logic dst_clear_req_sync;

  // Synchronize clear requests
  async_reset_synchronizer src_clear_req_sync_inst (
    .async_rst_ni(src_clear_req),
    .sync_clk_i(dst_clk_i),
    .sync_rst_no(src_clear_req_sync)
  );

  async_reset_synchronizer dst_clear_req_sync_inst (
    .async_rst_ni(dst_clear_req),
    .sync_clk_i(src_clk_i),
    .sync_rst_no(dst_clear_req_sync)
  );

  // Clear handshake logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_ack <= 0;
    end else if (src_clear_req && dst_clear_req_sync) begin
      src_clear_ack <= 1;
    end else if (src_clear_ack) begin
      src_clear_ack <= 0;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_ack <= 0;
    end else if (dst_clear_req && src_clear_req_sync) begin
      dst_clear_ack <= 1;
    end else if (dst_clear_ack) begin
      dst_clear_ack <= 0;
    end
  end

endmodule
