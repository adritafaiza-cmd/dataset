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

  logic [WIDTH-1:0] src_data_hold_q;
  logic             src_req_toggle_q;
  logic             dst_ack_toggle_q;

  (* async_reg = "true" *) logic dst_ack_sync1_q;
  (* async_reg = "true" *) logic dst_ack_sync2_q;
  (* async_reg = "true" *) logic src_req_sync1_q;
  (* async_reg = "true" *) logic src_req_sync2_q;

  assign src_ready_o =
      src_rst_ni && (src_req_toggle_q == dst_ack_sync2_q);

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_hold_q <= '0;
      src_req_toggle_q <= 1'b0;
    end else if (src_valid_i && src_ready_o) begin
      src_data_hold_q <= src_data_i;
      src_req_toggle_q <= ~src_req_toggle_q;
    end
  end

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ack_sync1_q <= 1'b0;
      dst_ack_sync2_q <= 1'b0;
    end else begin
      dst_ack_sync1_q <= dst_ack_toggle_q;
      dst_ack_sync2_q <= dst_ack_sync1_q;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_req_sync1_q <= 1'b0;
      src_req_sync2_q <= 1'b0;
    end else begin
      src_req_sync1_q <= src_req_toggle_q;
      src_req_sync2_q <= src_req_sync1_q;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ack_toggle_q <= 1'b0;
      dst_data_o <= '0;
      dst_valid_o <= 1'b0;
    end else begin
      if (!dst_valid_o) begin
        if (src_req_sync2_q != dst_ack_toggle_q) begin
          dst_data_o <= src_data_hold_q;
          dst_valid_o <= 1'b1;
        end
      end else if (dst_ready_i) begin
        dst_valid_o <= 1'b0;
        dst_ack_toggle_q <= src_req_sync2_q;
      end
    end
  end

endmodule
