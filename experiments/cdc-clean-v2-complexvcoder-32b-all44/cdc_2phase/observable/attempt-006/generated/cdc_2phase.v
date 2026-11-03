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
  reg [WIDTH-1:0] data_ff;
  reg src_valid_i_synced;
  reg dst_ready_i_synced;

  // Instantiate the synchronization flops
  ff_sync src_to_dst_sync (
    .data_i(src_valid_i),
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .data_o(src_valid_i_synced)
  );

  ff_sync dst_to_src_sync (
    .data_i(dst_ready_i),
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .data_o(dst_ready_i_synced)
  );

  // Source side logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_o <= 1'b1;
      data_ff <= {WIDTH{1'b0}};
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_ready_o <= 1'b0;
        data_ff <= src_data_i;
      end else if (dst_ready_i_synced) begin
        src_ready_o <= 1'b1;
      end
    end
  end

  // Destination side logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_o <= 1'b0;
      dst_data_o <= {WIDTH{1'b0}};
    end else begin
      if (src_valid_i_synced && dst_ready_i) begin
        dst_valid_o <= 1'b0;
        dst_data_o <= data_ff;
      end else if (src_valid_i_synced) begin
        dst_valid_o <= 1'b1;
      end
    end
  end

endmodule

// Synchronization flop module
module ff_sync (
  input  data_i,
  input  clk_i,
  input  rst_ni,
  output data_o
);

  reg sync_reg1;
  reg sync_reg2;

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      sync_reg1 <= 1'b0;
      sync_reg2 <= 1'b0;
    end else begin
      sync_reg1 <= data_i;
      sync_reg2 <= sync_reg1;
    end
  end

  assign data_o = sync_reg2;

endmodule
