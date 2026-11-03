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
    reg a_isolate_req, a_isolate_ack, a_clear_req, a_clear_ack, a_released_req, a_released_ack;
    reg b_isolate_req, b_isolate_ack, b_clear_req, b_clear_ack, b_released_req, b_released_ack;
    reg [1:0] a_state, b_state;

    // States
    localparam IDLE = 2'b00;
    localparam ISOLATE = 2'b01;
    localparam CLEAR = 2'b10;
    localparam RELEASE = 2'b11;

    // CDC handshakes
    cdc_handshake #(.SYNC_STAGES(SYNC_STAGES)) cdc_a_to_b (
        .local_clk_i(a_clk_i),
        .local_rst_ni(a_rst_ni),
        .remote_clk_i(b_clk_i),
        .remote_rst_ni(b_rst_ni),
        .local_req_i(a_isolate_req),
        .local_ack_o(a_isolate_ack),
        .remote_req_o(b_isolate_req),
        .remote_ack_i(b_isolate_ack)
    );

    cdc_handshake #(.SYNC_STAGES(SYNC_STAGES)) cdc_b_to_a (
        .local_clk_i(b_clk_i),
        .local_rst_ni(b_rst_ni),
        .remote_clk_i(a_clk_i),
        .remote_rst_ni(a_rst_ni),
        .local_req_i(b_isolate_req),
        .local_ack_o(b_isolate_ack),
        .remote_req_o(a_isolate_req),
        .remote_ack_i(a_isolate_ack)
    );

    cdc_handshake #(.SYNC_STAGES(SYNC_STAGES)) cdc_a_to_b_clear (
        .local_clk_i(a_clk_i),
        .local_rst_ni(a_rst_ni),
        .remote_clk_i(b_clk_i),
        .remote_rst_ni(b_rst_ni),
        .local_req_i(a_clear_req),
        .local_ack_o(a_clear_ack),
        .remote_req_o(b_clear_req),
        .remote_ack_i(b_clear_ack)
    );

    cdc_handshake #(.SYNC_STAGES(SYNC_STAGES)) cdc_b_to_a_clear (
        .local_clk_i(b_clk_i),
        .local_rst_ni(b_rst_ni),
        .remote_clk_i(a_clk_i),
        .remote_rst_ni(a_rst_ni),
        .local_req_i(b_clear_req),
        .local_ack_o(b_clear_ack),
        .remote_req_o(a_clear_req),
        .remote_ack_i(a_clear_ack)
    );

    cdc_handshake #(.SYNC_STAGES(SYNC_STAGES)) cdc_a_to_b_released (
        .local_clk_i(a_clk_i),
        .local_rst_ni(a_rst_ni),
        .remote_clk_i(b_clk_i),
        .remote_rst_ni(b_rst_ni),
        .local_req_i(a_released_req),
        .local_ack_o(a_released_ack),
        .remote_req_o(b_released_req),
        .remote_ack_i(b_released_ack)
    );

    cdc_handshake #(.SYNC_STAGES(SYNC_STAGES)) cdc_b_to_a_released (
        .local_clk_i(b_clk_i),
        .local_rst_ni(b_rst_ni),
        .remote_clk_i(a_clk_i),
        .remote_rst_ni(a_rst_ni),
        .local_req_i(b_released_req),
        .local_ack_o(b_released_ack),
        .remote_req_o(a_released_req),
        .remote_ack_i(a_released_ack)
    );

    // State machine for domain A
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_state <= IDLE;
            a_clear_o <= 0;
            a_isolate_o <= 0;
            a_clear_req <= 0;
            a_released_req <= 0;
        end else begin
            case (a_state)
                IDLE: begin
                    if (a_clear_i) begin
                        a_state <= ISOLATE;
                        a_isolate_o <= 1;
                    end
                end
                ISOLATE: begin
                    if (a_isolate_ack) begin
                        a_state <= CLEAR;
                        a_clear_req <= 1;
                    end
                end
                CLEAR: begin
                    if (a_clear_ack) begin
                        a_clear_o <= 1;
                        a_state <= RELEASE;
                        a_clear_req <= 0;
                    end
                end
                RELEASE: begin
                    if (b_released_ack) begin
                        a_state <= IDLE;
                        a_clear_o <= 0;
                        a_isolate_o <= 0;
                        a_released_req <= 1;
                    end
                end
            endcase
        end
    end

    // State machine for domain B
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_state <= IDLE;
            b_clear_o <= 0;
            b_isolate_o <= 0;
            b_clear_req <= 0;
            b_released_req <= 0;
        end else begin
            case (b_state)
                IDLE: begin
                    if (b_clear_i) begin
                        b_state <= ISOLATE;
                        b_isolate_o <= 1;
                    end
                end
                ISOLATE: begin
                    if (b_isolate_ack) begin
                        b_state <= CLEAR;
                        b_clear_req <= 1;
                    end
                end
                CLEAR: begin
                    if (b_clear_ack) begin
                        b_clear_o <= 1;
                        b_state <= RELEASE;
                        b_clear_req <= 0;
                    end
                end
                RELEASE: begin
                    if (a_released_ack) begin
                        b_state <= IDLE;
                        b_clear_o <= 0;
                        b_isolate_o <= 0;
                        b_released_req <= 1;
                    end
                end
            endcase
        end
    end

endmodule

module cdc_handshake #(
    parameter SYNC_STAGES = 2
)(
    input  local_clk_i,
    input  local_rst_ni,
    input  remote_clk_i,
    input  remote_rst_ni,
    input  local_req_i,
    output local_ack_o,
    output remote_req_o,
    input  remote_ack_i
);

    reg [SYNC_STAGES-1:0] local_sync, remote_sync;

    // Synchronize remote_ack_i to local_clk_i
    always @(posedge local_clk_i or negedge local_rst_ni) begin
        if (!local_rst_ni) begin
            local_sync <= 0;
        end else begin
            local_sync <= {local_sync[SYNC_STAGES-2:0], remote_ack_i};
        end
    end

    // Synchronize local_req_i to remote_clk_i
    always @(posedge remote_clk_i or negedge remote_rst_ni) begin
        if (!remote_rst_ni) begin
            remote_sync <= 0;
        end else begin
            remote_sync <= {remote_sync[SYNC_STAGES-2:0], local_req_i};
        end
    end

    // Outputs
    assign local_ack_o = local_sync[SYNC_STAGES-1];
    assign remote_req_o = remote_sync[SYNC_STAGES-1];

endmodule
