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
    localparam S_IDLE     = 3'd0;
    localparam S_ISOLATE  = 3'd1;
    localparam S_CLEAR    = 3'd2;
    localparam S_RELEASE  = 3'd3;

    // A-side state
    reg [2:0] a_state;
    reg       a_isolate_o_r;
    reg       a_clear_o_r;

    // B-side state
    reg [2:0] b_state;
    reg       b_isolate_o_r;
    reg       b_clear_o_r;

    // A-side sync registers for B-side signals
    reg [SYNC_STAGES-1:0] b_isolate_ack_sync;
    reg [SYNC_STAGES-1:0] b_clear_ack_sync;
    reg [SYNC_STAGES-1:0] b_state_sync;

    // B-side sync registers for A-side signals
    reg [SYNC_STAGES-1:0] a_isolate_ack_sync;
    reg [SYNC_STAGES-1:0] a_clear_ack_sync;
    reg [SYNC_STAGES-1:0] a_state_sync;

    // A-side outputs
    assign a_isolate_o = a_isolate_o_r;
    assign a_clear_o   = a_clear_o_r;

    // B-side outputs
    assign b_isolate_o = b_isolate_o_r;
    assign b_clear_o   = b_clear_o_r;

    // A-side synchronization of B-side signals
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            b_isolate_ack_sync <= {SYNC_STAGES{1'b0}};
            b_clear_ack_sync   <= {SYNC_STAGES{1'b0}};
            b_state_sync       <= {SYNC_STAGES*3{1'b0}};
        end else begin
            b_isolate_ack_sync <= {b_isolate_ack_sync[SYNC_STAGES-2:0], b_isolate_ack_i};
            b_clear_ack_sync   <= {b_clear_ack_sync[SYNC_STAGES-2:0], b_clear_ack_i};
            b_state_sync       <= {b_state_sync[SYNC_STAGES-2:0], b_state};
        end
    end

    // B-side synchronization of A-side signals
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            a_isolate_ack_sync <= {SYNC_STAGES{1'b0}};
            a_clear_ack_sync   <= {SYNC_STAGES{1'b0}};
            a_state_sync       <= {SYNC_STAGES*3{1'b0}};
        end else begin
            a_isolate_ack_sync <= {a_isolate_ack_sync[SYNC_STAGES-2:0], a_isolate_ack_i};
            a_clear_ack_sync   <= {a_clear_ack_sync[SYNC_STAGES-2:0], a_clear_ack_i};
            a_state_sync       <= {a_state_sync[SYNC_STAGES-2:0], a_state};
        end
    end

    // A-side state machine
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_state       <= S_IDLE;
            a_isolate_o_r <= 1'b0;
            a_clear_o_r   <= 1'b0;
        end else begin
            case (a_state)
                S_IDLE: begin
                    a_isolate_o_r <= 1'b0;
                    a_clear_o_r   <= 1'b0;
                    if (a_clear_i || b_clear_ack_sync[SYNC_STAGES-1]) begin
                        a_state <= S_ISOLATE;
                    end
                end

                S_ISOLATE: begin
                    a_isolate_o_r <= 1'b1;
                    a_clear_o_r   <= 1'b0;
                    if (a_isolate_ack_i && b_isolate_ack_sync[SYNC_STAGES-1]) begin
                        a_state <= S_CLEAR;
                    end
                end

                S_CLEAR: begin
                    a_isolate_o_r <= 1'b1;
                    a_clear_o_r   <= 1'b1;
                    if (a_clear_ack_i && b_clear_ack_sync[SYNC_STAGES-1]) begin
                        a_state <= S_RELEASE;
                    end
                end

                S_RELEASE: begin
                    a_isolate_o_r <= 1'b1;
                    a_clear_o_r   <= 1'b0;
                    if (a_isolate_ack_i && b_isolate_ack_sync[SYNC_STAGES-1]) begin
                        a_state <= S_IDLE;
                    end
                end

                default: begin
                    a_state       <= S_IDLE;
                    a_isolate_o_r <= 1'b0;
                    a_clear_o_r   <= 1'b0;
                end
            endcase
        end
    end

    // B-side state machine
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_state       <= S_IDLE;
            b_isolate_o_r <= 1'b0;
            b_clear_o_r   <= 1'b0;
        end else begin
            case (b_state)
                S_IDLE: begin
                    b_isolate_o_r <= 1'b0;
                    b_clear_o_r   <= 1'b0;
                    if (b_clear_i || a_clear_ack_sync[SYNC_STAGES-1]) begin
                        b_state <= S_ISOLATE;
                    end
                end

                S_ISOLATE: begin
                    b_isolate_o_r <= 1'b1;
                    b_clear_o_r   <= 1'b0;
                    if (b_isolate_ack_i && a_isolate_ack_sync[SYNC_STAGES-1]) begin
                        b_state <= S_CLEAR;
                    end
                end

                S_CLEAR: begin
                    b_isolate_o_r <= 1'b1;
                    b_clear_o_r   <= 1'b1;
                    if (b_clear_ack_i && a_clear_ack_sync[SYNC_STAGES-1]) begin
                        b_state <= S_RELEASE;
                    end
                end

                S_RELEASE: begin
                    b_isolate_o_r <= 1'b1;
                    b_clear_o_r   <= 1'b0;
                    if (b_isolate_ack_i && a_isolate_ack_sync[SYNC_STAGES-1]) begin
                        b_state <= S_IDLE;
                    end
                end

                default: begin
                    b_state       <= S_IDLE;
                    b_isolate_o_r <= 1'b0;
                    b_clear_o_r   <= 1'b0;
                end
            endcase
        end
    end

endmodule
