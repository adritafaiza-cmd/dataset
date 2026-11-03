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

  // Source side signals
  logic [WIDTH-1:0] src_data_sync;
  logic src_valid_sync;
  logic src_ready_sync;

  // Destination side signals
  logic [WIDTH-1:0] dst_data_sync;
  logic dst_valid_sync;
  logic dst_ready_sync;

  // Four-phase handshake signals
  logic [1:0] src_phase;
  logic [1:0] dst_phase;

  // Source side logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_phase <= 2'b00;
      src_data_sync <= RESET_MSG;
      src_valid_sync <= SEND_RESET_MSG;
    end else begin
      if (src_ready_sync && src_valid_i) begin
        src_data_sync <= src_data_i;
        src_valid_sync <= 1'b1;
      end else if (dst_ready_sync) begin
        src_valid_sync <= 1'b0;
      end
      src_phase <= src_phase + 1'b1;
    end
  end

  // Synchronize src_phase to destination clock
  logic [1:0] src_phase_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_phase_sync <= 2'b00;
    end else begin
      src_phase_sync <= src_phase;
    end
  end

  // Destination side logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_phase <= 2'b00;
      dst_data_sync <= RESET_MSG;
      dst_valid_sync <= SEND_RESET_MSG;
    end else begin
      if (dst_ready_i && dst_valid_sync) begin
        dst_valid_sync <= 1'b0;
      end else if (src_ready_sync) begin
        dst_data_sync <= src_data_sync;
        dst_valid_sync <= src_valid_sync;
      end
      dst_phase <= dst_phase + 1'b1;
    end
  end

  // Synchronize dst_phase to source clock
  logic [1:0] dst_phase_sync;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_phase_sync <= 2'b00;
    end else begin
      dst_phase_sync <= dst_phase;
    end
  end

  // Ready signals
  assign src_ready_sync = (src_phase_sync != src_phase);
  assign dst_ready_sync = (dst_phase_sync != dst_phase);

  // Output assignments
  assign src_ready_o = src_ready_sync;
  assign dst_data_o = dst_data_sync;
  assign dst_valid_o = dst_valid_sync;

endmodule
