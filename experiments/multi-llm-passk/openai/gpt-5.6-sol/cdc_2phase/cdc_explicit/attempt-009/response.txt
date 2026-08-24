`default_nettype none

module cdc_reset_sync (
  input  logic clk_i,
  input  logic rst_ni,
  output logic rst_sync_ni
);

  (* ASYNC_REG = "TRUE" *) logic [1:0] sync_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      sync_q <= 2'b00;
    end else begin
      sync_q <= {sync_q[0], 1'b1};
    end
  end

  assign rst_sync_ni = sync_q[1];

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

  logic src_reset_done;
  logic dst_reset_done;

  (* ASYNC_REG = "TRUE" *) logic [1:0] dst_up_src_sync_q;
  (* ASYNC_REG = "TRUE" *) logic [1:0] src_up_dst_sync_q;

  logic dst_up_src;
  logic src_up_dst;

  logic                 req_src_q;
  logic [WIDTH-1:0]     data_src_q;

  (* ASYNC_REG = "TRUE" *) logic [2:0] req_dst_sync_q;
  (* ASYNC_REG = "TRUE" *) logic [2:0] ack_src_sync_q;
  (* ASYNC_REG = "TRUE" *) logic [WIDTH-1:0] data_dst_sync1_q;
  (* ASYNC_REG = "TRUE" *) logic [WIDTH-1:0] data_dst_sync2_q;

  logic             ack_dst_q;
  logic             dst_valid_q;
  logic [WIDTH-1:0] dst_data_q;

  cdc_reset_sync u_src_reset_sync (
    .clk_i       (src_clk_i),
    .rst_ni      (src_rst_ni),
    .rst_sync_ni (src_reset_done)
  );

  cdc_reset_sync u_dst_reset_sync (
    .clk_i       (dst_clk_i),
    .rst_ni      (dst_rst_ni),
    .rst_sync_ni (dst_reset_done)
  );

  always_ff @(posedge src_clk_i or negedge src_reset_done) begin
    if (!src_reset_done) begin
      dst_up_src_sync_q <= 2'b00;
    end else begin
      dst_up_src_sync_q <= {dst_up_src_sync_q[0], dst_reset_done};
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_reset_done) begin
    if (!dst_reset_done) begin
      src_up_dst_sync_q <= 2'b00;
    end else begin
      src_up_dst_sync_q <= {src_up_dst_sync_q[0], src_reset_done};
    end
  end

  assign dst_up_src = dst_up_src_sync_q[1];
  assign src_up_dst = src_up_dst_sync_q[1];

  always_ff @(posedge src_clk_i or negedge src_reset_done) begin
    if (!src_reset_done) begin
      ack_src_sync_q <= 3'b000;
    end else begin
      ack_src_sync_q <= {ack_src_sync_q[1:0], ack_dst_q};
    end
  end

  assign src_ready_o =
      src_reset_done &&
      dst_up_src     &&
      (req_src_q == ack_src_sync_q[2]);

  always_ff @(posedge src_clk_i or negedge src_reset_done) begin
    if (!src_reset_done) begin
      req_src_q <= 1'b0;
    end else if (!dst_up_src) begin
      req_src_q <= 1'b0;
    end else if (src_valid_i && src_ready_o) begin
      data_src_q <= src_data_i;
      req_src_q  <= ~req_src_q;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_reset_done) begin
    if (!dst_reset_done) begin
      req_dst_sync_q <= 3'b000;
    end else begin
      req_dst_sync_q <= {req_dst_sync_q[1:0], req_src_q};
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_reset_done) begin
    if (!dst_reset_done) begin
      data_dst_sync1_q <= '0;
      data_dst_sync2_q <= '0;
    end else begin
      data_dst_sync1_q <= data_src_q;
      data_dst_sync2_q <= data_dst_sync1_q;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_reset_done) begin
    if (!dst_reset_done) begin
      ack_dst_q   <= 1'b0;
      dst_valid_q <= 1'b0;
      dst_data_q  <= '0;
    end else if (!src_up_dst) begin
      ack_dst_q   <= 1'b0;
      dst_valid_q <= 1'b0;
      dst_data_q  <= '0;
    end else if (dst_valid_q) begin
      if (dst_ready_i) begin
        dst_valid_q <= 1'b0;
        ack_dst_q   <= req_dst_sync_q[2];
      end
    end else if (req_dst_sync_q[2] != ack_dst_q) begin
      dst_data_q  <= data_dst_sync2_q;
      dst_valid_q <= 1'b1;
    end
  end

  assign dst_data_o  = dst_data_q;
  assign dst_valid_o = dst_valid_q && dst_reset_done && src_up_dst;

endmodule

`default_nettype wire
