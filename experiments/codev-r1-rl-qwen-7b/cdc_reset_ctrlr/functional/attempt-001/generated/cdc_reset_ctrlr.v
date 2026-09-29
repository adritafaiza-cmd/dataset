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

    // State machine in a_clk domain
    reg [SYNC_STAGES-1:0] b_clear_sync_a;
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) b_clear_sync_a <= '0;
        else b_clear_sync_a <= {b_clear_sync_a[SYNC_STAGES-2:0], b_clear_i};
    end
    wire b_clear_synced_a = &b_clear_sync_a;

    reg [1:0] state_a;
    localparam IDLE_A = 2'd0, ISOLATE_A = 2'd1, CLEAR_A = 2'd2, RELEASE_A = 2'd3;
    reg a_isolate_reg, a_clear_reg;

    reg a_isolate_ack_sync, a_clear_ack_sync;
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate_ack_sync <= 0;
            a_clear_ack_sync <= 0;
        end else begin
            a_isolate_ack_sync <= a_isolate_ack_i;
            a_clear_ack_sync <= a_clear_ack_i;
        end
    end

    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            state_a <= IDLE_A;
            a_isolate_reg <= 0;
            a_clear_reg <= 0;
        end else begin
            case (state_a)
                IDLE_A: if (a_clear_i || b_clear_synced_a) begin
                    state_a <= ISOLATE_A;
                    a_isolate_reg <= 1;
                end
                ISOLATE_A: if (a_isolate_ack_sync && b_isolate_ack_i) begin
                    state_a <= CLEAR_A;
                    a_clear_reg <= 1;
                end
                CLEAR_A: if (a_clear_ack_sync && b_clear_ack_i) begin
                    state_a <= RELEASE_A;
                    a_clear_reg <= 0;
                end
                RELEASE_A: begin
                    state_a <= IDLE_A;
                    a_isolate_reg <= 0;
                end
                default: state_a <= IDLE_A;
            endcase
        end
    end

    assign a_isolate_o = a_isolate_reg;
    assign a_clear_o = a_clear_reg;

    // State machine in b_clk domain
    reg [SYNC_STAGES-1:0] a_clear_sync_b;
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) a_clear_sync_b <= '0;
        else a_clear_sync_b <= {a_clear_sync_b[SYNC_STAGES-2:0], a_clear_i};
    end
    wire a_clear_synced_b = &a_clear_sync_b;

    reg [1:0] state_b;
    localparam IDLE_B = 2'd0, ISOLATE_B = 2'd1, CLEAR_B = 2'd2, RELEASE_B = 2'd3;
    reg b_isolate_reg, b_clear_reg;

    reg b_isolate_ack_sync, b_clear_ack_sync;
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate_ack_sync <= 0;
            b_clear_ack_sync <= 0;
        end else begin
            b_isolate_ack_sync <= b_isolate_ack_i;
            b_clear_ack_sync <= b_clear_ack_i;
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            state_b <= IDLE_B;
            b_isolate_reg <= 0;
            b_clear_reg <= 0;
        end else begin
            case (state_b)
                IDLE_B: if (b_clear_i || a_clear_synced_b) begin
                    state_b <= ISOLATE_B;
                    b_isolate_reg <= 1;
                end
                ISOLATE_B: if (b_isolate_ack_sync && a_isolate_ack_i) begin
                    state_b <= CLEAR_B;
                    b_clear_reg <= 1;
                end
                CLEAR_B: if (b_clear_ack_sync && a_clear_ack_i) begin
                    state_b <= RELEASE_B;
                    b_clear_reg <= 0;
                end
                RELEASE_B: begin
                    state_b <= IDLE_B;
                    b_isolate_reg <= 0;
                end
                default: state_b <= IDLE_B;
            endcase
        end
    end

    assign b_isolate_o = b_isolate_reg;
    assign b_clear_o = b_clear_reg;

endmodule
