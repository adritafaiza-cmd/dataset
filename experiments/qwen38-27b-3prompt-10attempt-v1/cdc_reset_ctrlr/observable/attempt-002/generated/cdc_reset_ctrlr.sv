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

    // State encoding
    localparam S_IDLE    = 3'd0;
    localparam S_ISOLATE = 3'd1;
    localparam S_CLEAR   = 3'd2;

    // A-side state machine
    reg [2:0] a_state;
    reg       a_isolate_r;
    reg       a_clear_r;

    // B-side state machine
    reg [2:0] b_state;
    reg       b_isolate_r;
    reg       b_clear_r;

    // Synchronizers for A-side signals to B domain
    reg [SYNC_STAGES-1:0] a_isolate_sync;
    reg [SYNC_STAGES-1:0] a_clear_sync;
    reg [SYNC_STAGES-1:0] a_isolate_ack_sync;
    reg [SYNC_STAGES-1:0] a_clear_ack_sync;

    // Synchronizers for B-side signals to A domain
    reg [SYNC_STAGES-1:0] b_isolate_sync;
    reg [SYNC_STAGES-1:0] b_clear_sync;
    reg [SYNC_STAGES-1:0] b_isolate_ack_sync;
    reg [SYNC_STAGES-1:0] b_clear_ack_sync;

    // Synchronizer for A clear request to B domain
    reg [SYNC_STAGES-1:0] a_clear_req_sync;

    // Synchronizer for B clear request to A domain
    reg [SYNC_STAGES-1:0] b_clear_req_sync;

    // Synchronizer for A state to B domain (to know when A is in ISOLATE or CLEAR)
    reg [SYNC_STAGES-1:0] a_state_isolate_sync;
    reg [SYNC_STAGES-1:0] a_state_clear_sync;

    // Synchronizer for B state to A domain
    reg [SYNC_STAGES-1:0] b_state_isolate_sync;
    reg [SYNC_STAGES-1:0] b_state_clear_sync;

    // Synchronizer for A isolate ack to B domain
    // Synchronizer for B isolate ack to A domain
    // Synchronizer for A clear ack to B domain
    // Synchronizer for B clear ack to A domain

    // A-side synchronizers
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate_sync <= {SYNC_STAGES{1'b0}};
            a_clear_sync   <= {SYNC_STAGES{1'b0}};
            a_isolate_ack_sync <= {SYNC_STAGES{1'b0}};
            a_clear_ack_sync   <= {SYNC_STAGES{1'b0}};
            a_clear_req_sync   <= {SYNC_STAGES{1'b0}};
            a_state_isolate_sync <= {SYNC_STAGES{1'b0}};
            a_state_clear_sync   <= {SYNC_STAGES{1'b0}};
        end else begin
            a_isolate_sync <= {a_isolate_sync[SYNC_STAGES-2:0], a_isolate_r};
            a_clear_sync   <= {a_clear_sync[SYNC_STAGES-2:0], a_clear_r};
            a_isolate_ack_sync <= {a_isolate_ack_sync[SYNC_STAGES-2:0], a_isolate_ack_i};
            a_clear_ack_sync   <= {a_clear_ack_sync[SYNC_STAGES-2:0], a_clear_ack_i};
            a_clear_req_sync   <= {a_clear_req_sync[SYNC_STAGES-2:0], a_clear_i};
            a_state_isolate_sync <= {a_state_isolate_sync[SYNC_STAGES-2:0], (a_state == S_ISOLATE)};
            a_state_clear_sync   <= {a_state_clear_sync[SYNC_STAGES-2:0], (a_state == S_CLEAR)};
        end
    end

    // B-side synchronizers
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate_sync <= {SYNC_STAGES{1'b0}};
            b_clear_sync   <= {SYNC_STAGES{1'b0}};
            b_isolate_ack_sync <= {SYNC_STAGES{1'b0}};
            b_clear_ack_sync   <= {SYNC_STAGES{1'b0}};
            b_clear_req_sync   <= {SYNC_STAGES{1'b0}};
            b_state_isolate_sync <= {SYNC_STAGES{1'b0}};
            b_state_clear_sync   <= {SYNC_STAGES{1'b0}};
        end else begin
            b_isolate_sync <= {b_isolate_sync[SYNC_STAGES-2:0], b_isolate_r};
            b_clear_sync   <= {b_clear_sync[SYNC_STAGES-2:0], b_clear_r};
            b_isolate_ack_sync <= {b_isolate_ack_sync[SYNC_STAGES-2:0], b_isolate_ack_i};
            b_clear_ack_sync   <= {b_clear_ack_sync[SYNC_STAGES-2:0], b_clear_ack_i};
            b_clear_req_sync   <= {b_clear_req_sync[SYNC_STAGES-2:0], b_clear_i};
            b_state_isolate_sync <= {b_state_isolate_sync[SYNC_STAGES-2:0], (b_state == S_ISOLATE)};
            b_state_clear_sync   <= {b_state_clear_sync[SYNC_STAGES-2:0], (b_state == S_CLEAR)};
        end
    end

    // A-side state machine
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_state     <= S_IDLE;
            a_isolate_r <= 1'b0;
            a_clear_r   <= 1'b0;
        end else begin
            case (a_state)
                S_IDLE: begin
                    if (a_clear_i || b_clear_sync[SYNC_STAGES-1]) begin
                        a_state     <= S_ISOLATE;
                        a_isolate_r <= 1'b1;
                        a_clear_r   <= 1'b0;
                    end
                end
                S_ISOLATE: begin
                    // Wait for both sides to acknowledge isolate
                    if (a_isolate_ack_i && b_isolate_ack_sync[SYNC_STAGES-1]) begin
                        a_state     <= S_CLEAR;
                        a_isolate_r <= 1'b1;
                        a_clear_r   <= 1'b1;
                    end
                end
                S_CLEAR: begin
                    // Wait for both sides to acknowledge clear
                    if (a_clear_ack_i && b_clear_ack_sync[SYNC_STAGES-1]) begin
                        a_state     <= S_IDLE;
                        a_isolate_r <= 1'b0;
                        a_clear_r   <= 1'b0;
                    end
                end
                default: begin
                    a_state     <= S_IDLE;
                    a_isolate_r <= 1'b0;
                    a_clear_r   <= 1'b0;
                end
            endcase
        end
    end

    // B-side state machine
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_state     <= S_IDLE;
            b_isolate_r <= 1'b0;
            b_clear_r   <= 1'b0;
        end else begin
            case (b_state)
                S_IDLE: begin
                    if (b_clear_i || a_clear_sync[SYNC_STAGES-1]) begin
                        b_state     <= S_ISOLATE;
                        b_isolate_r <= 1'b1;
                        b_clear_r   <= 1'b0;
                    end
                end
                S_ISOLATE: begin
                    // Wait for both sides to acknowledge isolate
                    if (b_isolate_ack_i && a_isolate_ack_sync[SYNC_STAGES-1]) begin
                        b_state     <= S_CLEAR;
                        b_isolate_r <= 1'b1;
                        b_clear_r   <= 1'b1;
                    end
                end
                S_CLEAR: begin
                    // Wait for both sides to acknowledge clear
                    if (b_clear_ack_i && a_clear_ack_sync[SYNC_STAGES-1]) begin
                        b_state     <= S_IDLE;
                        b_isolate_r <= 1'b0;
                        b_clear_r   <= 1'b0;
                    end
                end
                default: begin
                    b_state     <= S_IDLE;
                    b_isolate_r <= 1'b0;
                    b_clear_r   <= 1'b0;
                end
            endcase
        end
    end

    // Outputs
    assign a_isolate_o = a_isolate_r;
    assign a_clear_o   = a_clear_r;
    assign b_isolate_o = b_isolate_r;
    assign b_clear_o   = b_clear_r;

endmodule
