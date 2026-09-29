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

    // Domain A signals
    reg [2:0] state_a;
    reg [SYNC_STAGES-1:0] b_isolate_ack_sync;
    reg [SYNC_STAGES-1:0] b_clear_ack_sync;
    reg [SYNC_STAGES-1:0] a_clear_ack_sync;
    reg a_isolate_reg;
    reg a_clear_reg;

    // Domain B signals
    reg [2:0] state_b;
    reg [SYNC_STAGES-1:0] a_isolate_ack_sync;
    reg [SYNC_STAGES-1:0] a_clear_ack_sync;
    reg [SYNC_STAGES-1:0] b_clear_ack_sync;
    reg b_isolate_reg;
    reg b_clear_reg;

    // Synchronizers for Domain A
    always @(posedge a_clk_i) begin
        b_isolate_ack_sync <= {b_isolate_ack_sync[SYNC_STAGES-2:0], b_isolate_ack_i};
        b_clear_ack_sync <= {b_clear_ack_sync[SYNC_STAGES-2:0], b_clear_ack_i};
        a_clear_ack_sync <= {a_clear_ack_sync[SYNC_STAGES-2:0], a_clear_ack_i};
    end

    // Synchronizers for Domain B
    always @(posedge b_clk_i) begin
        a_isolate_ack_sync <= {a_isolate_ack_sync[SYNC_STAGES-2:0], a_isolate_ack_i};
        a_clear_ack_sync <= {a_clear_ack_sync[SYNC_STAGES-2:0], a_clear_ack_i};
        b_clear_ack_sync <= {b_clear_ack_sync[SYNC_STAGES-2:0], b_clear_ack_i};
    end

    // Domain A FSM
    localparam A_IDLE = 0,
               A_ISOLATE = 1,
               A_WAIT_B_ISOLATE = 2,
               A_CLEAR = 3,
               A_WAIT_B_CLEAR = 4,
               A_CLEAR_B = 5,
               A_WAIT_A_CLEAR = 6,
               A_RELEASE = 7;

    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            state_a <= A_IDLE;
            a_isolate_reg <= 0;
            a_clear_reg <= 1;
        end else begin
            case (state_a)
                A_IDLE: begin
                    if (a_clear_i || b_clear_i) begin
                        state_a <= A_ISOLATE;
                        a_isolate_reg <= 1;
                    end
                end
                A_ISOLATE: begin
                    if (b_isolate_ack_sync[SYNC_STAGES-1]) begin
                        state_a <= A_CLEAR;
                        a_isolate_reg <= 0;
                        a_clear_reg <= 0;
                    end
                end
                A_CLEAR: begin
                    if (b_clear_ack_sync[SYNC_STAGES-1]) begin
                        state_a <= A_CLEAR_B;
                        a_clear_reg <= 1;
                    end
                end
                A_CLEAR_B: begin
                    if (a_clear_ack_sync[SYNC_STAGES-1]) begin
                        state_a <= A_RELEASE;
                    end
                end
                A_RELEASE: begin
                    a_isolate_reg <= 0;
                    state_a <= A_IDLE;
                end
                default: state_a <= A_IDLE;
            endcase
        end
    end

    // Domain B FSM
    localparam B_IDLE = 0,
               B_ISOLATE = 1,
               B_WAIT_A_ISOLATE = 2,
               B_CLEAR = 3,
               B_WAIT_A_CLEAR = 4,
               B_RELEASE = 5;

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            state_b <= B_IDLE;
            b_isolate_reg <= 0;
            b_clear_reg <= 1;
        end else begin
            case (state_b)
                B_IDLE: begin
                    if (a_clear_i || b_clear_i) begin
                        state_b <= B_ISOLATE;
                        b_isolate_reg <= 1;
                    end
                end
                B_ISOLATE: begin
                    if (a_isolate_ack_sync[SYNC_STAGES-1]) begin
                        state_b <= B_CLEAR;
                        b_isolate_reg <= 0;
                        b_clear_reg <= 0;
                    end
                end
                B_CLEAR: begin
                    if (a_clear_ack_sync[SYNC_STAGES-1]) begin
                        state_b <= B_RELEASE;
                        b_clear_reg <= 1;
                    end
                end
                B_RELEASE: begin
                    b_isolate_reg <= 0;
                    state_b <= B_IDLE;
                end
                default: state_b <= B_IDLE;
            endcase
        end
    end

    assign a_isolate_o = a_isolate_reg;
    assign a_clear_o = a_clear_reg;
    assign b_isolate_o = b_isolate_reg;
    assign b_clear_o = b_clear_reg;

endmodule
