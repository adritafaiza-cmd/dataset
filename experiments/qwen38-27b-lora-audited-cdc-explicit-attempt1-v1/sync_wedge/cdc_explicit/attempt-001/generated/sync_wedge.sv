// SPDX-License-Identifier: MIT
// Copyright (C) 2018-2025 lowRISC contributors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Synchronizer with edge detect
//
// Synchronizes a single bit from one clock domain to another.
//
// The input is synchronized to the clock domain of the output.
// The output is the synchronized input.
//
// The rising and falling edges of the synchronized input are detected and
// output as single-cycle pulses.
//
// The edge detection is enabled by the `en_i` signal. If `en_i` is low, the
// edge detection is disabled and the output is low.
//
// The number of synchronization stages is configurable via the `STAGES`
// parameter. The default is 2 stages.
//
// The reset is active low and asynchronous.

`include "prim_assert.svh"

module sync_wedge #(
    parameter STAGES = 2
) (
    input  clk_i,
    input  rst_ni,

    input  en_i,
    input  serial_i,

    output r_edge_o,
    output f_edge_o,
    output serial_o
);

  (* ASYNC_REG = "TRUE" *)
  logic [STAGES-1:0] sync_ff;

  logic [STAGES-1:0] sync_ff_d;
  logic              sync_ff_q;

  assign sync_ff_d[0] = serial_i;
  for (genvar i = 1; i < STAGES; i++) begin : gen_sync_ff_d
    assign sync_ff_d[i] = sync_ff[i-1];
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      sync_ff <= '0;
    end else begin
      sync_ff <= sync_ff_d;
    end
  end

  assign sync_ff_q = sync_ff[STAGES-1];

  logic [STAGES-1:0] sync_ff_q_d;
  logic              sync_ff_q_q;

  assign sync_ff_q_d[0] = sync_ff_q;
  for (genvar i = 1; i < STAGES; i++) begin : gen_sync_ff_q_d
    assign sync_ff_q_d[i] = sync_ff_q[i-1];
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      sync_ff_q <= '0;
    end else begin
      sync_ff_q <= sync_ff_q_d;
    end
  end

  assign sync_ff_q_q = sync_ff_q[STAGES-1];

  assign r_edge_o = sync_ff_q & ~sync_ff_q_q & en_i;
  assign f_edge_o = ~sync_ff_q & sync_ff_q_q & en_i;

  assign serial_o = sync_ff_q;

endmodule