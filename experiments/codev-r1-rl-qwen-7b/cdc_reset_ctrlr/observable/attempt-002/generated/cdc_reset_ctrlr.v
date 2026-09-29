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

// State definitions
localparam [2:0] IDLE      = 3'd0;
localparam [2:0] ISOLATE   = 3'd1;
localparam [2:0] CLEAR_A   = 3'd2;
localparam [2:0] CLEAR_B   = 3'd3;
localparam [2:0] RELEASE   = 3'd4;

// A domain signals
reg [2:0] state_a;
reg [1:0] sync_b_ack;

// B domain signals
reg [2:0] state_b;
reg [1:0] sync_a_ack;

// Synchronize b_clear_ack_i to a_clk domain
always @(posedge a_clk_i or negedge a_rst_ni) begin
    if (!a_rst_ni) begin
        sync_b_ack <= 2'b0;
    end else begin
        sync_b_ack <= {sync_b_ack[0], b_clear_ack_i};
    end
end

// Synchronize a_clear_ack_i to b_clk domain
always @(posedge b_clk_i or negedge b_rst_ni) begin
    if (!b_rst_ni) begin
        sync_a_ack <= 2'b0;
    end else begin
        sync_a_ack <= {sync_a_ack[0], a_clear_ack_i};
    end
end

// A domain state machine
always @(posedge a_clk_i or negedge a_rst_ni) begin
    if (!a_rst_ni) begin
        state_a <= IDLE;
        a_isolate_o <= 1'b0;
        a_clear_o <= 1'b1;
    end else begin
        case (state_a)
            IDLE: begin
                if (a_clear_i || sync_b_ack[1]) begin
                    state_a <= ISOLATE;
                    a_isolate_o <= 1'b1;
                end
            end
            ISOLATE: begin
                if (a_isolate_ack_i && b_isolate_ack_i) begin
                    state_a <= CLEAR_A;
                    a_clear_o <= 1'b0;
                end
            end
            CLEAR_A: begin
                if (sync_a_ack[1]) begin
                    state_a <= CLEAR_B;
                    b_clear_o <= 1'b0;
                end
            end
            CLEAR_B: begin
                if (sync_b_ack[1]) begin
                    state_a <= RELEASE;
                    a_isolate_o <= 1'b0;
                    a_clear_o <= 1'b1;
                end
            end
            RELEASE: begin
                state_a <= IDLE;
            end
            default: state_a <= IDLE;
        endcase
    end
end

// B domain state machine
always @(posedge b_clk_i or negedge b_rst_ni) begin
    if (!b_rst_ni) begin
        state_b <= IDLE;
        b_isolate_o <= 1'b0;
        b_clear_o <= 1'b1;
    end else begin
        case (state_b)
            IDLE: begin
                if (b_clear_i || sync_a_ack[1]) begin
                    state_b <= ISOLATE;
                    b_isolate_o <= 1'b1;
                end
            end
            ISOLATE: begin
                if (a_isolate_ack_i && b_isolate_ack_i) begin
                    state_b <= CLEAR_A;
                    a_clear_o <= 1'b0;
                end
            end
            CLEAR_A: begin
                if (sync_a_ack[1]) begin
                    state_b <= CLEAR_B;
                    b_clear_o <= 1'b0;
                end
            end
            CLEAR_B: begin
                if (sync_b_ack[1]) begin
                    state_b <= RELEASE;
                    b_isolate_o <= 1'b0;
                    b_clear_o <= 1'b1;
                end
            end
            RELEASE: begin
                state_b <= IDLE;
            end
            default: state_b <= IDLE;
        endcase
    end
end

endmodule
