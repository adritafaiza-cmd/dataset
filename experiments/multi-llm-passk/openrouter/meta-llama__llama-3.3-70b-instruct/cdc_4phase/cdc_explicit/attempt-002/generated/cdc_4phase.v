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

  logic src_valid_q, src_valid_q2, src_valid_q3;
  logic src_ready_q, src_ready_q2;
  logic [WIDTH-1:0] src_data_q, src_data_q2;
  logic dst_valid_q, dst_valid_q2, dst_valid_q3;
  logic dst_ready_q, dst_ready_q2;
  logic [WIDTH-1:0] dst_data_q, dst_data_q2;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_q <= 1'b0;
      src_valid_q2 <= 1'b0;
      src_valid_q3 <= 1'b0;
      src_ready_q <= 1'b0;
      src_ready_q2 <= 1'b0;
      src_data_q <= {WIDTH{1'b0}};
      src_data_q2 <= {WIDTH{1'b0}};
    end else begin
      src_valid_q <= src_valid_i;
      src_valid_q2 <= src_valid_q;
      src_valid_q3 <= src_valid_q2;
      src_ready_q <= src_ready_o;
      src_ready_q2 <= src_ready_q;
      src_data_q <= src_data_i;
      src_data_q2 <= src_data_q;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_q <= 1'b0;
      dst_valid_q2 <= 1'b0;
      dst_valid_q3 <= 1'b0;
      dst_ready_q <= 1'b0;
      dst_ready_q2 <= 1'b0;
      dst_data_q <= {WIDTH{1'b0}};
      dst_data_q2 <= {WIDTH{1'b0}};
    end else begin
      dst_valid_q <= dst_valid_o;
      dst_valid_q2 <= dst_valid_q;
      dst_valid_q3 <= dst_valid_q2;
      dst_ready_q <= dst_ready_i;
      dst_ready_q2 <= dst_ready_q;
      dst_data_q <= dst_data_o;
      dst_data_q2 <= dst_data_q;
    end
  end

  logic src_handshake, dst_handshake;
  logic src_handshake_q, dst_handshake_q;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_handshake <= 1'b0;
      src_handshake_q <= 1'b0;
    end else begin
      src_handshake <= src_valid_i && src_ready_o;
      src_handshake_q <= src_handshake;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_handshake <= 1'b0;
      dst_handshake_q <= 1'b0;
    end else begin
      dst_handshake <= dst_valid_o && dst_ready_i;
      dst_handshake_q <= dst_handshake;
    end
  end

  logic src_rst_sync, dst_rst_sync;
  logic src_rst_sync_q, dst_rst_sync_q;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_rst_sync <= 1'b1;
      src_rst_sync_q <= 1'b1;
    end else begin
      src_rst_sync <= 1'b0;
      src_rst_sync_q <= src_rst_sync;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_rst_sync <= 1'b1;
      dst_rst_sync_q <= 1'b1;
    end else begin
      dst_rst_sync <= 1'b0;
      dst_rst_sync_q <= dst_rst_sync;
    end
  end

  logic src_valid_pulse, dst_valid_pulse;
  logic src_valid_pulse_q, dst_valid_pulse_q;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_pulse <= 1'b0;
      src_valid_pulse_q <= 1'b0;
    end else begin
      src_valid_pulse <= src_valid_i && !src_valid_q;
      src_valid_pulse_q <= src_valid_pulse;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_pulse <= 1'b0;
      dst_valid_pulse_q <= 1'b0;
    end else begin
      dst_valid_pulse <= dst_valid_o && !dst_valid_q;
      dst_valid_pulse_q <= dst_valid_pulse;
    end
  end

  assign src_ready_o = (DECOUPLED) ? src_ready_q2 : src_ready_q;
  assign dst_valid_o = dst_valid_q2;
  assign dst_data_o = (SEND_RESET_MSG && src_rst_sync_q) ? RESET_MSG : dst_data_q2;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_o <= 1'b0;
    end else if (src_valid_pulse_q && src_ready_q) begin
      src_ready_o <= 1'b1;
    end else if (src_handshake_q) begin
      src_ready_o <= 1'b0;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_o <= 1'b0;
    end else if (dst_valid_pulse_q && dst_ready_q) begin
      dst_valid_o <= 1'b1;
    end else if (dst_handshake_q) begin
      dst_valid_o <= 1'b0;
    end
  end

endmodule
