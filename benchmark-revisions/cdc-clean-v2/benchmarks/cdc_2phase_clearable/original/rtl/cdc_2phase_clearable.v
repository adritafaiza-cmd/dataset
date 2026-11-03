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
// Fabian Schuiki <fschuiki@iis.ee.ethz.ch> (original CDC)
// Manuel Eggimann <meggiman@iis.ee.ethz.ch> (clearability feature)

/// A two-phase clock domain crossing.
///
/// CONSTRAINT: Requires max_delay of min_period(src_clk_i, dst_clk_i) through
/// the paths async_req, async_ack, async_data.
///
///
/// Reset Behavior:
///
/// In contrast to the cdc_2phase version without clear signal, this module
/// supports one-sided warm resets (asynchronously and synchronously). The way
/// this is implemented is described in more detail in the cdc_reset_ctrlr
/// module. To summarize a synchronous clear request i.e. src/dst_clear_i will
/// cause the respective other clock domain to reset as well without introducing
/// any spurious transactions. This is acomplished by an internal module
/// (cdc_reset_ctrlr) that starts a reset sequence on both sides of the CDC in
/// lock-step that first isolates the CDC from the outside world and then resets
/// it. The reset sequencer provides the following behavior:
/// 1. There are no spurious invalid or duplicated transactions regardless how
///    the individual sides are reset (can also happen roughly simultaneosly)
/// 2. The CDC becomes unready at the src side in the next cycle after
///    synchronous reset request until the reset sequence is completed. A currently
///    pending transactions might still complete (if the dst accepts at the
///    exact time the reset is request on the src die).
/// 3. During the reset sequence the dst might withdraw the valid signal. This
///    might violate higher level protocols. If you need this feature you would
///    have to path the existing implementation to wait with the isolate_ack
///    assertion until all open handshakes were acknowledged.
/// 4. If the parameter CLEAR_ON_ASYNC_RESET is enabled, the same behavior as
///    above is also valid for asynchronous resets on either side. However, this
///    increases the minimum number of synchronization stages (SYNC_STAGES
///    parameter) from 2 to 3 (read the cdc_reset_ctrlr header to figure out
///    why).
///
///
/* verilator lint_off DECLFILENAME */

`include "common_cells/registers.svh"
`include "common_cells/assertions.svh"

module cdc_2phase_clearable #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3,
  parameter CLEAR_ON_ASYNC_RESET = 1
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  src_clear_i,
  output src_clear_pending_o,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,

  input  dst_rst_ni,
  input  dst_clk_i,
  input  dst_clear_i,
  output dst_clear_pending_o,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);

  wire s_src_clear_req;
  reg  s_src_clear_ack_q;
  wire s_src_ready;
  wire s_src_isolate_req;
  reg  s_src_isolate_ack_q;

  wire s_dst_clear_req;
  reg  s_dst_clear_ack_q;
  wire s_dst_valid;
  wire s_dst_isolate_req;
  reg  s_dst_isolate_ack_q;

  wire async_req;
  wire async_ack;
  wire [WIDTH-1:0] async_data;

  cdc_2phase_src_clearable #(
    .WIDTH(WIDTH),
    .SYNC_STAGES(SYNC_STAGES)
  ) i_src (
    .rst_ni       (src_rst_ni),
    .clk_i        (src_clk_i),
    .clear_i      (s_src_clear_req),
    .data_i       (src_data_i),
    .valid_i      (src_valid_i & ~s_src_isolate_req),
    .ready_o      (s_src_ready),
    .async_req_o  (async_req),
    .async_ack_i  (async_ack),
    .async_data_o (async_data)
  );

  assign src_ready_o = s_src_ready & ~s_src_isolate_req;

  cdc_2phase_dst_clearable #(
    .WIDTH(WIDTH),
    .SYNC_STAGES(SYNC_STAGES)
  ) i_dst (
    .rst_ni       (dst_rst_ni),
    .clk_i        (dst_clk_i),
    .clear_i      (s_dst_clear_req),
    .data_o       (dst_data_o),
    .valid_o      (s_dst_valid),
    .ready_i      (dst_ready_i & ~s_dst_isolate_req),
    .async_req_i  (async_req),
    .async_ack_o  (async_ack),
    .async_data_i (async_data)
  );

  assign dst_valid_o = s_dst_valid & ~s_dst_isolate_req;

  cdc_reset_ctrlr #(
    .SYNC_STAGES(SYNC_STAGES-1)
  ) i_cdc_reset_ctrlr (
    .a_clk_i         (src_clk_i),
    .a_rst_ni        (src_rst_ni),
    .a_clear_i       (src_clear_i),
    .a_clear_o       (s_src_clear_req),
    .a_clear_ack_i   (s_src_clear_ack_q),
    .a_isolate_o     (s_src_isolate_req),
    .a_isolate_ack_i (s_src_isolate_ack_q),

    .b_clk_i         (dst_clk_i),
    .b_rst_ni        (dst_rst_ni),
    .b_clear_i       (dst_clear_i),
    .b_clear_o       (s_dst_clear_req),
    .b_clear_ack_i   (s_dst_clear_ack_q),
    .b_isolate_o     (s_dst_isolate_req),
    .b_isolate_ack_i (s_dst_isolate_ack_q)
  );

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      s_src_isolate_ack_q <= 1'b0;
      s_src_clear_ack_q   <= 1'b0;
    end else begin
      s_src_isolate_ack_q <= s_src_isolate_req;
      s_src_clear_ack_q   <= s_src_clear_req;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      s_dst_isolate_ack_q <= 1'b0;
      s_dst_clear_ack_q   <= 1'b0;
    end else begin
      s_dst_isolate_ack_q <= s_dst_isolate_req;
      s_dst_clear_ack_q   <= s_dst_clear_req;
    end
  end

  assign src_clear_pending_o = s_src_isolate_req;
  assign dst_clear_pending_o = s_dst_isolate_req;

