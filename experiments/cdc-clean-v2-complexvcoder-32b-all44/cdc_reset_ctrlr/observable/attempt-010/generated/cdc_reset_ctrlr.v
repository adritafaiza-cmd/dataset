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
    reg  [1:0] a_state, b_state;
    reg        a_clear_req, b_clear_req;
    reg        a_isolate_req, b_isolate_req;
    reg        a_clear, b_clear;
    reg        a_isolate, b_isolate;
    reg        a_released, b_released;
    reg        a_clear_req_sync, b_clear_req_sync;
    reg        a_isolate_ack_sync, b_isolate_ack_sync;
    reg        a_clear_ack_sync, b_clear_ack_sync;

    // State definitions
    localparam IDLE = 2'b00;
    localparam ISOLATE = 2'b01;
    localparam CLEAR = 2'b10;
    localparam RELEASE = 2'b11;

    // CDC synchronization instances
    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) sync_a_clear_req_to_b (
        .local(a_clear_i),
        .remote(a_clear_req_sync)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) sync_b_clear_req_to_a (
        .local(b_clear_i),
        .remote(b_clear_req_sync)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) sync_a_isolate_ack_to_b (
        .local(a_isolate_ack_i),
        .remote(a_isolate_ack_sync)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) sync_b_isolate_ack_to_a (
        .local(b_isolate_ack_i),
        .remote(b_isolate_ack_sync)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) sync_a_clear_ack_to_b (
        .local(a_clear_ack_i),
        .remote(a_clear_ack_sync)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) sync_b_clear_ack_to_a (
        .local(b_clear_ack_i),
        .remote(b_clear_ack_sync)
    );

    // Domain A state machine
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_state <= IDLE;
            a_isolate <= 0;
            a_clear <= 1;
            a_released <= 0;
        end else begin
            case (a_state)
                IDLE: begin
                    a_clear_req <= a_clear_i;
                    if (a_clear_req && !b_clear_req) begin
                        a_state <= ISOLATE;
                        a_isolate <= 1;
                    end
                end
                ISOLATE: begin
                    if (a_isolate_ack_sync) begin
                        a_state <= CLEAR;
                        a_clear <= 0;
                    end
                end
                CLEAR: begin
                    if (a_clear_ack_sync) begin
                        a_state <= RELEASE;
                    end
                end
                RELEASE: begin
                    a_isolate <= 0;
                    if (b_isolate_ack_sync) begin
                        a_state <= IDLE;
                        a_released <= 1;
                    end
                end
                default: begin
                    a_state <= IDLE;
                end
            endcase
        end
    end

    // Domain B state machine
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_state <= IDLE;
            b_isolate <= 0;
            b_clear <= 1;
            b_released <= 0;
        end else begin
            case (b_state)
                IDLE: begin
                    b_clear_req <= b_clear_i;
                    if (b_clear_req && !a_clear_req) begin
                        b_state <= ISOLATE;
                        b_isolate <= 1;
                    end
                end
                ISOLATE: begin
                    if (b_isolate_ack_sync) begin
                        b_state <= CLEAR;
                        b_clear <= 0;
                    end
                end
                CLEAR: begin
                    if (b_clear_ack_sync) begin
                        b_state <= RELEASE;
                    end
                end
                RELEASE: begin
                    b_isolate <= 0;
                    if (a_isolate_ack_sync) begin
                        b_state <= IDLE;
                        b_released <= 1;
                    end
                end
                default: begin
                    b_state <= IDLE;
                end
            endcase
        end
    end

    // Outputs
    assign a_clear_o = a_clear;
    assign a_isolate_o = a_isolate;
    assign b_clear_o = b_clear;
    assign b_isolate_o = b_isolate;

endmodule

module cdc_sync #(
    parameter SYNC_STAGES = 2
)(
    input  local,
    output remote
);

    reg [SYNC_STAGES-1:0] sync_reg;

    always @(posedge remote_clk) begin
        sync_reg <= {sync_reg[SYNC_STAGES-2:0], local};
    end

    assign remote = sync_reg[SYNC_STAGES-1];

endmodule
