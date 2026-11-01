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

  // Source domain state
  reg src_busy;
  reg [WIDTH-1:0] src_data_reg;

  // Destination domain state
  reg dst_busy;
  reg [WIDTH-1:0] dst_data_reg;

  // Synchronization signals
  // src_to_dst: indicates source has data ready for destination
  // dst_to_src: indicates destination has consumed data, source can accept new

  reg src_to_dst_raw;
  reg src_to_dst_sync1;
  reg src_to_dst_sync2;
  reg src_to_dst_sync3;

  reg dst_to_src_raw;
  reg dst_to_src_sync1;
  reg dst_to_src_sync2;
  reg dst_to_src_sync3;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_busy <= 1'b0;
      src_data_reg <= {WIDTH{1'b0}};
      src_to_dst_raw <= 1'b0;
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_data_reg <= src_data_i;
        src_busy <= 1'b1;
        src_to_dst_raw <= 1'b1;
      end else if (dst_to_src_sync3 && src_busy) begin
        src_busy <= 1'b0;
        src_to_dst_raw <= 1'b0;
      end
    end
  end

  assign src_ready_o = !src_busy;

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_busy <= 1'b0;
      dst_data_reg <= {WIDTH{1'b0}};
      dst_to_src_raw <= 1'b0;
    end else begin
      if (src_to_dst_sync3 && !dst_busy) begin
        dst_data_reg <= src_data_reg;
        dst_busy <= 1'b1;
      end else if (dst_busy && dst_ready_i) begin
        dst_busy <= 1'b0;
        dst_to_src_raw <= 1'b1;
      end
    end
  end

  assign dst_valid_o = dst_busy;
  assign dst_data_o = dst_data_reg;

  // Synchronizers
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_to_dst_sync1 <= 1'b0;
      src_to_dst_sync2 <= 1'b0;
      src_to_dst_sync3 <= 1'b0;
    end else begin
      src_to_dst_sync1 <= src_to_dst_raw;
      src_to_dst_sync2 <= src_to_dst_sync1;
      src_to_dst_sync3 <= src_to_dst_sync2;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_to_src_sync1 <= 1'b0;
      dst_to_src_sync2 <= 1'b0;
      dst_to_src_sync3 <= 1'b0;
    end else begin
      dst_to_src_sync1 <= dst_to_src_raw;
      dst_to_src_sync2 <= dst_to_src_sync1;
      dst_to_src_sync3 <= dst_to_src_sync2;
    end
  end

endmodule
