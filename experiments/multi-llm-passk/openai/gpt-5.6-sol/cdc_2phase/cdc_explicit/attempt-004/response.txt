`default_nettype none

module cdc_reset_sync (
  input  logic clk_i,
  input  logic arst_ni,
  output logic rst_no
);

  (* ASYNC_REG = "TRUE" *) logic [1:0] reset_sync_q;

  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (!arst_ni) begin
      reset_sync_q <= 2'b00;
    end else begin
      reset_sync_q <= {reset_sync_q[0], 1'b1};
    end
  end

  assign rst_no = reset_sync_q[1];

endmodule


module cdc_2phase #(
  parameter WIDTH = 1
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

  logic src_reset_n;
  logic dst_reset_n;

  logic [WIDTH-1:0] src_data_hold_q;
  logic             src_request_q;

  logic             dst_ack_q;

  (* ASYNC_REG = "TRUE" *) logic [1:0] src_ack_sync_q;
  (* ASYNC_REG = "TRUE" *) logic [2:0] dst_request_sync_q;
  (* ASYNC_REG = "TRUE" *) logic [WIDTH-1:0] dst_data_sync1_q;
  (* ASYNC_REG = "TRUE" *) logic [WIDTH-1:0] dst_data_sync2_q;

  cdc_reset_sync i_src_reset_sync (
    .clk_i   (src_clk_i),
    .arst_ni (src_rst_ni),
    .rst_no  (src_reset_n)
  );

  cdc_reset_sync i_dst_reset_sync (
    .clk_i   (dst_clk_i),
    .arst_ni (dst_rst_ni),
    .rst_no  (dst_reset_n)
  );

  assign src_ready_o = src_reset_n &&
                       (src_ack_sync_q[1] == src_request_q);

  always_ff @(posedge src_clk_i or negedge src_reset_n) begin
    if (!src_reset_n) begin
      src_data_hold_q <= '0;
      src_request_q   <= 1'b0;
    end else if (src_valid_i && src_ready_o) begin
      src_data_hold_q <= src_data_i;
      src_request_q   <= ~src_request_q;
    end
  end

  always_ff @(posedge src_clk_i or negedge src_reset_n) begin
    if (!src_reset_n) begin
      src_ack_sync_q <= 2'b00;
    end else begin
      src_ack_sync_q[0] <= dst_ack_q;
      src_ack_sync_q[1] <= src_ack_sync_q[0];
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_reset_n) begin
    if (!dst_reset_n) begin
      dst_request_sync_q <= 3'b000;
      dst_data_sync1_q   <= '0;
      dst_data_sync2_q   <= '0;
    end else begin
      dst_request_sync_q[0] <= src_request_q;
      dst_request_sync_q[1] <= dst_request_sync_q[0];
      dst_request_sync_q[2] <= dst_request_sync_q[1];

      dst_data_sync1_q <= src_data_hold_q;
      dst_data_sync2_q <= dst_data_sync1_q;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_reset_n) begin
    if (!dst_reset_n) begin
      dst_data_o  <= '0;
      dst_valid_o <= 1'b0;
      dst_ack_q   <= 1'b0;
    end else begin
      if (!dst_valid_o) begin
        if (dst_request_sync_q[2] != dst_ack_q) begin
          dst_data_o  <= dst_data_sync2_q;
          dst_valid_o <= 1'b1;
        end
      end else if (dst_ready_i) begin
        dst_valid_o <= 1'b0;
        dst_ack_q   <= dst_request_sync_q[2];
      end
    end
  end

endmodule

`default_nettype wire
