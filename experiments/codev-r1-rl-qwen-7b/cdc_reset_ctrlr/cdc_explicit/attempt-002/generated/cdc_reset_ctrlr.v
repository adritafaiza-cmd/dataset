module cdc_reset_ctrlr #(
    parameter SYNC_STAGES = 2
) (
    input a_clk_i,
    input a_rst_ni,
    input a_clear_i,
    output reg a_clear_o,
    input a_clear_ack_i,
    output reg a_isolate_o,
    input a_isolate_ack_i,

    input b_clk_i,
    input b_rst_ni,
    input b_clear_i,
    output reg b_clear_o,
    input b_clear_ack_i,
    output reg b_isolate_o,
    input b_isolate_ack_i
);

// Domain A state machine
localparam A_IDLE = 2'd0;
localparam A_ISOLATE = 2'd1;
localparam A_CLEAR = 2'd2;
localparam A_RELEASE = 2'd3;

reg [1:0] a_state;
reg [SYNC_STAGES-1:0] a_sync_b_isolate_ack;
reg [SYNC_STAGES-1:0] a_sync_b_clear_ack;

wire a_sync_b_isolate_ack_ready = &a_sync_b_isolate_ack;
wire a_sync_b_clear_ack_ready = &a_sync_b_clear_ack;

// Domain B state machine
localparam B_IDLE = 2'd0;
localparam B_ISOLATE = 2'd1;
localparam B_CLEAR = 2'd2;
localparam B_RELEASE = 2'd3;

reg [1:0] b_state;
reg [SYNC_STAGES-1:0] b_sync_a_isolate_ack;
reg [SYNC_STAGES-1:0] b_sync_a_clear_ack;

wire b_sync_a_isolate_ack_ready = &b_sync_a_isolate_ack;
wire b_sync_a_clear_ack_ready = &b_sync_a_clear_ack;

// Domain A always block
always @(posedge a_clk_i or negedge a_rst_ni) begin
    if (!a_rst_ni) begin
        a_state <= A_IDLE;
        a_isolate_o <= 0;
        a_clear_o <= 0;
        a_sync_b_isolate_ack <= 0;
        a_sync_b_clear_ack <= 0;
    end else begin
        // Synchronizers
        a_sync_b_isolate_ack <= {a_sync_b_isolate_ack[SYNC_STAGES-2:0], b_isolate_ack_i};
        a_sync_b_clear_ack <= {a_sync_b_clear_ack[SYNC_STAGES-2:0], b_clear_ack_i};

        case (a_state)
            A_IDLE: begin
                if (a_clear_i || b_clear_i) begin
                    a_state <= A_ISOLATE;
                    a_isolate_o <= 1;
                end
            end
            A_ISOLATE: begin
                if (a_isolate_ack_i && a_sync_b_isolate_ack_ready) begin
                    a_state <= A_CLEAR;
                    a_clear_o <= 1;
                end
            end
            A_CLEAR: begin
                if (a_clear_ack_i && a_sync_b_clear_ack_ready) begin
                    a_state <= A_RELEASE;
                    a_isolate_o <= 0;
                    a_clear_o <= 0;
                end
            end
            A_RELEASE: begin
                a_state <= A_IDLE;
            end
            default: a_state <= A_IDLE;
        endcase
    end
end

// Domain B always block
always @(posedge b_clk_i or negedge b_rst_ni) begin
    if (!b_rst_ni) begin
        b_state <= B_IDLE;
        b_isolate_o <= 0;
        b_clear_o <= 0;
        b_sync_a_isolate_ack <= 0;
        b_sync_a_clear_ack <= 0;
    end else begin
        // Synchronizers
        b_sync_a_isolate_ack <= {b_sync_a_isolate_ack[SYNC_STAGES-2:0], a_isolate_ack_i};
        b_sync_a_clear_ack <= {b_sync_a_clear_ack[SYNC_STAGES-2:0], a_clear_ack_i};

        case (b_state)
            B_IDLE: begin
                if (a_clear_i || b_clear_i) begin
                    b_state <= B_ISOLATE;
                    b_isolate_o <= 1;
                end
            end
            B_ISOLATE: begin
                if (b_isolate_ack_i && b_sync_a_isolate_ack_ready) begin
                    b_state <= B_CLEAR;
                    b_clear_o <= 1;
                end
            end
            B_CLEAR: begin
                if (b_clear_ack_i && b_sync_a_clear_ack_ready) begin
                    b_state <= B_RELEASE;
                    b_isolate_o <= 0;
                    b_clear_o <= 0;
                end
            end
            B_RELEASE: begin
                b_state <= B_IDLE;
            end
            default: b_state <= B_IDLE;
        endcase
    end
end

endmodule
