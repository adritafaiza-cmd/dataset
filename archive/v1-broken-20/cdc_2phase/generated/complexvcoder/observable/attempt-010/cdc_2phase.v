module cdc_2phase #(
  parameter WIDTH = 1
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
  logic dst_ready_reg;

  // Register synchronization instances
  register_sync #(.WIDTH(WIDTH)) src_data_sync (
    .rst_ni(src_rst_ni),
    .clk_i(src_clk_i),
    .d_i(src_data_i),
    .q_o(src_data_reg)
  );

  register_sync #(.WIDTH(1)) src_valid_sync (
    .rst_ni(src_rst_ni),
    .clk_i(src_clk_i),
    .d_i(src_valid_i),
    .q_o(src_valid_reg)
  );

  register_sync #(.WIDTH(1)) src_ready_sync (
    .rst_ni(src_rst_ni),
    .clk_i(src_clk_i),
    .d_i(src_ready_o),
    .q_o(src_ready_reg)
  );

  register_sync #(.WIDTH(1)) dst_ready_sync (
    .rst_ni(dst_rst_ni),
    .clk_i(dst_clk_i),
    .d_i(dst_ready_i),
    .q_o(dst_ready_reg)
  );

  // Two-phase valid/ready handshake logic
  logic [1:0] state;
  localparam [1:0] IDLE = 2'b00, TRANSFERRING = 2'b01, DONE = 2'b10;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      state <= IDLE;
      src_ready_o <= 1'b0;
    end else begin
      src_ready_o <= 1'b1;
      case (state)
        IDLE: begin
          if (src_valid_i && dst_ready_reg) begin
            state <= TRANSFERRING;
          end
        end
        TRANSFERRING: begin
          state <= DONE;
        end
        DONE: begin
          if (dst_ready_reg) begin
            state <= IDLE;
          end
        end
        default: state <= IDLE;
      endcase
    end
  end

  assign dst_data_o = src_data_reg;
  assign dst_valid_o = (state == DONE) && dst_ready_reg;

endmodule

module register_sync #(
  parameter WIDTH = 1
)(
  input  rst_ni,
  input  clk_i,
  input  [WIDTH-1:0] d_i,
  output [WIDTH-1:0] q_o
);

  logic [WIDTH-1:0] q_reg;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      q_reg <= {WIDTH{1'b0}};
    end else begin
      q_reg <= d_i;
    end
  end

  assign q_o = q_reg;

endmodule
