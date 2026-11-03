// Copyright 2018 ETH Zurich and University of Bologna.
//
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Manuel Eggimann <meggimann@iis.ee.ethz.ch>

/// A 4-phase clock domain crossing. While this is less efficient than a 2-phase
/// CDC, it doesn't suffer from the same issues during one sided resets since
/// the IDLE state doesn't alternate with every transaction.
///
/// Parameters: T - The type of the data to transmit through the CDC.
///
/// Decoupled - If decoupled is disabled, the 4phase cdc will not consume the
/// src item until the handshake with the other side is completed. This
/// increases the latency of the first transaction but has no effect on
/// throughput. However, critical paths might be slightly longer. Use this mode
/// if you want to ensure that there are no in-flight transactions within the
/// CDC.
///
/// SEND_RESET_MSG - If send reset msg is enabled, the 4phase cdc starts sending
/// the RESET_MSG within its' asynchronous reset state. This can be usefull if
/// we need to transmit a message to the other side of the CDC immediately
/// during an async reset even if there is no clock available. This mode is
/// required for proper functionality of the cdc_reset_ctrlr module.
///
/// CONSTRAINT: Requires max_delay of min_period(src_clk_i, dst_clk_i) through
/// the paths async_req, async_ack, async_data.
/* verilator lint_off DECLFILENAME */
module cdc_4phase #(
  parameter WIDTH = 1,
  parameter DECOUPLED = 1,
  parameter SEND_RESET_MSG = 0,
  parameter [WIDTH-1:0] RESET_MSG = {WIDTH{1'b0}}
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,

  input  dst_rst_ni,
  input  dst_clk_i,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);

  wire async_req;
  wire async_ack;
  wire [WIDTH-1:0] async_data;

  cdc_4phase_src #(
    .WIDTH(WIDTH),
    .DECOUPLED(DECOUPLED),
    .SEND_RESET_MSG(SEND_RESET_MSG),
    .RESET_MSG(RESET_MSG)
  ) i_src (
    .rst_ni       (src_rst_ni),
    .clk_i        (src_clk_i),
    .data_i       (src_data_i),
    .valid_i      (src_valid_i),
    .ready_o      (src_ready_o),
    .async_req_o  (async_req),
    .async_ack_i  (async_ack),
    .async_data_o (async_data)
  );

  cdc_4phase_dst #(
    .WIDTH(WIDTH),
    .DECOUPLED(DECOUPLED)
  ) i_dst (
    .rst_ni       (dst_rst_ni),
    .clk_i        (dst_clk_i),
    .data_o       (dst_data_o),
    .valid_o      (dst_valid_o),
    .ready_i      (dst_ready_i),
    .async_req_i  (async_req),
    .async_ack_o  (async_ack),
    .async_data_i (async_data)
  );

endmodule


