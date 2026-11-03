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
  logic [WIDTH-1:0] data_sync_ff1;
  logic [WIDTH-1:0] data_sync_ff2;
  logic [1:0] valid_sync_ff1;
  logic [1:0] valid_sync_ff2;
  logic src_ready;
  logic dst_valid;

  // Source-side logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready <= 1'b0;
    end else begin
      src_ready <= ~src_valid_i | (DECOUPLED & src_ready);
    end
  end

  assign src_ready_o = src_ready;

  // Data and valid synchronization
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      data_sync_ff1 <= RESET_MSG;
      data_sync_ff2 <= RESET_MSG;
      valid_sync_ff1 <= 2'b00;
      valid_sync_ff2 <= 2'b00;
    end else begin
      data_sync_ff1 <= src_data_i;
      data_sync_ff2 <= data_sync_ff1;
      valid_sync_ff1 <= {valid_sync_ff1[0], src_valid_i};
      valid_sync_ff2 <= valid_sync_ff1;
    end
  end

  // Destination-side logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid <= SEND_RESET_MSG;
    end else begin
      dst_valid <= (valid_sync_ff2[1] & ~valid_sync_ff2[0]) | (SEND_RESET_MSG & ~valid_sync_ff2[1]);
    end
  end

  assign dst_valid_o = dst_valid;

  // Data output assignment
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o <= RESET_MSG;
    end else if (valid_sync_ff2[1] & ~valid_sync_ff2[0]) begin
      dst_data_o <= data_sync_ff2;
    end
  end

endmodule
