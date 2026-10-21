```verilog
module cdc_reset_ctrlr #(
    parameter SYNC_STAGES = 2
)(
    input  wire a_clk_i,
    input  wire a_rst_ni,
    input  wire a_clear_i,
    output reg  a_clear_o,
    input  wire a_clear_ack_i,
    output reg  a_isolate_o,
    input  wire a_isolate_ack_i,
    input  wire b_clk_i,
    input  wire b_rst_ni,
    input  wire b_clear_i,
    output reg  b_clear_o,
    input  wire b_clear_ack_i,
    output reg  b_isolate_o,
    input  wire b_isolate_ack_i
);

    localparam [1:0] IDLE = 2'b00;
    localparam [1:0] ISOLATING = 2'b01;
    localparam [1:0] CLEARING = 2'b10;
    localparam [1:0] DONE = 2'b11;

    // State machine for Domain A
    reg [1:0] a_state;
    reg [1:0] b_state;

    // Handshake signals for Domain A
    reg a_isolate_req;
    reg a_clear_req;
    reg a_isolate_ack_int;
    reg a_clear_ack_int;

    // Handshake signals for Domain B
    reg b_isolate_req;
    reg b_clear_req;
    reg b_isolate_ack_int;
    reg b_clear_ack_int;

    // Synchronizers for cross-domain signals
    // Domain A inputs coming from Domain B
    reg [1:0] b_clear_sync_a;
    reg [1:0] b_isolate_ack_sync_a;
    reg [1:0] b_clear_ack_sync_a;
    
    // Domain B inputs coming from Domain A
    reg [1:0] a_clear_sync_b;
    reg [1:0] a_isolate_ack_sync_b;
    reg [1:0] a_clear_ack_sync_b;

    // Synchronizer logic for Domain A inputs
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_state <= IDLE;
            b_state <= IDLE;
            a_clear_o <= 1'b0;
            a_isolate_o <= 1'b0;
            b_clear_o <= 1'b0;
            b_isolate_o <= 1'b0;
            a_isolate_req <= 1'b0;
            a_clear_req <= 1'b0;
            a_isolate_ack_int <= 1'b0;
            a_clear_ack_int <= 1'b0;
            b_isolate_req <= 1'b0;
            b_clear_req <= 1'b0;
            b_isolate_ack_int <= 1'b0;
            b_clear_ack_int <= 1'b0;
            a_clear_sync_b <= 2'b00;
            a_isolate_ack_sync_b <= 2'b00;
            a_clear_ack_sync_b <= 2'b00;
            b_clear_sync_a <= 2'b00;
            b_isolate_ack_sync_a <= 2'b00;
            b_clear_ack_sync_a <= 2'b00;
        end else begin
            a_clear_sync_b <= {a_clear_sync_b[0], a_clear_i};
            a_isolate_ack_sync_b <= {a_isolate_ack_sync_b[0], a_isolate_ack_i};
            a_clear_ack_sync_b <= {a_clear_ack_sync_b[0], a_clear_ack_i};
            
            b_clear_sync_a <= {b_clear_sync_a[0], b_clear_i};
            b_isolate_ack_sync_a <= {b_isolate_ack_sync_a[0], b_isolate_ack_i};
            b_clear_ack_sync_a <= {b_clear_ack_sync_a[0], b_clear_ack_i};

            a_state <= a_state_next;
            b_state <= b_state_next;
            a_clear_o <= a_clear_out;
            a_isolate_o <= a_isolate_out;
            b_clear_o <= b_clear_out;
            b_isolate_o <= b_isolate_out;
            a_isolate_req <= a_isolate_req_next;
            a_clear_req <= a_clear_req_next;
            a_isolate_ack_int <= a_isolate_ack_int_next;
            a_clear_ack_int <= a_clear_ack_int_next;
            b_isolate_req <= b_isolate_req_next;
            b_clear_req <= b_clear_req_next;
            b_isolate_ack_int <= b_isolate_ack_int_next;
            b_clear_ack_int <= b_clear_ack_int_next;
        end
    end

    // Next state and output logic for Domain A
    always @(*) begin
        a_state_next = a_state;
        b_state_next = b_state;
        a_clear_out = 1'b0;
        a_isolate_out = 1'b0;
        b_clear_out = 1'b0;
        b_isolate_out = 1'b0;
        a_isolate_req_next = 1'b0;
        a_clear_req_next = 1'b0;
        a_isolate_ack_int_next = 1'b0;
        a_clear_ack_int_next = 1'b0;
        b_isolate_req_next = 1'b0;
        b_clear_req_next = 1'b0;
        b_isolate_ack_int_next = 1'b0;
        b_clear_ack_int_next = 1'b0;

        case (a_state)
            IDLE: begin
                if (a_clear_i || b_clear_sync_a[1]) begin
                    a_state_next = ISOLATING;
                    a_isolate_req_next = 1'b1;
                    b_clear_req_next = 1'b1;
                end
            end

            ISOLATING: begin
                if (a_isolate_ack_sync_b[1] && b_isolate_ack_sync_a[1]) begin
                    a_state_next = CLEARING;
                    a_clear_req_next = 1'b1;
                    b_clear_req_next = 1'b1;
                end
            end

            CLEARING: begin
                if (a_clear_ack_sync_b[1] && b_clear_ack_sync_a[1]) begin
                    a_state_next = DONE;
                    a_isolate_req_next = 1'b1;
                    b_clear_req_next = 1'b1;
                end
            end

            DONE: begin
                if (a_isolate_ack_sync_b[1] && b_isolate_ack_sync_a[1]) begin
                    a_state_next = IDLE;
                    a_isolate_req_next = 1'b1;
                    b_clear_req_next = 1'b1;
                end
            end

            default: begin
                a_state_next = IDLE;
                b_state_next = IDLE;
                a_clear_out = 1'b0;
                a_isolate_out = 1'b0;
                b_clear_out = 1'b0;
                b_isolate_out = 1'b0;
                a_isolate_req_next = 1'b0;
                a_clear_req_next = 1'b0;
                a_isolate_ack_int_next = 1'b0;
                a_clear_ack_int_next = 1'b0;
                b_isolate_req_next = 1'b0;
                b_clear_req_next = 1'b0;
                b_isolate_ack_int_next = 1'b0;
                b_clear_ack_int_next = 1'b0;
            end
        endcase
    end

    // Output logic for Domain A
    always @(*) begin
        a_clear_o = (a_state == CLEARING || a_state == DONE) ? 1'b1 : 1'b0;
        a_isolate_o = (a_state == ISOLATING || a_state == CLEARING || a_state == DONE) ? 1'b1 : 1'b0;
    end

    // Output logic for Domain B
    always @(*) begin
        b_clear_o = (b_state == CLEARING || b_state == DONE) ? 1'b1 : 1'b0;
        b_isolate_o = (b_state == ISOLATING || b_state == CLEARING || b_state == DONE) ? 1'b1 : 1'b0;
    end

    // State machine for Domain B
    always @(*) begin
        b_state_next = b_state;
        a_state_next = a_state;
        b_clear_out = 1'b0;
        b_isolate_out = 1'b0;
        a_clear_out = 1'b0;
        a_isolate_out = 1'b0;
        b_isolate_req_next = 1'b0;
        b_clear_req_next = 1'b0;
        b_isolate_ack_int_next = 1'b0;
        b_clear_ack_int_next = 1'b0;
        a_isolate_req_next = 1'b0;
        a_clear_req_next = 1'b0;
        a_isolate_ack_int_next = 1'b0;
        a_clear_ack_int_next = 1'b0;

        case (b_state)
            IDLE: begin
                if (b_clear_i || a_clear_sync_b[1]) begin
                    b_state_next = ISOLATING;
                    b_isolate_req_next = 1'b1;
                    a_clear_req_next = 1'b1;
                end
            end

            ISOLATING: begin
                if (b_isolate_ack_sync_a[1] && a_isolate_ack_sync_b[1]) begin
                    b_state_next = CLEARING;
                    b_clear_req_next = 1'b1;
                    a_clear_req_next = 1'b1;
                end
            end

            CLEARING: begin
                if (b_clear_ack_sync_a[1] && a_clear_ack_sync_b[1]) begin
                    b_state_next = DONE;
                    b_isolate_req_next = 1'b1;
                    a_clear_req_next = 1'b1;
                end
            end

            DONE: begin
                if (b_isolate_ack_sync_a[1] && a_isolate_ack_sync_b[1]) begin
                    b_state_next = IDLE;
                    b_isolate_req_next = 1'b1;
                    a_clear_req_next = 1'b1;
                end
            end

            default: begin
                b_state_next = IDLE;
                a_state_next = IDLE;
                b_clear_out = 1'b0;
                b_isolate_out = 1'b0;
                a_clear_out = 1'b0;
                a_isolate_out = 1'b0;
                b_isolate_req_next = 1'b0;
                b_clear_req_next = 1'b0;
                b_isolate_ack_int_next = 1'b0;
                b_clear_ack_int_next = 1'b0;
                a_isolate_req_next = 1'b0;
                a_clear_req_next = 1'b0;
                a_isolate_ack_int_next = 1'b0;
                a_clear_ack_int_next = 1'b0;
            end
        endcase
    end

    // Output logic for Domain B (redundant but explicit for clarity)
    always @(*) begin
        b_clear_o = (b_state == CLEARING || b_state == DONE) ? 1'b1 : 1'b0;
        b_isolate_o = (b_state == ISOLATING || b_state == CLEARING || b_state == DONE) ? 1'b1 : 1'b0;
    end

    // Internal handshake logic for Domain A
    always @(*) begin
        a_isolate_ack_int = a_isolate_ack_sync_b[1];
        a_clear_ack_int = a_clear_ack_sync_b[1];
    end

    // Internal handshake logic for Domain B
    always @(*) begin
        b_isolate_ack_int = b_isolate_ack_sync_a[1];
        b_clear_ack_int = b_clear_ack_sync_a[1];
    end

endmodule
```<|im_end|>
