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

  logic src_valid_d, src_valid_q;
  logic src_ready_d, src_ready_q;
  logic [WIDTH-1:0] src_data_d, src_data_q;
  logic dst_valid_d, dst_valid_q;
  logic dst_ready_d, dst_ready_q;
  logic [WIDTH-1:0] dst_data_d, dst_data_q;
  logic src_rst, dst_rst;
  logic send_reset_msg;

  assign src_rst = ~src_rst_ni;
  assign dst_rst = ~dst_rst_ni;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
      src_valid_q <= 1'b0;
      src_ready_q <= 1'b0;
      src_data_q <= {WIDTH{1'b0}};
    end else begin
      src_valid_q <= src_valid_d;
      src_ready_q <= src_ready_d;
      src_data_q <= src_data_d;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
      dst_valid_q <= 1'b0;
      dst_ready_q <= 1'b0;
      dst_data_q <= {WIDTH{1'b0}};
    end else begin
      dst_valid_q <= dst_valid_d;
      dst_ready_q <= dst_ready_d;
      dst_data_q <= dst_data_d;
    end
  end

  always_comb begin
    src_valid_d = src_valid_q;
    src_ready_d = src_valid_i && src_ready_q;
    src_data_d = src_data_q;
    if (src_valid_i && src_ready_q) begin
      src_valid_d = 1'b1;
      src_data_d = src_data_i;
    end
    if (~src_rst_ni) begin
      src_valid_d = 1'b0;
      src_ready_d = 1'b0;
      src_data_d = {WIDTH{1'b0}};
    end
  end

  always_comb begin
    dst_valid_d = dst_valid_q;
    dst_ready_d = dst_ready_i;
    dst_data_d = dst_data_q;
    if (dst_valid_q && dst_ready_i) begin
      dst_valid_d = 1'b0;
    end
    if (~dst_rst_ni) begin
      dst_valid_d = SEND_RESET_MSG? 1'b1 : 1'b0;
      dst_data_d = SEND_RESET_MSG? RESET_MSG : {WIDTH{1'b0}};
    end
  end

  always_comb begin
    src_ready_o = src_ready_q;
    dst_data_o = dst_data_q;
    dst_valid_o = dst_valid_q;
  end

  // handshake signals
  logic src_handshake, dst_handshake;
  logic src_handshake_d, dst_handshake_d;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
      src_handshake <= 1'b0;
    end else begin
      src_handshake <= src_handshake_d;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
      dst_handshake <= 1'b0;
    end else begin
      dst_handshake <= dst_handshake_d;
    end
  end

  always_comb begin
    src_handshake_d = src_handshake;
    if (src_valid_i && src_ready_q) begin
      src_handshake_d = 1'b1;
    end
    if (~src_rst_ni) begin
      src_handshake_d = 1'b0;
    end
  end

  always_comb begin
    dst_handshake_d = dst_handshake;
    if (dst_valid_q && dst_ready_i) begin
      dst_handshake_d = 1'b1;
    end
    if (~dst_rst_ni) begin
      dst_handshake_d = 1'b0;
    end
  end

  // 4-phase channel
  logic [1:0] src_phase, dst_phase;
  logic [1:0] src_phase_d, dst_phase_d;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
      src_phase <= 2'b00;
    end else begin
      src_phase <= src_phase_d;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
      dst_phase <= 2'b00;
    end else begin
      dst_phase <= dst_phase_d;
    end
  end

  always_comb begin
    src_phase_d = src_phase;
    case (src_phase)
      2'b00: begin
        if (src_valid_i && src_ready_q) begin
          src_phase_d = 2'b01;
        end
      end
      2'b01: begin
        if (dst_handshake) begin
          src_phase_d = 2'b10;
        end
      end
      2'b10: begin
        if (dst_handshake) begin
          src_phase_d = 2'b00;
        end
      end
    endcase
    if (~src_rst_ni) begin
      src_phase_d = 2'b00;
    end
  end

  always_comb begin
    dst_phase_d = dst_phase;
    case (dst_phase)
      2'b00: begin
        if (src_handshake) begin
          dst_phase_d = 2'b01;
        end
      end
      2'b01: begin
        if (dst_ready_i) begin
          dst_phase_d = 2'b10;
        end
      end
      2'b10: begin
        if (dst_ready_i) begin
          dst_phase_d = 2'b00;
        end
      end
    endcase
    if (~dst_rst_ni) begin
      dst_phase_d = 2'b00;
    end
  end

endmodule