endmodule


module cdc_2phase_src_clearable #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 2
)(
  input  rst_ni,
  input  clk_i,
  input  clear_i,
  input  [WIDTH-1:0] data_i,
  input  valid_i,
  output ready_o,
  output async_req_o,
  input  async_ack_i,
  output [WIDTH-1:0] async_data_o
);

  reg req_src_d;
  reg req_src_q;
  wire ack_synced;

  reg [WIDTH-1:0] data_src_d;
  reg [WIDTH-1:0] data_src_q;

  sync #(
    .STAGES(SYNC_STAGES)
  ) i_sync (
    .clk_i    (clk_i),
    .rst_ni   (rst_ni),
    .serial_i (async_ack_i),
    .serial_o (ack_synced)
  );

  always @(*) begin
    data_src_d = data_src_q;
    req_src_d  = req_src_q;

    if (clear_i) begin
      req_src_d = 1'b0;
    end else if (valid_i && ready_o) begin
      req_src_d  = ~req_src_q;
      data_src_d = data_i;
    end
  end

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      data_src_q <= {WIDTH{1'b0}};
      req_src_q  <= 1'b0;
    end else begin
      data_src_q <= data_src_d;
      req_src_q  <= req_src_d;
    end
  end

  assign ready_o = (req_src_q == ack_synced);
  assign async_req_o = req_src_q;
  assign async_data_o = data_src_q;

endmodule


module cdc_2phase_dst_clearable #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 2
)(
  input  rst_ni,
  input  clk_i,
  input  clear_i,
  output [WIDTH-1:0] data_o,
  output valid_o,
  input  ready_i,
  input  async_req_i,
  output async_ack_o,
  input  [WIDTH-1:0] async_data_i
);

  reg ack_dst_d;
  reg ack_dst_q;
  wire req_synced;
  reg req_synced_q1;

  reg [WIDTH-1:0] data_dst_d;
  reg [WIDTH-1:0] data_dst_q;

  sync #(
    .STAGES(SYNC_STAGES)
  ) i_sync (
    .clk_i    (clk_i),
    .rst_ni   (rst_ni),
    .serial_i (async_req_i),
    .serial_o (req_synced)
  );

  always @(*) begin
    ack_dst_d = ack_dst_q;

    if (clear_i) begin
      ack_dst_d = 1'b0;
    end else if (valid_o && ready_i) begin
      ack_dst_d = ~ack_dst_q;
    end
  end

  always @(*) begin
    data_dst_d = data_dst_q;

    if ((req_synced != req_synced_q1) && !valid_o) begin
      data_dst_d = async_data_i;
    end
  end

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      ack_dst_q     <= 1'b0;
      req_synced_q1 <= 1'b0;
      data_dst_q    <= {WIDTH{1'b0}};
    end else begin
      ack_dst_q     <= ack_dst_d;
      req_synced_q1 <= req_synced;
      data_dst_q    <= data_dst_d;
    end
  end

  assign valid_o = (ack_dst_q != req_synced_q1);
  assign data_o = data_dst_q;
  assign async_ack_o = ack_dst_q;

endmodule
