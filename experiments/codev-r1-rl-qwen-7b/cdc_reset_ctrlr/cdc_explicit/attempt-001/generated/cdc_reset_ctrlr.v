module cdc_reset_ctrlr #(
    parameter SYNC_STAGES = 2
)(
    input  a_clk_i,
    input  a_rst_ni,
    input  a_clear_i,
    output a_clear_o,
    output a_isolate_o,
    input  a_clear_ack_i,
    input  a_isolate_ack_i,
    input  b_clk_i,
    input  b_rst_ni,
    input  b_clear_i,
    output b_clear_o,
    input  b_clear_ack_i,
    output b_isolate_o,
    input  b_isolate_ack_i
);

    // Synchronize b_clear_i to a_clk domain
    reg [SYNC_STAGES-1:0] b_clear_sync_a;
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            b_clear_sync_a <= 0;
        end else begin
            b_clear_sync_a <= {b_clear_sync_a[SYNC_STAGES-2:0], b_clear_i};
        end
    end
    wire b_clear_synced_a = b_clear_sync_a[SYNC_STAGES-1];

    // Synchronize a_clear_i to b_clk domain
    reg [SYNC_STAGES-1:0] a_clear_sync_b;
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            a_clear_sync_b <= 0;
        end else begin
            a_clear_sync_b <= {a_clear_sync_b[SYNC_STAGES-2:0], a_clear_i};
        end
    end
    wire a_clear_synced_b = a_clear_sync_b[SYNC_STAGES-1];

    // State machine in a_clk domain
    reg [1:0] state_a;
    localparam IDLE_A = 2'd0;
    localparam ACTIVE_A = 2'd1;
    localparam CLEAR_A = 2'd2;
    localparam RELEASE_A = 2'd3;

    reg a_clear_reg;
    reg a_isolate_reg;

    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            state_a <= IDLE_A;
            a_clear_reg <= 0;
            a_isolate_reg <= 0;
        end else begin
            case (state_a)
                IDLE_A: begin
                    if (a_clear_i || b_clear_synced_a) begin
                        state_a <= ACTIVE_A;
                        a_isolate_reg <= 1;
                    end
                end
                ACTIVE_A: begin
                    if (a_isolate_ack_i && b_isolate_ack_i) begin
                        a_clear_reg <= 1;
                        state_a <= CLEAR_A;
                    end
                end
                CLEAR_A: begin
                    if (a_clear_ack_i && b_clear_ack_i) begin
                        a_clear_reg <= 0;
                        a_isolate_reg <= 0;
                        state_a <= RELEASE_A;
                    end
                end
                RELEASE_A: begin
                    state_a <= IDLE_A;
                end
            endcase
        end
    end

    assign a_clear_o = a_clear_reg;
    assign a_isolate_o = a_isolate_reg;

    // State machine in b_clk domain
    reg [1:0] state_b;
    localparam IDLE_B = 2'd0;
    localparam ACTIVE_B = 2'd1;
    localparam CLEAR_B = 2'd2;
    localparam RELEASE_B = 2'd3;

    reg b_clear_reg;
    reg b_isolate_reg;

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            state_b <= IDLE_B;
            b_clear_reg <= 0;
            b_isolate_reg <= 0;
        end else begin
            case (state_b)
                IDLE_B: begin
                    if (b_clear_i || a_clear_synced_b) begin
                        state_b <= ACTIVE_B;
                        b_isolate_reg <= 1;
                    end
                end
                ACTIVE_B: begin
                    if (a_isolate_ack_i && b_isolate_ack_i) begin
                        b_clear_reg <= 1;
                        state_b <= CLEAR_B;
                    end
                end
                CLEAR_B: begin
                    if (a_clear_ack_i && b_clear_ack_i) begin
                        b_clear_reg <= 0;
                        b_isolate_reg <= 0;
                        state_b <= RELEASE_B;
                    end
                end
                RELEASE_B: begin
                    state_b <= IDLE_B;
                end
            endcase
        end
    end

    assign b_clear_o = b_clear_reg;
    assign b_isolate_o = b_isolate_reg;

endmodule
