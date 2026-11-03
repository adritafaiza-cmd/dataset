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
  reg [WIDTH-1:0] data_register;
  reg valid_src_to_dst_synced;
  reg ready_dst_to_src_synced;
  reg valid_ff;

  // Instantiate sync_register for src_valid_i to dst_clk_i
  sync_register sync_valid_src_to_dst (
    .clk_i  (dst_clk_i),
    .rst_ni (dst_rst_ni),
    .data_i (src_valid_i),
    .data_o (valid_src_to_dst_synced)
  );

  // Instantiate sync_register for dst_ready_i to src_clk_i
  sync_register sync_ready_dst_to_src (
    .clk_i  (src_clk_i),
    .rst_ni (src_rst_ni),
    .data_i (dst_ready_i),
    .data_o (ready_dst_to_src_synced)
  );

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_o <= 1'b0;
      data_register <= '0;
    end else begin
      if (src_valid_i && ready_dst_to_src_synced) begin
        src_ready_o <= 1'b1;
        data_register <= src_data_i;
      end else begin
        src_ready_o <= 1'b0;
      end
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      valid_ff <= 1'b0;
      dst_valid_o <= 1'b0;
      dst_data_o <= '0;
    end else begin
      if (valid_src_to_dst_synced && !valid_ff) begin
        valid_ff <= 1'b1;
        dst_valid_o <= 1'b1;
        dst_data_o <= data_register;
      end else if (dst_valid_o && dst_ready_i) begin
        valid_ff <= 1'b0;
        dst_valid_o <= 1'b0;
      end
    end
  end

endmodule

// Sync register module
module sync_register (
  input  clk_i,
  input  rst_ni,
  input  data_i,
  output data_o
);

  reg reg_1;
  reg reg_2;

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      reg_1 <= 1'b0;
      reg_2 <= 1'b0;
    end else begin
      reg_1 <= data_i;
      reg_2 <= reg_1;
    end
  end

  assign data_o = reg_2;

endmodule
