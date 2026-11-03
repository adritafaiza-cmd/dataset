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

  reg [WIDTH-1:0] src_data_i_ff;
  reg             src_valid_i_ff;
  reg             src_valid_i_sync_reg;
  reg             src_valid_i_synced;
  reg             src_ready_o_reg;
  reg [WIDTH-1:0] dst_data_o_reg;
  reg             dst_valid_o_ff;
  reg             dst_valid_o_reg;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_i_ff   <= '0;
      src_valid_i_ff  <= '0;
      src_ready_o_reg <= '0;
    end else begin
      if (src_valid_i && src_ready_o_reg) begin
        src_data_i_ff  <= src_data_i;
        src_valid_i_ff <= src_valid_i;
      end
      src_ready_o_reg <= !(src_valid_i_ff && dst_valid_o_ff);
    end
  end

  // Synchronize src_valid_i_ff to dst_clk_i
  sync_stage sync_stage_inst (
    .rst_ni(dst_rst_ni),
    .clk_i(dst_clk_i),
    .async_in_i(src_valid_i_ff),
    .sync_out_o(src_valid_i_synced)
  );

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o_reg  <= '0;
      dst_valid_o_ff  <= '0;
      dst_valid_o_reg <= '0;
    end else begin
      if (src_valid_i_synced) begin
        dst_data_o_reg  <= src_data_i_ff;
        dst_valid_o_ff  <= src_valid_i_synced;
      end
      if (dst_ready_i && dst_valid_o_ff) begin
        dst_valid_o_ff <= '0;
      end
      dst_valid_o_reg <= dst_valid_o_ff;
    end
  end

endmodule

module sync_stage (
  input  rst_ni,
  input  clk_i,
  input  async_in_i,
  output sync_out_o
);

  reg ff1;
  reg ff2;

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      ff1 <= '0;
      ff2 <= '0;
    end else begin
      ff1 <= async_in_i;
      ff2 <= ff1;
    end
  end

  assign sync_out_o = ff2;

endmodule
