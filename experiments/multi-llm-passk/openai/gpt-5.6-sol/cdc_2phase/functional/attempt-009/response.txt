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

  (* ASYNC_REG = "TRUE" *) logic src_ack_sync_q1;
  (* ASYNC_REG = "TRUE" *) logic src_ack_sync_q2;
  (* ASYNC_REG = "TRUE" *) logic dst_req_sync_q1;
  (* ASYNC_REG = "TRUE" *) logic dst_req_sync_q2;

  assign src_ready_o = src_rst_ni &&
                       (src_req_toggle_q == src_ack_sync_q2);

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
      src_ack_sync_q1 <= 1'b0;
      src_ack_sync_q2 <= 1'b0;
    end else begin
      src_ack_sync_q1 <= dst_ack_toggle_q;
      src_ack_sync_q2 <= src_ack_sync_q1;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_req_sync_q1 <= 1'b0;
      dst_req_sync_q2 <= 1'b0;
    end else begin
      dst_req_sync_q1 <= src_req_toggle_q;
      dst_req_sync_q2 <= dst_req_sync_q1;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o         <= '0;
      dst_valid_o        <= 1'b0;
      dst_ack_toggle_q   <= 1'b0;
    end else begin
      if (dst_valid_o) begin
        if (dst_ready_i) begin
          dst_valid_o      <= 1'b0;
          dst_ack_toggle_q <= dst_req_sync_q2;
        end
      end else if (dst_req_sync_q2 != dst_ack_toggle_q) begin
        dst_data_o  <= src_data_hold_q;
        dst_valid_o <= 1'b1;
      end
    end
  end

endmodule
