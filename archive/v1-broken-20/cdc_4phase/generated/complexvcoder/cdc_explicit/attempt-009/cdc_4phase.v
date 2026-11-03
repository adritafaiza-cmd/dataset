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
  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic [WIDTH-1:0] dst_data_reg;
  logic src_valid_out;
  logic src_ready_out;
  logic dst_valid_out;
  logic dst_ready_out;

  // Synchronizers
  logic [WIDTH-1:0] src_data_sync;
  logic src_valid_sync;
  logic src_ready_sync;
  logic dst_data_sync;
  logic dst_valid_sync;
  logic dst_ready_sync;

  // Handshake logic
  logic src_accept;
  logic dst_accept;

  // Edge detection for source clock domain
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
      src_data_reg <= {WIDTH{1'b0}};
    end else begin
      src_valid_reg <= src_valid_i;
      src_data_reg <= src_data_i;
    end
  end

  // Edge detection for destination clock domain
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
      dst_data_reg <= {WIDTH{1'b0}};
    end else begin
      dst_valid_reg <= dst_valid_i;
      dst_data_reg <= dst_data_i;
    end
  end

  // Source domain synchronization
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_sync <= {WIDTH{1'b0}};
      src_valid_sync <= 1'b0;
      src_ready_sync <= 1'b0;
    end else begin
      src_data_sync <= src_data_reg;
      src_valid_sync <= src_valid_reg;
      src_ready_sync <= src_ready_o;
    end
  end

  // Destination domain synchronization
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_sync <= {WIDTH{1'b0}};
      dst_valid_sync <= 1'b0;
      dst_ready_sync <= 1'b0;
    end else begin
      dst_data_sync <= dst_data_reg;
      dst_valid_sync <= dst_valid_reg;
      dst_ready_sync <= dst_ready_i;
    end
  end

  // Handshake logic
  assign src_accept = src_valid_sync & src_ready_sync;
  assign dst_accept = dst_valid_sync & dst_ready_sync;

  // Output logic
  assign src_ready_o = dst_ready_reg;
  assign dst_data_o = src_data_sync;
  assign dst_valid_o = src_accept;

  // Reset handling
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_o <= 1'b0;
    end else if (SEND_RESET_MSG) begin
      src_ready_o <= 1'b1;
    end else begin
      src_ready_o <= dst_ready_reg;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o <= RESET_MSG;
      dst_valid_o <= 1'b1;
    end else if (SEND_RESET_MSG) begin
      dst_data_o <= RESET_MSG;
      dst_valid_o <= 1'b1;
    end else begin
      dst_data_o <= src_data_sync;
      dst_valid_o <= src_accept;
    end
  end

endmodule
