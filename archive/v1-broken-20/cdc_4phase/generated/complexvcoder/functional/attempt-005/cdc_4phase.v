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

  // Internal signals
  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic src_ready_reg;
  logic dst_valid_reg;
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_ready_reg;
  logic [1:0] src_phase;
  logic [1:0] dst_phase;
  logic [1:0] sync_src_valid;
  logic [1:0] sync_src_ready;
  logic [1:0] sync_dst_valid;
  logic [1:0] sync_dst_ready;

  // Synchronizers for source signals
  sync_ff #(.WIDTH(1)) src_valid_sync (
    .clk(src_clk_i),
    .rst_n(src_rst_ni),
    .din(src_valid_i),
    .dout(sync_src_valid)
  );

  sync_ff #(.WIDTH(WIDTH)) src_data_sync (
    .clk(src_clk_i),
    .rst_n(src_rst_ni),
    .din(src_data_i),
    .dout(src_data_reg)
  );

  sync_ff #(.WIDTH(1)) src_ready_sync (
    .clk(src_clk_i),
    .rst_n(src_rst_ni),
    .din(src_ready_i),
    .dout(sync_src_ready)
  );

  // Synchronizers for destination signals
  sync_ff #(.WIDTH(1)) dst_valid_sync (
    .clk(dst_clk_i),
    .rst_n(dst_rst_ni),
    .din(dst_valid_o),
    .dout(sync_dst_valid)
  );

  sync_ff #(.WIDTH(WIDTH)) dst_data_sync (
    .clk(dst_clk_i),
    .rst_n(dst_rst_ni),
    .din(dst_data_o),
    .dout(dst_data_reg)
  );

  sync_ff #(.WIDTH(1)) dst_ready_sync (
    .clk(dst_clk_i),
    .rst_n(dst_rst_ni),
    .din(dst_ready_i),
    .dout(sync_dst_ready)
  );

  // Phase logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_phase <= 2'b00;
    end else begin
      src_phase <= src_phase + 1;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_phase <= 2'b00;
    end else begin
      dst_phase <= dst_phase + 1;
    end
  end

  // Handshake logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_reg <= 1'b0;
      dst_valid_reg <= 1'b0;
    end else begin
      if (src_phase == 2'b00 && src_valid_reg && dst_ready_reg) begin
        src_ready_reg <= 1'b0;
        dst_valid_reg <= 1'b1;
      end else if (src_phase == 2'b01 && dst_valid_reg) begin
        src_ready_reg <= 1'b0;
        dst_valid_reg <= 1'b0;
      end else if (src_phase == 2'b10 && src_valid_i && dst_ready_reg) begin
        src_ready_reg <= 1'b1;
        dst_valid_reg <= 1'b1;
      end else if (src_phase == 2'b11 && dst_valid_reg) begin
        src_ready_reg <= 1'b1;
        dst_valid_reg <= 1'b0;
      end
    end
  end

  // Output logic
  assign src_ready_o = src_ready_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

  // Reset handling
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b0;
      dst_valid_reg <= 1'b0;
      dst_data_reg <= {WIDTH{1'b0}};
      dst_ready_reg <= 1'b0;
    end else if (SEND_RESET_MSG) begin
      src_data_reg <= RESET_MSG;
      src_valid_reg <= 1'b1;
      src_ready_reg <= 1'b0;
      dst_valid_reg <= 1'b1;
      dst_data_reg <= RESET_MSG;
      dst_ready_reg <= 1'b0;
    end
  end

endmodule
