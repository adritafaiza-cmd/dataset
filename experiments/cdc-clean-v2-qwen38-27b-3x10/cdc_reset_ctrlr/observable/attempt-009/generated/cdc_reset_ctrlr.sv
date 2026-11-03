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
    localparam S_IDLE     = 3'd0;
    localparam S_ISOLATE  = 3'd1;
    localparam S_CLEAR    = 3'd2;
    localparam S_RELEASE  = 3'd3;

    // A-side state
    reg [2:0] a_state;
    // B-side state
    reg [2:0] b_state;

    // A-side outputs
    assign a_isolate_o = (a_state == S_ISOLATE) || (a_state == S_CLEAR);
    assign a_clear_o   = (a_state == S_CLEAR);

    // B-side outputs
    assign b_isolate_o = (b_state == S_ISOLATE) || (b_state == S_CLEAR);
    assign b_clear_o   = (b_state == S_CLEAR);

    // Synchronizers for A-side signals to B domain
    reg [SYNC_STAGES-1:0] a_isolate_ack_sync;
    reg [SYNC_STAGES-1:0] a_clear_ack_sync;
    reg [SYNC_STAGES-1:0] a_state_sync;

    // Synchronizers for B-side signals to A domain
    reg [SYNC_STAGES-1:0] b_isolate_ack_sync;
    reg [SYNC_STAGES-1:0] b_clear_ack_sync;
    reg [SYNC_STAGES-1:0] b_state_sync;

    // A-side synchronizer logic
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate_ack_sync <= {SYNC_STAGES{1'b0}};
            a_clear_ack_sync   <= {SYNC_STAGES{1'b0}};
            a_state_sync       <= {SYNC_STAGES{3'b0}};
        end else begin
            a_isolate_ack_sync <= {a_isolate_ack_sync[SYNC_STAGES-2:0], a_isolate_ack_i};
            a_clear_ack_sync   <= {a_clear_ack_sync[SYNC_STAGES-2:0], a_clear_ack_i};
            a_state_sync       <= {a_state_sync[SYNC_STAGES-2:0], a_state};
        end
    end

    // B-side synchronizer logic
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate_ack_sync <= {SYNC_STAGES{1'b0}};
            b_clear_ack_sync   <= {SYNC_STAGES{1'b0}};
            b_state_sync       <= {SYNC_STAGES{3'b0}};
        end else begin
            b_isolate_ack_sync <= {b_isolate_ack_sync[SYNC_STAGES-2:0], b_isolate_ack_i};
            b_clear_ack_sync   <= {b_clear_ack_sync[SYNC_STAGES-2:0], b_clear_ack_i};
            b_state_sync       <= {b_state_sync[SYNC_STAGES-2:0], b_state};
        end
    end

    // Synchronized versions
    wire a_isolate_ack_synced = a_isolate_ack_sync[SYNC_STAGES-1];
    wire a_clear_ack_synced   = a_clear_ack_sync[SYNC_STAGES-1];
    wire [2:0] a_state_synced = a_state_sync[SYNC_STAGES-1];

    wire b_isolate_ack_synced = b_isolate_ack_sync[SYNC_STAGES-1];
    wire b_clear_ack_synced   = b_clear_ack_sync[SYNC_STAGES-1];
    wire [2:0] b_state_synced = b_state_sync[SYNC_STAGES-1];

    // A-side state machine
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_state <= S_IDLE;
        end else begin
            case (a_state)
                S_IDLE: begin
                    if (a_clear_i || b_clear_ack_synced) begin
                        a_state <= S_ISOLATE;
                    end
                end
                S_ISOLATE: begin
                    if (a_isolate_ack_synced && b_isolate_ack_synced) begin
                        a_state <= S_CLEAR;
                    end
                end
                S_CLEAR: begin
                    if (a_clear_ack_synced && b_clear_ack_synced) begin
                        a_state <= S_RELEASE;
                    end
                end
                S_RELEASE: begin
                    if (b_state_synced == S_RELEASE || b_state_synced == S_IDLE) begin
                        a_state <= S_IDLE;
                    end
                end
                default: a_state <= S_IDLE;
            endcase
        end
    end

    // B-side state machine
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_state <= S_IDLE;
        end else begin
            case (b_state)
                S_IDLE: begin
                    if (b_clear_i || a_clear_ack_synced) begin
                        b_state <= S_ISOLATE;
                    end
                end
                S_ISOLATE: begin
                    if (b_isolate_ack_synced && a_isolate_ack_synced) begin
                        b_state <= S_CLEAR;
                    end
                end
                S_CLEAR: begin
                    if (b_clear_ack_synced && a_clear_ack_synced) begin
                        b_state <= S_RELEASE;
                    end
                end
                S_RELEASE: begin
                    if (a_state_synced == S_RELEASE || a_state_synced == S_IDLE) begin
                        b_state <= S_IDLE;
                    end
                end
                default: b_state <= S_IDLE;
            endcase
        end
    end

endmodule
