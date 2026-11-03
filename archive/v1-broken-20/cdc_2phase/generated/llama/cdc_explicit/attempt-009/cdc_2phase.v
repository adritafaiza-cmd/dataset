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

  logic [WIDTH-1:0] src_data_sync;
  logic src_valid_sync;
  logic src_ready_sync;
  logic dst_valid_sync;
  logic dst_ready_sync;
  logic [WIDTH-1:0] dst_data_sync;

  // Source clock domain
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_sync <= '0;
      src_valid_sync <= 1'b0;
      src_ready_sync <= 1'b1;
    end else begin
      src_data_sync <= src_data_i;
      src_valid_sync <= src_valid_i;
      src_ready_sync <= !src_valid_sync || dst_valid_sync;
    end
  end

  // Source to destination clock domain crossing
  logic [1:0] src_valid_pulse;
  logic [1:0] src_valid_pulse_sync;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_pulse <= '0;
    end else begin
      src_valid_pulse <= {src_valid_pulse[0], src_valid_i && src_ready_sync};
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_pulse_sync <= '0;
    end else begin
      src_valid_pulse_sync <= {src_valid_pulse_sync[0], src_valid_pulse[1]};
    end
  end

  // Destination clock domain
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_sync <= '0;
      dst_valid_sync <= 1'b0;
      dst_ready_sync <= 1'b1;
    end else begin
      dst_data_sync <= src_data_sync;
      dst_valid_sync <= src_valid_pulse_sync[1] && !dst_valid_sync;
      dst_ready_sync <= !dst_valid_sync || dst_ready_i;
    end
  end

  // Destination output
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o <= '0;
      dst_valid_o <= 1'b0;
    end else begin
      dst_data_o <= dst_data_sync;
      dst_valid_o <= dst_valid_sync;
    end
  end

  // Source output
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_o <= 1'b0;
    end else begin
      src_ready_o <= src_ready_sync;
    end
  end

endmodule
