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

  // Instantiate the async_fifo module
  async_fifo #(
    .WIDTH(WIDTH),
    .SYNC_STAGES(SYNC_STAGES)
  ) fifo_inst (
    .clk_wr(src_clk_i),
    .rst_wr_ni(src_rst_ni),
    .data_wr(src_data_i),
    .valid_wr(src_valid_i),
    .ready_wr(src_ready_o),
    .clk_rd(dst_clk_i),
    .rst_rd_ni(dst_rst_ni),
    .data_rd(dst_data_o),
    .valid_rd(dst_valid_o),
    .ready_rd(dst_ready_i)
  );

  // Instantiate the cdc_clear_control module for the source side
  cdc_clear_control src_clear_control_inst (
    .clk(src_clk_i),
    .rst_ni(src_rst_ni),
    .clear_i(src_clear_i),
    .clear_pending_o(src_clear_pending_o),
    .valid_i(fifo_inst.valid_wr),
    .ready_i(fifo_inst.ready_wr),
    .clear_ack(dst_clear_control_inst.clear_ack),
    .clear_req(dst_clear_control_inst.clear_req)
  );

  // Instantiate the cdc_clear_control module for the destination side
  cdc_clear_control dst_clear_control_inst (
    .clk(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .clear_i(dst_clear_i),
    .clear_pending_o(dst_clear_pending_o),
    .valid_i(fifo_inst.valid_rd),
    .ready_i(fifo_inst.ready_rd),
    .clear_ack(src_clear_control_inst.clear_ack),
    .clear_req(src_clear_control_inst.clear_req)
  );

endmodule

module async_fifo #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3
)(
  input  clk_wr,
  input  rst_wr_ni,
  input  [WIDTH-1:0] data_wr,
  input  valid_wr,
  output ready_wr,
  input  clk_rd,
  input  rst_rd_ni,
  output [WIDTH-1:0] data_rd,
  output valid_rd,
  input  ready_rd
);

  reg [WIDTH-1:0] data_reg;
  reg valid_reg, ready_reg;

  // Synchronize the write side to the read side
  reg [SYNC_STAGES-1:0] sync_valid;
  reg [SYNC_STAGES-1:0] sync_ready;

  always @(posedge clk_wr or negedge rst_wr_ni) begin
    if (!rst_wr_ni) begin
      sync_valid <= 0;
      valid_reg <= 0;
    end else begin
      sync_valid <= {sync_valid[SYNC_STAGES-2:0], valid_wr};
      if (ready_reg) begin
        data_reg <= data_wr;
        valid_reg <= sync_valid[SYNC_STAGES-1];
      end
    end
  end

  always @(posedge clk_rd or negedge rst_rd_ni) begin
    if (!rst_rd_ni) begin
      sync_ready <= 0;
      ready_reg <= 0;
    end else begin
      sync_ready <= {sync_ready[SYNC_STAGES-2:0], ready_rd};
      ready_reg <= sync_ready[SYNC_STAGES-1];
    end
  end

  assign valid_rd = valid_reg;
  assign ready_wr = ready_reg;

endmodule

module cdc_clear_control (
  input  clk,
  input  rst_ni,
  input  clear_i,
  output clear_pending_o,
  input  valid_i,
  input  ready_i,
  input  clear_ack,
  output clear_req
);

  reg clear_req_reg;
  reg clear_pending_reg;

  always @(posedge clk or negedge rst_ni) begin
    if (!rst_ni) begin
      clear_req_reg <= 0;
      clear_pending_reg <= 0;
    end else begin
      if (clear_i && !clear_pending_reg) begin
        clear_req_reg <= 1;
        clear_pending_reg <= 1;
      end else if (clear_ack) begin
        clear_req_reg <= 0;
        clear_pending_reg <= 0;
      end
    end
  end

  assign clear_pending_o = clear_pending_reg;
  assign clear_req = clear_req_reg;

endmodule
