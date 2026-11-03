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

  // Internal signals for synchronization and state management
  reg [WIDTH-1:0] src_data_sync;
  reg [WIDTH-1:0] src_data_sync_d1;
  reg src_valid_sync;
  reg src_valid_sync_d1;
  reg src_valid_sync_d2;
  reg dst_valid;
  reg [WIDTH-1:0] dst_data;
  reg reset_msg_sent;

  // Source-side synchronization logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_sync <= {WIDTH{1'b0}};
      src_valid_sync <= 1'b0;
      src_valid_sync_d1 <= 1'b0;
      src_valid_sync_d2 <= 1'b0;
    end else begin
      src_data_sync <= src_data_i;
      src_valid_sync <= src_valid_i;
      src_valid_sync_d1 <= src_valid_sync;
      src_valid_sync_d2 <= src_valid_sync_d1;
    end
  end

  // Destination-side synchronization logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_data_sync_d1 <= {WIDTH{1'b0}};
      dst_valid <= 1'b0;
      dst_data <= {WIDTH{1'b0}};
      reset_msg_sent <= 1'b0;
    end else begin
      src_data_sync_d1 <= src_data_sync;
      if (SEND_RESET_MSG && !reset_msg_sent) begin
        dst_valid <= 1'b1;
        dst_data <= RESET_MSG;
        reset_msg_sent <= 1'b1;
      end else if (src_valid_sync_d2 && !dst_valid) begin
        dst_valid <= 1'b1;
        dst_data <= src_data_sync_d1;
        reset_msg_sent <= 1'b0;
      end else if (dst_ready_i) begin
        dst_valid <= 1'b0;
      end
    end
  end

  // Source ready output
  assign src_ready_o = DECOUPLED || !dst_valid;

  // Destination outputs
  assign dst_data_o = dst_data;
  assign dst_valid_o = dst_valid;

endmodule
