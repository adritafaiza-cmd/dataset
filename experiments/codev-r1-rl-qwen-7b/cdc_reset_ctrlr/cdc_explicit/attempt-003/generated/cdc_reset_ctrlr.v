module cdc_reset_ctrlr #(
    parameter SYNC_STAGES = 2
) (
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

// A domain state machine
localparam [1:0] A_IDLE = 2'd0;
localparam [1:0] A_ISOLATE = 2'd1;
localparam [1:0] A_CLEAR = 2'd2;

reg [1:0] a_state;
reg a_clear_reg;
reg a_isolate_reg;

// Synchronize B's ack signals into A domain
reg b_clear_ack_sync, b_isolate_ack_sync;
reg b_clear_ack_meta, b_clear_ack_sync_reg;
reg b_isolate_ack_meta, b_isolate_ack_sync_reg;

always @(posedge a_clk_i or negedge a_rst_ni) begin
    if (!a_rst_ni) begin
        b_clear_ack_meta <= 0;
        b_clear_ack_sync_reg <= 0;
        b_isolate_ack_meta <= 0;
        b_isolate_ack_sync_reg <= 0;
    end else begin
        b_clear_ack_meta <= b_clear_ack_i;
        b_clear_ack_sync_reg <= b_clear_ack_meta;
        b_isolate_ack_meta <= b_isolate_ack_i;
        b_isolate_ack_sync_reg <= b_isolate_ack_meta;
    end
end

assign b_clear_ack_sync = b_clear_ack_sync_reg;
assign b_isolate_ack_sync = b_isolate_ack_sync_reg;

// B domain state machine
localparam [1:0] B_IDLE = 2'd0;
localparam [1:0] B_ISOLATE = 2'd1;
localparam [1:0] B_CLEAR = 2'd2;

reg [1:0] b_state;
reg b_clear_reg;
reg b_isolate_reg;

// Synchronize A's ack signals into B domain
reg a_clear_ack_sync, a_isolate_ack_sync;
reg a_clear_ack_meta, a_clear_ack_sync_reg;
reg a_isolate_ack_meta, a_isolate_ack_sync_reg;

always @(posedge b_clk_i or negedge b_rst_ni) begin
    if (!b_rst_ni) begin
        a_clear_ack_meta <= 0;
        a_clear_ack_sync_reg <= 0;
        a_isolate_ack_meta <= 0;
        a_isolate_ack_sync_reg <= 0;
    end else begin
        a_clear_ack_meta <= a_clear_ack_i;
        a_clear_ack_sync_reg <= a_clear_ack_meta;
        a_isolate_ack_meta <= a_isolate_ack_i;
        a_isolate_ack_sync_reg <= a_isolate_ack_meta;
    end
end

assign a_clear_ack_sync = a_clear_ack_sync_reg;
assign a_isolate_ack_sync = a_isolate_ack_sync_reg;

// A state machine
always @(posedge a_clk_i or negedge a_rst_ni) begin
    if (!a_rst_ni) begin
        a_state <= A_IDLE;
        a_clear_reg <= 0;
        a_isolate_reg <= 0;
    end else begin
        case (a_state)
            A_IDLE: begin
                if (a_clear_i || b_clear_ack_sync) begin
                    a_state <= A_ISOLATE;
                    a_isolate_reg <= 1;
                end
            end
            A_ISOLATE: begin
                if (a_isolate_ack_i && b_isolate_ack_sync) begin
                    a_state <= A_CLEAR;
                    a_clear_reg <= 1;
                end
            end
            A_CLEAR: begin
                if (a_clear_ack_i && b_clear_ack_sync) begin
                    a_state <= A_IDLE;
                    a_isolate_reg <= 0;
                    a_clear_reg <= 0;
                end
            end
            default: a_state <= A_IDLE;
        endcase
    end
end

// B state machine
always @(posedge b_clk_i or negedge b_rst_ni) begin
    if (!b_rst_ni) begin
        b_state <= B_IDLE;
        b_clear_reg <= 0;
        b_isolate_reg <= 0;
    end else begin
        case (b_state)
            B_IDLE: begin
                if (b_clear_i || a_clear_ack_sync) begin
                    b_state <= B_ISOLATE;
                    b_isolate_reg <= 1;
                end
            end
            B_ISOLATE: begin
                if (b_isolate_ack_i && a_isolate_ack_sync) begin
                    b_state <= B_CLEAR;
                    b_clear_reg <= 1;
                end
            end
            B_CLEAR: begin
                if (b_clear_ack_i && a_clear_ack_sync) begin
                    b_state <= B_IDLE;
                    b_isolate_reg <= 0;
                    b_clear_reg <= 0;
                end
            end
            default: b_state <= B_IDLE;
        endcase
    end
end

assign a_clear_o = a_clear_reg;
assign a_isolate_o = a_isolate_reg;
assign b_clear_o = b_clear_reg;
assign b_isolate_o = b_isolate_reg;

endmodule
