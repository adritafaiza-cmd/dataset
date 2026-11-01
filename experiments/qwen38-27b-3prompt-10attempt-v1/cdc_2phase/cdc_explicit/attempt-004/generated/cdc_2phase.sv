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

  // Handshake signals
  // src_to_dst: source indicates it has data ready for destination
  // dst_to_src: destination indicates it has consumed the data
  reg src_to_dst;
  reg dst_to_src;

  // Synchronizers
  // src_to_dst goes from src domain to dst domain
  reg [1:0] src_to_dst_sync;
  // dst_to_src goes from dst domain to src domain
  reg [1:0] dst_to_src_sync;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_busy <= 1'b0;
      src_data_reg <= {WIDTH{1'b0}};
      src_to_dst <= 1'b0;
    end else begin
      if (src_valid_i && !src_busy) begin
        src_busy <= 1'b1;
        src_data_reg <= src_data_i;
        src_to_dst <= 1'b1;
      end else if (dst_to_src_sync[1]) begin
        src_busy <= 1'b0;
        src_to_dst <= 1'b0;
      end
    end
  end

  assign src_ready_o = !src_busy;

  // Synchronize src_to_dst to dst domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_to_dst_sync <= 2'b00;
    end else begin
      src_to_dst_sync <= {src_to_dst_sync[0], src_to_dst};
    end
  end

  // Synchronize dst_to_src to src domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_to_src_sync <= 2'b00;
    end else begin
      dst_to_src_sync <= {dst_to_src_sync[0], dst_to_src};
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_busy <= 1'b0;
      dst_data_reg <= {WIDTH{1'b0}};
      dst_to_src <= 1'b0;
    end else begin
      if (src_to_dst_sync[1] && !dst_busy) begin
        dst_busy <= 1'b1;
        dst_data_reg <= src_data_reg;
        dst_to_src <= 1'b1;
      end else if (dst_busy && dst_ready_i) begin
        dst_busy <= 1'b0;
        dst_to_src <= 1'b0;
      end
    end
  end

  assign dst_valid_o = dst_busy;
  assign dst_data_o = dst_data_reg;

endmodule
