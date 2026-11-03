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
    reg  a_clear_req;
    reg  a_isolate_req;
    reg  b_clear_req;
    reg  b_isolate_req;
    wire a_clear_req_sync;
    wire a_isolate_req_sync;
    wire b_clear_req_sync;
    wire b_isolate_req_sync;

    // Instantiate domain_crosser for a to b
    domain_crosser #(
        .SYNC_STAGES(SYNC_STAGES)
    ) a2b_crosser (
        .local_clk(a_clk_i),
        .local_rst_ni(a_rst_ni),
        .remote_clk(b_clk_i),
        .remote_rst_ni(b_rst_ni),
        .local(a_clear_i),
        .remote(b_clear_req),
        .remote_ack(b_clear_ack_i),
        .local_ack(a_clear_ack_i)
    );

    domain_crosser #(
        .SYNC_STAGES(SYNC_STAGES)
    ) a2b_isolate_crosser (
        .local_clk(a_clk_i),
        .local_rst_ni(a_rst_ni),
        .remote_clk(b_clk_i),
        .remote_rst_ni(b_rst_ni),
        .local(a_isolate_o),
        .remote(b_isolate_req),
        .remote_ack(b_isolate_ack_i),
        .local_ack(a_isolate_ack_i)
    );

    // Instantiate domain_crosser for b to a
    domain_crosser #(
        .SYNC_STAGES(SYNC_STAGES)
    ) b2a_crosser (
        .local_clk(b_clk_i),
        .local_rst_ni(b_rst_ni),
        .remote_clk(a_clk_i),
        .remote_rst_ni(a_rst_ni),
        .local(b_clear_i),
        .remote(a_clear_req),
        .remote_ack(a_clear_ack_i),
        .local_ack(b_clear_ack_i)
    );

    domain_crosser #(
        .SYNC_STAGES(SYNC_STAGES)
    ) b2a_isolate_crosser (
        .local_clk(b_clk_i),
        .local_rst_ni(b_rst_ni),
        .remote_clk(a_clk_i),
        .remote_rst_ni(a_rst_ni),
        .local(b_isolate_o),
        .remote(a_isolate_req),
        .remote_ack(a_isolate_ack_i),
        .local_ack(b_isolate_ack_i)
    );

    // Synchronize requests from domain a to b
    domain_crosser #(
        .SYNC_STAGES(SYNC_STAGES)
    ) a2b_clear_req_sync_crosser (
        .local_clk(a_clk_i),
        .local_rst_ni(a_rst_ni),
        .remote_clk(b_clk_i),
        .remote_rst_ni(b_rst_ni),
        .local(a_clear_req),
        .remote(a_clear_req_sync),
        .remote_ack(1'b1),
        .local_ack()
    );

    domain_crosser #(
        .SYNC_STAGES(SYNC_STAGES)
    ) a2b_isolate_req_sync_crosser (
        .local_clk(a_clk_i),
        .local_rst_ni(a_rst_ni),
        .remote_clk(b_clk_i),
        .remote_rst_ni(b_rst_ni),
        .local(a_isolate_req),
        .remote(a_isolate_req_sync),
        .remote_ack(1'b1),
        .local_ack()
    );

    // Synchronize requests from domain b to a
    domain_crosser #(
        .SYNC_STAGES(SYNC_STAGES)
    ) b2a_clear_req_sync_crosser (
        .local_clk(b_clk_i),
        .local_rst_ni(b_rst_ni),
        .remote_clk(a_clk_i),
        .remote_rst_ni(a_rst_ni),
        .local(b_clear_req),
        .remote(b_clear_req_sync),
        .remote_ack(1'b1),
        .local_ack()
    );

    domain_crosser #(
        .SYNC_STAGES(SYNC_STAGES)
    ) b2a_isolate_req_sync_crosser (
        .local_clk(b_clk_i),
        .local_rst_ni(b_rst_ni),
        .remote_clk(a_clk_i),
        .remote_rst_ni(a_rst_ni),
        .local(b_isolate_req),
        .remote(b_isolate_req_sync),
        .remote_ack(1'b1),
        .local_ack()
    );

    // State machine for domain a
    typedef enum reg [2:0] {
        IDLE_A = 3'b000,
        ISOLATE_A = 3'b001,
        CLEAR_A = 3'b010,
        RELEASE_CLEAR_A = 3'b011,
        RELEASE_ISOLATE_A = 3'b100
    } state_a_t;

    state_a_t state_a, next_state_a;

    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            state_a <= IDLE_A;
        end else begin
            state_a <= next_state_a;
        end
    end

    always @(*) begin
        next_state_a = state_a;

        case (state_a)
            IDLE_A: begin
                if (a_clear_req_sync) begin
                    next_state_a = ISOLATE_A;
                end
            end
            ISOLATE_A: begin
                if (a_isolate_ack_i) begin
                    next_state_a = CLEAR_A;
                end
            end
            CLEAR_A: begin
                if (a_clear_ack_i) begin
                    next_state_a = RELEASE_CLEAR_A;
                end
            end
            RELEASE_CLEAR_A: begin
                next_state_a = RELEASE_ISOLATE_A;
            end
            RELEASE_ISOLATE_A: begin
                next_state_a = IDLE_A;
            end
            default: begin
                next_state_a = IDLE_A;
            end
        endcase
    end

    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate_o <= 1'b0;
            a_clear_o <= 1'b0;
        end else begin
            case (state_a)
                ISOLATE_A: begin
                    a_isolate_o <= 1'b1;
                end
                CLEAR_A: begin
                    a_clear_o <= 1'b1;
                end
                RELEASE_CLEAR_A: begin
                    a_clear_o <= 1'b0;
                end
                RELEASE_ISOLATE_A: begin
                    a_isolate_o <= 1'b0;
                end
            endcase
        end
    end

    // State machine for domain b
    typedef enum reg [2:0] {
        IDLE_B = 3'b000,
        ISOLATE_B = 3'b001,
        CLEAR_B = 3'b010,
        RELEASE_CLEAR_B = 3'b011,
        RELEASE_ISOLATE_B = 3'b100
    } state_b_t;

    state_b_t state_b, next_state_b;

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            state_b <= IDLE_B;
        end else begin
            state_b <= next_state_b;
        end
    end

    always @(*) begin
        next_state_b = state_b;

        case (state_b)
            IDLE_B: begin
                if (b_clear_req_sync) begin
                    next_state_b = ISOLATE_B;
                end
            end
            ISOLATE_B: begin
                if (b_isolate_ack_i) begin
                    next_state_b = CLEAR_B;
                end
            end
            CLEAR_B: begin
                if (b_clear_ack_i) begin
                    next_state_b = RELEASE_CLEAR_B;
                end
            end
            RELEASE_CLEAR_B: begin
                next_state_b = RELEASE_ISOLATE_B;
            end
            RELEASE_ISOLATE_B: begin
                next_state_b = IDLE_B;
            end
            default: begin
                next_state_b = IDLE_B;
            end
        endcase
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate_o <= 1'b0;
            b_clear_o <= 1'b0;
        end else begin
            case (state_b)
                ISOLATE_B: begin
                    b_isolate_o <= 1'b1;
                end
                CLEAR_B: begin
                    b_clear_o <= 1'b1;
                end
                RELEASE_CLEAR_B: begin
                    b_clear_o <= 1'b0;
                end
                RELEASE_ISOLATE_B: begin
                    b_isolate_o <= 1'b0;
                end
            endcase
        end
    end

endmodule

module domain_crosser #(
    parameter SYNC_STAGES = 2
)(
    input  local_clk,
    input  local_rst_ni,
    input  remote_clk,
    input  remote_rst_ni,
    input  local,
    output remote,
    input  remote_ack,
    output local_ack
);

    reg [SYNC_STAGES-1:0] sync_chain;

    // Synchronize the local signal to the remote clock domain
    always @(posedge remote_clk or negedge remote_rst_ni) begin
        if (!remote_rst_ni) begin
            sync_chain <= {SYNC_STAGES{1'b0}};
        end else begin
            sync_chain <= {sync_chain[SYNC_STAGES-2:0], local};
        end
    end

    // Assign the synchronized signal to the remote output
    assign remote = sync_chain[SYNC_STAGES-1];

    // Generate local_ack to indicate successful synchronization of remote_ack
    reg [SYNC_STAGES-1:0] remote_ack_sync;

    always @(posedge local_clk or negedge local_rst_ni) begin
        if (!local_rst_ni) begin
            remote_ack_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            remote_ack_sync <= {remote_ack_sync[SYNC_STAGES-2:0], remote_ack};
        end
    end

    assign local_ack = remote_ack_sync[SYNC_STAGES-1];

endmodule
