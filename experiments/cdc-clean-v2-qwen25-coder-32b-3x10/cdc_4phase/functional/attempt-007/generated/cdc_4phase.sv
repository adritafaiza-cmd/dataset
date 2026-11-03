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

  // Source domain signals
  logic [WIDTH-1:0] src_data_sync [3:0];
  logic [1:0] src_phase;
  logic src_valid_sync;
  logic src_ready;

  // Destination domain signals
  logic [WIDTH-1:0] dst_data_sync [3:0];
  logic [1:0] dst_phase;
  logic dst_valid;
  logic dst_ready_sync;

  // Source domain logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_phase <= 2'b00;
      src_valid_sync <= 1'b0;
    end else begin
      src_phase <= src_phase + 1'b1;
      if (src_valid_i && src_ready) begin
        src_data_sync[src_phase] <= src_data_i;
        src_valid_sync <= 1'b1;
      end else if (dst_ready_sync) begin
        src_valid_sync <= 1'b0;
      end
    end
  end

  assign src_ready = DECOUPLED || !src_valid_sync;

  // Cross-domain synchronization for dst_ready
  logic [1:0] dst_ready_sync_reg;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_sync_reg <= 2'b00;
    end else begin
      dst_ready_sync_reg <= {dst_ready_sync_reg[0], dst_ready_i};
    end
  end

  assign dst_ready_sync = dst_ready_sync_reg[1];

  // Destination domain logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_phase <= 2'b00;
      dst_valid <= SEND_RESET_MSG;
      dst_data_sync <= {4{RESET_MSG}};
    end else begin
      dst_phase <= dst_phase + 1'b1;
      if (dst_ready_i && dst_valid) begin
        dst_phase <= dst_phase + 1'b1;
        dst_valid <= 1'b0;
      end else if (src_valid_sync) begin
        dst_data_sync[dst_phase] <= src_data_sync[dst_phase];
        dst_valid <= 1'b1;
      end
    end
  end

  assign dst_data_o = dst_data_sync[dst_phase];
  assign dst_valid_o = dst_valid;

endmodule
