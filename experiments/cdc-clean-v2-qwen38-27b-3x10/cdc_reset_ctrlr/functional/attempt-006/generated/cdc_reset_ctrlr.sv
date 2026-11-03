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
    localparam S_IDLE       = 3'd0;
    localparam S_ISOLATE    = 3'd1;
    localparam S_ISOLATE_W  = 3'd2; // Wait for peer isolate ack
    localparam S_CLEAR      = 3'd3;
    localparam S_CLEAR_W    = 3'd4; // Wait for peer clear ack
    localparam S_RELEASE    = 3'd5; // Release clear, wait for peer release
    localparam S_RELEASE_W  = 3'd6; // Wait for peer release ack

    // A-side state
    reg [2:0] a_state;
    reg       a_isolate_o_r;
    reg       a_clear_o_r;

    // B-side state
    reg [2:0] b_state;
    reg       b_isolate_o_r;
    reg       b_clear_o_r;

    // CDC signals: A to B
    // a_to_b_isolate: A has isolated (local)
    // a_to_b_clear: A has cleared (local)
    // a_to_b_release: A has released clear
    reg a_to_b_isolate;
    reg a_to_b_clear;
    reg a_to_b_release;

    // CDC signals: B to A
    // b_to_a_isolate: B has isolated (local)
    // b_to_a_clear: B has cleared (local)
    // b_to_a_release: B has released clear
    reg b_to_a_isolate;
    reg b_to_a_clear;
    reg b_to_a_release;

    // Synchronized versions of A-to-B signals in B domain
    reg [SYNC_STAGES-1:0] a_to_b_isolate_sync;
    reg [SYNC_STAGES-1:0] a_to_b_clear_sync;
    reg [SYNC_STAGES-1:0] a_to_b_release_sync;

    // Synchronized versions of B-to-A signals in A domain
    reg [SYNC_STAGES-1:0] b_to_a_isolate_sync;
    reg [SYNC_STAGES-1:0] b_to_a_clear_sync;
    reg [SYNC_STAGES-1:0] b_to_a_release_sync;

    // Assign outputs
    assign a_isolate_o = a_isolate_o_r;
    assign a_clear_o   = a_clear_o_r;
    assign b_isolate_o = b_isolate_o_r;
    assign b_clear_o   = b_clear_o_r;

    // A-side state machine
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_state       <= S_IDLE;
            a_isolate_o_r <= 1'b0;
            a_clear_o_r   <= 1'b0;
            a_to_b_isolate <= 1'b0;
            a_to_b_clear   <= 1'b0;
            a_to_b_release <= 1'b0;
        end else begin
            case (a_state)
                S_IDLE: begin
                    if (a_clear_i) begin
                        a_state       <= S_ISOLATE;
                        a_isolate_o_r <= 1'b1;
                        a_to_b_isolate <= 1'b1;
                    end
                end
                S_ISOLATE: begin
                    // Wait for local isolate ack
                    if (a_isolate_ack_i) begin
                        a_state <= S_ISOLATE_W;
                    end
                end
                S_ISOLATE_W: begin
                    // Wait for peer isolate ack (synchronized)
                    if (b_to_a_isolate_sync[SYNC_STAGES-1]) begin
                        a_state       <= S_CLEAR;
                        a_clear_o_r   <= 1'b1;
                        a_to_b_clear  <= 1'b1;
                    end
                end
                S_CLEAR: begin
                    // Wait for local clear ack
                    if (a_clear_ack_i) begin
                        a_state <= S_CLEAR_W;
                    end
                end
                S_CLEAR_W: begin
                    // Wait for peer clear ack (synchronized)
                    if (b_to_a_clear_sync[SYNC_STAGES-1]) begin
                        a_state        <= S_RELEASE;
                        a_clear_o_r    <= 1'b0;
                        a_to_b_release <= 1'b1;
                    end
                end
                S_RELEASE: begin
                    // Wait for peer release ack (synchronized)
                    if (b_to_a_release_sync[SYNC_STAGES-1]) begin
                        a_state        <= S_RELEASE_W;
                        a_isolate_o_r  <= 1'b0;
                        a_to_b_isolate <= 1'b0;
                        a_to_b_clear   <= 1'b0;
                        a_to_b_release <= 1'b0;
                    end
                end
                S_RELEASE_W: begin
                    // Wait for local isolate to be deasserted (ack)
                    if (!a_isolate_ack_i) begin
                        a_state <= S_IDLE;
                    end
                end
                default: begin
                    a_state       <= S_IDLE;
                    a_isolate_o_r <= 1'b0;
                    a_clear_o_r   <= 1'b0;
                    a_to_b_isolate <= 1'b0;
                    a_to_b_clear   <= 1'b0;
                    a_to_b_release <= 1'b0;
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
            b_to_a_isolate <= 1'b0;
            b_to_a_clear   <= 1'b0;
            b_to_a_release <= 1'b0;
        end else begin
            case (b_state)
                S_IDLE: begin
                    if (b_clear_i) begin
                        b_state       <= S_ISOLATE;
                        b_isolate_o_r <= 1'b1;
                        b_to_a_isolate <= 1'b1;
                    end
                end
                S_ISOLATE: begin
                    // Wait for local isolate ack
                    if (b_isolate_ack_i) begin
                        b_state <= S_ISOLATE_W;
                    end
                end
                S_ISOLATE_W: begin
                    // Wait for peer isolate ack (synchronized)
                    if (a_to_b_isolate_sync[SYNC_STAGES-1]) begin
                        b_state       <= S_CLEAR;
                        b_clear_o_r   <= 1'b1;
                        b_to_a_clear  <= 1'b1;
                    end
                end
                S_CLEAR: begin
                    // Wait for local clear ack
                    if (b_clear_ack_i) begin
                        b_state <= S_CLEAR_W;
                    end
                end
                S_CLEAR_W: begin
                    // Wait for peer clear ack (synchronized)
                    if (a_to_b_clear_sync[SYNC_STAGES-1]) begin
                        b_state        <= S_RELEASE;
                        b_clear_o_r    <= 1'b0;
                        b_to_a_release <= 1'b1;
                    end
                end
                S_RELEASE: begin
                    // Wait for peer release ack (synchronized)
                    if (a_to_b_release_sync[SYNC_STAGES-1]) begin
                        b_state        <= S_RELEASE_W;
                        b_isolate_o_r  <= 1'b0;
                        b_to_a_isolate <= 1'b0;
                        b_to_a_clear   <= 1'b0;
                        b_to_a_release <= 1'b0;
                    end
                end
                S_RELEASE_W: begin
                    // Wait for local isolate to be deasserted (ack)
                    if (!b_isolate_ack_i) begin
                        b_state <= S_IDLE;
                    end
                end
                default: begin
                    b_state       <= S_IDLE;
                    b_isolate_o_r <= 1'b0;
                    b_clear_o_r   <= 1'b0;
                    b_to_a_isolate <= 1'b0;
                    b_to_a_clear   <= 1'b0;
                    b_to_a_release <= 1'b0;
                end
            endcase
        end
    end

    // Synchronizers: A-to-B signals in B domain
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            a_to_b_isolate_sync  <= {SYNC_STAGES{1'b0}};
            a_to_b_clear_sync    <= {SYNC_STAGES{1'b0}};
            a_to_b_release_sync  <= {SYNC_STAGES{1'b0}};
        end else begin
            a_to_b_isolate_sync  <= {a_to_b_isolate_sync[SYNC_STAGES-2:0], a_to_b_isolate};
            a_to_b_clear_sync    <= {a_to_b_clear_sync[SYNC_STAGES-2:0], a_to_b_clear};
            a_to_b_release_sync  <= {a_to_b_release_sync[SYNC_STAGES-2:0], a_to_b_release};
        end
    end

    // Synchronizers: B-to-A signals in A domain
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            b_to_a_isolate_sync  <= {SYNC_STAGES{1'b0}};
            b_to_a_clear_sync    <= {SYNC_STAGES{1'b0}};
            b_to_a_release_sync  <= {SYNC_STAGES{1'b0}};
        end else begin
            b_to_a_isolate_sync  <= {b_to_a_isolate_sync[SYNC_STAGES-2:0], b_to_a_isolate};
            b_to_a_clear_sync    <= {b_to_a_clear_sync[SYNC_STAGES-2:0], b_to_a_clear};
            b_to_a_release_sync  <= {b_to_a_release_sync[SYNC_STAGES-2:0], b_to_a_release};
        end
    end

endmodule
