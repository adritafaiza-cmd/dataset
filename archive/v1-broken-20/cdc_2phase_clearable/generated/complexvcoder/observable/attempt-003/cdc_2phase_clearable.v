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
  logic [WIDTH-1:0] src_sync_data;
  logic src_sync_valid, src_sync_ready;
  logic dst_sync_data;
  logic dst_sync_valid, dst_sync_ready;
  logic src_clear_reg_clear, dst_clear_reg_clear;
  logic src_valid_ready_valid, src_valid_ready_ready;
  logic [WIDTH-1:0] src_valid_ready_data;
  logic flush_src_flush, flush_dst_flush;
  logic [WIDTH-1:0] flush_dst_data;

  // Sync source signals to destination clock domain
  sync_block #(
    .WIDTH(WIDTH),
    .SYNC_STAGES(SYNC_STAGES)
  ) src_sync (
    .src_rst_ni(src_rst_ni),
    .src_clk_i(src_clk_i),
    .src_valid_i(src_valid_i),
    .src_ready_o(src_ready_o),
    .src_data_i(src_data_i),
    .dst_valid_o(src_sync_valid),
    .dst_ready_i(src_sync_ready),
    .dst_data_o(src_sync_data)
  );

  // Sync destination signals to source clock domain
  sync_block #(
    .WIDTH(WIDTH),
    .SYNC_STAGES(SYNC_STAGES)
  ) dst_sync (
    .src_rst_ni(dst_rst_ni),
    .src_clk_i(dst_clk_i),
    .src_valid_i(dst_ready_i),
    .src_ready_o(dst_ready_i),
    .src_data_i(dst_data_o),
    .dst_valid_o(dst_sync_valid),
    .dst_ready_i(dst_sync_ready),
    .dst_data_o(dst_sync_data)
  );

  // Register for source clear signal
  clear_reg src_clear_reg (
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .clear_i(src_clear_i),
    .clear_o(src_clear_reg_clear)
  );

  // Register for destination clear signal
  clear_reg dst_clear_reg (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .clear_i(dst_clear_i),
    .clear_o(dst_clear_reg_clear)
  );

  // Valid/ready logic for source
  valid_ready_logic src_valid_ready (
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .valid_i(src_sync_valid),
    .ready_i(src_ready_o),
    .data_i(src_sync_data),
    .valid_o(src_valid_ready_valid),
    .ready_o(src_valid_ready_ready),
    .data_o(src_valid_ready_data)
  );

  // Valid/ready logic for destination
  valid_ready_logic dst_valid_ready (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .valid_i(dst_sync_valid),
    .ready_i(dst_ready_i),
    .data_i(dst_sync_data),
    .valid_o(dst_valid_ready_valid),
    .ready_o(dst_valid_ready_ready),
    .data_o(dst_valid_ready_data)
  );

  // Flushing logic
  flush_logic flush (
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .src_clear_i(src_clear_reg_clear),
    .dst_clear_i(dst_clear_reg_clear),
    .src_valid_o(src_valid_ready_valid),
    .src_ready_o(src_valid_ready_ready),
    .src_data_o(src_valid_ready_data),
    .dst_valid_o(flush_dst_flush),
    .dst_ready_o(flush_dst_ready),
    .dst_data_o(flush_dst_data),
    .src_flush_o(src_clear_pending_o),
    .dst_flush_o(dst_clear_pending_o)
  );

endmodule

module sync_block #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  src_valid_i,
  input  src_ready_o,
  input  [WIDTH-1:0] src_data_i,
  output dst_valid_o,
  output dst_ready_i,
  output [WIDTH-1:0] dst_data_o
);

  logic [WIDTH-1:0] sync_reg [0:SYNC_STAGES-1];
  logic [SYNC_STAGES-1:0] valid_reg;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      sync_reg <= '{default: 0};
      valid_reg <= 0;
    end else begin
      if (src_valid_i && src_ready_o) begin
        sync_reg <= {sync_reg[SYNC_STAGES-2:0], src_data_i};
        valid_reg <= {valid_reg[SYNC_STAGES-2:0], 1'b1};
      end
    end
  end

  assign dst_valid_o = valid_reg[SYNC_STAGES-1];
  assign dst_data_o = sync_reg[SYNC_STAGES-1];
  assign dst_ready_i = (valid_reg[SYNC_STAGES-1] && dst_ready_i) || !valid_reg[SYNC_STAGES-1];

endmodule

module clear_reg (
  input  clk_i,
  input  rst_ni,
  input  clear_i,
  output clear_o
);

  logic clear_reg;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      clear_reg <= 0;
    end else begin
      clear_reg <= clear_i;
    end
  end

  assign clear_o = clear_reg;

endmodule

module valid_ready_logic (
  input  clk_i,
  input  rst_ni,
  input  valid_i,
  input  ready_i,
  input  [WIDTH-1:0] data_i,
  output valid_o,
  output ready_o,
  output [WIDTH-1:0] data_o
);

  logic valid_reg, ready_reg;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      valid_reg <= 0;
      ready_reg <= 0;
    end else begin
      if (valid_i && ready_i) begin
        valid_reg <= 1;
        ready_reg <= 0;
      end else if (ready_i) begin
        valid_reg <= 0;
        ready_reg <= 1;
      end
    end
  end

  assign valid_o = valid_reg;
  assign ready_o = ready_reg;
  assign data_o = data_i;

endmodule

module flush_logic (
  input  clk_i,
  input  rst_ni,
  input  src_clear_i,
  input  dst_clear_i,
  input  src_valid_o,
  input  src_ready_o,
  input  src_data_o,
  output dst_valid_o,
  output dst_ready_o,
  output [WIDTH-1:0] dst_data_o,
  output src_flush_o,
  output dst_flush_o
);

  logic src_flush, dst_flush;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      src_flush <= 0;
      dst_flush <= 0;
    end else begin
      if (src_clear_i || dst_clear_i) begin
        src_flush <= 1;
        dst_flush <= 1;
      end else begin
        src_flush <= 0;
        dst_flush <= 0;
      end
    end
  end

  assign dst_valid_o = src_flush;
  assign dst_ready_o = 1;
  assign dst_data_o = src_data_o;
  assign src_flush_o = src_flush;
  assign dst_flush_o = dst_flush;

endmodule
