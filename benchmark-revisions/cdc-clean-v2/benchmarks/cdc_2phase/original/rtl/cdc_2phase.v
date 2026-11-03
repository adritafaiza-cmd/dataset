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
// Fabian Schuiki <fschuiki@iis.ee.ethz.ch>

/// A two-phase clock domain crossing.
///
/// # Reset Behavior!!
///
/// This module must not be used if warm reset capabily is a requirement. The
/// only execption is if you consistently use a reset controller that sequences
/// the resets while gating both clock domains (be very careful if you follow
/// this strategy!). If you need warm reset/clear/flush capabilities, use (AND
/// CAREFULLY READ THE DESCRIPTION) the cdc_2phase_clearable module.
///
/// After this disclaimer, here is how you connect the src_rst_ni and the
/// dst_rst_ni of this module for power-on-reset (POR). The src_rst_ni and
/// dst_rst_ni signal must be asserted SIMULTANEOUSLY (i.e. asynchronous
/// assertion). Othwerwise, spurious transactions could occur in the domain
/// where the reset arrives later than the other. The de-assertion of both reset
/// must be synchronized to their respective clock domain (i.e. src_rst_ni must
/// be deasserted synchronously to the src_clk_i and dst_rst_ni must be
/// deasserted synchronously to dst_clk_i.) You can use the rstgen cell in the
/// common_cells library to achieve this (synchronization of only the
/// de-assertion). However, be careful about reset domain crossings; If you
/// reset both domain asynchronously in their entirety (i.e. POR) you are fine.
/// However, if you use this strategy for warm resets (some parts of the circuit
/// are not reset) you might introduce metastability in this separate
/// reset-domain when you assert the reset (the deassertion synchronizer doen't
/// help here).
///
/// CONSTRAINT: Requires max_delay of min_period(src_clk_i, dst_clk_i) through
/// the paths async_req, async_ack, async_data.
/* verilator lint_off DECLFILENAME */
module cdc_2phase #(
  parameter WIDTH = 1
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

  cdc_2phase_src #(.WIDTH(WIDTH)) i_src (
    .rst_ni       (src_rst_ni),
    .clk_i        (src_clk_i),
    .data_i       (src_data_i),
    .valid_i      (src_valid_i),
    .ready_o      (src_ready_o),
    .async_req_o  (async_req),
    .async_ack_i  (async_ack),
    .async_data_o (async_data)
  );

  cdc_2phase_dst #(.WIDTH(WIDTH)) i_dst (
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


module cdc_2phase_src #(
  parameter WIDTH = 1
)(
  input  rst_ni,
  input  clk_i,
  input  [WIDTH-1:0] data_i,
  input  valid_i,
  output ready_o,
  output async_req_o,
  input  async_ack_i,
  output [WIDTH-1:0] async_data_o
);

  reg req_src_q, ack_src_q, ack_q;
  reg [WIDTH-1:0] data_src_q;

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      req_src_q  <= 1'b0;
      data_src_q <= {WIDTH{1'b0}};
    end else if (valid_i && ready_o) begin
      req_src_q  <= ~req_src_q;
      data_src_q <= data_i;
    end
  end

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      ack_src_q <= 1'b0;
      ack_q     <= 1'b0;
    end else begin
      ack_src_q <= async_ack_i;
      ack_q     <= ack_src_q;
    end
  end

  assign ready_o = (req_src_q == ack_q);
  assign async_req_o = req_src_q;
  assign async_data_o = data_src_q;

endmodule


module cdc_2phase_dst #(
  parameter WIDTH = 1
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

  reg req_dst_q, req_q0, req_q1, ack_dst_q;
  reg [WIDTH-1:0] data_dst_q;

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni)
      ack_dst_q <= 1'b0;
    else if (valid_o && ready_i)
      ack_dst_q <= ~ack_dst_q;
  end

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni)
      data_dst_q <= {WIDTH{1'b0}};
    else if ((req_q0 != req_q1) && !valid_o)
      data_dst_q <= async_data_i;
  end

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      req_dst_q <= 1'b0;
      req_q0    <= 1'b0;
      req_q1    <= 1'b0;
    end else begin
      req_dst_q <= async_req_i;
      req_q0    <= req_dst_q;
      req_q1    <= req_q0;
    end
  end

  assign valid_o = (ack_dst_q != req_q1);
  assign data_o = data_dst_q;
  assign async_ack_o = ack_dst_q;

endmodule