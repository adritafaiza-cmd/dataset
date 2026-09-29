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

    // State definitions
    localparam [1:0] IDLE     = 2'd0;
    localparam [1:0] ISOLATE  = 2'd1;
    localparam [1:0] CLEAR    = 2'd2;
    localparam [1:0] RELEASE  = 2'd3;

    // Synchronization registers for cross-domain signals
    reg [SYNC_STAGES-1:0] b_clear_sync_a;
    reg [SYNC_STAGES-1:0] a_clear_sync_b;
    reg [SYNC_STAGES-1:0] b_isolate_ack_sync_a;
    reg [SYNC_STAGES-1:0] b_clear_ack_sync_a;
    reg [SYNC_STAGES-1:0] a_isolate_ack_sync_b;
    reg [SYNC_STAGES-1:0] a_clear_ack_sync_b;

    // State registers for each domain
    reg [1:0] state_a;
    reg [1:0] state_b;

    // Synchronize b_clear_i to a_clk domain
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            b_clear_sync_a <= 0;
        end else begin
            b_clear_sync_a <= {b_clear_sync_a[SYNC_STAGES-2:0], b_clear_i};
        end
    end

    // Synchronize a_clear_i to b_clk domain
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            a_clear_sync_b <= 0;
        end else begin
            a_clear_sync_b <= {a_clear_sync_b[SYNC_STAGES-2:0], a_clear_i};
        end
    end

    // State machine in a_clk domain
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            state_a <= IDLE;
        end else begin
            case (state_a)
                IDLE: begin
                    if (a_clear_i || b_clear_sync_a[SYNC_STAGES-1]) begin
                        state_a <= ISOLATE;
                    end
                end
                ISOLATE: begin
                    if (a_isolate_ack_i && b_isolate_ack_sync_a[SYNC_STAGES-1]) begin
                        state_a <= CLEAR;
                    end
                end
                CLEAR: begin
                    if (a_clear_ack_i && b_clear_ack_sync_a[SYNC_STAGES-1]) begin
                        state_a <= RELEASE;
                    end
                end
                RELEASE: begin
                    state_a <= IDLE;
                end
                default: state_a <= IDLE;
            endcase
        end
    end

    // Synchronize isolate ack from b to a domain
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            b_isolate_ack_sync_a <= 0;
        end else begin
            b_isolate_ack_sync_a <= {b_isolate_ack_sync_a[SYNC_STAGES-2:0], b_isolate_ack_i};
        end
    end

    // Synchronize clear ack from b to a domain
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            b_clear_ack_sync_a <= 0;
        end else begin
            b_clear_ack_sync_a <= {b_clear_ack_sync_a[SYNC_STAGES-2:0], b_clear_ack_i};
        end
    end

    // Assign outputs in a domain
    assign a_isolate_o = (state_a == ISOLATE || state_a == CLEAR || state_a == RELEASE);
    assign a_clear_o   = (state_a == CLEAR || state_a == RELEASE);

    // State machine in b_clk domain
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            state_b <= IDLE;
        end else begin
            case (state_b)
                IDLE: begin
                    if (b_clear_i || a_clear_sync_b[SYNC_STAGES-1]) begin
                        state_b <= ISOLATE;
                    end
                end
                ISOLATE: begin
                    if (b_isolate_ack_i && a_isolate_ack_sync_b[SYNC_STAGES-1]) begin
                        state_b <= CLEAR;
                    end
                end
                CLEAR: begin
                    if (b_clear_ack_i && a_clear_ack_sync_b[SYNC_STAGES-1]) begin
                        state_b <= RELEASE;
                    end
                end
                RELEASE: begin
                    state_b <= IDLE;
                end
                default: state_b <= IDLE;
            endcase
        end
    end

    // Synchronize isolate ack from a to b domain
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            a_isolate_ack_sync_b <= 0;
        end else begin
            a_isolate_ack_sync_b <= {a_isolate_ack_sync_b[SYNC_STAGES-2:0], a_isolate_ack_i};
        end
    end

    // Synchronize clear ack from a to b domain
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            a_clear_ack_sync_b <= 0;
        end else begin
            a_clear_ack_sync_b <= {a_clear_ack_sync_b[SYNC_STAGES-2:0], a_clear_ack_i};
        end
    end

    // Assign outputs in b domain
    assign b_isolate_o = (state_b == ISOLATE || state_b == CLEAR || state_b == RELEASE);
    assign b_clear_o   = (state_b == CLEAR || state_b == RELEASE);

endmodule
