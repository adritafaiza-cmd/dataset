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
  reg [WIDTH-1:0] data_sync;
  reg valid_sync;
  reg dst_valid_reg;
  reg src_ready_reg;

  // Instantiate sync_ff for valid signal
  sync_ff sync_valid_ff (
    .d      (src_valid_i),
    .clk    (dst_clk_i),
    .rst_ni (dst_rst_ni),
    .q      (valid_sync)
  );

  // Instantiate sync_ff for data signal
  sync_ff sync_data_ff (
    .d      (src_data_i),
    .clk    (dst_clk_i),
    .rst_ni (dst_rst_ni),
    .q      (data_sync)
  );

  // Source clock domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_reg <= 1'b0;
    end else begin
      if (!dst_valid_reg) begin
        src_ready_reg <= 1'b1;
      end else if (src_valid_i) begin
        src_ready_reg <= 1'b0;
      end
    end
  end

  assign src_ready_o = src_ready_reg;

  // Destination clock domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
      dst_data_o    <= {WIDTH{1'b0}};
    end else begin
      if (dst_ready_i) begin
        if (valid_sync) begin
          dst_valid_reg <= 1'b1;
          dst_data_o    <= data_sync;
        end else begin
          dst_valid_reg <= 1'b0;
        end
      end else if (dst_valid_reg) begin
        dst_valid_reg <= 1'b1;
        dst_data_o    <= dst_data_o; // Hold the data stable
      end
    end
  end

  assign dst_valid_o = dst_valid_reg;

endmodule

module sync_ff (
  input  d,
  input  clk,
  input  rst_ni,
  output q
);

  reg q1, q2;

  always @(posedge clk or negedge rst_ni) begin
    if (!rst_ni) begin
      q1 <= 1'b0;
      q2 <= 1'b0;
    end else begin
      q1 <= d;
      q2 <= q1;
    end
  end

  assign q = q2;

endmodule
