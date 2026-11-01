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
  reg src_valid_reg;
  reg [WIDTH-1:0] src_data_reg;

  // Destination domain state
  reg dst_valid_reg;
  reg [WIDTH-1:0] dst_data_reg;

  // CDC synchronizers
  // src_valid_reg -> dst domain
  reg src_valid_sync1;
  reg src_valid_sync2;

  // dst_valid_reg -> src domain
  reg dst_valid_sync1;
  reg dst_valid_sync2;

  // Synchronize src_valid_reg to dst domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync1 <= 1'b0;
      src_valid_sync2 <= 1'b0;
    end else begin
      src_valid_sync1 <= src_valid_reg;
      src_valid_sync2 <= src_valid_sync1;
    end
  end

  // Synchronize dst_valid_reg to src domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_valid_sync1 <= 1'b0;
      dst_valid_sync2 <= 1'b0;
    end else begin
      dst_valid_sync1 <= dst_valid_reg;
      dst_valid_sync2 <= dst_valid_sync1;
    end
  end

  // Source domain logic
  assign src_ready_o = !src_valid_reg;

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
      src_data_reg  <= {WIDTH{1'b0}};
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_valid_reg <= 1'b1;
        src_data_reg  <= src_data_i;
      end else if (dst_valid_sync2) begin
        // Destination has consumed the item, clear source valid
        src_valid_reg <= 1'b0;
      end
    end
  end

  // Destination domain logic
  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o  = dst_data_reg;

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
      dst_data_reg  <= {WIDTH{1'b0}};
    end else begin
      if (src_valid_sync2 && !dst_valid_reg) begin
        // Source has a valid item, accept it
        dst_valid_reg <= 1'b1;
        dst_data_reg  <= src_data_reg;
      end else if (dst_valid_reg && dst_ready_i) begin
        // Destination consumed the item, clear valid
        dst_valid_reg <= 1'b0;
      end
    end
  end

endmodule
