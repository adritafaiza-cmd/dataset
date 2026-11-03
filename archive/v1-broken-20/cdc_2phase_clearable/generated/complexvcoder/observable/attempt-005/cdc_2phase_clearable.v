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
  logic [WIDTH-1:0] synced_data_o;
  logic src_clear_pending;
  logic dst_clear_pending;

  // Source side synchronization and clear logic
  sync_register #(
    .WIDTH(WIDTH),
    .SYNC_STAGES(SYNC_STAGES)
  ) src_sync_reg (
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .data_i(src_data_i),
    .data_o(synced_data_o)
  );

  clear_logic src_clear_logic (
    .clear_i(src_clear_i),
    .clear_pending_o(src_clear_pending)
  );

  // Destination side synchronization and clear logic
  sync_register #(
    .WIDTH(WIDTH),
    .SYNC_STAGES(SYNC_STAGES)
  ) dst_sync_reg (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .data_i(synced_data_o),
    .data_o(dst_data_o)
  );

  clear_logic dst_clear_logic (
    .clear_i(dst_clear_i),
    .clear_pending_o(dst_clear_pending)
  );

  // Handshake logic for source side
  assign src_ready_o = dst_valid_o;

  // Handshake logic for destination side
  assign dst_valid_o = src_ready_i;

  // Clear pending outputs
  assign src_clear_pending_o = src_clear_pending;
  assign dst_clear_pending_o = dst_clear_pending;

endmodule

module sync_register #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3
)(
  input  clk_i,
  input  rst_ni,
  input  data_i,
  output data_o
);

  logic [WIDTH-1:0] reg_array [0:SYNC_STAGES-1];

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      reg_array <= '{WIDTH{1'b0}};
    end else begin
      reg_array <= {data_i, reg_array[0:SYNC_STAGES-2]};
    end
  end

  assign data_o = reg_array[SYNC_STAGES-1];

endmodule

module clear_logic (
  input  clear_i,
  output clear_pending_o
);

  logic clear_pending;

  always_ff @(posedge clear_i) begin
    clear_pending <= 1'b1;
  end

  always_ff @(negedge clear_i) begin
    clear_pending <= 1'b0;
  end

  assign clear_pending_o = clear_pending;

endmodule
