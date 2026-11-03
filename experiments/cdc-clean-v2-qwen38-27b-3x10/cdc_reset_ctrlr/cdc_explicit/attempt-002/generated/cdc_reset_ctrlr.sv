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
    localparam S_IDLE       = 4'd0;
    localparam S_ISOLATE    = 4'd1;
    localparam S_ISOLATE_W  = 4'd2;
    localparam S_CLEAR      = 4'd3;
    localparam S_CLEAR_W    = 4'd4;
    localparam S_RELEASE    = 4'd5;
    localparam S_RELEASE_W  = 4'd6;

    // A-side state
    reg [3:0] a_state;
    reg       a_isolate_o_r;
    reg       a_clear_o_r;

    // B-side state
    reg [3:0] b_state;
    reg       b_isolate_o_r;
    reg       b_clear_o_r;

    // A-side: synchronized B-side status
    // We need to know B's state to coordinate. 
    // The protocol requires that we wait for peer acks.
    // Let's define the handshake signals that cross domains.
    
    // A tells B: "I am isolating" -> b_isolate_req
    // B tells A: "I am isolating" -> a_isolate_req
    // A tells B: "I am clearing"   -> b_clear_req
    // B tells A: "I am clearing"   -> a_clear_req
    // A tells B: "I am releasing"  -> b_release_req
    // B tells A: "I am releasing"  -> a_release_req

    // Actually, let's simplify. The behavior says:
    // 1. Either side requests clear.
    // 2. First raise both isolate outputs.
    // 3. Wait for both isolate acks.
    // 4. Raise both clear outputs.
    // 5. Wait for both clear acks.
    // 6. Release isolate and clear.

    // This implies a coordinated sequence. Let's use a master-slave or symmetric approach.
    // Since both sides can initiate, we need a symmetric protocol.
    
    // Let's define the crossing signals:
    // a_to_b_isolate: A is in isolate state
    // b_to_a_isolate: B is in isolate state
    // a_to_b_clear:   A is in clear state
    // b_to_a_clear:   B is in clear state
    // a_to_b_release: A is in release state
    // b_to_a_release: B is in release state

    // But we need to ensure that both sides are in the same phase.
    // Let's use a simpler approach: 
    // Each side has a local state machine.
    // The state machine transitions are gated by the peer's synchronized status.

    // Let's define the synchronized peer status for each side.
    // For A side, we need to know B's state.
    // For B side, we need to know A's state.

    // We'll use 2-bit status to encode the phase:
    // 00: IDLE
    // 01: ISOLATE
    // 10: CLEAR
    // 11: RELEASE

    // A-side: synchronized B status
    reg [1:0] b_status_sync_a;
    reg [1:0] b_status_sync_a_d1;
    reg [1:0] b_status_sync_a_d2;

    // B-side: synchronized A status
    reg [1:0] a_status_sync_b;
    reg [1:0] a_status_sync_b_d1;
    reg [1:0] a_status_sync_b_d2;

    // A-side: local status to send to B
    reg [1:0] a_status_to_b;
    // B-side: local status to send to A
    reg [1:0] b_status_to_a;

    // Synchronize a_status_to_b into B domain
    // Synchronize b_status_to_a into A domain

    // A domain: sync b_status_to_a
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            b_status_sync_a_d1 <= 2'b00;
            b_status_sync_a_d2 <= 2'b00;
            b_status_sync_a    <= 2'b00;
        end else begin
            b_status_sync_a_d1 <= b_status_to_a;
            b_status_sync_a_d2 <= b_status_sync_a_d1;
            b_status_sync_a    <= b_status_sync_a_d2;
        end
    end

    // B domain: sync a_status_to_b
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            a_status_sync_b_d1 <= 2'b00;
            a_status_sync_b_d2 <= 2'b00;
            a_status_sync_b    <= 2'b00;
        end else begin
            a_status_sync_b_d1 <= a_status_to_b;
            a_status_sync_b_d2 <= a_status_sync_b_d1;
            a_status_sync_b    <= a_status_sync_b_d2;
        end
    end

    // A-side state machine
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_state       <= S_IDLE;
            a_isolate_o_r <= 1'b0;
            a_clear_o_r   <= 1'b0;
            a_status_to_b <= 2'b00;
        end else begin
            case (a_state)
                S_IDLE: begin
                    a_isolate_o_r <= 1'b0;
                    a_clear_o_r   <= 1'b0;
                    a_status_to_b <= 2'b00;
                    if (a_clear_i) begin
                        a_state <= S_ISOLATE;
                    end
                end
                S_ISOLATE: begin
                    a_isolate_o_r <= 1'b1;
                    a_clear_o_r   <= 1'b0;
                    a_status_to_b <= 2'b01;
                    // Wait for local isolate ack and peer isolate ack
                    if (a_isolate_ack_i && (b_status_sync_a == 2'b01)) begin
                        a_state <= S_ISOLATE_W;
                    end
                end
                S_ISOLATE_W: begin
                    a_isolate_o_r <= 1'b1;
                    a_clear_o_r   <= 1'b0;
                    a_status_to_b <= 2'b01;
                    // Wait for peer to also be in isolate state (already checked)
                    // Actually, we need to wait for peer to acknowledge our isolate
                    // The peer will see our status and transition to isolate
                    // Let's wait for peer to be in isolate state
                    if (b_status_sync_a == 2'b01) begin
                        a_state <= S_CLEAR;
                    end
                end
                S_CLEAR: begin
                    a_isolate_o_r <= 1'b1;
                    a_clear_o_r   <= 1'b1;
                    a_status_to_b <= 2'b10;
                    // Wait for local clear ack and peer clear ack
                    if (a_clear_ack_i && (b_status_sync_a == 2'b10)) begin
                        a_state <= S_CLEAR_W;
                    end
                end
                S_CLEAR_W: begin
                    a_isolate_o_r <= 1'b1;
                    a_clear_o_r   <= 1'b1;
                    a_status_to_b <= 2'b10;
                    // Wait for peer to be in clear state
                    if (b_status_sync_a == 2'b10) begin
                        a_state <= S_RELEASE;
                    end
                end
                S_RELEASE: begin
                    a_isolate_o_r <= 1'b0;
                    a_clear_o_r   <= 1'b0;
                    a_status_to_b <= 2'b11;
                    // Wait for peer to be in release state
                    if (b_status_sync_a == 2'b11) begin
                        a_state <= S_RELEASE_W;
                    end
                end
                S_RELEASE_W: begin
                    a_isolate_o_r <= 1'b0;
                    a_clear_o_r   <= 1'b0;
                    a_status_to_b <= 2'b00;
                    // Wait for peer to be back in idle
                    if (b_status_sync_a == 2'b00) begin
                        a_state <= S_IDLE;
                    end
                end
                default: begin
                    a_state       <= S_IDLE;
                    a_isolate_o_r <= 1'b0;
                    a_clear_o_r   <= 1'b0;
                    a_status_to_b <= 2'b00;
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
            b_status_to_a <= 2'b00;
        end else begin
            case (b_state)
                S_IDLE: begin
                    b_isolate_o_r <= 1'b0;
                    b_clear_o_r   <= 1'b0;
                    b_status_to_a <= 2'b00;
                    if (b_clear_i) begin
                        b_state <= S_ISOLATE;
                    end
                end
                S_ISOLATE: begin
                    b_isolate_o_r <= 1'b1;
                    b_clear_o_r   <= 1'b0;
                    b_status_to_a <= 2'b01;
                    if (b_isolate_ack_i && (a_status_sync_b == 2'b01)) begin
                        b_state <= S_ISOLATE_W;
                    end
                end
                S_ISOLATE_W: begin
                    b_isolate_o_r <= 1'b1;
                    b_clear_o_r   <= 1'b0;
                    b_status_to_a <= 2'b01;
                    if (a_status_sync_b == 2'b01) begin
                        b_state <= S_CLEAR;
                    end
                end
                S_CLEAR: begin
                    b_isolate_o_r <= 1'b1;
                    b_clear_o_r   <= 1'b1;
                    b_status_to_a <= 2'b10;
                    if (b_clear_ack_i && (a_status_sync_b == 2'b10)) begin
                        b_state <= S_CLEAR_W;
                    end
                end
                S_CLEAR_W: begin
                    b_isolate_o_r <= 1'b1;
                    b_clear_o_r   <= 1'b1;
                    b_status_to_a <= 2'b10;
                    if (a_status_sync_b == 2'b10) begin
                        b_state <= S_RELEASE;
                    end
                end
                S_RELEASE: begin
                    b_isolate_o_r <= 1'b0;
                    b_clear_o_r   <= 1'b0;
                    b_status_to_a <= 2'b11;
                    if (a_status_sync_b == 2'b11) begin
                        b_state <= S_RELEASE_W;
                    end
                end
                S_RELEASE_W: begin
                    b_isolate_o_r <= 1'b0;
                    b_clear_o_r   <= 1'b0;
                    b_status_to_a <= 2'b00;
                    if (a_status_sync_b == 2'b00) begin
                        b_state <= S_IDLE;
                    end
                end
                default: begin
                    b_state       <= S_IDLE;
                    b_isolate_o_r <= 1'b0;
                    b_clear_o_r   <= 1'b0;
                    b_status_to_a <= 2'b00;
                end
            endcase
        end
    end

    assign a_isolate_o = a_isolate_o_r;
    assign a_clear_o   = a_clear_o_r;
    assign b_isolate_o = b_isolate_o_r;
    assign b_clear_o   = b_clear_o_r;

endmodule
