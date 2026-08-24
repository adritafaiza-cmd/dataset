module cdc_2phase_sync (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic async_i,
  output logic sync_o
);

  (* ASYNC_REG = "TRUE" *) logic sync_ff1_q;
  (* ASYNC_REG = "TRUE" *) logic sync_ff2_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      sync_ff1_q <= 1'b0;
      sync_ff2_q <= 1'b0;
    end else begin
      sync_ff1_q <= async_i;
      sync_ff2_q <= sync_ff1_q;
    end
  end

  assign sync_o = sync_ff2_q;

endmodule


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
  logic             src_ack_sync;

  logic             dst_req_sync;
  logic             dst_ack_q;
  logic [WIDTH-1:0] dst_data_q;
  logic             dst_valid_q;

  assign src_ready_o = (src_req_q == src_ack_sync);
  assign dst_data_o  = dst_data_q;
  assign dst_valid_o = dst_valid_q;

  cdc_2phase_sync u_sync_ack_to_src (
    .clk_i   (src_clk_i),
    .rst_ni  (src_rst_ni),
    .async_i (dst_ack_q),
    .sync_o  (src_ack_sync)
  );

  cdc_2phase_sync u_sync_req_to_dst (
    .clk_i   (dst_clk_i),
    .rst_ni  (dst_rst_ni),
    .async_i (src_req_q),
    .sync_o  (dst_req_sync)
  );

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_q <= '0;
      src_req_q  <= 1'b0;
    end else if (src_valid_i && src_ready_o) begin
      src_data_q <= src_data_i;
      src_req_q  <= ~src_req_q;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_q  <= '0;
      dst_valid_q <= 1'b0;
      dst_ack_q   <= 1'b0;
    end else begin
      if (!dst_valid_q) begin
        if (dst_req_sync != dst_ack_q) begin
          dst_data_q  <= src_data_q;
          dst_valid_q <= 1'b1;
        end
      end else if (dst_ready_i) begin
        dst_valid_q <= 1'b0;
        dst_ack_q   <= dst_req_sync;
      end
    end
  end

endmodule
