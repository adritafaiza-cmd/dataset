module cdc_2phase #(
  parameter int unsigned WIDTH = 1
)(
  input  logic                 src_rst_ni,
  input  logic                 src_clk_i,
  input  logic [WIDTH-1:0]     src_data_i,
  input  logic                 src_valid_i,
  output logic                 src_ready_o,

  input  logic                 dst_rst_ni,
  input  logic                 dst_clk_i,
  output logic [WIDTH-1:0]     dst_data_o,
  output logic                 dst_valid_o,
  input  logic                 dst_ready_i
);

  logic protocol_rst_ni;

  logic [WIDTH-1:0] src_data_hold_q;
  logic             src_req_q;
  logic             src_ack_sync;

  logic             dst_req_sync;
  logic             dst_ack_q;

  assign protocol_rst_ni = src_rst_ni & dst_rst_ni;

  cdc_2phase_sync_bit i_sync_ack_to_src (
    .clk_i   (src_clk_i),
    .rst_ni  (protocol_rst_ni),
    .async_i (dst_ack_q),
    .sync_o  (src_ack_sync)
  );

  cdc_2phase_sync_bit i_sync_req_to_dst (
    .clk_i   (dst_clk_i),
    .rst_ni  (protocol_rst_ni),
    .async_i (src_req_q),
    .sync_o  (dst_req_sync)
  );

  assign src_ready_o = protocol_rst_ni &&
                       (src_req_q == src_ack_sync);

  always_ff @(posedge src_clk_i or negedge protocol_rst_ni) begin
    if (!protocol_rst_ni) begin
      src_data_hold_q <= '0;
      src_req_q       <= 1'b0;
    end else if (src_valid_i && src_ready_o) begin
      src_data_hold_q <= src_data_i;
      src_req_q       <= ~src_req_q;
    end
  end

  always_ff @(posedge dst_clk_i or negedge protocol_rst_ni) begin
    if (!protocol_rst_ni) begin
      dst_data_o  <= '0;
      dst_valid_o <= 1'b0;
      dst_ack_q   <= 1'b0;
    end else begin
      if (!dst_valid_o) begin
        if (dst_req_sync != dst_ack_q) begin
          dst_data_o  <= src_data_hold_q;
          dst_valid_o <= 1'b1;
        end
      end else if (dst_ready_i) begin
        dst_valid_o <= 1'b0;
        dst_ack_q   <= dst_req_sync;
      end
    end
  end

endmodule


module cdc_2phase_sync_bit (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic async_i,
  output logic sync_o
);

  logic sync_meta_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      sync_meta_q <= 1'b0;
      sync_o      <= 1'b0;
    end else begin
      sync_meta_q <= async_i;
      sync_o      <= sync_meta_q;
    end
  end

endmodule
