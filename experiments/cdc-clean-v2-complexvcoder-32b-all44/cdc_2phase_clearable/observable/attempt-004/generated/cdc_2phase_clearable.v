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
  reg sync_src_rst_rst_ni;
  reg sync_dst_rst_rst_ni;
  reg sync_src_clear_o;
  reg sync_dst_clear_o;
  reg src_clear_req;
  reg dst_clear_req;
  reg clear_src_stage;
  reg clear_dst_stage;
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  reg dst_valid_reg;

  // Instantiate sync_reset for source reset to destination clock domain
  sync_reset sync_src_rst (
    .rst_ni(src_rst_ni),
    .clk_i(dst_clk_i),
    .rst_no(sync_src_rst_rst_ni)
  );

  // Instantiate sync_reset for destination reset to source clock domain
  sync_reset sync_dst_rst (
    .rst_ni(dst_rst_ni),
    .clk_i(src_clk_i),
    .rst_no(sync_dst_rst_rst_ni)
  );

  // Instantiate sync_signal for source clear request to destination clock domain
  sync_signal #(.SYNC_STAGES(SYNC_STAGES)) sync_src_clear (
    .signal_i(src_clear_i),
    .clk_i(dst_clk_i),
    .signal_o(sync_src_clear_o)
  );

  // Instantiate sync_signal for destination clear request to source clock domain
  sync_signal #(.SYNC_STAGES(SYNC_STAGES)) sync_dst_clear (
    .signal_i(dst_clear_i),
    .clk_i(src_clk_i),
    .signal_o(sync_dst_clear_o)
  );

  // Source side logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_req <= 0;
      src_ready_o <= 0;
      src_data_reg <= 0;
      src_valid_reg <= 0;
      clear_src_stage <= 0;
    end else begin
      // Handle clear request
      if (src_clear_i) begin
        src_clear_req <= 1;
        src_ready_o <= 0;
        src_valid_reg <= 0;
      end else if (sync_dst_clear_o) begin
        src_clear_req <= 0;
        clear_src_stage <= 1;
      end else if (clear_src_stage) begin
        clear_src_stage <= 0;
      end

      // Handle data transfer
      if (src_valid_i && src_ready_o) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1;
      end else if (dst_ready_i && dst_valid_o) begin
        src_valid_reg <= 0;
      end

      // Ready signal generation
      if (!src_valid_reg && !src_clear_req) begin
        src_ready_o <= 1;
      end else begin
        src_ready_o <= 0;
      end
    end
  end

  // Destination side logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_req <= 0;
      dst_valid_o <= 0;
      dst_data_o <= 0;
      clear_dst_stage <= 0;
    end else begin
      // Handle clear request
      if (dst_clear_i) begin
        dst_clear_req <= 1;
        dst_valid_o <= 0;
      end else if (sync_src_clear_o) begin
        dst_clear_req <= 0;
        clear_dst_stage <= 1;
      end else if (clear_dst_stage) begin
        clear_dst_stage <= 0;
      end

      // Handle data transfer
      if (src_valid_reg && !dst_valid_reg && dst_ready_i) begin
        dst_valid_o <= 1;
        dst_data_o <= src_data_reg;
      end else if (dst_ready_i && dst_valid_o) begin
        dst_valid_o <= 0;
      end
    end
  end

  // Clear pending outputs
  assign src_clear_pending_o = src_clear_req;
  assign dst_clear_pending_o = dst_clear_req;

endmodule

// sync_reset module
module sync_reset (
  input  rst_ni,
  input  clk_i,
  output rst_no
);

  reg [1:0] rst_sync;

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rst_sync <= 2'b11;
    end else begin
      rst_sync <= {rst_sync[0], rst_ni};
    end
  end

  assign rst_no = rst_sync[1];

endmodule

// sync_signal module
module sync_signal #(
  parameter SYNC_STAGES = 3
)(
  input  signal_i,
  input  clk_i,
  output signal_o
);

  reg [SYNC_STAGES-1:0] signal_sync;

  always @(posedge clk_i) begin
    signal_sync <= {signal_sync[SYNC_STAGES-2:0], signal_i};
  end

  assign signal_o = signal_sync[SYNC_STAGES-1];

endmodule
