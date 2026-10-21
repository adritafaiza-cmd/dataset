```verilog
`timescale 1ns/1ps

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
    output b_isolate_o
);

    // ------------------------------------------------------------------
    // Synchronizers for asynchronous signals crossing domains
    // ------------------------------------------------------------------
    
    // Domain A -> Domain B
    wire [SYNC_STAGES-1:0] a_clear_sync_b;
    wire [SYNC_STAGES-1:0] a_clear_ack_sync_b;
    wire [SYNC_STAGES-1:0] a_isolate_ack_sync_b;
    wire [SYNC_STAGES-1:0] b_clear_sync_a;
    wire [SYNC_STAGES-1:0] b_clear_ack_sync_a;
    wire [SYNC_STAGES-1:0] b_isolate_ack_sync_a;

    genvar i;
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_sync_a_to_b
            wire sync_in, sync_out;
            assign sync_in = (i == 0) ? a_clear_i : a_clear_sync_b[i-1];
            assign sync_out = (i == SYNC_STAGES-1) ? a_clear_sync_b[i] : sync_in;
            always @(posedge b_clk_i or negedge b_rst_ni) begin
                if (!b_rst_ni)
                    sync_out <= 1'b0;
                else
                    sync_out <= sync_in;
            end
        end
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_sync_a_ack_to_b
            wire sync_in, sync_out;
            assign sync_in = (i == 0) ? a_clear_ack_i : a_clear_ack_sync_b[i-1];
            assign sync_out = (i == SYNC_STAGES-1) ? a_clear_ack_sync_b[i] : sync_in;
            always @(posedge b_clk_i or negedge b_rst_ni) begin
                if (!b_rst_ni)
                    sync_out <= 1'b0;
                else
                    sync_out <= sync_in;
            end
        end
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_sync_a_iso_ack_to_b
            wire sync_in, sync_out;
            assign sync_in = (i == 0) ? a_isolate_ack_i : a_isolate_ack_sync_b[i-1];
            assign sync_out = (i == SYNC_STAGES-1) ? a_isolate_ack_sync_b[i] : sync_in;
            always @(posedge b_clk_i or negedge b_rst_ni) begin
                if (!b_rst_ni)
                    sync_out <= 1'b0;
                else
                    sync_out <= sync_in;
            end
        end
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_sync_b_to_a
            wire sync_in, sync_out;
            assign sync_in = (i == 0) ? b_clear_i : b_clear_sync_a[i-1];
            assign sync_out = (i == SYNC_STAGES-1) ? b_clear_sync_a[i] : sync_in;
            always @(posedge a_clk_i or negedge a_rst_ni) begin
                if (!a_rst_ni)
                    sync_out <= 1'b0;
                else
                    sync_out <= sync_in;
            end
        end
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_sync_b_ack_to_a
            wire sync_in, sync_out;
            assign sync_in = (i == 0) ? b_clear_ack_i : b_clear_ack_sync_a[i-1];
            assign sync_out = (i == SYNC_STAGES-1) ? b_clear_ack_sync_a[i] : sync_in;
            always @(posedge a_clk_i or negedge a_rst_ni) begin
                if (!a_rst_ni)
                    sync_out <= 1'b0;
                else
                    sync_out <= sync_in;
            end
        end
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_sync_b_iso_ack_to_a
            wire sync_in, sync_out;
            assign sync_in = (i == 0) ? b_isolate_ack_i : b_isolate_ack_sync_a[i-1];
            assign sync_out = (i == SYNC_STAGES-1) ? b_isolate_ack_sync_a[i] : sync_in;
            always @(posedge a_clk_i or negedge a_rst_ni) begin
                if (!a_rst_ni)
                    sync_out <= 1'b0;
                else
                    sync_out <= sync_in;
            end
        end
    endgenerate

    // ------------------------------------------------------------------
    // State Machine Logic (Domain A)
    // ------------------------------------------------------------------
    
    // State Encoding
    // IDLE: Normal operation
    // REQ_A: A requested clear
    // REQ_B: B requested clear
    // ISOLATING: Both domains isolated, waiting for acks
    // CLEARING: Both domains cleared, waiting for acks
    // DONE: Handshake complete, returning to IDLE
    
    localparam IDLE = 2'b00;
    localparam REQ_A = 2'b01;
    localparam REQ_B = 2'b10;
    localparam ISOLATING = 2'b11;
    
    reg [1:0] state_a;
    reg [1:0] state_b;
    
    // Internal flags for handshake completion
    reg a_isolate_req_done;
    reg a_clear_req_done;
    reg b_isolate_req_done;
    reg b_clear_req_done;
    
    // Output registers
    reg a_clear_o;
    reg a_isolate_o;
    reg b_clear_o;
    reg b_isolate_o;
    
    // ------------------------------------------------------------------
    // Domain A State Machine
    // ------------------------------------------------------------------
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            state_a <= IDLE;
            a_clear_o <= 1'b0;
            a_isolate_o <= 1'b0;
            a_isolate_req_done <= 1'b0;
            a_clear_req_done <= 1'b0;
        end
        else begin
            case (state_a)
                IDLE: begin
                    if (a_clear_i)
                        state_a <= REQ_A;
                    else if (b_clear_sync_a[SYNC_STAGES-1])
                        state_a <= REQ_B;
                    else
                        state_a <= IDLE;
                end
                
                REQ_A: begin
                    if (b_clear_sync_a[SYNC_STAGES-1])
                        state_a <= REQ_B;
                    else if (b_isolate_ack_sync_b[SYNC_STAGES-1])
                        state_a <= ISOLATING;
                    else
                        state_a <= REQ_A;
                end
                
                REQ_B: begin
                    if (b_isolate_ack_sync_b[SYNC_STAGES-1])
                        state_a <= ISOLATING;
                    else
                        state_a <= REQ_B;
                end
                
                ISOLATING: begin
                    if (a_isolate_ack_i)
                        a_isolate_req_done <= 1'b1;
                    else
                        a_isolate_req_done <= 1'b0;
                        
                    if (b_isolate_ack_sync_b[SYNC_STAGES-1] && a_isolate_req_done)
                        state_a <= CLEARING;
                    else if (!b_isolate_ack_sync_b[SYNC_STAGES-1])
                        state_a <= ISOLATING;
                    else
                        state_a <= ISOLATING;
                end
                
                CLEARING: begin
                    if (a_clear_ack_i)
                        a_clear_req_done <= 1'b1;
                    else
                        a_clear_req_done <= 1'b0;
                        
                    if (b_clear_ack_sync_a[SYNC_STAGES-1] && a_clear_req_done)
                        state_a <= DONE;
                    else if (!b_clear_ack_sync_a[SYNC_STAGES-1])
                        state_a <= CLEARING;
                    else
                        state_a <= CLEARING;
                end
                
                DONE: begin
                    if (a_clear_i)
                        state_a <= REQ_A;
                    else if (b_clear_sync_a[SYNC_STAGES-1])
                        state_a <= REQ_B;
                    else
                        state_a <= IDLE;
                end
            endcase
        end
    end

    // ------------------------------------------------------------------
    // Domain B State Machine
    // ------------------------------------------------------------------
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            state_b <= IDLE;
            b_clear_o <= 1'b0;
            b_isolate_o <= 1'b0;
            b_isolate_req_done <= 1'b0;
            b_clear_req_done <= 1'b0;
        end
        else begin
            case (state_b)
                IDLE: begin
                    if (b_clear_i)
                        state_b <= REQ_B;
                    else if (a_clear_sync_b[SYNC_STAGES-1])
                        state_b <= REQ_A;
                    else
                        state_b <= IDLE;
                end
                
                REQ_B: begin
                    if (a_clear_sync_b[SYNC_STAGES-1])
                        state_b <= REQ_A;
                    else if (a_isolate_ack_sync_b[SYNC_STAGES-1])
                        state_b <= ISOLATING;
                    else
                        state_b <= REQ_B;
                end
                
                REQ_A: begin
                    if (a_isolate_ack_sync_b[SYNC_STAGES-1])
                        state_b <= ISOLATING;
                    else
                        state_b <= REQ_A;
                end
                
                ISOLATING: begin
                    if (b_isolate_ack_i)
                        b_isolate_req_done <= 1'b1;
                    else
                        b_isolate_req_done <= 1'b0;
                        
                    if (a_isolate_ack_sync_b[SYNC_STAGES-1] && b_isolate_req_done)
                        state_b <= CLEARING;
                    else if (!a_isolate_ack_sync_b[SYNC_STAGES-1])
                        state_b <= ISOLATING;
                    else
                        state_b <= ISOLATING;
                end
                
                CLEARING: begin
                    if (b_clear_ack_i)
                        b_clear_req_done <= 1'b1;
                    else
                        b_clear_req_done <= 1'b0;
                        
                    if (a_clear_ack_sync_b[SYNC_STAGES-1] && b_clear_req_done)
                        state_b <= DONE;
                    else if (!a_clear_ack_sync_b[SYNC_STAGES-1])
                        state_b <= CLEARING;
                    else
                        state_b <= CLEARING;
                end
                
                DONE: begin
                    if (b_clear_i)
                        state_b <= REQ_B;
                    else if (a_clear_sync_b[SYNC_STAGES-1])
                        state_b <= REQ_A;
                    else
                        state_b <= IDLE;
                end
            endcase
        end
    end

    // ------------------------------------------------------------------
    // Output Logic
    // ------------------------------------------------------------------
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_clear_o <= 1'b0;
            a_isolate_o <= 1'b0;
        end
        else begin
            case (state_a)
                IDLE, REQ_A, REQ_B: begin
                    a_isolate_o <= 1'b0;
                    a_clear_o <= 1'b0;
                end
                ISOLATING: begin
                    a_isolate_o <= 1'b1;
                    a_clear_o <= 1'b0;
                end
                CLEARING: begin
                    a_isolate_o <= 1'b1;
                    a_clear_o <= 1'b1;
                end
                DONE: begin
                    a_isolate_o <= 1'b0;
                    a_clear_o <= 1'b0;
                end
            endcase
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_clear_o <= 1'b0;
            b_isolate_o <= 1'b0;
        end
        else begin
            case (state_b)
                IDLE, REQ_B, REQ_A: begin
                    b_isolate_o <= 1'b0;
                    b_clear_o <= 1'b0;
                end
                ISOLATING: begin
                    b_isolate_o <= 1'b1;
                    b_clear_o <= 1'b0;
                end
                CLEARING: begin
                    b_isolate_o <= 1'b1;
                    b_clear_o <= 1'b1;
                end
                DONE: begin
                    b_isolate_o <= 1'b0;
                    b_clear_o <= 1'b0;
                end
            endcase
        end
    end

endmodule
```<|im_end|>
