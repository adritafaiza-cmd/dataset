module cdc_4phase #(
  parameter WIDTH = 1,
  parameter DECOUPLED = 1,
  parameter SEND_RESET_MSG = 0,
  parameter [WIDTH-1:0] RESET_MSG = {WIDTH{1'b0}}
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

  wire src_valid;
  wire src_ready;
  wire dst_valid;
  wire dst_ready;

  // Source handshake
  src_handshake src_hs (
    .valid_i(src_valid_i),
    .ready_o(src_ready),
    .valid(src_valid),
    .ready(src_ready_o)
  );

  // Destination handshake
  dst_handshake dst_hs (
    .valid_i(dst_valid_o),
    .ready_o(dst_ready),
    .valid(dst_valid),
    .ready(dst_ready_i)
  );

  // Source clock domain crossing
  src_crossing src_xing (
    .valid_i(src_valid),
    .ready_o(src_ready),
    .valid(src_valid),
    .ready(src_ready),
    .data_i(src_data_i),
    .data_o(src_data_o),
    .reset_o(src_sync_reset.reset_o)
  );

  // Destination clock domain crossing
  dst_crossing dst_xing (
    .valid_i(dst_valid),
    .ready_o(dst_ready),
    .valid(dst_valid),
    .ready(dst_ready),
    .data_i(dst_data_i),
    .data_o(dst_data_o),
    .reset_o(dst_sync_reset.reset_o)
  );

  // Synchronize source reset
  sync_reset src_sync_reset (
    .reset_ni(src_rst_ni),
    .clk_i(src_clk_i),
    .reset_o(src_sync_reset.reset_o)
  );

  // Synchronize destination reset
  sync_reset dst_sync_reset (
    .reset_ni(dst_rst_ni),
    .clk_i(dst_clk_i),
    .reset_o(dst_sync_reset.reset_o)
  );

endmodule

module src_handshake (
  input  valid_i,
  output ready_o,
  output valid,
  input  ready
);

  reg valid_r;
  reg ready_r;

  always @(posedge src_clk_i) begin
    if (!src_rst_ni) begin
      valid_r <= 0;
      ready_r <= 0;
    end else begin
      valid_r <= valid_i;
      ready_r <= ready;
    end
  end

  assign valid = valid_r;
  assign ready_o = ready_r;

endmodule

module dst_handshake (
  input  valid_i,
  output ready_o,
  output valid,
  input  ready
);

  reg valid_r;
  reg ready_r;

  always @(posedge dst_clk_i) begin
    if (!dst_rst_ni) begin
      valid_r <= 0;
      ready_r <= 0;
    end else begin
      valid_r <= valid_i;
      ready_r <= ready;
    end
  end

  assign valid = valid_r;
  assign ready_o = ready_r;

endmodule

module src_crossing (
  input  valid_i,
  output ready_o,
  output valid,
  input  ready,
  input  [WIDTH-1:0] data_i,
  output [WIDTH-1:0] data_o,
  input  reset_o
);

  reg [WIDTH-1:0] data_r;
  reg valid_r;
  reg ready_r;

  always @(posedge dst_clk_i or posedge reset_o) begin
    if (reset_o) begin
      valid_r <= 0;
      ready_r <= 0;
      data_r <= {WIDTH{1'b0}};
    end else begin
      valid_r <= valid_i;
      ready_r <= ready;
      data_r <= data_i;
    end
  end

  assign valid = valid_r;
  assign ready_o = ready_r;
  assign data_o = data_r;

endmodule

module dst_crossing (
  input  valid_i,
  output ready_o,
  output valid,
  input  ready,
  input  [WIDTH-1:0] data_i,
  output [WIDTH-1:0] data_o,
  input  reset_o
);

  reg [WIDTH-1:0] data_r;
  reg valid_r;
  reg ready_r;

  always @(posedge src_clk_i or posedge reset_o) begin
    if (reset_o) begin
      valid_r <= 0;
      ready_r <= 0;
      data_r <= {WIDTH{1'b0}};
    end else begin
      valid_r <= valid_i;
      ready_r <= ready;
      data_r <= data_i;
    end
  end

  assign valid = valid_r;
  assign ready_o = ready_r;
  assign data_o = data_r;

endmodule

module sync_reset (
  input  reset_ni,
  input  clk_i,
  output reset_o
);

  reg reset_r;

  always @(posedge clk_i) begin
    if (!reset_ni) begin
      reset_r <= 1;
    end else begin
      reset_r <= 0;
    end
  end

  assign reset_o = reset_r;

endmodule
