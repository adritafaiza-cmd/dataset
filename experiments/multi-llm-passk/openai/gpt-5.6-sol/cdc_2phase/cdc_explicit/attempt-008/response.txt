module cdc_reset_sync (
  input  logic clk_i,
  input  logic arst_ni,
  output logic rst_ni
);

  (* ASYNC_REG = "TRUE" *) logic [1:0] sync_q;

  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (!arst_ni)
      sync_q <= 2'b00;
    else
      sync_q <= {sync_q[0], 1'b1};
  end

  assign rst_ni = sync_q[1];

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
  output logic [WIDTH-1:0] dst_data_o,
  output logic             dst_valid_o,
  input                    dst_ready_i
);

  wire global_arst_ni = src_rst_ni & dst_rst_ni;

  logic src_reset_ni;
  logic dst_reset_ni;

  cdc_reset_sync u_src_reset_sync (
    .clk_i   (src_clk_i),
    .arst_ni (global_arst_ni),
    .rst_ni  (src_reset_ni)
  );

  cdc_reset_sync u_dst_reset_sync (
    .clk_i   (dst_clk_i),
    .arst_ni (global_arst_ni),
    .rst_ni  (dst_reset_ni)
  );

  logic             src_req_toggle_q;
  logic [WIDTH-1:0] src_data_q;

  logic dst_ack_toggle_q;

  (* ASYNC_REG = "TRUE" *) logic src_ack_sync_ff1;
  (* ASYNC_REG = "TRUE" *) logic src_ack_sync_ff2;

  (* ASYNC_REG = "TRUE" *) logic dst_req_sync_ff1;
  (* ASYNC_REG = "TRUE" *) logic dst_req_sync_ff2;

  (* ASYNC_REG = "TRUE" *) logic [WIDTH-1:0] dst_data_sync_ff1;
  (* ASYNC_REG = "TRUE" *) logic [WIDTH-1:0] dst_data_sync_ff2;

  assign src_ready_o =
      src_reset_ni && (src_req_toggle_q == src_ack_sync_ff2);

  always_ff @(posedge src_clk_i or negedge src_reset_ni) begin
    if (!src_reset_ni) begin
      src_req_toggle_q <= 1'b0;
      src_data_q       <= '0;
    end else if (src_valid_i && src_ready_o) begin
      src_data_q       <= src_data_i;
      src_req_toggle_q <= ~src_req_toggle_q;
    end
  end

  always_ff @(posedge src_clk_i or negedge src_reset_ni) begin
    if (!src_reset_ni) begin
      src_ack_sync_ff1 <= 1'b0;
      src_ack_sync_ff2 <= 1'b0;
    end else begin
      src_ack_sync_ff1 <= dst_ack_toggle_q;
      src_ack_sync_ff2 <= src_ack_sync_ff1;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_reset_ni) begin
    if (!dst_reset_ni) begin
      dst_req_sync_ff1 <= 1'b0;
      dst_req_sync_ff2 <= 1'b0;
    end else begin
      dst_req_sync_ff1 <= src_req_toggle_q;
      dst_req_sync_ff2 <= dst_req_sync_ff1;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_reset_ni) begin
    if (!dst_reset_ni) begin
      dst_data_sync_ff1 <= '0;
      dst_data_sync_ff2 <= '0;
    end else begin
      dst_data_sync_ff1 <= src_data_q;
      dst_data_sync_ff2 <= dst_data_sync_ff1;
    end
  end

  typedef enum logic [1:0] {
    DST_IDLE,
    DST_SETTLE,
    DST_VALID
  } dst_state_t;

  dst_state_t dst_state_q;

  always_ff @(posedge dst_clk_i or negedge dst_reset_ni) begin
    if (!dst_reset_ni) begin
      dst_state_q      <= DST_IDLE;
      dst_ack_toggle_q <= 1'b0;
      dst_data_o       <= '0;
      dst_valid_o      <= 1'b0;
    end else begin
      case (dst_state_q)
        DST_IDLE: begin
          dst_valid_o <= 1'b0;

          if (dst_req_sync_ff2 != dst_ack_toggle_q)
            dst_state_q <= DST_SETTLE;
        end

        DST_SETTLE: begin
          if (dst_req_sync_ff2 == dst_ack_toggle_q) begin
            dst_state_q <= DST_IDLE;
          end else begin
            dst_data_o  <= dst_data_sync_ff2;
            dst_valid_o <= 1'b1;
            dst_state_q <= DST_VALID;
          end
        end

        DST_VALID: begin
          if (dst_valid_o && dst_ready_i) begin
            dst_valid_o      <= 1'b0;
            dst_ack_toggle_q <= dst_req_sync_ff2;
            dst_state_q      <= DST_IDLE;
          end
        end

        default: begin
          dst_state_q      <= DST_IDLE;
          dst_ack_toggle_q <= 1'b0;
          dst_data_o       <= '0;
          dst_valid_o      <= 1'b0;
        end
      endcase
    end
  end

endmodule
