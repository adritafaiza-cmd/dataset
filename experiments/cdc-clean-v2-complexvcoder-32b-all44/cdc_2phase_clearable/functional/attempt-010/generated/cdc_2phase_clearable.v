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

  // Instantiate the async_crossing module
  async_crossing #(
    .WIDTH(WIDTH),
    .SYNC_STAGES(SYNC_STAGES),
    .CLEAR_ON_ASYNC_RESET(CLEAR_ON_ASYNC_RESET)
  ) async_crossing_inst (
    .rst_ni(src_rst_ni),
    .clk_i(src_clk_i),
    .valid_i(src_valid_i),
    .data_i(src_data_i),
    .ready_o(src_ready_o),
    .clear_i(src_clear_i),
    .clear_pending_o(src_clear_pending_o),
    .rst_no(dst_rst_ni),
    .clk_no(dst_clk_i),
    .ready_i(dst_ready_i),
    .data_o(dst_data_o),
    .valid_o(dst_valid_o),
    .clear_no(dst_clear_i),
    .clear_pending_no(dst_clear_pending_o)
  );

endmodule

module async_crossing #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3,
  parameter CLEAR_ON_ASYNC_RESET = 1
)(
  input  rst_ni,
  input  clk_i,
  input  valid_i,
  input  [WIDTH-1:0] data_i,
  output ready_o,
  input  clear_i,
  output clear_pending_o,
  input  rst_no,
  input  clk_no,
  input  ready_i,
  output [WIDTH-1:0] data_o,
  output valid_o,
  input  clear_no,
  output clear_pending_no
);

  // Internal signals
  logic [SYNC_STAGES:0] sync_valid;
  logic [SYNC_STAGES:0] sync_ready;
  logic [SYNC_STAGES:0] sync_clear;
  logic [WIDTH-1:0] data_reg;
  logic valid_reg;
  logic ready_reg;
  logic clear_reg;

  // Synchronize valid signal
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      sync_valid <= 0;
    end else begin
      sync_valid <= {sync_valid[SYNC_STAGES-1:0], valid_i};
    end
  end

  // Synchronize ready signal
  always_ff @(posedge clk_no or negedge rst_no) begin
    if (!rst_no) begin
      sync_ready <= 0;
    end else begin
      sync_ready <= {sync_ready[SYNC_STAGES-1:0], ready_i};
    end
  end

  // Synchronize clear signal
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      sync_clear <= 0;
    end else begin
      sync_clear <= {sync_clear[SYNC_STAGES-1:0], clear_i};
    end
  end

  // Register data payload on the source clock edge
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni || clear_i || (CLEAR_ON_ASYNC_RESET && !rst_ni)) begin
      data_reg <= 0;
      valid_reg <= 0;
    end else if (valid_i && sync_ready[SYNC_STAGES]) begin
      data_reg <= data_i;
      valid_reg <= 1;
    end
  end

  // Drive the destination valid signal high when there is registered data
  assign valid_o = valid_reg;

  // Drive the destination data signal with the registered data payload
  assign data_o = data_reg;

  // Register the ready signal on the destination clock edge
  always_ff @(posedge clk_no or negedge rst_no) begin
    if (!rst_no || clear_no || (CLEAR_ON_ASYNC_RESET && !rst_no)) begin
      ready_reg <= 0;
    end else if (ready_i && sync_valid[SYNC_STAGES]) begin
      ready_reg <= 1;
    end else if (valid_o && ready_i) begin
      ready_reg <= 0;
    end
  end

  // Drive the source ready signal high when there is room for new data
  assign ready_o = ~valid_reg || ready_reg;

  // Implement clear functionality to drop in-flight data and isolate the channel
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      clear_pending_o <= 0;
    end else if (clear_i || (CLEAR_ON_ASYNC_RESET && !rst_ni)) begin
      clear_pending_o <= 1;
    end else if (sync_clear[SYNC_STAGES]) begin
      clear_pending_o <= 0;
    end
  end

  always_ff @(posedge clk_no or negedge rst_no) begin
    if (!rst_no) begin
      clear_pending_no <= 0;
    end else if (clear_no || (CLEAR_ON_ASYNC_RESET && !rst_no)) begin
      clear_pending_no <= 1;
    end else if (sync_clear[SYNC_STAGES]) begin
      clear_pending_no <= 0;
    end
  end

endmodule
