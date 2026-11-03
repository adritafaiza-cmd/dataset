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

  logic src_valid_sync;
  logic src_data_sync;
  logic src_clear_sync;
  logic dst_valid_sync;
  logic dst_data_sync;
  logic dst_clear_sync;

  logic src_clear_pending;
  logic dst_clear_pending;

  logic src_valid_reg;
  logic src_data_reg;
  logic dst_valid_reg;
  logic dst_data_reg;

  logic src_valid_pulse;
  logic dst_valid_pulse;

  assign src_clear_pending_o = src_clear_pending;
  assign dst_clear_pending_o = dst_clear_pending;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pending <= 1'b0;
      src_valid_sync <= 1'b0;
      src_data_sync <= '0;
      src_valid_reg <= 1'b0;
      src_data_reg <= '0;
    end else if (src_clear_i) begin
      src_clear_pending <= 1'b1;
      src_valid_sync <= 1'b0;
      src_data_sync <= '0;
      src_valid_reg <= 1'b0;
      src_data_reg <= '0;
    end else if (src_valid_i &&!src_valid_sync) begin
      src_valid_sync <= 1'b1;
      src_data_sync <= src_data_i;
    end else if (!src_valid_i && src_valid_sync) begin
      src_valid_sync <= 1'b0;
      src_data_sync <= '0;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pending <= 1'b0;
      dst_valid_sync <= 1'b0;
      dst_data_sync <= '0;
      dst_valid_reg <= 1'b0;
      dst_data_reg <= '0;
    end else if (dst_clear_i) begin
      dst_clear_pending <= 1'b1;
      dst_valid_sync <= 1'b0;
      dst_data_sync <= '0;
      dst_valid_reg <= 1'b0;
      dst_data_reg <= '0;
    end else if (dst_valid_sync && dst_ready_i) begin
      dst_valid_sync <= 1'b0;
      dst_data_sync <= '0;
    end
  end

  always_ff @(posedge src_clk_i) begin
    if (src_clear_i) begin
      src_valid_reg <= 1'b0;
      src_data_reg <= '0;
    end else if (src_valid_i && src_ready_o) begin
      src_valid_reg <= 1'b1;
      src_data_reg <= src_data_i;
    end
  end

  always_ff @(posedge dst_clk_i) begin
    if (dst_clear_i) begin
      dst_valid_reg <= 1'b0;
      dst_data_reg <= '0;
    end else if (dst_valid_sync && dst_ready_i) begin
      dst_valid_reg <= 1'b0;
      dst_data_reg <= '0;
    end
  end

  assign src_ready_o =!src_valid_reg &&!src_clear_pending;

  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o = dst_data_reg;

  assign src_valid_pulse = src_valid_sync &&!src_valid_reg;
  assign dst_valid_pulse = dst_valid_sync && dst_valid_reg;

  sync_pulse #(
   .WIDTH(1),
   .SYNC_STAGES(SYNC_STAGES)
  ) src_valid_sync_inst (
   .clk_i(src_clk_i),
   .rst_ni(src_rst_ni),
   .pulse_i(src_valid_pulse),
   .pulse_o()
  );

  sync_pulse #(
   .WIDTH(1),
   .SYNC_STAGES(SYNC_STAGES)
  ) src_clear_sync_inst (
   .clk_i(src_clk_i),
   .rst_ni(src_rst_ni),
   .pulse_i(src_clear_i),
   .pulse_o(src_clear_sync)
  );

  sync_pulse #(
   .WIDTH(WIDTH),
   .SYNC_STAGES(SYNC_STAGES)
  ) src_data_sync_inst (
   .clk_i(src_clk_i),
   .rst_ni(src_rst_ni),
   .pulse_i(src_valid_pulse),
   .data_i(src_data_sync),
   .data_o()
  );

  sync_pulse #(
   .WIDTH(1),
   .SYNC_STAGES(SYNC_STAGES)
  ) dst_valid_sync_inst (
   .clk_i(dst_clk_i),
   .rst_ni(dst_rst_ni),
   .pulse_i(dst_valid_pulse),
   .pulse_o()
  );

  sync_pulse #(
   .WIDTH(1),
   .SYNC_STAGES(SYNC_STAGES)
  ) dst_clear_sync_inst (
   .clk_i(dst_clk_i),
   .rst_ni(dst_rst_ni),
   .pulse_i(dst_clear_i),
   .pulse_o(dst_clear_sync)
  );

  sync_pulse #(
   .WIDTH(WIDTH),
   .SYNC_STAGES(SYNC_STAGES)
  ) dst_data_sync_inst (
   .clk_i(dst_clk_i),
   .rst_ni(dst_rst_ni),
   .pulse_i(dst_valid_pulse),
   .data_i(dst_data_sync),
   .data_o()
  );

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pending <= 1'b0;
    end else if (src_clear_i) begin
      src_clear_pending <= 1'b1;
    end else if (dst_clear_sync) begin
      src_clear_pending <= 1'b0;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pending <= 1'b0;
    end else if (dst_clear_i) begin
      dst_clear_pending <= 1'b1;
    end else if (src_clear_sync) begin
      dst_clear_pending <= 1'b0;
    end
  end

endmodule

module sync_pulse #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3
)(
  input  clk_i,
  input  rst_ni,
  input  pulse_i,
  output [WIDTH-1:0] data_o,
  input  [WIDTH-1:0] data_i
);

  logic [WIDTH-1:0] data_reg [SYNC_STAGES-1:0];

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (int i = 0; i < SYNC_STAGES; i++) begin
        data_reg[i] <= '0;
      end
    end else if (pulse_i) begin
      data_reg[0] <= data_i;
      for (int i = 1; i < SYNC_STAGES; i++) begin
        data_reg[i] <= data_reg[i-1];
      end
    end else begin
      for (int i = 1; i < SYNC_STAGES; i++) begin
        data_reg[i] <= data_reg[i-1];
      end
      data_reg[0] <= '0;
    end
  end

  assign data_o = data_reg[SYNC_STAGES-1];

endmodule
