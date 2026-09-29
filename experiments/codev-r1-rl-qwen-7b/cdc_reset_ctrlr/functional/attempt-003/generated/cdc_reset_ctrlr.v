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

// State machine for a domain
typedef enum logic [1:0] {
    A_IDLE,
    A_ISO,
    A_CLEAR,
    A_DONE
} a_state_t;

reg [1:0] a_state;
reg a_clear_reg;
reg a_isolate_reg;

// Synchronization registers for b's ack signals
reg [SYNC_STAGES-1:0] a_sync_b_isolate_ack;
reg [SYNC_STAGES-1:0] a_sync_b_clear_ack;

// Synchronize b's isolate ack to a's clock
always @(posedge a_clk_i or negedge a_rst_ni) begin
    if (!a_rst_ni) begin
        a_sync_b_isolate_ack <= 0;
    end else begin
        a_sync_b_isolate_ack <= {a_sync_b_isolate_ack[SYNC_STAGES-2:0], b_isolate_ack_i};
    end
end

// Synchronize b's clear ack to a's clock
always @(posedge a_clk_i or negedge a_rst_ni) begin
    if (!a_rst_ni) begin
        a_sync_b_clear_ack <= 0;
    end else begin
        a_sync_b_clear_ack <= {a_sync_b_clear_ack[SYNC_STAGES-2:0], b_clear_ack_i};
    end
end

// State machine logic for a domain
always @(posedge a_clk_i or negedge a_rst_ni) begin
    if (!a_rst_ni) begin
        a_state <= A_IDLE;
        a_isolate_reg <= 0;
        a_clear_reg <= 0;
    end else begin
        case (a_state)
            A_IDLE: begin
                if (a_clear_i) begin
                    a_state <= A_ISO;
                    a_isolate_reg <= 1;
                end
            end
            A_ISO: begin
                if (a_isolate_ack_i && a_sync_b_isolate_ack[SYNC_STAGES-1]) begin
                    a_state <= A_CLEAR;
                    a_clear_reg <= 1;
                end
            end
            A_CLEAR: begin
                if (a_clear_ack_i && a_sync_b_clear_ack[SYNC_STAGES-1]) begin
                    a_state <= A_DONE;
                    a_clear_reg <= 0;
                    a_isolate_reg <= 0;
                end
            end
            A_DONE: begin
                a_state <= A_IDLE;
            end
        endcase
    end
end

assign a_isolate_o = a_isolate_reg;
assign a_clear_o = a_clear_reg;

// State machine for b domain
typedef enum logic [1:0] {
    B_IDLE,
    B_ISO,
    B_CLEAR,
    B_DONE
} b_state_t;

reg [1:0] b_state;
reg b_clear_reg;
reg b_isolate_reg;

// Synchronization registers for a's ack signals
reg [SYNC_STAGES-1:0] b_sync_a_isolate_ack;
reg [SYNC_STAGES-1:0] b_sync_a_clear_ack;

// Synchronize a's isolate ack to b's clock
always @(posedge b_clk_i or negedge b_rst_ni) begin
    if (!b_rst_ni) begin
        b_sync_a_isolate_ack <= 0;
    end else begin
        b_sync_a_isolate_ack <= {b_sync_a_isolate_ack[SYNC_STAGES-2:0], a_isolate_ack_i};
    end
end

// Synchronize a's clear ack to b's clock
always @(posedge b_clk_i or negedge b_rst_ni) begin
    if (!b_rst_ni) begin
        b_sync_a_clear_ack <= 0;
    end else begin
        b_sync_a_clear_ack <= {b_sync_a_clear_ack[SYNC_STAGES-2:0], a_clear_ack_i};
    end
end

// State machine logic for b domain
always @(posedge b_clk_i or negedge b_rst_ni) begin
    if (!b_rst_ni) begin
        b_state <= B_IDLE;
        b_isolate_reg <= 0;
        b_clear_reg <= 0;
    end else begin
        case (b_state)
            B_IDLE: begin
                if (b_clear_i) begin
                    b_state <= B_ISO;
                    b_isolate_reg <= 1;
                end
            end
            B_ISO: begin
                if (b_isolate_ack_i && b_sync_a_isolate_ack[SYNC_STAGES-1]) begin
                    b_state <= B_CLEAR;
                    b_clear_reg <= 1;
                end
            end
            B_CLEAR: begin
                if (b_clear_ack_i && b_sync_a_clear_ack[SYNC_STAGES-1]) begin
                    b_state <= B_DONE;
                    b_clear_reg <= 0;
                    b_isolate_reg <= 0;
                end
            end
            B_DONE: begin
                b_state <= B_IDLE;
            end
        endcase
    end
end

assign b_isolate_o = b_isolate_reg;
assign b_clear_o = b_clear_reg;

endmodule