module cdc_4phase_src #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 2,
  parameter DECOUPLED = 1,
  parameter SEND_RESET_MSG = 0,
  parameter [WIDTH-1:0] RESET_MSG = {WIDTH{1'b0}}
)(
  input  rst_ni,
  input  clk_i,
  input  [WIDTH-1:0] data_i,
  input  valid_i,
  output reg ready_o,
  output async_req_o,
  input  async_ack_i,
  output [WIDTH-1:0] async_data_o
);

  localparam IDLE              = 2'b00;
  localparam WAIT_ACK_ASSERT   = 2'b01;
  localparam WAIT_ACK_DEASSERT = 2'b10;

  reg [1:0] state_d;
  reg [1:0] state_q;

  reg req_src_d;
  reg req_src_q;

  reg [WIDTH-1:0] data_src_d;
  reg [WIDTH-1:0] data_src_q;

  wire ack_synced;

  sync #(
    .STAGES(SYNC_STAGES)
  ) i_sync (
    .clk_i    (clk_i),
    .rst_ni   (rst_ni),
    .serial_i (async_ack_i),
    .serial_o (ack_synced)
  );

  always @(*) begin
    state_d    = state_q;
    req_src_d  = 1'b0;
    data_src_d = data_src_q;
    ready_o    = 1'b0;

    case (state_q)
      IDLE: begin
        if (DECOUPLED)
          ready_o = 1'b1;
        else
          ready_o = 1'b0;

        if (valid_i) begin
          data_src_d = data_i;
          req_src_d  = 1'b1;
          state_d    = WAIT_ACK_ASSERT;
        end
      end

      WAIT_ACK_ASSERT: begin
        req_src_d = 1'b1;
        if (ack_synced == 1'b1) begin
          req_src_d = 1'b0;
          state_d   = WAIT_ACK_DEASSERT;
        end
      end

      WAIT_ACK_DEASSERT: begin
        if (ack_synced == 1'b0) begin
          state_d = IDLE;
          if (!DECOUPLED)
            ready_o = 1'b1;
        end
      end

      default: begin
        state_d = IDLE;
      end
    endcase
  end

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni)
      state_q <= IDLE;
    else
      state_q <= state_d;
  end

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      if (SEND_RESET_MSG) begin
        req_src_q  <= 1'b1;
        data_src_q <= RESET_MSG;
      end else begin
        req_src_q  <= 1'b0;
        data_src_q <= {WIDTH{1'b0}};
      end
    end else begin
      req_src_q  <= req_src_d;
      data_src_q <= data_src_d;
    end
  end

  assign async_req_o  = req_src_q;
  assign async_data_o = data_src_q;

endmodule


module cdc_4phase_dst #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 2,
  parameter DECOUPLED = 1
)(
  input  rst_ni,
  input  clk_i,
  output [WIDTH-1:0] data_o,
  output valid_o,
  input  ready_i,
  input  async_req_i,
  output async_ack_o,
  input  [WIDTH-1:0] async_data_i
);

  localparam IDLE                = 2'b00;
  localparam WAIT_DOWNSTREAM_ACK = 2'b01;
  localparam WAIT_REQ_DEASSERT   = 2'b10;

  reg [1:0] state_d;
  reg [1:0] state_q;

  reg ack_dst_d;
  reg ack_dst_q;

  wire req_synced;

  reg data_valid;
  wire output_ready;

  sync #(
    .STAGES(SYNC_STAGES)
  ) i_sync (
    .clk_i    (clk_i),
    .rst_ni   (rst_ni),
    .serial_i (async_req_i),
    .serial_o (req_synced)
  );

  always @(*) begin
    state_d    = state_q;
    data_valid = 1'b0;
    ack_dst_d  = 1'b0;

    case (state_q)
      IDLE: begin
        if (req_synced == 1'b1) begin
          data_valid = 1'b1;
          if (output_ready == 1'b1)
            state_d = WAIT_REQ_DEASSERT;
          else
            state_d = WAIT_DOWNSTREAM_ACK;
        end
      end

      WAIT_DOWNSTREAM_ACK: begin
        data_valid = 1'b1;
        if (output_ready == 1'b1) begin
          state_d   = WAIT_REQ_DEASSERT;
          ack_dst_d = 1'b1;
        end
      end

      WAIT_REQ_DEASSERT: begin
        ack_dst_d = 1'b1;
        if (req_synced == 1'b0) begin
          ack_dst_d = 1'b0;
          state_d   = IDLE;
        end
      end

      default: begin
        state_d = IDLE;
      end
    endcase
  end

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni)
      state_q <= IDLE;
    else
      state_q <= state_d;
  end

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni)
      ack_dst_q <= 1'b0;
    else
      ack_dst_q <= ack_dst_d;
  end

  generate
    if (DECOUPLED) begin : gen_decoupled
      spill_register #(
        .WIDTH(WIDTH)
      ) i_spill_register (
        .clk_i   (clk_i),
        .rst_ni  (rst_ni),
        .valid_i (data_valid),
        .ready_o (output_ready),
        .data_i  (async_data_i),
        .valid_o (valid_o),
        .ready_i (ready_i),
        .data_o  (data_o)
      );
    end else begin : gen_not_decoupled
      assign valid_o      = data_valid;
      assign output_ready = ready_i;
      assign data_o       = async_data_i;
    end
  endgenerate

  assign async_ack_o = ack_dst_q;

endmodule


module sync #(
  parameter STAGES = 2
)(
  input  clk_i,
  input  rst_ni,
  input  serial_i,
  output serial_o
);

  reg [STAGES-1:0] reg_q;

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni)
      reg_q <= {STAGES{1'b0}};
    else
      reg_q <= {reg_q[STAGES-2:0], serial_i};
  end

  assign serial_o = reg_q[STAGES-1];

endmodule


module spill_register #(
  parameter WIDTH = 1
)(
  input  clk_i,
  input  rst_ni,
  input  valid_i,
  output ready_o,
  input  [WIDTH-1:0] data_i,
  output valid_o,
  input  ready_i,
  output [WIDTH-1:0] data_o
);

  reg valid_q;
  reg [WIDTH-1:0] data_q;

  assign ready_o = ~valid_q | ready_i;
  assign valid_o = valid_q;
  assign data_o  = data_q;

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      valid_q <= 1'b0;
      data_q  <= {WIDTH{1'b0}};
    end else if (ready_o) begin
      valid_q <= valid_i;
      data_q  <= data_i;
    end
  end

endmodule