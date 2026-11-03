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
  reg src_valid_ff1, src_valid_ff2, src_valid_ff3, src_valid_sync;
  reg dst_ready_ff1, dst_ready_ff2, dst_ready_ff3, dst_ready_sync;
  reg [WIDTH-1:0] data_ff;
  reg valid_ff, ready_ff;
  reg src_ready, dst_valid, src_reset, dst_reset;

  // Reset logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_reset <= 1'b1;
    end else begin
      src_reset <= 1'b0;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_reset <= 1'b1;
    end else begin
      dst_reset <= 1'b0;
    end
  end

  // Synchronize src_valid_i to dst_clk_i domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_ff1 <= 1'b0;
      src_valid_ff2 <= 1'b0;
      src_valid_ff3 <= 1'b0;
      src_valid_sync <= 1'b0;
    end else begin
      src_valid_ff1 <= src_valid_i;
      src_valid_ff2 <= src_valid_ff1;
      src_valid_ff3 <= src_valid_ff2;
      src_valid_sync <= src_valid_ff3;
    end
  end

  // Synchronize dst_ready_i to src_clk_i domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_ff1 <= 1'b0;
      dst_ready_ff2 <= 1'b0;
      dst_ready_ff3 <= 1'b0;
      dst_ready_sync <= 1'b0;
    end else begin
      dst_ready_ff1 <= dst_ready_i;
      dst_ready_ff2 <= dst_ready_ff1;
      dst_ready_ff3 <= dst_ready_ff2;
      dst_ready_sync <= dst_ready_ff3;
    end
  end

  // Source-side logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      data_ff <= RESET_MSG;
      valid_ff <= 1'b0;
    end else if (src_valid_i && src_ready) begin
      data_ff <= src_data_i;
      valid_ff <= 1'b1;
    end else if (src_valid_sync && dst_ready_sync) begin
      valid_ff <= 1'b0;
    end
  end

  always @(*) begin
    if (src_valid_i && !src_valid_sync) begin
      src_ready = 1'b1;
    end else if (DECOUPLED) begin
      src_ready = 1'b1;
    end else begin
      src_ready = 1'b0;
    end
  end

  assign src_ready_o = src_ready;

  // Destination-side logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data <= RESET_MSG;
      dst_valid <= 1'b0;
    end else if (src_valid_sync && !dst_valid && !dst_ready_sync) begin
      dst_data <= data_ff;
      dst_valid <= 1'b1;
    end else if (dst_ready_i) begin
      dst_valid <= 1'b0;
    end
  end

  assign dst_data_o = dst_valid ? dst_data : RESET_MSG;
  assign dst_valid_o = dst_valid;

endmodule
