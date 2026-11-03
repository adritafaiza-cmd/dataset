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
  reg src_ff_valid;
  reg [WIDTH-1:0] src_ff_data;
  reg src_sync_ready;
  reg dst_ff_valid;
  reg [WIDTH-1:0] dst_ff_data;
  reg dst_sync_valid;

  // Source-domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ff_valid <= 0;
      src_ff_data <= 0;
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_ff_valid <= 1;
        src_ff_data <= src_data_i;
      end
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_o <= 1;
    end else begin
      src_ready_o <= ~src_ff_valid || (src_sync_ready && ~dst_sync_valid);
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_sync_ready <= 0;
    end else begin
      src_sync_ready <= ~dst_ff_valid;
    end
  end

  // Destination-domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ff_valid <= 0;
      dst_ff_data <= 0;
    end else begin
      if (src_sync_valid && ~dst_sync_valid) begin
        dst_ff_valid <= 1;
        dst_ff_data <= src_ff_data;
      end
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_sync_valid <= 0;
    end else begin
      if (dst_sync_valid && dst_ready_i) begin
        dst_sync_valid <= 0;
      end else begin
        dst_sync_valid <= src_ff_valid;
      end
    end
  end

  // Output assignments
  assign dst_valid_o = dst_ff_valid;
  assign dst_data_o = dst_ff_data;

endmodule
