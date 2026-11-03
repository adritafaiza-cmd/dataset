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

    reg [1:0] a_state, b_state;
    reg a_isolate, b_isolate;
    reg a_clear, b_clear;
    reg [SYNC_STAGES-1:0] a_sync_b_clear, b_sync_a_clear;
    reg [SYNC_STAGES-1:0] a_sync_b_isolate, b_sync_a_isolate;
    reg [SYNC_STAGES-1:0] a_sync_b_clear_ack, b_sync_a_clear_ack;
    reg [SYNC_STAGES-1:0] a_sync_b_isolate_ack, b_sync_a_isolate_ack;

    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_state <= 0;
            a_isolate <= 0;
            a_clear <= 0;
        end else begin
            case (a_state)
                0: begin
                    if (a_clear_i) begin
                        a_state <= 1;
                        a_isolate <= 1;
                    end
                end
                1: begin
                    if (a_isolate_ack_i && b_sync_a_isolate[SYNC_STAGES-1]) begin
                        a_state <= 2;
                        a_clear <= 1;
                    end
                end
                2: begin
                    if (a_clear_ack_i && b_sync_a_clear[SYNC_STAGES-1]) begin
                        a_state <= 3;
                    end
                end
                3: begin
                    if (b_sync_a_isolate_ack[SYNC_STAGES-1] && b_sync_a_clear_ack[SYNC_STAGES-1]) begin
                        a_state <= 0;
                        a_isolate <= 0;
                        a_clear <= 0;
                    end
                end
            endcase
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_state <= 0;
            b_isolate <= 0;
            b_clear <= 0;
        end else begin
            case (b_state)
                0: begin
                    if (b_clear_i) begin
                        b_state <= 1;
                        b_isolate <= 1;
                    end
                end
                1: begin
                    if (b_isolate_ack_i && a_sync_b_isolate[SYNC_STAGES-1]) begin
                        b_state <= 2;
                        b_clear <= 1;
                    end
                end
                2: begin
                    if (b_clear_ack_i && a_sync_b_clear[SYNC_STAGES-1]) begin
                        b_state <= 3;
                    end
                end
                3: begin
                    if (a_sync_b_isolate_ack[SYNC_STAGES-1] && a_sync_b_clear_ack[SYNC_STAGES-1]) begin
                        b_state <= 0;
                        b_isolate <= 0;
                        b_clear <= 0;
                    end
                end
            endcase
        end
    end

    always @(posedge a_clk_i) begin
        a_sync_b_clear[0] <= b_clear_i;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            a_sync_b_clear[i] <= a_sync_b_clear[i-1];
        end
        a_sync_b_isolate[0] <= b_isolate;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            a_sync_b_isolate[i] <= a_sync_b_isolate[i-1];
        end
        a_sync_b_clear_ack[0] <= b_clear_ack_i;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            a_sync_b_clear_ack[i] <= a_sync_b_clear_ack[i-1];
        end
        a_sync_b_isolate_ack[0] <= b_isolate_ack_i;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            a_sync_b_isolate_ack[i] <= a_sync_b_isolate_ack[i-1];
        end
    end

    always @(posedge b_clk_i) begin
        b_sync_a_clear[0] <= a_clear_i;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            b_sync_a_clear[i] <= b_sync_a_clear[i-1];
        end
        b_sync_a_isolate[0] <= a_isolate;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            b_sync_a_isolate[i] <= b_sync_a_isolate[i-1];
        end
        b_sync_a_clear_ack[0] <= a_clear_ack_i;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            b_sync_a_clear_ack[i] <= b_sync_a_clear_ack[i-1];
        end
        b_sync_a_isolate_ack[0] <= a_isolate_ack_i;
        for (int i = 1; i < SYNC_STAGES; i++) begin
            b_sync_a_isolate_ack[i] <= b_sync_a_isolate_ack[i-1];
        end
    end

    assign a_clear_o = a_clear;
    assign a_isolate_o = a_isolate;
    assign b_clear_o = b_clear;
    assign b_isolate_o = b_isolate;

endmodule
