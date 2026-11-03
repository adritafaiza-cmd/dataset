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

  // Instantiate sync_fifo for data and handshake signals
  sync_fifo #(
    .WIDTH(WIDTH),
    .SYNC_STAGES(SYNC_STAGES)
  ) src_to_dst_fifo (
    .src_rst_ni(src_rst_ni),
    .src_clk_i(src_clk_i),
    .src_data_i(src_data_i),
    .src_valid_i(src_valid_i),
    .src_ready_o(src_ready_o),
    .dst_rst_ni(dst_rst_ni),
    .dst_clk_i(dst_clk_i),
    .dst_data_o(dst_data_o),
    .dst_valid_o(dst_valid_o),
    .dst_ready_i(dst_ready_i)
  );

  // Instantiate sync_register for clear requests from source to destination
  sync_register #(
    .SYNC_STAGES(SYNC_STAGES)
  ) src_clear_sync (
    .src_rst_ni(src_rst_ni),
    .src_clk_i(src_clk_i),
    .src_data_i(src_clear_i),
    .dst_rst_ni(dst_rst_ni),
    .dst_clk_i(dst_clk_i),
    .dst_data_o(src_to_dst_fifo.src_clear_i)
  );

  // Instantiate sync_register for clear requests from destination to source
  sync_register #(
    .SYNC_STAGES(SYNC_STAGES)
  ) dst_clear_sync (
    .src_rst_ni(dst_rst_ni),
    .src_clk_i(dst_clk_i),
    .src_data_i(dst_clear_i),
    .dst_rst_ni(src_rst_ni),
    .dst_clk_i(src_clk_i),
    .dst_data_o(src_to_dst_fifo.dst_clear_i)
  );

  // Instantiate sync_register for clear pending status from source to destination
  sync_register #(
    .SYNC_STAGES(SYNC_STAGES)
  ) src_clear_pending_sync (
    .src_rst_ni(src_rst_ni),
    .src_clk_i(src_clk_i),
    .src_data_i(src_to_dst_fifo.src_clear_pending_o),
    .dst_rst_ni(dst_rst_ni),
    .dst_clk_i(dst_clk_i),
    .dst_data_o(dst_clear_pending_o)
  );

  // Instantiate sync_register for clear pending status from destination to source
  sync_register #(
    .SYNC_STAGES(SYNC_STAGES)
  ) dst_clear_pending_sync (
    .src_rst_ni(dst_rst_ni),
    .src_clk_i(dst_clk_i),
    .src_data_i(src_to_dst_fifo.dst_clear_pending_o),
    .dst_rst_ni(src_rst_ni),
    .dst_clk_i(src_clk_i),
    .dst_data_o(src_clear_pending_o)
  );

endmodule

module sync_fifo #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3
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

  reg [WIDTH-1:0] data_ff;
  reg valid_ff;
  reg clear_src, clear_dst;

  // Synchronize clear signals
  sync_register #(
    .SYNC_STAGES(SYNC_STAGES)
  ) clear_src_sync (
    .src_rst_ni(src_rst_ni),
    .src_clk_i(src_clk_i),
    .src_data_i(src_clear_i),
    .dst_rst_ni(src_rst_ni),
    .dst_clk_i(src_clk_i),
    .dst_data_o(clear_src)
  );

  sync_register #(
    .SYNC_STAGES(SYNC_STAGES)
  ) clear_dst_sync (
    .src_rst_ni(dst_rst_ni),
    .src_clk_i(dst_clk_i),
    .src_data_i(dst_clear_i),
    .dst_rst_ni(dst_rst_ni),
    .dst_clk_i(dst_clk_i),
    .dst_data_o(clear_dst)
  );

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      data_ff <= '0;
      valid_ff <= 0;
      src_ready_o <= 0;
    end else begin
      if (clear_src) begin
        valid_ff <= 0;
        src_ready_o <= 1;
      end else if (src_valid_i && src_ready_o) begin
        data_ff <= src_data_i;
        valid_ff <= 1;
        src_ready_o <= 0;
      end else if (dst_ready_i && valid_ff) begin
        src_ready_o <= 1;
      end
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o <= '0;
      dst_valid_o <= 0;
    end else begin
      if (clear_dst) begin
        dst_valid_o <= 0;
      end else if (src_ready_o && src_valid_i) begin
        dst_data_o <= data_ff;
        dst_valid_o <= valid_ff;
      end else if (dst_ready_i) begin
        dst_valid_o <= 0;
      end
    end
  end

endmodule

module sync_register #(
  parameter SYNC_STAGES = 3
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  src_data_i,
  input  dst_rst_ni,
  input  dst_clk_i,
  output dst_data_o
);

  reg [SYNC_STAGES-1:0] sync_ff;

  // Source to destination synchronization
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      sync_ff <= '0;
    end else begin
      sync_ff[0] <= src_data_i;
      for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
        sync_ff[i] <= sync_ff[i-1];
      end
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o <= 0;
    end else begin
      dst_data_o <= sync_ff[SYNC_STAGES-1];
    end
  end

endmodule
