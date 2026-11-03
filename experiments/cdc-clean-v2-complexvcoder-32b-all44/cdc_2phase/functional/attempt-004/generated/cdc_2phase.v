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
  reg src_reg_valid;
  reg [WIDTH-1:0] src_reg_data;
  reg dst_reg_valid;
  reg [WIDTH-1:0] dst_reg_data;
  reg sync_src_to_dst_valid;
  reg [WIDTH-1:0] sync_src_to_dst_data;
  reg sync_dst_to_src_ack;
  reg sync_dst_to_src_ack_reg;

  // Two-stage synchronizer for src_valid_i and src_data_i
  reg sync_stage1_src_valid;
  reg sync_stage1_src_data [WIDTH-1:0];

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      sync_stage1_src_valid <= 1'b0;
      sync_stage1_src_data <= '0;
      sync_src_to_dst_valid <= 1'b0;
      sync_src_to_dst_data <= '0;
      src_reg_valid <= 1'b0;
      src_reg_data <= '0;
    end else begin
      sync_stage1_src_valid <= src_valid_i;
      sync_stage1_src_data <= src_data_i;
      sync_src_to_dst_valid <= sync_stage1_src_valid;
      sync_src_to_dst_data <= sync_stage1_src_data;
      if (src_ready_o && src_valid_i) begin
        src_reg_valid <= 1'b1;
        src_reg_data <= src_data_i;
      end
    end
  end

  // Single-stage synchronizer for dst_ready_i
  reg sync_dst_ready;

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      sync_dst_ready <= 1'b0;
    end else begin
      sync_dst_ready <= dst_ready_i;
    end
  end

  // Destination-side logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_reg_valid <= 1'b0;
      dst_reg_data <= '0;
      sync_dst_to_src_ack <= 1'b0;
      sync_dst_to_src_ack_reg <= 1'b0;
    end else begin
      if (sync_src_to_dst_valid && !sync_dst_to_src_ack) begin
        dst_reg_valid <= 1'b1;
        dst_reg_data <= sync_src_to_dst_data;
      end else if (dst_ready_i && dst_valid_o) begin
        dst_reg_valid <= 1'b0;
      end
      sync_dst_to_src_ack_reg <= sync_dst_to_src_ack;
      sync_dst_to_src_ack <= dst_ready_i && dst_valid_o;
    end
  end

  // Output assignments
  assign src_ready_o = !sync_dst_to_src_ack && !sync_src_to_dst_valid;
  assign dst_data_o = dst_reg_data;
  assign dst_valid_o = dst_reg_valid;

endmodule
