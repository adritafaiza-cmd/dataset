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

    // CDC Handshake module
    module cdc_handshake #(
        parameter SYNC_STAGES = 2
    )(
        input  clk_i,
        input  rst_ni,
        input  local,
        output remote,
        input  local_ack,
        output remote_ack
    );
        reg [SYNC_STAGES-1:0] sync_ffs;
        reg                   remote_reg;
        reg                   remote_ack_reg;

        always @(posedge clk_i or negedge rst_ni) begin
            if (!rst_ni) begin
                sync_ffs <= {SYNC_STAGES{1'b0}};
                remote_reg <= 1'b0;
                remote_ack_reg <= 1'b0;
            end else begin
                sync_ffs <= {sync_ffs[SYNC_STAGES-2:0], local};
                remote_reg <= sync_ffs[SYNC_STAGES-1];
                remote_ack_reg <= local_ack;
            end
        end

        assign remote = remote_reg;
        assign remote_ack = remote_ack_reg;
    endmodule

    // Reset control logic module
    module reset_control_logic (
        input  clk_i,
        input  rst_ni,
        input  clear_i,
        output isolate_o,
        input  isolate_ack_i,
        output clear_o,
        input  clear_ack_i,
        input  peer_isolate_i,
        output peer_isolate_ack_o,
        input  peer_clear_i,
        output peer_clear_ack_o
    );
        typedef enum logic [2:0] {
            IDLE = 3'b000,
            ISOLATE_LOCAL = 3'b001,
            WAIT_ISOLATE_LOCAL_ACK = 3'b010,
            ISOLATE_PEER = 3'b011,
            WAIT_ISOLATE_PEER_ACK = 3'b100,
            CLEAR_LOCAL = 3'b101,
            WAIT_CLEAR_LOCAL_ACK = 3'b110,
            CLEAR_PEER = 3'b111,
            WAIT_CLEAR_PEER_ACK = 4'b0000,
            RELEASE_LOCAL = 4'b0001,
            WAIT_RELEASE_LOCAL_ACK = 4'b0010,
            RELEASE_PEER = 4'b0011,
            WAIT_RELEASE_PEER_ACK = 4'b0100
        } state_t;

        state_t state, next_state;

        always @(posedge clk_i or negedge rst_ni) begin
            if (!rst_ni) begin
                state <= IDLE;
            end else begin
                state <= next_state;
            end
        end

        always @(*) begin
            next_state = state;
            isolate_o = 1'b0;
            clear_o = 1'b0;
            peer_isolate_ack_o = 1'b0;
            peer_clear_ack_o = 1'b0;

            case (state)
                IDLE: begin
                    if (clear_i) begin
                        next_state = ISOLATE_LOCAL;
                    end
                end
                ISOLATE_LOCAL: begin
                    isolate_o = 1'b1;
                    next_state = WAIT_ISOLATE_LOCAL_ACK;
                end
                WAIT_ISOLATE_LOCAL_ACK: begin
                    if (isolate_ack_i) begin
                        next_state = ISOLATE_PEER;
                    end
                end
                ISOLATE_PEER: begin
                    peer_isolate_ack_o = 1'b1;
                    next_state = WAIT_ISOLATE_PEER_ACK;
                end
                WAIT_ISOLATE_PEER_ACK: begin
                    if (peer_isolate_i) begin
                        next_state = CLEAR_LOCAL;
                    end
                end
                CLEAR_LOCAL: begin
                    clear_o = 1'b1;
                    next_state = WAIT_CLEAR_LOCAL_ACK;
                end
                WAIT_CLEAR_LOCAL_ACK: begin
                    if (clear_ack_i) begin
                        next_state = CLEAR_PEER;
                    end
                end
                CLEAR_PEER: begin
                    peer_clear_ack_o = 1'b1;
                    next_state = WAIT_CLEAR_PEER_ACK;
                end
                WAIT_CLEAR_PEER_ACK: begin
                    if (peer_clear_i) begin
                        next_state = RELEASE_LOCAL;
                    end
                end
                RELEASE_LOCAL: begin
                    isolate_o = 1'b0;
                    clear_o = 1'b0;
                    next_state = WAIT_RELEASE_LOCAL_ACK;
                end
                WAIT_RELEASE_LOCAL_ACK: begin
                    if (isolate_ack_i) begin
                        next_state = RELEASE_PEER;
                    end
                end
                RELEASE_PEER: begin
                    peer_isolate_ack_o = 1'b0;
                    next_state = WAIT_RELEASE_PEER_ACK;
                end
                WAIT_RELEASE_PEER_ACK: begin
                    if (peer_isolate_i) begin
                        next_state = IDLE;
                    end
                end
                default: begin
                    next_state = IDLE;
                end
            endcase
        end
    endmodule

    // Instantiate CDC handshakes
    cdc_handshake #(.SYNC_STAGES(SYNC_STAGES)) a_to_b_isolate_handshake (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .local(a_isolate_o),
        .remote(b_isolate_i),
        .local_ack(a_isolate_ack_i),
        .remote_ack(b_isolate_ack_o)
    );

    cdc_handshake #(.SYNC_STAGES(SYNC_STAGES)) b_to_a_isolate_handshake (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .local(b_isolate_o),
        .remote(a_isolate_i),
        .local_ack(b_isolate_ack_i),
        .remote_ack(a_isolate_ack_o)
    );

    cdc_handshake #(.SYNC_STAGES(SYNC_STAGES)) a_to_b_clear_handshake (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .local(a_clear_o),
        .remote(b_clear_i),
        .local_ack(a_clear_ack_i),
        .remote_ack(b_clear_ack_o)
    );

    cdc_handshake #(.SYNC_STAGES(SYNC_STAGES)) b_to_a_clear_handshake (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .local(b_clear_o),
        .remote(a_clear_i),
        .local_ack(b_clear_ack_i),
        .remote_ack(a_clear_ack_o)
    );

    // Instantiate reset control logic
    reset_control_logic a_reset_control (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .clear_i(a_clear_i),
        .isolate_o(a_isolate_o),
        .isolate_ack_i(a_isolate_ack_i),
        .clear_o(a_clear_o),
        .clear_ack_i(a_clear_ack_i),
        .peer_isolate_i(b_isolate_o),
        .peer_isolate_ack_o(b_isolate_ack_i),
        .peer_clear_i(b_clear_o),
        .peer_clear_ack_o(b_clear_ack_i)
    );

    reset_control_logic b_reset_control (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .clear_i(b_clear_i),
        .isolate_o(b_isolate_o),
        .isolate_ack_i(b_isolate_ack_i),
        .clear_o(b_clear_o),
        .clear_ack_i(b_clear_ack_i),
        .peer_isolate_i(a_isolate_o),
        .peer_isolate_ack_o(a_isolate_ack_i),
        .peer_clear_i(a_clear_o),
        .peer_clear_ack_o(a_clear_ack_i)
    );

endmodule
