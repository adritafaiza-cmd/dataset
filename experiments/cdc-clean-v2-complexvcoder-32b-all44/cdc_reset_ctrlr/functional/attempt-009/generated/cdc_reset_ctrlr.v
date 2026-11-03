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
    reg  a_isolate_req;
    reg  a_clear_req;
    reg  b_isolate_req;
    reg  b_clear_req;
    reg  a_isolate_sync;
    reg  a_clear_sync;
    reg  b_isolate_sync;
    reg  b_clear_sync;
    reg  a_isolate_done;
    reg  a_clear_done;
    reg  b_isolate_done;
    reg  b_clear_done;
    reg [1:0] a_isolate_state;
    reg [1:0] a_clear_state;
    reg [1:0] b_isolate_state;
    reg [1:0] b_clear_state;

    // Synchronizers
    cdc_sync #(.STAGES(SYNC_STAGES)) sync_a_isolate_req (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .d_i(a_isolate_req),
        .q_o(a_isolate_sync)
    );

    cdc_sync #(.STAGES(SYNC_STAGES)) sync_a_clear_req (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .d_i(a_clear_req),
        .q_o(a_clear_sync)
    );

    cdc_sync #(.STAGES(SYNC_STAGES)) sync_b_isolate_req (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .d_i(b_isolate_req),
        .q_o(b_isolate_sync)
    );

    cdc_sync #(.STAGES(SYNC_STAGES)) sync_b_clear_req (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .d_i(b_clear_req),
        .q_o(b_clear_sync)
    );

    // Domain A logic
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate_o <= 0;
            a_clear_o <= 0;
            a_isolate_req <= 0;
            a_clear_req <= 0;
            a_isolate_done <= 0;
            a_clear_done <= 0;
            a_isolate_state <= 0;
            a_clear_state <= 0;
        end else begin
            case (a_isolate_state)
                2'b00: begin // IDLE
                    if (a_clear_i || b_clear_sync) begin
                        a_isolate_req <= 1;
                        a_isolate_state <= 2'b01; // REQUEST
                    end
                end
                2'b01: begin // REQUEST
                    if (a_isolate_ack_i) begin
                        a_isolate_o <= 1;
                        a_isolate_state <= 2'b10; // ACTIVE
                    end
                end
                2'b10: begin // ACTIVE
                    if (b_isolate_sync) begin
                        a_isolate_done <= 1;
                        a_isolate_state <= 2'b11; // DONE
                    end
                end
                2'b11: begin // DONE
                    a_isolate_done <= 0;
                    a_isolate_state <= 2'b00; // IDLE
                end
            endcase

            case (a_clear_state)
                2'b00: begin // IDLE
                    if (a_isolate_done && (a_clear_i || b_clear_sync)) begin
                        a_clear_req <= 1;
                        a_clear_state <= 2'b01; // REQUEST
                    end
                end
                2'b01: begin // REQUEST
                    if (a_clear_ack_i) begin
                        a_clear_o <= 1;
                        a_clear_state <= 2'b10; // ACTIVE
                    end
                end
                2'b10: begin // ACTIVE
                    if (b_clear_sync) begin
                        a_clear_done <= 1;
                        a_clear_state <= 2'b11; // DONE
                    end
                end
                2'b11: begin // DONE
                    a_clear_o <= 0;
                    a_clear_done <= 0;
                    a_clear_req <= 0;
                    a_clear_state <= 2'b00; // IDLE
                end
            endcase
        end
    end

    // Domain B logic
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate_o <= 0;
            b_clear_o <= 0;
            b_isolate_req <= 0;
            b_clear_req <= 0;
            b_isolate_done <= 0;
            b_clear_done <= 0;
            b_isolate_state <= 0;
            b_clear_state <= 0;
        end else begin
            case (b_isolate_state)
                2'b00: begin // IDLE
                    if (b_clear_i || a_clear_sync) begin
                        b_isolate_req <= 1;
                        b_isolate_state <= 2'b01; // REQUEST
                    end
                end
                2'b01: begin // REQUEST
                    if (b_isolate_ack_i) begin
                        b_isolate_o <= 1;
                        b_isolate_state <= 2'b10; // ACTIVE
                    end
                end
                2'b10: begin // ACTIVE
                    if (a_isolate_sync) begin
                        b_isolate_done <= 1;
                        b_isolate_state <= 2'b11; // DONE
                    end
                end
                2'b11: begin // DONE
                    b_isolate_done <= 0;
                    b_isolate_state <= 2'b00; // IDLE
                end
            endcase

            case (b_clear_state)
                2'b00: begin // IDLE
                    if (b_isolate_done && (b_clear_i || a_clear_sync)) begin
                        b_clear_req <= 1;
                        b_clear_state <= 2'b01; // REQUEST
                    end
                end
                2'b01: begin // REQUEST
                    if (b_clear_ack_i) begin
                        b_clear_o <= 1;
                        b_clear_state <= 2'b10; // ACTIVE
                    end
                end
                2'b10: begin // ACTIVE
                    if (a_clear_sync) begin
                        b_clear_done <= 1;
                        b_clear_state <= 2'b11; // DONE
                    end
                end
                2'b11: begin // DONE
                    b_clear_o <= 0;
                    b_clear_done <= 0;
                    b_clear_req <= 0;
                    b_clear_state <= 2'b00; // IDLE
                end
            endcase
        end
    end

endmodule

// Synchronizer module
module cdc_sync #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  d_i,
    output q_o
);

    reg [STAGES:0] sync_reg;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg <= 0;
        end else begin
            sync_reg <= {sync_reg[STAGES-1:0], d_i};
        end
    end

    assign q_o = sync_reg[STAGES];

endmodule
