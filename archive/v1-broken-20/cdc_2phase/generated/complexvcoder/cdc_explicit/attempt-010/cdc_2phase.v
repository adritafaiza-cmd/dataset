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

  // Internal signals
  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic src_ready_reg;
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic transfer_flag;
  logic transfer_flag_sync;

  // Synchronization registers for source signals
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= 0;
      src_valid_reg <= 0;
    end else begin
      src_data_reg <= src_data_i;
      src_valid_reg <= src_valid_i;
    end
  end

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_reg <= 0;
    end else begin
      src_ready_reg <= src_ready_o;
    end
  end

  // Synchronization registers for destination signals
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= 0;
      dst_valid_reg <= 0;
    end else begin
      dst_data_reg <= dst_data_i;
      dst_valid_reg <= dst_valid_i;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_reg <= 0;
    end else begin
      dst_ready_reg <= dst_ready_i;
    end
  end

  // Transfer logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      transfer_flag <= 0;
    end else begin
      if (src_valid_i && src_ready_o && dst_ready_i) begin
        transfer_flag <= 1;
      end else if (dst_valid_o && dst_ready_i) begin
        transfer_flag <= 0;
      end
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      transfer_flag_sync <= 0;
    end else begin
      transfer_flag_sync <= transfer_flag;
    end
  end

  // Output logic
  assign src_ready_o = !transfer_flag;
  assign dst_data_o = src_data_reg;
  assign dst_valid_o = transfer_flag_sync && dst_ready_i;

endmodule
