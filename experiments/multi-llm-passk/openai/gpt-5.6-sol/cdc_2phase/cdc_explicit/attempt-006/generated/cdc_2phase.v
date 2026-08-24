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


module cdc_sync #(
  parameter int unsigned WIDTH = 1
) (
  input  logic             clk_i,
  input  logic             rst_ni,
  input  logic [WIDTH-1:0] async_i,
  output logic [WIDTH-1:0] sync_o
);

  (* ASYNC_REG = "TRUE" *) logic [WIDTH-1:0] sync_meta_q;
  (* ASYNC_REG = "TRUE" *) logic [WIDTH-1:0] sync_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      sync_meta_q <= '0;
      sync_q      <= '0;
    end else begin
      sync_meta_q <= async_i;
      sync_q      <= sync_meta_q;
    end
  end

  assign sync_o = sync_q;

endmodule


module cdc_2phase #(
  parameter int unsigned WIDTH = 1
) (
  input  logic             src_rst_ni,
  input  logic             src_clk_i,
  input  logic [WIDTH-1:0] src_data_i,
  input  logic             src_valid_i,
  output logic             src_ready_o,

  input  logic             dst_rst_ni,
  input  logic             dst_clk_i,
  output logic [WIDTH-1:0] dst_data_o,
  output logic             dst_valid_o,
  input  logic             dst_ready_i
);

  typedef enum logic [1:0] {
    SRC_IDLE,
    SRC_WAIT_ACK_HIGH,
    SRC_WAIT_ACK_LOW
  } src_state_t;

  typedef enum logic [1:0] {
    DST_IDLE,
    DST_VALID,
    DST_WAIT_REQ_LOW
  } dst_state_t;

  logic src_reset_ni;
  logic dst_reset_ni;

  src_state_t src_state_q;
  dst_state_t dst_state_q;

  logic [WIDTH-1:0] src_data_hold_q;
  logic [WIDTH-1:0] dst_data_q;

  logic src_req_q;
  logic dst_ack_q;

  logic src_ack_sync;
  logic dst_req_sync;
  logic dst_req_sync_d;

  logic [WIDTH-1:0] dst_data_sync;

  logic dst_valid_q;

  cdc_reset_sync i_src_reset_sync (
    .clk_i      (src_clk_i),
    .rst_ni     (src_rst_ni),
    .rst_sync_ni(src_reset_ni)
  );

  cdc_reset_sync i_dst_reset_sync (
    .clk_i      (dst_clk_i),
    .rst_ni     (dst_rst_ni),
    .rst_sync_ni(dst_reset_ni)
  );

  cdc_sync #(
    .WIDTH(1)
  ) i_ack_sync (
    .clk_i  (src_clk_i),
    .rst_ni (src_reset_ni),
    .async_i(dst_ack_q),
    .sync_o (src_ack_sync)
  );

  cdc_sync #(
    .WIDTH(1)
  ) i_req_sync (
    .clk_i  (dst_clk_i),
    .rst_ni (dst_reset_ni),
    .async_i(src_req_q),
    .sync_o (dst_req_sync)
  );

  cdc_sync #(
    .WIDTH(WIDTH)
  ) i_data_sync (
    .clk_i  (dst_clk_i),
    .rst_ni (dst_reset_ni),
    .async_i(src_data_hold_q),
    .sync_o (dst_data_sync)
  );

  always_ff @(posedge dst_clk_i or negedge dst_reset_ni) begin
    if (!dst_reset_ni) begin
      dst_req_sync_d <= 1'b0;
    end else begin
      dst_req_sync_d <= dst_req_sync;
    end
  end

  assign src_ready_o = src_reset_ni && (src_state_q == SRC_IDLE);
  assign dst_data_o  = dst_data_q;
  assign dst_valid_o = dst_reset_ni && dst_valid_q;

  always_ff @(posedge src_clk_i or negedge src_reset_ni) begin
    if (!src_reset_ni) begin
      src_state_q     <= SRC_IDLE;
      src_data_hold_q <= '0;
      src_req_q       <= 1'b0;
    end else begin
      unique case (src_state_q)
        SRC_IDLE: begin
          if (src_valid_i) begin
            src_data_hold_q <= src_data_i;
            src_req_q       <= 1'b1;
            src_state_q     <= SRC_WAIT_ACK_HIGH;
          end
        end

        SRC_WAIT_ACK_HIGH: begin
          if (src_ack_sync) begin
            src_req_q   <= 1'b0;
            src_state_q <= SRC_WAIT_ACK_LOW;
          end
        end

        SRC_WAIT_ACK_LOW: begin
          if (!src_ack_sync) begin
            src_state_q <= SRC_IDLE;
          end
        end

        default: begin
          src_state_q <= SRC_IDLE;
          src_req_q   <= 1'b0;
        end
      endcase
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_reset_ni) begin
    if (!dst_reset_ni) begin
      dst_state_q <= DST_IDLE;
      dst_data_q  <= '0;
      dst_valid_q <= 1'b0;
      dst_ack_q   <= 1'b0;
    end else begin
      unique case (dst_state_q)
        DST_IDLE: begin
          dst_valid_q <= 1'b0;
          dst_ack_q   <= 1'b0;

          if (dst_req_sync_d) begin
            dst_data_q  <= dst_data_sync;
            dst_valid_q <= 1'b1;
            dst_state_q <= DST_VALID;
          end
        end

        DST_VALID: begin
          if (dst_ready_i) begin
            dst_valid_q <= 1'b0;
            dst_ack_q   <= 1'b1;
            dst_state_q <= DST_WAIT_REQ_LOW;
          end
        end

        DST_WAIT_REQ_LOW: begin
          dst_valid_q <= 1'b0;

          if (!dst_req_sync_d) begin
            dst_ack_q   <= 1'b0;
            dst_state_q <= DST_IDLE;
          end
        end

        default: begin
          dst_state_q <= DST_IDLE;
          dst_valid_q <= 1'b0;
          dst_ack_q   <= 1'b0;
        end
      endcase
    end
  end

endmodule

`default_nettype wire
