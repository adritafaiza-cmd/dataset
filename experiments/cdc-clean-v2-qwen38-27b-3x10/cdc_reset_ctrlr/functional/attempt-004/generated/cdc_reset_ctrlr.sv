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

    // State encoding
    localparam S_IDLE      = 3'd0;
    localparam S_ISOLATE   = 3'd1;
    localparam S_CLEAR     = 3'd2;
    localparam S_RELEASE   = 3'd3;
    localparam S_DONE      = 3'd4;

    // A-side state
    reg [2:0] a_state;
    reg       a_isolate_o_r;
    reg       a_clear_o_r;

    // B-side state
    reg [2:0] b_state;
    reg       b_isolate_o_r;
    reg       b_clear_o_r;

    // Synchronizers for A->B
    reg [SYNC_STAGES-1:0] a_state_sync;
    reg [SYNC_STAGES-1:0] a_isolate_sync;
    reg [SYNC_STAGES-1:0] a_clear_sync;

    // Synchronizers for B->A
    reg [SYNC_STAGES-1:0] b_state_sync;
    reg [SYNC_STAGES-1:0] b_isolate_sync;
    reg [SYNC_STAGES-1:0] b_clear_sync;

    // Synchronized signals
    wire [2:0] a_state_synced = a_state_sync[SYNC_STAGES-1:0];
    wire       a_isolate_synced = a_isolate_sync[SYNC_STAGES-1];
    wire       a_clear_synced = a_clear_sync[SYNC_STAGES-1];

    wire [2:0] b_state_synced = b_state_sync[SYNC_STAGES-1:0];
    wire       b_isolate_synced = b_isolate_sync[SYNC_STAGES-1];
    wire       b_clear_synced = b_clear_sync[SYNC_STAGES-1];

    // A-side logic
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_state <= S_IDLE;
            a_isolate_o_r <= 1'b0;
            a_clear_o_r <= 1'b0;
        end else begin
            case (a_state)
                S_IDLE: begin
                    if (a_clear_i) begin
                        a_state <= S_ISOLATE;
                        a_isolate_o_r <= 1'b1;
                    end
                end
                S_ISOLATE: begin
                    // Wait for both isolate acks
                    if (a_isolate_ack_i && b_isolate_synced) begin
                        a_state <= S_CLEAR;
                        a_clear_o_r <= 1'b1;
                    end
                end
                S_CLEAR: begin
                    // Wait for both clear acks
                    if (a_clear_ack_i && b_clear_synced) begin
                        a_state <= S_RELEASE;
                        a_clear_o_r <= 1'b0;
                    end
                end
                S_RELEASE: begin
                    // Wait for peer to observe release (peer state should be S_RELEASE or S_DONE)
                    if (b_state_synced == S_RELEASE || b_state_synced == S_DONE) begin
                        a_state <= S_DONE;
                        a_isolate_o_r <= 1'b0;
                    end
                end
                S_DONE: begin
                    // Wait for peer to return to idle
                    if (b_state_synced == S_IDLE) begin
                        a_state <= S_IDLE;
                    end
                end
                default: begin
                    a_state <= S_IDLE;
                    a_isolate_o_r <= 1'b0;
                    a_clear_o_r <= 1'b0;
                end
            endcase
        end
    end

    // B-side logic
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_state <= S_IDLE;
            b_isolate_o_r <= 1'b0;
            b_clear_o_r <= 1'b0;
        end else begin
            case (b_state)
                S_IDLE: begin
                    if (b_clear_i) begin
                        b_state <= S_ISOLATE;
                        b_isolate_o_r <= 1'b1;
                    end
                end
                S_ISOLATE: begin
                    // Wait for both isolate acks
                    if (b_isolate_ack_i && a_isolate_synced) begin
                        b_state <= S_CLEAR;
                        b_clear_o_r <= 1'b1;
                    end
                end
                S_CLEAR: begin
                    // Wait for both clear acks
                    if (b_clear_ack_i && a_clear_synced) begin
                        b_state <= S_RELEASE;
                        b_clear_o_r <= 1'b0;
                    end
                end
                S_RELEASE: begin
                    // Wait for peer to observe release
                    if (a_state_synced == S_RELEASE || a_state_synced == S_DONE) begin
                        b_state <= S_DONE;
                        b_isolate_o_r <= 1'b0;
                    end
                end
                S_DONE: begin
                    // Wait for peer to return to idle
                    if (a_state_synced == S_IDLE) begin
                        b_state <= S_IDLE;
                    end
                end
                default: begin
                    b_state <= S_IDLE;
                    b_isolate_o_r <= 1'b0;
                    b_clear_o_r <= 1'b0;
                end
            endcase
        end
    end

    // A->B synchronizers
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            a_state_sync <= {SYNC_STAGES{1'b0}};
            a_isolate_sync <= {SYNC_STAGES{1'b0}};
            a_clear_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            a_state_sync <= {a_state_sync[SYNC_STAGES-2:0], a_state};
            a_isolate_sync <= {a_isolate_sync[SYNC_STAGES-2:0], a_isolate_o_r};
            a_clear_sync <= {a_clear_sync[SYNC_STAGES-2:0], a_clear_o_r};
        end
    end

    // B->A synchronizers
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            b_state_sync <= {SYNC_STAGES{1'b0}};
            b_isolate_sync <= {SYNC_STAGES{1'b0}};
            b_clear_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            b_state_sync <= {b_state_sync[SYNC_STAGES-2:0], b_state};
            b_isolate_sync <= {b_isolate_sync[SYNC_STAGES-2:0], b_isolate_o_r};
            b_clear_sync <= {b_clear_sync[SYNC_STAGES-2:0], b_clear_o_r};
        end
    end

    // Outputs
    assign a_isolate_o = a_isolate_o_r;
    assign a_clear_o = a_clear_o_r;
    assign b_isolate_o = b_isolate_o_r;
    assign b_clear_o = b_clear_o_r;

endmodule
