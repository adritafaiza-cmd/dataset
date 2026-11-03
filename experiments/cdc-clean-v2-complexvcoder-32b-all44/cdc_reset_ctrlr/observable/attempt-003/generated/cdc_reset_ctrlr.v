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

    // Internal signals for state management
    reg a_isolate_req, a_clear_req, a_isolate_done, a_clear_done;
    reg b_isolate_req, b_clear_req, b_isolate_done, b_clear_done;

    // State machine states
    typedef enum logic [2:0] {
        IDLE,
        ISOLATE,
        WAIT_ISOLATE_ACK,
        CLEAR,
        WAIT_CLEAR_ACK,
        RELEASE,
        WAIT_RELEASE_ACK
    } state_t;

    state_t a_state, a_next_state;
    state_t b_state, b_next_state;

    // State machine for domain A
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_state <= IDLE;
        end else begin
            a_state <= a_next_state;
        end
    end

    always @(*) begin
        a_next_state = a_state;
        a_isolate_req = 0;
        a_clear_req = 0;
        a_isolate_done = 0;
        a_clear_done = 0;

        case (a_state)
            IDLE: begin
                if (a_clear_i) begin
                    a_next_state = ISOLATE;
                end
            end
            ISOLATE: begin
                a_isolate_req = 1;
                a_next_state = WAIT_ISOLATE_ACK;
            end
            WAIT_ISOLATE_ACK: begin
                if (a_isolate_ack_i) begin
                    a_isolate_done = 1;
                    a_next_state = CLEAR;
                end
            end
            CLEAR: begin
                a_clear_req = 1;
                a_next_state = WAIT_CLEAR_ACK;
            end
            WAIT_CLEAR_ACK: begin
                if (a_clear_ack_i) begin
                    a_clear_done = 1;
                    a_next_state = RELEASE;
                end
            end
            RELEASE: begin
                a_next_state = WAIT_RELEASE_ACK;
            end
            WAIT_RELEASE_ACK: begin
                if (b_isolate_ack_i) begin // Assuming b_isolate_ack_i is used as the release ack
                    a_next_state = IDLE;
                end
            end
        endcase
    end

    // State machine for domain B
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_state <= IDLE;
        end else begin
            b_state <= b_next_state;
        end
    end

    always @(*) begin
        b_next_state = b_state;
        b_isolate_req = 0;
        b_clear_req = 0;
        b_isolate_done = 0;
        b_clear_done = 0;

        case (b_state)
            IDLE: begin
                if (b_clear_i) begin
                    b_next_state = ISOLATE;
                end
            end
            ISOLATE: begin
                b_isolate_req = 1;
                b_next_state = WAIT_ISOLATE_ACK;
            end
            WAIT_ISOLATE_ACK: begin
                if (b_isolate_ack_i) begin
                    b_isolate_done = 1;
                    b_next_state = CLEAR;
                end
            end
            CLEAR: begin
                b_clear_req = 1;
                b_next_state = WAIT_CLEAR_ACK;
            end
            WAIT_CLEAR_ACK: begin
                if (b_clear_ack_i) begin
                    b_clear_done = 1;
                    b_next_state = RELEASE;
                end
            end
            RELEASE: begin
                b_next_state = WAIT_RELEASE_ACK;
            end
            WAIT_RELEASE_ACK: begin
                if (a_isolate_ack_i) begin // Assuming a_isolate_ack_i is used as the release ack
                    b_next_state = IDLE;
                end
            end
        endcase
    end

    // CDC handshake instances
    cdc_handshake #(.SYNC_STAGES(SYNC_STAGES)) a_to_b_handshake (
        .local(a_isolate_req),
        .remote(b_isolate_o),
        .local_ack(a_isolate_ack_i),
        .remote_ack(b_isolate_ack_i),
        .local_clk(a_clk_i),
        .remote_clk(b_clk_i),
        .local_rst_ni(a_rst_ni),
        .remote_rst_ni(b_rst_ni)
    );

    cdc_handshake #(.SYNC_STAGES(SYNC_STAGES)) b_to_a_handshake (
        .local(b_isolate_req),
        .remote(a_isolate_o),
        .local_ack(b_isolate_ack_i),
        .remote_ack(a_isolate_ack_i),
        .local_clk(b_clk_i),
        .remote_clk(a_clk_i),
        .local_rst_ni(b_rst_ni),
        .remote_rst_ni(a_rst_ni)
    );

    cdc_handshake #(.SYNC_STAGES(SYNC_STAGES)) a_to_b_clear_handshake (
        .local(a_clear_req),
        .remote(b_clear_o),
        .local_ack(a_clear_ack_i),
        .remote_ack(b_clear_ack_i),
        .local_clk(a_clk_i),
        .remote_clk(b_clk_i),
        .local_rst_ni(a_rst_ni),
        .remote_rst_ni(b_rst_ni)
    );

    cdc_handshake #(.SYNC_STAGES(SYNC_STAGES)) b_to_a_clear_handshake (
        .local(b_clear_req),
        .remote(a_clear_o),
        .local_ack(b_clear_ack_i),
        .remote_ack(a_clear_ack_i),
        .local_clk(b_clk_i),
        .remote_clk(a_clk_i),
        .local_rst_ni(b_rst_ni),
        .remote_rst_ni(a_rst_ni)
    );

endmodule

module cdc_handshake #(
    parameter SYNC_STAGES = 2
)(
    input  local,
    output remote,
    output local_ack,
    input  remote_ack,
    input  local_clk,
    input  remote_clk,
    input  local_rst_ni,
    input  remote_rst_ni
);

    reg [SYNC_STAGES:0] sync_ffs;

    // Synchronize local signal to remote clock domain
    always @(posedge remote_clk or negedge remote_rst_ni) begin
        if (!remote_rst_ni) begin
            sync_ffs <= 0;
        end else begin
            sync_ffs <= {sync_ffs[SYNC_STAGES-1:0], local};
        end
    end

    assign remote = sync_ffs[SYNC_STAGES];

    // Acknowledge the remote signal in the local clock domain
    reg remote_ack_sync;

    always @(posedge local_clk or negedge local_rst_ni) begin
        if (!local_rst_ni) begin
            remote_ack_sync <= 0;
        end else begin
            remote_ack_sync <= remote_ack;
        end
    end

    assign local_ack = remote_ack_sync;

endmodule
