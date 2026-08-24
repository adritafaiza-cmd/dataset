module cdc_reset_sync (
  input  logic clk_i,
  input  logic arst_ni,
  output logic rst_ni
);

  (* ASYNC_REG = "TRUE" *) logic [1:0] rst_sync_q;

  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (!arst_ni)
      rst_sync_q <= 2'b00;
    else
      rst_sync_q <= {rst_sync_q[0], 1'b1};
  end

  assign rst_ni = rst_sync_q[1];

endmodule


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

  logic bridge_arst_ni;
  logic src_local_rst_ni;
  logic dst_local_rst_ni;

  logic [WIDTH-1:0] src_data_hold_q;
  logic             src_req_toggle_q;

  (* ASYNC_REG = "TRUE" *) logic [1:0] src_ack_sync_q;

  (* ASYNC_REG = "TRUE" *) logic [2:0] dst_req_sync_q;
  (* ASYNC_REG = "TRUE" *) logic [WIDTH-1:0] dst_data_meta_q;
  (* ASYNC_REG = "TRUE" *) logic [WIDTH-1:0] dst_data_sync_q;

  logic dst_ack_toggle_q;

  assign bridge_arst_ni = src_rst_ni & dst_rst_ni;

  cdc_reset_sync u_src_reset_sync (
    .clk_i  (src_clk_i),
    .arst_ni(bridge_arst_ni),
    .rst_ni (src_local_rst_ni)
  );

  cdc_reset_sync u_dst_reset_sync (
    .clk_i  (dst_clk_i),
    .arst_ni(bridge_arst_ni),
    .rst_ni (dst_local_rst_ni)
  );

  assign src_ready_o =
      src_local_rst_ni &&
      (src_req_toggle_q == src_ack_sync_q[1]);

  always_ff @(posedge src_clk_i or negedge src_local_rst_ni) begin
    if (!src_local_rst_ni) begin
      src_data_hold_q  <= '0;
      src_req_toggle_q <= 1'b0;
    end else if (src_valid_i && src_ready_o) begin
      src_data_hold_q  <= src_data_i;
      src_req_toggle_q <= ~src_req_toggle_q;
    end
  end

  always_ff @(posedge src_clk_i or negedge src_local_rst_ni) begin
    if (!src_local_rst_ni)
      src_ack_sync_q <= 2'b00;
    else begin
      src_ack_sync_q[0] <= dst_ack_toggle_q;
      src_ack_sync_q[1] <= src_ack_sync_q[0];
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_local_rst_ni) begin
    if (!dst_local_rst_ni)
      dst_req_sync_q <= 3'b000;
    else begin
      dst_req_sync_q[0] <= src_req_toggle_q;
      dst_req_sync_q[1] <= dst_req_sync_q[0];
      dst_req_sync_q[2] <= dst_req_sync_q[1];
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_local_rst_ni) begin
    if (!dst_local_rst_ni) begin
      dst_data_meta_q <= '0;
      dst_data_sync_q <= '0;
    end else begin
      dst_data_meta_q <= src_data_hold_q;
      dst_data_sync_q <= dst_data_meta_q;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_local_rst_ni) begin
    if (!dst_local_rst_ni) begin
      dst_data_o       <= '0;
      dst_valid_o      <= 1'b0;
      dst_ack_toggle_q <= 1'b0;
    end else begin
      if (dst_valid_o) begin
        if (dst_ready_i) begin
          dst_valid_o      <= 1'b0;
          dst_ack_toggle_q <= dst_req_sync_q[2];
        end
      end else if (dst_req_sync_q[2] != dst_ack_toggle_q) begin
        dst_data_o  <= dst_data_sync_q;
        dst_valid_o <= 1'b1;
      end
    end
  end

endmodule
