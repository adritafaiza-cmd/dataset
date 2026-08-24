module cdc_reset_sync (
  input  logic clk_i,
  input  logic rst_ni,
  output logic rst_sync_ni
);

  (* async_reg = "true" *) logic [1:0] sync_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni)
      sync_q <= 2'b00;
    else
      sync_q <= {sync_q[0], 1'b1};
  end

  assign rst_sync_ni = sync_q[1];

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

  logic src_rst_sync_ni;
  logic dst_rst_sync_ni;

  logic [WIDTH-1:0] src_data_hold_q;
  logic             src_req_toggle_q;

  (* async_reg = "true" *) logic src_ack_sync1_q;
  (* async_reg = "true" *) logic src_ack_sync2_q;

  (* async_reg = "true" *) logic dst_req_sync1_q;
  (* async_reg = "true" *) logic dst_req_sync2_q;

  (* async_reg = "true" *) logic [WIDTH-1:0] dst_data_sync1_q;
  (* async_reg = "true" *) logic [WIDTH-1:0] dst_data_sync2_q;

  logic             dst_ack_toggle_q;
  logic [WIDTH-1:0] dst_data_q;
  logic             dst_valid_q;

  typedef enum logic [1:0] {
    DST_IDLE,
    DST_WAIT,
    DST_VALID
  } dst_state_t;

  dst_state_t dst_state_q;

  cdc_reset_sync u_src_reset_sync (
    .clk_i       (src_clk_i),
    .rst_ni      (src_rst_ni),
    .rst_sync_ni (src_rst_sync_ni)
  );

  cdc_reset_sync u_dst_reset_sync (
    .clk_i       (dst_clk_i),
    .rst_ni      (dst_rst_ni),
    .rst_sync_ni (dst_rst_sync_ni)
  );

  assign src_ready_o = src_rst_sync_ni &&
                       (src_ack_sync2_q == src_req_toggle_q);

  assign dst_data_o  = dst_data_q;
  assign dst_valid_o = dst_valid_q;

  always_ff @(posedge src_clk_i or negedge src_rst_sync_ni) begin
    if (!src_rst_sync_ni) begin
      src_data_hold_q  <= '0;
      src_req_toggle_q <= 1'b0;
    end else if (src_valid_i && src_ready_o) begin
      src_data_hold_q  <= src_data_i;
      src_req_toggle_q <= ~src_req_toggle_q;
    end
  end

  always_ff @(posedge src_clk_i or negedge src_rst_sync_ni) begin
    if (!src_rst_sync_ni) begin
      src_ack_sync1_q <= 1'b0;
      src_ack_sync2_q <= 1'b0;
    end else begin
      src_ack_sync1_q <= dst_ack_toggle_q;
      src_ack_sync2_q <= src_ack_sync1_q;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_sync_ni) begin
    if (!dst_rst_sync_ni) begin
      dst_req_sync1_q <= 1'b0;
      dst_req_sync2_q <= 1'b0;
    end else begin
      dst_req_sync1_q <= src_req_toggle_q;
      dst_req_sync2_q <= dst_req_sync1_q;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_sync_ni) begin
    if (!dst_rst_sync_ni) begin
      dst_data_sync1_q <= '0;
      dst_data_sync2_q <= '0;
    end else begin
      dst_data_sync1_q <= src_data_hold_q;
      dst_data_sync2_q <= dst_data_sync1_q;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_sync_ni) begin
    if (!dst_rst_sync_ni) begin
      dst_ack_toggle_q <= 1'b0;
      dst_data_q       <= '0;
      dst_valid_q      <= 1'b0;
      dst_state_q      <= DST_IDLE;
    end else begin
      case (dst_state_q)
        DST_IDLE: begin
          dst_valid_q <= 1'b0;
          if (dst_req_sync2_q != dst_ack_toggle_q)
            dst_state_q <= DST_WAIT;
        end

        DST_WAIT: begin
          dst_data_q  <= dst_data_sync2_q;
          dst_valid_q <= 1'b1;
          dst_state_q <= DST_VALID;
        end

        DST_VALID: begin
          if (dst_valid_q && dst_ready_i) begin
            dst_valid_q      <= 1'b0;
            dst_ack_toggle_q <= dst_req_sync2_q;
            dst_state_q      <= DST_IDLE;
          end
        end

        default: begin
          dst_ack_toggle_q <= 1'b0;
          dst_data_q       <= '0;
          dst_valid_q      <= 1'b0;
          dst_state_q      <= DST_IDLE;
        end
      endcase
    end
  end

endmodule
