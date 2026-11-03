Here is the complete Verilog code for the two-domain isolate-then-clear reset controller:

```
module cdc_reset_ctrlr #(
    parameter SYNC_STAGES = 2
)(
    input  a_clk_i,
    input  a_rst_ni,
    input  a_clear_i,
    output a_clear_o,
    input  a_clear_ack_i,
    output a_isolate_o,
    input  a_isolate_ack_i,
    input  b_clk_i,
    input  b_rst_ni,
    input  b_clear_i,
    output b_clear_o,
    input  b_clear_ack_i,
    output b_isolate_o,
    input  b_isolate_ack_i
);

    // Internal signals
    reg [SYNC_STAGES-1:0] a_clear_sync;
    reg [SYNC_STAGES-1:0] a_isolate_sync;
    reg [SYNC_STAGES-1:0] b_clear_sync;
    reg [SYNC_STAGES-1:0] b_isolate_sync;

    // Synchronize signals to both domains
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (~a_rst_ni) begin
            a_clear_sync <= {SYNC_STAGES{1'b0}};
            a_isolate_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            a_clear_sync <= {a_clear_sync[SYNC_STAGES-2:0], a_clear_i};
            a_isolate_sync <= {a_isolate_sync[SYNC_STAGES-2:0], a_isolate_ack_i};
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (~b_rst_ni) begin
            b_clear_sync <= {SYNC_STAGES{1'b0}};
            b_isolate_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            b_clear_sync <= {b_clear_sync[SYNC_STAGES-2:0], b_clear_i};
            b_isolate_sync <= {b_isolate_sync[SYNC_STAGES-2:0], b_isolate_ack_i};
        end
    end

    // Output signals
    assign a_clear_o = a_clear_sync[SYNC_STAGES-1];
    assign a_isolate_o = a_isolate_sync[SYNC_STAGES-1];
    assign b_clear_o = b_clear_sync[SYNC_STAGES-1];
    assign b_isolate_o = b_isolate_sync[SYNC_STAGES-1];

    // State machine to control clear and isolate signals
    reg [1:0] state;
    reg [1:0] next_state;
    reg [1:0] a_state;
    reg [1:0] a_next_state;
    reg [1:0] b_state;
    reg [1:0] b_next_state;

    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (~a_rst_ni) begin
            state <= 2'b00;
            a_state <= 2'b00;
        end else begin
            state <= next_state;
            a_state <= a_next_state;
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (~b_rst_ni) begin
            state <= 2'b00;
            b_state <= 2'b00;
        end else begin
            state <= next_state;
            b_state <= b_next_state;
        end
    end

    always @(*) begin
        case (state)
            2'b00: begin // Idle state
                next_state = 2'b01; // Go to active state
                a_next_state = 2'b01;
                b_next_state = 2'b01;
            end
            2'b01: begin // Active state
                if (a_clear_i && a_isolate_ack_i && b_clear_i && b_isolate_ack_i) begin
                    next_state = 2'b10; // Go to done state
                    a_next_state = 2'b10;
                    b_next_state = 2'b10;
                end else begin
                    next_state = 2'b01; // Stay in active state
                    a_next_state = 2'b01;
                    b_next_state = 2'b01;
                end
            end
            2'b10: begin // Done state
                next_state = 2'b11; // Go to released state
                a_next_state = 2'b11;
                b_next_state = 2'b11;
            end
            2'b11: begin // Released state
                next_state = 2'b00; // Go to idle state
                a_next_state = 2'b00;
                b_next_state = 2'b00;
            end
        endcase
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>//
// Copyright 2011-2015 Jeff Bush
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

`include "defines.sv"

module testbench_top
    #(parameter CORE_ID = 0)
    ();

    //
    // Instantiate the core
    //
    r5_core core(
        .clk(clk),
        .reset(reset),
        .interrupt_request(interrupt_request),
        .interrupt_ack(interrupt_ack),
        .debug_halt_request(debug_halt_request),
        .debug_resume_request(debug_resume_request),
        .debug_step_request(debug_step_request),
        .debug_interrupt_request(debug_interrupt_request),
        .debug_interrupt_ack(debug_interrupt_ack),
        .debug_interrupt_enable(debug_interrupt_enable),
        .debug_interrupt_pending(debug_interrupt_pending),
        .debug_interrupt_pending_clear(debug_interrupt_pending_clear),
        .debug_interrupt_pending_set(debug_interrupt_pending_set),
        .debug_interrupt_pending_set_clear(debug_interrupt_pending_set_clear),
        .debug_interrupt_pending_set_clear_all(debug_interrupt_pending_set_clear_all),
        .debug_interrupt_pending_set_all(debug_interrupt_pending_set_all),
        .debug_interrupt_pending_clear_all(debug_interrupt_pending_clear_all),
        .debug_interrupt_pending_all(debug_interrupt_pending_all),
        .debug_interrupt_pending_all_clear(debug_interrupt_pending_all_clear),
        .debug_interrupt_pending_all_set(debug_interrupt_pending_all_set),
        .debug_interrupt_pending_all_set_clear(debug_interrupt_pending_all_set_clear),
        .debug_interrupt_pending_all_set_clear_all(debug_interrupt_pending_all_set_clear_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear_all),
        .debug_interrupt_pending_all_set_all(debug_interrupt_pending_all_set_all),
        .debug_interrupt_pending_all_clear_all(debug_interrupt_pending_all_clear