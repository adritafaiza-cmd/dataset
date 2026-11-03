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

  // Internal signals for synchronization and handshake
  logic [WIDTH-1:0] src_to_dst_data_out;
  logic src_to_dst_valid_out;
  logic dst_to_src_ready_out;
  logic dst_to_src_valid_out;
  logic [WIDTH-1:0] dst_to_src_data_out;

  // Synchronizers for src_data_i and src_valid_i to dst_clk_i domain
  sync_crossing #(.WIDTH(WIDTH)) src_to_dst_sync (
    .data_in(src_data_i),
    .valid_in(src_valid_i),
    .rst_ni(src_rst_ni),
    .clk_i(dst_clk_i),
    .data_out(src_to_dst_data_out),
    .valid_out(src_to_dst_valid_out)
  );

  // Synchronizers for dst_data_o and dst_valid_o to src_clk_i domain
  sync_crossing #(.WIDTH(WIDTH)) dst_to_src_sync (
    .data_in(dst_data_o),
    .valid_in(dst_valid_o),
    .rst_ni(dst_rst_ni),
    .clk_i(src_clk_i),
    .data_out(dst_to_src_data_out),
    .valid_out(dst_to_src_valid_out)
  );

  // Four-phase handshake from src_clk_i domain to dst_clk_i domain
  four_phase_handshake #(.WIDTH(WIDTH)) src_to_dst_handshake (
    .req_in(src_to_dst_valid_out),
    .data_in(src_to_dst_data_out),
    .ack_out(dst_to_src_ready_out),
    .rst_ni(src_rst_ni),
    .clk_i(dst_clk_i),
    .valid_out(dst_valid_o),
    .data_out(src_data_o),
    .ack_in(dst_ready_i)
  );

  // Four-phase handshake from dst_clk_i domain to src_clk_i domain
  four_phase_handshake #(.WIDTH(WIDTH)) dst_to_src_handshake (
    .req_in(dst_to_src_valid_out),
    .data_in(dst_to_src_data_out),
    .ack_out(src_to_dst_ready_out),
    .rst_ni(dst_rst_ni),
    .clk_i(src_clk_i),
    .valid_out(src_ready_o),
    .data_out(dst_data_o),
    .ack_in(src_valid_i)
  );

endmodule

module sync_crossing #(
  parameter WIDTH = 1
)(
  input  [WIDTH-1:0] data_in,
  input  valid_in,
  input  rst_ni,
  input  clk_i,
  output [WIDTH-1:0] data_out,
  output valid_out
);

  logic [WIDTH-1:0] data_reg;
  logic valid_reg;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      data_out <= {WIDTH{1'b0}};
      valid_out <= 1'b0;
    end else begin
      data_out <= data_reg;
      valid_out <= valid_reg;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      data_reg <= {WIDTH{1'b0}};
      valid_reg <= 1'b0;
    end else if (valid_in) begin
      data_reg <= data_in;
      valid_reg <= 1'b1;
    end else begin
      valid_reg <= 1'b0;
    end
  end

endmodule

module four_phase_handshake #(
  parameter WIDTH = 1
)(
  input  req_in,
  input  [WIDTH-1:0] data_in,
  input  rst_ni,
  input  clk_i,
  output [WIDTH-1:0] data_out,
  output valid_out,
  input  ack_in
);

  typedef enum logic [1:0] {IDLE, REQ, ACK, DATA} state_t;
  state_t state, next_state;

  logic [WIDTH-1:0] data_reg;
  logic valid_reg;
  logic ack_reg;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state <= IDLE;
      data_out <= {WIDTH{1'b0}};
      valid_out <= 1'b0;
    end else begin
      state <= next_state;
      data_out <= data_reg;
      valid_out <= valid_reg;
    end
  end

  always_comb begin
    next_state = state;
    data_reg = data_in;
    valid_reg = 1'b0;
    ack_reg = ack_in;

    case (state)
      IDLE: begin
        if (req_in) begin
          next_state = REQ;
          data_reg = data_in;
        end
      end
      REQ: begin
        next_state = ACK;
        valid_reg = 1'b1;
      end
      ACK: begin
        next_state = DATA;
        ack_reg = ack_in;
      end
      DATA: begin
        if (ack_reg) begin
          next_state = IDLE;
        end
      end
      default: begin
        next_state = IDLE;
      end
    endcase
  end

endmodule
