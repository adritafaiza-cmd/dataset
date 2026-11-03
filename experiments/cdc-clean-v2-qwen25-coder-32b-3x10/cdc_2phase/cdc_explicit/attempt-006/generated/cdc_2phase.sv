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

  // Source domain signals
  logic [WIDTH-1:0] src_data_sync;
  logic src_valid_sync;
  logic src_ready;

  // Destination domain signals
  logic [WIDTH-1:0] dst_data_reg [1:0];
  logic dst_valid_reg [1:0];
  logic dst_ready;

  // Source domain logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_sync <= '0;
      src_valid_sync <= 1'b0;
    end else begin
      if (src_ready) begin
        src_data_sync <= src_data_i;
        src_valid_sync <= src_valid_i;
      end
    end
  end

  assign src_ready_o = src_ready;

  // Cross-domain synchronization
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg[0] <= '0;
      dst_valid_reg[0] <= 1'b0;
    end else begin
      dst_data_reg[0] <= src_data_sync;
      dst_valid_reg[0] <= src_valid_sync;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg[1] <= '0;
      dst_valid_reg[1] <= 1'b0;
    end else begin
      dst_data_reg[1] <= dst_data_reg[0];
      dst_valid_reg[1] <= dst_valid_reg[0];
    end
  end

  // Destination domain logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o <= '0;
      dst_valid_o <= 1'b0;
      dst_ready <= 1'b0;
    end else begin
      if (dst_ready_i && dst_valid_reg[1]) begin
        dst_valid_o <= 1'b0;
      end else if (dst_valid_reg[1]) begin
        dst_valid_o <= 1'b1;
        dst_data_o <= dst_data_reg[1];
      end else begin
        dst_valid_o <= 1'b0;
      end

      dst_ready <= ~dst_valid_o || dst_ready_i;
    end
  end

  // Source ready logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready <= 1'b0;
    end else begin
      src_ready <= ~dst_valid_reg[1] || (dst_valid_reg[1] && dst_ready_i);
    end
  end

endmodule
