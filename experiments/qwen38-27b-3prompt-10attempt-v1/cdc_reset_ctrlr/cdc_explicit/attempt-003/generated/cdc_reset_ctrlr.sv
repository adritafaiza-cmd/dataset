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

    // Internal state machines
    reg [1:0] a_state;
    reg [1:0] b_state;

    localparam A_IDLE      = 2'd0;
    localparam A_ISOLATE   = 2'd1;
    localparam A_CLEAR     = 2'd2;
    localparam A_RELEASE   = 2'd3;

    localparam B_IDLE      = 2'd0;
    localparam B_ISOLATE   = 2'd1;
    localparam B_CLEAR     = 2'd2;
    localparam B_RELEASE   = 2'd3;

    // Synchronizers for cross-domain signals
    // A side needs to see B's isolate and clear requests
    reg [SYNC_STAGES-1:0] b_isolate_req_sync;
    reg [SYNC_STAGES-1:0] b_clear_req_sync;
    reg [SYNC_STAGES-1:0] b_isolate_done_sync;
    reg [SYNC_STAGES-1:0] b_clear_done_sync;

    // B side needs to see A's isolate and clear requests
    reg [SYNC_STAGES-1:0] a_isolate_req_sync;
    reg [SYNC_STAGES-1:0] a_clear_req_sync;
    reg [SYNC_STAGES-1:0] a_isolate_done_sync;
    reg [SYNC_STAGES-1:0] a_clear_done_sync;

    // Synchronizer outputs
    wire b_isolate_req_synced  = b_isolate_req_sync[SYNC_STAGES-1];
    wire b_clear_req_synced    = b_clear_req_sync[SYNC_STAGES-1];
    wire b_isolate_done_synced = b_isolate_done_sync[SYNC_STAGES-1];
    wire b_clear_done_synced   = b_clear_done_sync[SYNC_STAGES-1];

    wire a_isolate_req_synced  = a_isolate_req_sync[SYNC_STAGES-1];
    wire a_clear_req_synced    = a_clear_req_sync[SYNC_STAGES-1];
    wire a_isolate_done_synced = a_isolate_done_sync[SYNC_STAGES-1];
    wire a_clear_done_synced   = a_clear_done_sync[SYNC_STAGES-1];

    // Synchronizer logic for B->A signals
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            b_isolate_req_sync  <= {SYNC_STAGES{1'b0}};
            b_clear_req_sync    <= {SYNC_STAGES{1'b0}};
            b_isolate_done_sync <= {SYNC_STAGES{1'b0}};
            b_clear_done_sync   <= {SYNC_STAGES{1'b0}};
        end else begin
            b_isolate_req_sync  <= {b_isolate_req_sync[SYNC_STAGES-2:0], b_isolate_o};
            b_clear_req_sync    <= {b_clear_req_sync[SYNC_STAGES-2:0], b_clear_o};
            b_isolate_done_sync <= {b_isolate_done_sync[SYNC_STAGES-2:0], b_isolate_ack_i};
            b_clear_done_sync   <= {b_clear_done_sync[SYNC_STAGES-2:0], b_clear_ack_i};
        end
    end

    // Synchronizer logic for A->B signals
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            a_isolate_req_sync  <= {SYNC_STAGES{1'b0}};
            a_clear_req_sync    <= {SYNC_STAGES{1'b0}};
            a_isolate_done_sync <= {SYNC_STAGES{1'b0}};
            a_clear_done_sync   <= {SYNC_STAGES{1'b0}};
        end else begin
            a_isolate_req_sync  <= {a_isolate_req_sync[SYNC_STAGES-2:0], a_isolate_o};
            a_clear_req_sync    <= {a_clear_req_sync[SYNC_STAGES-2:0], a_clear_o};
            a_isolate_done_sync <= {a_isolate_done_sync[SYNC_STAGES-2:0], a_isolate_ack_i};
            a_clear_done_sync   <= {a_clear_done_sync[SYNC_STAGES-2:0], a_clear_ack_i};
        end
    end

    // A-side state machine
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_state <= A_IDLE;
        end else begin
            case (a_state)
                A_IDLE: begin
                    if (a_clear_i || b_clear_req_synced) begin
                        a_state <= A_ISOLATE;
                    end
                end
                A_ISOLATE: begin
                    // Wait for both sides to acknowledge isolate
                    if (a_isolate_ack_i && b_isolate_done_synced) begin
                        a_state <= A_CLEAR;
                    end
                end
                A_CLEAR: begin
                    // Wait for both sides to acknowledge clear
                    if (a_clear_ack_i && b_clear_done_synced) begin
                        a_state <= A_RELEASE;
                    end
                end
                A_RELEASE: begin
                    // Release isolate and clear, return to idle
                    a_state <= A_IDLE;
                end
                default: a_state <= A_IDLE;
            endcase
        end
    end

    // B-side state machine
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_state <= B_IDLE;
        end else begin
            case (b_state)
                B_IDLE: begin
                    if (b_clear_i || a_clear_req_synced) begin
                        b_state <= B_ISOLATE;
                    end
                end
                B_ISOLATE: begin
                    // Wait for both sides to acknowledge isolate
                    if (b_isolate_ack_i && a_isolate_done_synced) begin
                        b_state <= B_CLEAR;
                    end
                end
                B_CLEAR: begin
                    // Wait for both sides to acknowledge clear
                    if (b_clear_ack_i && a_clear_done_synced) begin
                        b_state <= B_RELEASE;
                    end
                end
                B_RELEASE: begin
                    // Release isolate and clear, return to idle
                    b_state <= B_IDLE;
                end
                default: b_state <= B_IDLE;
            endcase
        end
    end

    // Output logic
    assign a_isolate_o = (a_state == A_ISOLATE) || (a_state == A_CLEAR);
    assign a_clear_o   = (a_state == A_CLEAR);
    assign b_isolate_o = (b_state == B_ISOLATE) || (b_state == B_CLEAR);
    assign b_clear_o   = (b_state == B_CLEAR);

endmodule
