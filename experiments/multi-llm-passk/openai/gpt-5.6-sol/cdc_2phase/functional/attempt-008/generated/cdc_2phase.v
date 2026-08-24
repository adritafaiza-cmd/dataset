module cdc_2phase #(
  parameter WIDTH = 1
)(
  input                  src_rst_ni,
  input                  src_clk_i,
  input      [WIDTH-1:0] src_data_i,
  input                  src_valid_i,
  output                 src_ready_o,

  input                  dst_rst_ni,
  input                  dst_clk_i,
  output     [WIDTH-1:0] dst_data_o,
  output                 dst_valid_o,
  input                  dst_ready_i
);

  logic [WIDTH-1:0] src_data_q;
  logic             src_req_q;

  (* ASYNC_REG = "TRUE" *) logic src_ack_sync1_q;
  (* ASYNC_REG = "TRUE" *) logic src_ack_sync2_q;

  (* ASYNC_REG = "TRUE" *) logic dst_req_sync1_q;
  (* ASYNC_REG = "TRUE" *) logic dst_req_sync2_q;

  logic             dst_ack_q;
  logic [WIDTH-1:0] dst_data_q;
  logic             dst_valid_q;

  assign src_ready_o = (src_req_q == src_ack_sync2_q);
  assign dst_data_o  = dst_data_q;
  assign dst_valid_o = dst_valid_q;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_q <= '0;
      src_req_q  <= 1'b0;
    end else if (src_valid_i && src_ready_o) begin
      src_data_q <= src_data_i;
      src_req_q  <= ~src_req_q;
    end
  end

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ack_sync1_q <= 1'b0;
      src_ack_sync2_q <= 1'b0;
    end else begin
      src_ack_sync1_q <= dst_ack_q;
      src_ack_sync2_q <= src_ack_sync1_q;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_req_sync1_q <= 1'b0;
      dst_req_sync2_q <= 1'b0;
    end else begin
      dst_req_sync1_q <= src_req_q;
      dst_req_sync2_q <= dst_req_sync1_q;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ack_q   <= 1'b0;
      dst_data_q  <= '0;
      dst_valid_q <= 1'b0;
    end else begin
      if (dst_valid_q) begin
        if (dst_ready_i) begin
          dst_valid_q <= 1'b0;
          dst_ack_q   <= dst_req_sync2_q;
        end
      end else if (dst_req_sync2_q != dst_ack_q) begin
        dst_data_q  <= src_data_q;
        dst_valid_q <= 1'b1;
      end
    end
  end

endmodule
