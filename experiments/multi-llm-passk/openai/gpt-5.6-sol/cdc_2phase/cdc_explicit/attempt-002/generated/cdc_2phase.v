module cdc_reset_sync (
  input  logic clk_i,
  input  logic rst_ni,
  output logic rst_no
);

  (* ASYNC_REG = "TRUE" *)
  logic [1:0] reset_sync_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni)
      reset_sync_q <= 2'b00;
    else
      reset_sync_q <= {reset_sync_q[0], 1'b1};
  end

  assign rst_no = reset_sync_q[1];

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

  logic src_rst_no;
  logic dst_rst_no;

  logic [WIDTH-1:0] src_data_q;
  logic             src_req_q;

  logic             dst_ack_q;
  logic             dst_pending_q;
  logic             dst_valid_q;
  logic [WIDTH-1:0] dst_data_q;

  (* ASYNC_REG = "TRUE" *)
  logic [1:0] src_ack_sync_q;

  (* ASYNC_REG = "TRUE" *)
  logic [1:0] dst_req_sync_q;

  (* ASYNC_REG = "TRUE" *)
  logic [WIDTH-1:0] dst_data_sync1_q;

  (* ASYNC_REG = "TRUE" *)
  logic [WIDTH-1:0] dst_data_sync2_q;

  wire src_ack_sync = src_ack_sync_q[1];
  wire dst_req_sync = dst_req_sync_q[1];

  cdc_reset_sync u_src_reset_sync (
    .clk_i  (src_clk_i),
    .rst_ni (src_rst_ni),
    .rst_no (src_rst_no)
  );

  cdc_reset_sync u_dst_reset_sync (
    .clk_i  (dst_clk_i),
    .rst_ni (dst_rst_ni),
    .rst_no (dst_rst_no)
  );

  always_ff @(posedge src_clk_i or negedge src_rst_no) begin
    if (!src_rst_no) begin
      src_ack_sync_q <= 2'b00;
    end else begin
      src_ack_sync_q <= {src_ack_sync_q[0], dst_ack_q};
    end
  end

  assign src_ready_o = src_rst_no && (src_req_q == src_ack_sync);

  always_ff @(posedge src_clk_i or negedge src_rst_no) begin
    if (!src_rst_no) begin
      src_data_q <= '0;
      src_req_q  <= 1'b0;
    end else if (src_valid_i && src_ready_o) begin
      src_data_q <= src_data_i;
      src_req_q  <= ~src_req_q;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_no) begin
    if (!dst_rst_no) begin
      dst_req_sync_q   <= 2'b00;
      dst_data_sync1_q <= '0;
      dst_data_sync2_q <= '0;
    end else begin
      dst_req_sync_q   <= {dst_req_sync_q[0], src_req_q};
      dst_data_sync1_q <= src_data_q;
      dst_data_sync2_q <= dst_data_sync1_q;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_no) begin
    if (!dst_rst_no) begin
      dst_ack_q     <= 1'b0;
      dst_pending_q <= 1'b0;
      dst_valid_q   <= 1'b0;
      dst_data_q    <= '0;
    end else begin
      if (dst_valid_q) begin
        if (dst_ready_i) begin
          dst_valid_q <= 1'b0;
          dst_ack_q   <= dst_req_sync;
        end
      end else if (dst_pending_q) begin
        dst_pending_q <= 1'b0;
        if (dst_req_sync != dst_ack_q) begin
          dst_data_q  <= dst_data_sync2_q;
          dst_valid_q <= 1'b1;
        end
      end else if (dst_req_sync != dst_ack_q) begin
        dst_pending_q <= 1'b1;
      end
    end
  end

  assign dst_data_o  = dst_data_q;
  assign dst_valid_o = dst_rst_no && dst_valid_q;

endmodule
