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
  logic [WIDTH-1:0] src_sync_data_o;
  logic [WIDTH-1:0] dst_sync_data_o;
  logic clearable_channel_ready_o;
  logic clearable_channel_clear_pending_o;

  // Sync FFs for source clock domain
  sync_ff #(
    .WIDTH(WIDTH),
    .SYNC_STAGES(SYNC_STAGES)
  ) src_sync_ff (
    .rst_ni(src_rst_ni),
    .clk_i(src_clk_i),
    .d_i(src_data_i),
    .q_o(src_sync_data_o)
  );

  // Sync FFs for destination clock domain
  sync_ff #(
    .WIDTH(WIDTH),
    .SYNC_STAGES(SYNC_STAGES)
  ) dst_sync_ff (
    .rst_ni(dst_rst_ni),
    .clk_i(dst_clk_i),
    .d_i(dst_sync_data_o),
    .q_o(dst_data_o)
  );

  // Clearable two-phase valid/ready channel logic
  clearable_channel #(
    .WIDTH(WIDTH)
  ) clearable_channel (
    .clear_i(src_clear_i | dst_clear_i),
    .valid_i(src_valid_i),
    .data_i(src_sync_data_o),
    .ready_i(dst_ready_i),
    .clear_pending_o(src_clear_pending_o),
    .data_o(dst_sync_data_o),
    .valid_o(dst_valid_o)
  );

  // Drive ready signal from clearable channel
  assign src_ready_o = clearable_channel_ready_o;

endmodule

// Helper module: Sync FF
module sync_ff #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3
)(
  input  rst_ni,
  input  clk_i,
  input  [WIDTH-1:0] d_i,
  output reg [WIDTH-1:0] q_o
);

  generate
    if (SYNC_STAGES == 1) begin : single_ff
      always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
          q_o <= {WIDTH{1'b0}};
        end else begin
          q_o <= d_i;
        end
      end
    end else begin : multiple_ffs
      logic [WIDTH-1:0] q_reg [0:SYNC_STAGES-1];
      always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
          q_reg <= '{default: {WIDTH{1'b0}}};
        end else begin
          q_reg[0] <= d_i;
          for (integer i = 0; i < SYNC_STAGES - 1; i = i + 1) begin
            q_reg[i + 1] <= q_reg[i];
          end
        end
      end
      assign q_o = q_reg[SYNC_STAGES - 1];
    end
  endgenerate

endmodule

// Helper module: Clearable two-phase valid/ready channel
module clearable_channel #(
  parameter WIDTH = 1
)(
  input  clear_i,
  input  valid_i,
  input  [WIDTH-1:0] data_i,
  input  ready_i,
  output reg clear_pending_o,
  output reg [WIDTH-1:0] data_o,
  output reg valid_o
);

  reg [WIDTH-1:0] buffer;
  reg buffer_valid;
  reg clear_pending;

  always @(posedge clear_i or posedge ready_i) begin
    if (!ready_i) begin
      buffer_valid <= 1'b0;
      clear_pending <= 1'b0;
    end else if (clear_i) begin
      buffer_valid <= 1'b0;
      clear_pending <= 1'b1;
    end else if (valid_i && buffer_valid) begin
      buffer_valid <= 1'b0;
      clear_pending <= 1'b0;
    end else if (valid_i) begin
      buffer_valid <= 1'b1;
      buffer <= data_i;
      clear_pending <= 1'b0;
    end
  end

  assign clear_pending_o = clear_pending;
  assign data_o = buffer;
  assign valid_o = buffer_valid;

endmodule
