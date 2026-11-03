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
    reg  a_isolate;
    reg  b_isolate;
    reg  a_clear;
    reg  b_clear;
    reg  a2b_clear_sync;
    reg  b2a_clear_sync;
    reg  a2b_clear_ack_sync;
    reg  b2a_clear_ack_sync;
    reg  a2b_isolate_ack_sync;
    reg  b2a_isolate_ack_sync;
    reg  a_clear_req;
    reg  b_clear_req;
    reg  a_clear_ack;
    reg  b_clear_ack;
    reg  a_isolate_ack;
    reg  b_isolate_ack;
    reg  [2:0] a_state;
    reg  [2:0] b_state;

    // CDC synchronization instances
    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) a2b_sync_clear (
        .clk       (b_clk_i),
        .rst_ni    (b_rst_ni),
        .data_in   (a_clear_i),
        .data_out  (a2b_clear_sync)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) b2a_sync_clear (
        .clk       (a_clk_i),
        .rst_ni    (a_rst_ni),
        .data_in   (b_clear_i),
        .data_out  (b2a_clear_sync)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) a2b_sync_clear_ack (
        .clk       (b_clk_i),
        .rst_ni    (b_rst_ni),
        .data_in   (a_clear_ack_i),
        .data_out  (a2b_clear_ack_sync)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) b2a_sync_clear_ack (
        .clk       (a_clk_i),
        .rst_ni    (a_rst_ni),
        .data_in   (b_clear_ack_i),
        .data_out  (b2a_clear_ack_sync)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) a2b_sync_isolate_ack (
        .clk       (b_clk_i),
        .rst_ni    (b_rst_ni),
        .data_in   (a_isolate_ack_i),
        .data_out  (a2b_isolate_ack_sync)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) b2a_sync_isolate_ack (
        .clk       (a_clk_i),
        .rst_ni    (a_rst_ni),
        .data_in   (b_isolate_ack_i),
        .data_out  (b2a_isolate_ack_sync)
    );

    // State machine for domain A
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_state <= 3'b000;
            a_isolate <= 1'b0;
            a_clear <= 1'b0;
        end else begin
            case (a_state)
                3'b000: begin // IDLE
                    if (a_clear_i || b2a_clear_sync) begin
                        a_state <= 3'b001;
                        a_isolate <= 1'b1;
                    end
                end
                3'b001: begin // ISOLATE
                    if (a_isolate_ack_i && b2a_isolate_ack_sync) begin
                        a_state <= 3'b010;
                        a_clear <= 1'b1;
                    end
                end
                3'b010: begin // CLEAR
                    if (a_clear_ack_i && b2a_clear_ack_sync) begin
                        a_state <= 3'b011;
                    end
                end
                3'b011: begin // RELEASE
                    a_clear <= 1'b0;
                    a_isolate <= 1'b0;
                    a_state <= 3'b100;
                end
                3'b100: begin // WAIT FOR NEXT REQUEST
                    if (!a_clear_i && !b2a_clear_sync) begin
                        a_state <= 3'b000;
                    end
                end
                default: begin
                    a_state <= 3'b000;
                end
            endcase
        end
    end

    // State machine for domain B
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_state <= 3'b000;
            b_isolate <= 1'b0;
            b_clear <= 1'b0;
        end else begin
            case (b_state)
                3'b000: begin // IDLE
                    if (b_clear_i || a2b_clear_sync) begin
                        b_state <= 3'b001;
                        b_isolate <= 1'b1;
                    end
                end
                3'b001: begin // ISOLATE
                    if (b_isolate_ack_i && a2b_isolate_ack_sync) begin
                        b_state <= 3'b010;
                        b_clear <= 1'b1;
                    end
                end
                3'b010: begin // CLEAR
                    if (b_clear_ack_i && a2b_clear_ack_sync) begin
                        b_state <= 3'b011;
                    end
                end
                3'b011: begin // RELEASE
                    b_clear <= 1'b0;
                    b_isolate <= 1'b0;
                    b_state <= 3'b100;
                end
                3'b100: begin // WAIT FOR NEXT REQUEST
                    if (!b_clear_i && !a2b_clear_sync) begin
                        b_state <= 3'b000;
                    end
                end
                default: begin
                    b_state <= 3'b000;
                end
            endcase
        end
    end

    // Output assignments
    assign a_clear_o = a_clear;
    assign a_isolate_o = a_isolate;
    assign b_clear_o = b_clear;
    assign b_isolate_o = b_isolate;

endmodule

module cdc_sync #(
    parameter SYNC_STAGES = 2
)(
    input  clk,
    input  rst_ni,
    input  data_in,
    output reg data_out
);

    reg [SYNC_STAGES-1:0] sync_ff;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_ff <= {SYNC_STAGES{1'b0}};
        end else begin
            sync_ff <= {sync_ff[SYNC_STAGES-2:0], data_in};
        end
    end

    assign data_out = sync_ff[SYNC_STAGES-1];

endmodule
