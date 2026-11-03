module cdc_reset_ctrlr #(
    parameter SYNC_STAGES = 2
)(
    input  a_clk_i,
    input  a_rst_ni,
    input  a_clear_i,
    output reg a_clear_o,
    input  a_clear_ack_i,
    output reg a_isolate_o,
    input  a_isolate_ack_i,
    input  b_clk_i,
    input  b_rst_ni,
    input  b_clear_i,
    output reg b_clear_o,
    input  b_clear_ack_i,
    output reg b_isolate_o,
    input  b_isolate_ack_i
);

    // Internal signals for CDC handshakes
    reg [SYNC_STAGES-1:0] a_to_b_isolate_req_sync;
    reg [SYNC_STAGES-1:0] a_to_b_isolate_ack_sync;
    reg [SYNC_STAGES-1:0] b_to_a_isolate_req_sync;
    reg [SYNC_STAGES-1:0] b_to_a_isolate_ack_sync;
    reg [SYNC_STAGES-1:0] a_to_b_clear_req_sync;
    reg [SYNC_STAGES-1:0] a_to_b_clear_ack_sync;
    reg [SYNC_STAGES-1:0] b_to_a_clear_req_sync;
    reg [SYNC_STAGES-1:0] b_to_a_clear_ack_sync;
    reg [SYNC_STAGES-1:0] a_to_b_isolate_rel_sync;
    reg [SYNC_STAGES-1:0] a_to_b_isolate_rel_ack_sync;
    reg [SYNC_STAGES-1:0] b_to_a_isolate_rel_sync;
    reg [SYNC_STAGES-1:0] b_to_a_isolate_rel_ack_sync;
    reg [SYNC_STAGES-1:0] a_to_b_clear_rel_sync;
    reg [SYNC_STAGES-1:0] a_to_b_clear_rel_ack_sync;
    reg [SYNC_STAGES-1:0] b_to_a_clear_rel_sync;
    reg [SYNC_STAGES-1:0] b_to_a_clear_rel_ack_sync;

    // Control states
    typedef enum reg [2:0] {
        IDLE,
        ISOLATE_REQUEST,
        WAIT_ISOLATE_ACK,
        CLEAR_REQUEST,
        WAIT_CLEAR_ACK,
        CLEAR_RELEASE,
        WAIT_CLEAR_REL_ACK,
        ISOLATE_RELEASE,
        WAIT_ISOLATE_REL_ACK
    } state_t;

    state_t a_state, a_next_state;
    state_t b_state, b_next_state;

    // CDC Handshake synchronization
    cdc_handshake #(.SYNC_STAGES(SYNC_STAGES))
    a_to_b_isolate_req (
        .clk_src(a_clk_i),
        .rst_src_ni(a_rst_ni),
        .req(a_isolate_o),
        .ack(a_isolate_ack_i),
        .clk_dst(b_clk_i),
        .rst_dst_ni(b_rst_ni),
        .req_sync(a_to_b_isolate_req_sync)
    );

    cdc_handshake #(.SYNC_STAGES(SYNC_STAGES))
    a_to_b_isolate_ack (
        .clk_src(b_clk_i),
        .rst_src_ni(b_rst_ni),
        .req(a_to_b_isolate_ack_sync[0]),
        .ack(a_isolate_ack_i),
        .clk_dst(a_clk_i),
        .rst_dst_ni(a_rst_ni),
        .ack_sync(a_to_b_isolate_ack_sync[SYNC_STAGES-1])
    );

    cdc_handshake #(.SYNC_STAGES(SYNC_STAGES))
    b_to_a_isolate_req (
        .clk_src(b_clk_i),
        .rst_src_ni(b_rst_ni),
        .req(b_isolate_o),
        .ack(b_isolate_ack_i),
        .clk_dst(a_clk_i),
        .rst_dst_ni(a_rst_ni),
        .req_sync(b_to_a_isolate_req_sync)
    );

    cdc_handshake #(.SYNC_STAGES(SYNC_STAGES))
    b_to_a_isolate_ack (
        .clk_src(a_clk_i),
        .rst_src_ni(a_rst_ni),
        .req(b_to_a_isolate_ack_sync[0]),
        .ack(b_isolate_ack_i),
        .clk_dst(b_clk_i),
        .rst_dst_ni(b_rst_ni),
        .ack_sync(b_to_a_isolate_ack_sync[SYNC_STAGES-1])
    );

    cdc_handshake #(.SYNC_STAGES(SYNC_STAGES))
    a_to_b_clear_req (
        .clk_src(a_clk_i),
        .rst_src_ni(a_rst_ni),
        .req(a_clear_o),
        .ack(a_clear_ack_i),
        .clk_dst(b_clk_i),
        .rst_dst_ni(b_rst_ni),
        .req_sync(a_to_b_clear_req_sync)
    );

    cdc_handshake #(.SYNC_STAGES(SYNC_STAGES))
    a_to_b_clear_ack (
        .clk_src(b_clk_i),
        .rst_src_ni(b_rst_ni),
        .req(a_to_b_clear_ack_sync[0]),
        .ack(a_clear_ack_i),
        .clk_dst(a_clk_i),
        .rst_dst_ni(a_rst_ni),
        .ack_sync(a_to_b_clear_ack_sync[SYNC_STAGES-1])
    );

    cdc_handshake #(.SYNC_STAGES(SYNC_STAGES))
    b_to_a_clear_req (
        .clk_src(b_clk_i),
        .rst_src_ni(b_rst_ni),
        .req(b_clear_o),
        .ack(b_clear_ack_i),
        .clk_dst(a_clk_i),
        .rst_dst_ni(a_rst_ni),
        .req_sync(b_to_a_clear_req_sync)
    );

    cdc_handshake #(.SYNC_STAGES(SYNC_STAGES))
    b_to_a_clear_ack (
        .clk_src(a_clk_i),
        .rst_src_ni(a_rst_ni),
        .req(b_to_a_clear_ack_sync[0]),
        .ack(b_clear_ack_i),
        .clk_dst(b_clk_i),
        .rst_dst_ni(b_rst_ni),
        .ack_sync(b_to_a_clear_ack_sync[SYNC_STAGES-1])
    );

    cdc_handshake #(.SYNC_STAGES(SYNC_STAGES))
    a_to_b_isolate_rel (
        .clk_src(a_clk_i),
        .rst_src_ni(a_rst_ni),
        .req(a_to_b_isolate_rel_sync[0]),
        .ack(a_to_b_isolate_rel_ack_sync[SYNC_STAGES-1]),
        .clk_dst(b_clk_i),
        .rst_dst_ni(b_rst_ni),
        .req_sync(a_to_b_isolate_rel_sync[SYNC_STAGES-1])
    );

    cdc_handshake #(.SYNC_STAGES(SYNC_STAGES))
    a_to_b_isolate_rel_ack (
        .clk_src(b_clk_i),
        .rst_src_ni(b_rst_ni),
        .req(a_to_b_isolate_rel_ack_sync[0]),
        .ack(a_to_b_isolate_rel_ack_sync[SYNC_STAGES-1]),
        .clk_dst(a_clk_i),
        .rst_dst_ni(a_rst_ni),
        .ack_sync(a_to_b_isolate_rel_ack_sync[SYNC_STAGES-1])
    );

    cdc_handshake #(.SYNC_STAGES(SYNC_STAGES))
    b_to_a_isolate_rel (
        .clk_src(b_clk_i),
        .rst_src_ni(b_rst_ni),
        .req(b_to_a_isolate_rel_sync[0]),
        .ack(b_to_a_isolate_rel_ack_sync[SYNC_STAGES-1]),
        .clk_dst(a_clk_i),
        .rst_dst_ni(a_rst_ni),
        .req_sync(b_to_a_isolate_rel_sync[SYNC_STAGES-1])
    );

    cdc_handshake #(.SYNC_STAGES(SYNC_STAGES))
    b_to_a_isolate_rel_ack (
        .clk_src(a_clk_i),
        .rst_src_ni(a_rst_ni),
        .req(b_to_a_isolate_rel_ack_sync[0]),
        .ack(b_to_a_isolate_rel_ack_sync[SYNC_STAGES-1]),
        .clk_dst(b_clk_i),
        .rst_dst_ni(b_rst_ni),
        .ack_sync(b_to_a_isolate_rel_ack_sync[SYNC_STAGES-1])
    );

    cdc_handshake #(.SYNC_STAGES(SYNC_STAGES))
    a_to_b_clear_rel (
        .clk_src(a_clk_i),
        .rst_src_ni(a_rst_ni),
        .req(a_to_b_clear_rel_sync[0]),
        .ack(a_to_b_clear_rel_ack_sync[SYNC_STAGES-1]),
        .clk_dst(b_clk_i),
        .rst_dst_ni(b_rst_ni),
        .req_sync(a_to_b_clear_rel_sync[SYNC_STAGES-1])
    );

    cdc_handshake #(.SYNC_STAGES(SYNC_STAGES))
    a_to_b_clear_rel_ack (
        .clk_src(b_clk_i),
        .rst_src_ni(b_rst_ni),
        .req(a_to_b_clear_rel_ack_sync[0]),
        .ack(a_to_b_clear_rel_ack_sync[SYNC_STAGES-1]),
        .clk_dst(a_clk_i),
        .rst_dst_ni(a_rst_ni),
        .ack_sync(a_to_b_clear_rel_ack_sync[SYNC_STAGES-1])
    );

    cdc_handshake #(.SYNC_STAGES(SYNC_STAGES))
    b_to_a_clear_rel (
        .clk_src(b_clk_i),
        .rst_src_ni(b_rst_ni),
        .req(b_to_a_clear_rel_sync[0]),
        .ack(b_to_a_clear_rel_ack_sync[SYNC_STAGES-1]),
        .clk_dst(a_clk_i),
        .rst_dst_ni(a_rst_ni),
        .req_sync(b_to_a_clear_rel_sync[SYNC_STAGES-1])
    );

    cdc_handshake #(.SYNC_STAGES(SYNC_STAGES))
    b_to_a_clear_rel_ack (
        .clk_src(a_clk_i),
        .rst_src_ni(a_rst_ni),
        .req(b_to_a_clear_rel_ack_sync[0]),
        .ack(b_to_a_clear_rel_ack_sync[SYNC_STAGES-1]),
        .clk_dst(b_clk_i),
        .rst_dst_ni(b_rst_ni),
        .ack_sync(b_to_a_clear_rel_ack_sync[SYNC_STAGES-1])
    );

    // A-side state machine
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_state <= IDLE;
        end else begin
            a_state <= a_next_state;
        end
    end

    always @(*) begin
        a_next_state = a_state;
        a_isolate_o = 0;
        a_clear_o = 0;
        a_to_b_isolate_rel_sync[0] = 0;
        a_to_b_clear_rel_sync[0] = 0;

        case (a_state)
            IDLE: begin
                if (a_clear_i) begin
                    a_isolate_o = 1;
                    a_next_state = ISOLATE_REQUEST;
                end
            end
            ISOLATE_REQUEST: begin
                if (a_to_b_isolate_req_sync[SYNC_STAGES-1] && a_isolate_ack_i) begin
                    a_next_state = WAIT_ISOLATE_ACK;
                end
            end
            WAIT_ISOLATE_ACK: begin
                if (b_to_a_isolate_ack_sync[SYNC_STAGES-1]) begin
                    a_clear_o = 1;
                    a_next_state = CLEAR_REQUEST;
                end
            end
            CLEAR_REQUEST: begin
                if (a_to_b_clear_req_sync[SYNC_STAGES-1] && a_clear_ack_i) begin
                    a_next_state = WAIT_CLEAR_ACK;
                end
            end
            WAIT_CLEAR_ACK: begin
                if (b_to_a_clear_ack_sync[SYNC_STAGES-1]) begin
                    a_to_b_clear_rel_sync[0] = 1;
                    a_next_state = CLEAR_RELEASE;
                end
            end
            CLEAR_RELEASE: begin
                if (a_to_b_clear_rel_ack_sync[SYNC_STAGES-1]) begin
                    a_to_b_isolate_rel_sync[0] = 1;
                    a_next_state = ISOLATE_RELEASE;
                end
            end
            ISOLATE_RELEASE: begin
                if (a_to_b_isolate_rel_ack_sync[SYNC_STAGES-1]) begin
                    a_next_state = WAIT_ISOLATE_REL_ACK;
                end
            end
            WAIT_ISOLATE_REL_ACK: begin
                if (b_to_a_isolate_rel_ack_sync[SYNC_STAGES-1]) begin
                    a_next_state = IDLE;
                end
            end
        endcase
    end

    // B-side state machine
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_state <= IDLE;
        end else begin
            b_state <= b_next_state;
        end
    end

    always @(*) begin
        b_next_state = b_state;
        b_isolate_o = 0;
        b_clear_o = 0;
        b_to_a_isolate_rel_sync[0] = 0;
        b_to_a_clear_rel_sync[0] = 0;

        case (b_state)
            IDLE: begin
                if (b_clear_i) begin
                    b_isolate_o = 1;
                    b_next_state = ISOLATE_REQUEST;
                end
            end
            ISOLATE_REQUEST: begin
                if (b_to_a_isolate_req_sync[SYNC_STAGES-1] && b_isolate_ack_i) begin
                    b_next_state = WAIT_ISOLATE_ACK;
                end
            end
            WAIT_ISOLATE_ACK: begin
                if (a_to_b_isolate_ack_sync[SYNC_STAGES-1]) begin
                    b_clear_o = 1;
                    b_next_state = CLEAR_REQUEST;
                end
            end
            CLEAR_REQUEST: begin
                if (b_to_a_clear_req_sync[SYNC_STAGES-1] && b_clear_ack_i) begin
                    b_next_state = WAIT_CLEAR_ACK;
                end
            end
            WAIT_CLEAR_ACK: begin
                if (a_to_b_clear_ack_sync[SYNC_STAGES-1]) begin
                    b_to_a_clear_rel_sync[0] = 1;
                    b_next_state = CLEAR_RELEASE;
                end
            end
            CLEAR_RELEASE: begin
                if (b_to_a_clear_rel_ack_sync[SYNC_STAGES-1]) begin
                    b_to_a_isolate_rel_sync[0] = 1;
                    b_next_state = ISOLATE_RELEASE;
                end
            end
            ISOLATE_RELEASE: begin
                if (b_to_a_isolate_rel_ack_sync[SYNC_STAGES-1]) begin
                    b_next_state = WAIT_ISOLATE_REL_ACK;
                end
            end
            WAIT_ISOLATE_REL_ACK: begin
                if (a_to_b_isolate_rel_ack_sync[SYNC_STAGES-1]) begin
                    b_next_state = IDLE;
                end
            end
        endcase
    end

endmodule

module cdc_handshake #(
    parameter SYNC_STAGES = 2
)(
    input clk_src,
    input rst_src_ni,
    input req,
    input ack,
    input clk_dst,
    input rst_dst_ni,
    output reg [SYNC_STAGES-1:0] req_sync,
    output reg [SYNC_STAGES-1:0] ack_sync
);

    always @(posedge clk_src or negedge rst_src_ni) begin
        if (!rst_src_ni) begin
            req_sync <= 0;
        end else begin
            req_sync[0] <= req;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                req_sync[i] <= req_sync[i-1];
            end
        end
    end

    always @(posedge clk_dst or negedge rst_dst_ni) begin
        if (!rst_dst_ni) begin
            ack_sync <= 0;
        end else begin
            ack_sync[0] <= ack;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                ack_sync[i] <= ack_sync[i-1];
            end
        end
    end

endmodule
