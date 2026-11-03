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
  reg [WIDTH-1:0] data_reg;
  reg valid_reg;
  reg ready_reg;
  reg valid_sync;
  reg ready_sync;

  // Instantiate CDC synchronizers
  cdc_2phase_ff_sync #(.WIDTH(1)) ff_sync_src (
    .rst_ni(src_rst_ni),
    .clk_i(src_clk_i),
    .data_i(src_valid_i),
    .clk_o(dst_clk_i),
    .data_o(valid_sync)
  );

  cdc_2phase_ff_sync #(.WIDTH(1)) ff_sync_dst (
    .rst_ni(dst_rst_ni),
    .clk_i(dst_clk_i),
    .data_i(dst_ready_i),
    .clk_o(src_clk_i),
    .data_o(ready_sync)
  );

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_o <= 0;
      data_reg <= 0;
      valid_reg <= 0;
    end else begin
      // Accept new data if both src_valid_i and src_ready_o are high
      if (src_valid_i && ready_sync) begin
        src_ready_o <= 0;
        data_reg <= src_data_i;
        valid_reg <= 1;
      end else if (valid_sync && dst_ready_i) begin
        // Data has been accepted by the destination
        src_ready_o <= 1;
        valid_reg <= 0;
      end else begin
        src_ready_o <= ready_sync;
      end
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o <= 0;
      dst_valid_o <= 0;
    end else begin
      if (valid_sync && !dst_valid_o) begin
        dst_data_o <= data_reg;
        dst_valid_o <= 1;
      end else if (dst_valid_o && dst_ready_i) begin
        dst_valid_o <= 0;
      end
    end
  end

endmodule

module cdc_2phase_ff_sync #(
  parameter WIDTH = 1
)(
  input  rst_ni,
  input  clk_i,
  input  [WIDTH-1:0] data_i,
  input  clk_o,
  output [WIDTH-1:0] data_o
);

  // Internal synchronization registers
  reg [WIDTH-1:0] sync_reg1;
  reg [WIDTH-1:0] sync_reg2;

  // Synchronize data from clk_i to clk_o
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      sync_reg1 <= 0;
      sync_reg2 <= 0;
    end else begin
      sync_reg1 <= data_i;
      sync_reg2 <= sync_reg1;
    end
  end

  // Output synchronized data
  always @(posedge clk_o or negedge rst_ni) begin
    if (!rst_ni) begin
      data_o <= 0;
    end else begin
      data_o <= sync_reg2;
    end
  end

endmodule
