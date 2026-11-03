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
  reg  src_rst_sync;
  reg  dst_rst_sync;
  reg  src_valid_ff1;
  reg  src_valid_ff2;
  reg  [WIDTH-1:0] src_data_ff1;
  reg  [WIDTH-1:0] src_data_ff2;
  reg  [WIDTH-1:0] dst_data_ff1;
  reg  [WIDTH-1:0] dst_data_ff2;
  reg  [WIDTH-1:0] dst_data_ff3;
  reg  dst_valid_ff1;
  reg  dst_valid_ff2;
  reg  dst_valid_ff3;

  // Synchronize src_rst_ni to dst_clk_i domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_rst_sync <= 1'b0;
    end else begin
      src_rst_sync <= src_rst_ni;
    end
  end

  // Synchronize dst_rst_ni to src_clk_i domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_rst_sync <= 1'b0;
    end else begin
      dst_rst_sync <= dst_rst_ni;
    end
  end

  // Register src_valid_i to src_valid_ff1 and src_valid_ff2 on src_clk_i with src_rst_sync
  always @(posedge src_clk_i or negedge src_rst_sync) begin
    if (!src_rst_sync) begin
      src_valid_ff1 <= 1'b0;
      src_valid_ff2 <= 1'b0;
    end else begin
      src_valid_ff1 <= src_valid_i;
      src_valid_ff2 <= src_valid_ff1;
    end
  end

  // Register src_data_i to src_data_ff1 and src_data_ff2 on src_clk_i with src_rst_sync
  always @(posedge src_clk_i or negedge src_rst_sync) begin
    if (!src_rst_sync) begin
      src_data_ff1 <= RESET_MSG;
      src_data_ff2 <= RESET_MSG;
    end else begin
      src_data_ff1 <= src_data_i;
      src_data_ff2 <= src_data_ff1;
    end
  end

  // Register src_valid_ff2 to dst_valid_ff1 on dst_clk_i with dst_rst_sync
  always @(posedge dst_clk_i or negedge dst_rst_sync) begin
    if (!dst_rst_sync) begin
      dst_valid_ff1 <= 1'b0;
    end else begin
      dst_valid_ff1 <= src_valid_ff2;
    end
  end

  // Register dst_valid_ff1 to dst_valid_ff2 on dst_clk_i with dst_rst_sync
  always @(posedge dst_clk_i or negedge dst_rst_sync) begin
    if (!dst_rst_sync) begin
      dst_valid_ff2 <= 1'b0;
    end else begin
      dst_valid_ff2 <= dst_valid_ff1;
    end
  end

  // Register dst_valid_ff2 to dst_valid_ff3 on dst_clk_i with dst_rst_sync
  always @(posedge dst_clk_i or negedge dst_rst_sync) begin
    if (!dst_rst_sync) begin
      dst_valid_ff3 <= 1'b0;
    end else begin
      dst_valid_ff3 <= dst_valid_ff2;
    end
  end

  // Register src_data_ff2 to dst_data_ff1 on dst_clk_i with dst_rst_sync
  always @(posedge dst_clk_i or negedge dst_rst_sync) begin
    if (!dst_rst_sync) begin
      dst_data_ff1 <= RESET_MSG;
    end else begin
      dst_data_ff1 <= src_data_ff2;
    end
  end

  // Register dst_data_ff1 to dst_data_ff2 on dst_clk_i with dst_rst_sync
  always @(posedge dst_clk_i or negedge dst_rst_sync) begin
    if (!dst_rst_sync) begin
      dst_data_ff2 <= RESET_MSG;
    end else begin
      dst_data_ff2 <= dst_data_ff1;
    end
  end

  // Register dst_data_ff2 to dst_data_ff3 on dst_clk_i with dst_rst_sync
  always @(posedge dst_clk_i or negedge dst_rst_sync) begin
    if (!dst_rst_sync) begin
      dst_data_ff3 <= RESET_MSG;
    end else begin
      dst_data_ff3 <= dst_data_ff2;
    end
  end

  // Set src_ready_o to 1 if src_valid_ff1 is 0 or (DECOUPLED is 1 and src_valid_ff1 is 1 and dst_valid_ff3 is 0)
  assign src_ready_o = ~src_valid_ff1 || (DECOUPLED && src_valid_ff1 && ~dst_valid_ff3);

  // Set dst_data_o to dst_data_ff3 if dst_valid_ff3 is 1, otherwise to RESET_MSG if SEND_RESET_MSG is 1 and dst_rst_sync is 0
  assign dst_data_o = dst_valid_ff3 ? dst_data_ff3 : (SEND_RESET_MSG && dst_rst_sync) ? RESET_MSG : RESET_MSG;

  // Set dst_valid_o to dst_valid_ff3 if dst_valid_ff3 is 1, otherwise to 0 if SEND_RESET_MSG is 0 or dst_rst_sync is 1
  assign dst_valid_o = dst_valid_ff3 ? dst_valid_ff3 : (SEND_RESET_MSG && ~dst_rst_sync) ? 1'b1 : 1'b0;

endmodule
