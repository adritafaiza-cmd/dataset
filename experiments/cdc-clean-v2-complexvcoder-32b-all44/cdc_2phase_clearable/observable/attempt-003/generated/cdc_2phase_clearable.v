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
  wire synced_src_clear;
  wire synced_dst_clear;
  wire synced_src_valid;
  wire [WIDTH-1:0] synced_src_data;

  // Synchronize clear signals
  sync_register #(.SYNC_STAGES(SYNC_STAGES)) sync_src_clear (
    .rst_ni(dst_rst_ni),
    .clk_i(dst_clk_i),
    .d_i(src_clear_i),
    .q_o(synced_src_clear)
  );

  sync_register #(.SYNC_STAGES(SYNC_STAGES)) sync_dst_clear (
    .rst_ni(src_rst_ni),
    .clk_i(src_clk_i),
    .d_i(dst_clear_i),
    .q_o(synced_dst_clear)
  );

  // Synchronize valid and data signals
  sync_register #(.SYNC_STAGES(SYNC_STAGES)) sync_src_valid (
    .rst_ni(dst_rst_ni),
    .clk_i(dst_clk_i),
    .d_i(src_valid_i),
    .q_o(synced_src_valid)
  );

  sync_register #( .WIDTH(WIDTH), .SYNC_STAGES(SYNC_STAGES)) sync_src_data (
    .rst_ni(dst_rst_ni),
    .clk_i(dst_clk_i),
    .d_i(src_data_i),
    .q_o(synced_src_data)
  );

  // Clear pending outputs
  assign src_clear_pending_o = synced_dst_clear;
  assign dst_clear_pending_o = synced_src_clear;

  // Source ready output
  assign src_ready_o = dst_ready_i & ~synced_dst_clear;

  // Destination data and valid outputs
  assign dst_data_o = synced_src_data;
  assign dst_valid_o = synced_src_valid & ~synced_dst_clear;

endmodule

module sync_register #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3
)(
  input  rst_ni,
  input  clk_i,
  input  [WIDTH-1:0] d_i,
  output reg [WIDTH-1:0] q_o
);

  reg [WIDTH-1:0] sync_stages [SYNC_STAGES-1:0];

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (int i = 0; i < SYNC_STAGES; i = i + 1) begin
        sync_stages[i] <= {WIDTH{1'b0}};
      end
      q_o <= {WIDTH{1'b0}};
    end else begin
      sync_stages[0] <= d_i;
      for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
        sync_stages[i] <= sync_stages[i-1];
      end
      q_o <= sync_stages[SYNC_STAGES-1];
    end
  end

endmodule
