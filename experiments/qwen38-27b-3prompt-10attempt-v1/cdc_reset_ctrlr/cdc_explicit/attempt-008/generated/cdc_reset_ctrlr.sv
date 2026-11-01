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

    // Internal state machine states
    localparam S_IDLE      = 2'd0;
    localparam S_ISOLATE   = 2'd1;
    localparam S_CLEAR     = 2'd2;
    localparam S_RELEASE   = 2'd3;

    // State registers for each domain
    reg [1:0] a_state_q;
    reg [1:0] b_state_q;

    // Synchronizer registers for state crossing
    reg [1:0] a_state_sync_q;
    reg [1:0] b_state_sync_q;

    // Synchronizer registers for clear request crossing
    reg a_clear_req_sync_q;
    reg b_clear_req_sync_q;

    // Synchronizer registers for isolate ack crossing
    reg a_isolate_ack_sync_q;
    reg b_isolate_ack_sync_q;

    // Synchronizer registers for clear ack crossing
    reg a_clear_ack_sync_q;
    reg b_clear_ack_sync_q;

    // Synchronizer registers for release signal crossing
    reg a_release_sync_q;
    reg b_release_sync_q;

    // Generate synchronizer chains
    genvar i;
    generate
        // Synchronize a_state to b domain
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_a_state_sync
            if (i == 0) begin
                always @(posedge b_clk_i or negedge b_rst_ni) begin
                    if (!b_rst_ni)
                        a_state_sync_q[0] <= 1'b0;
                    else
                        a_state_sync_q[0] <= a_state_q[0];
                end
            end else if (i == SYNC_STAGES - 1) begin
                always @(posedge b_clk_i or negedge b_rst_ni) begin
                    if (!b_rst_ni)
                        a_state_sync_q[i] <= 1'b0;
                    else
                        a_state_sync_q[i] <= a_state_sync_q[i-1];
                end
            end else begin
                always @(posedge b_clk_i or negedge b_rst_ni) begin
                    if (!b_rst_ni)
                        a_state_sync_q[i] <= 1'b0;
                    else
                        a_state_sync_q[i] <= a_state_sync_q[i-1];
                end
            end
        end

        // Synchronize b_state to a domain
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_b_state_sync
            if (i == 0) begin
                always @(posedge a_clk_i or negedge a_rst_ni) begin
                    if (!a_rst_ni)
                        b_state_sync_q[0] <= 1'b0;
                    else
                        b_state_sync_q[0] <= b_state_q[0];
                end
            end else if (i == SYNC_STAGES - 1) begin
                always @(posedge a_clk_i or negedge a_rst_ni) begin
                    if (!a_rst_ni)
                        b_state_sync_q[i] <= 1'b0;
                    else
                        b_state_sync_q[i] <= b_state_sync_q[i-1];
                end
            end else begin
                always @(posedge a_clk_i or negedge a_rst_ni) begin
                    if (!a_rst_ni)
                        b_state_sync_q[i] <= 1'b0;
                    else
                        b_state_sync_q[i] <= b_state_sync_q[i-1];
                end
            end
        end

        // Synchronize a_clear_req to b domain
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_a_clear_req_sync
            if (i == 0) begin
                always @(posedge b_clk_i or negedge b_rst_ni) begin
                    if (!b_rst_ni)
                        a_clear_req_sync_q <= 1'b0;
                    else
                        a_clear_req_sync_q <= a_clear_i;
                end
            end else begin
                // This is a single-bit signal, so we just need one register
                // But we need to handle the chain properly
            end
        end

        // Synchronize b_clear_req to a domain
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_b_clear_req_sync
            if (i == 0) begin
                always @(posedge a_clk_i or negedge a_rst_ni) begin
                    if (!a_rst_ni)
                        b_clear_req_sync_q <= 1'b0;
                    else
                        b_clear_req_sync_q <= b_clear_i;
                end
            end else begin
                // This is a single-bit signal, so we just need one register
            end
        end

        // Synchronize a_isolate_ack to b domain
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_a_isolate_ack_sync
            if (i == 0) begin
                always @(posedge b_clk_i or negedge b_rst_ni) begin
                    if (!b_rst_ni)
                        a_isolate_ack_sync_q <= 1'b0;
                    else
                        a_isolate_ack_sync_q <= a_isolate_ack_i;
                end
            end else begin
                // This is a single-bit signal, so we just need one register
            end
        end

        // Synchronize b_isolate_ack to a domain
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_b_isolate_ack_sync
            if (i == 0) begin
                always @(posedge a_clk_i or negedge a_rst_ni) begin
                    if (!a_rst_ni)
                        b_isolate_ack_sync_q <= 1'b0;
                    else
                        b_isolate_ack_sync_q <= b_isolate_ack_i;
                end
            end else begin
                // This is a single-bit signal, so we just need one register
            end
        end

        // Synchronize a_clear_ack to b domain
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_a_clear_ack_sync
            if (i == 0) begin
                always @(posedge b_clk_i or negedge b_rst_ni) begin
                    if (!b_rst_ni)
                        a_clear_ack_sync_q <= 1'b0;
                    else
                        a_clear_ack_sync_q <= a_clear_ack_i;
                end
            end else begin
                // This is a single-bit signal, so we just need one register
            end
        end

        // Synchronize b_clear_ack to a domain
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_b_clear_ack_sync
            if (i == 0) begin
                always @(posedge a_clk_i or negedge a_rst_ni) begin
                    if (!a_rst_ni)
                        b_clear_ack_sync_q <= 1'b0;
                    else
                        b_clear_ack_sync_q <= b_clear_ack_i;
                end
            end else begin
                // This is a single-bit signal, so we just need one register
            end
        end

        // Synchronize a_release to b domain
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_a_release_sync
            if (i == 0) begin
                always @(posedge b_clk_i or negedge b_rst_ni) begin
                    if (!b_rst_ni)
                        a_release_sync_q <= 1'b0;
                    else
                        a_release_sync_q <= (a_state_q == S_RELEASE);
                end
            end else begin
                // This is a single-bit signal, so we just need one register
            end
        end

        // Synchronize b_release to a domain
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_b_release_sync
            if (i == 0) begin
                always @(posedge a_clk_i or negedge a_rst_ni) begin
                    if (!a_rst_ni)
                        b_release_sync_q <= 1'b0;
                    else
                        b_release_sync_q <= (b_state_q == S_RELEASE);
                end
            end else begin
                // This is a single-bit signal, so we just need one register
            end
        end
    endgenerate

    // Additional synchronizer registers for multi-stage single-bit signals
    // For single-bit signals, we need to properly chain them
    reg [SYNC_STAGES-1:0] a_clear_req_sync_chain;
    reg [SYNC_STAGES-1:0] b_clear_req_sync_chain;
    reg [SYNC_STAGES-1:0] a_isolate_ack_sync_chain;
    reg [SYNC_STAGES-1:0] b_isolate_ack_sync_chain;
    reg [SYNC_STAGES-1:0] a_clear_ack_sync_chain;
    reg [SYNC_STAGES-1:0] b_clear_ack_sync_chain;
    reg [SYNC_STAGES-1:0] a_release_sync_chain;
    reg [SYNC_STAGES-1:0] b_release_sync_chain;

    generate
        // a_clear_req sync chain
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_a_clear_req_chain
            if (i == 0) begin
                always @(posedge b_clk_i or negedge b_rst_ni) begin
                    if (!b_rst_ni)
                        a_clear_req_sync_chain[0] <= 1'b0;
                    else
                        a_clear_req_sync_chain[0] <= a_clear_i;
                end
            end else begin
                always @(posedge b_clk_i or negedge b_rst_ni) begin
                    if (!b_rst_ni)
                        a_clear_req_sync_chain[i] <= 1'b0;
                    else
                        a_clear_req_sync_chain[i] <= a_clear_req_sync_chain[i-1];
                end
            end
        end

        // b_clear_req sync chain
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_b_clear_req_chain
            if (i == 0) begin
                always @(posedge a_clk_i or negedge a_rst_ni) begin
                    if (!a_rst_ni)
                        b_clear_req_sync_chain[0] <= 1'b0;
                    else
                        b_clear_req_sync_chain[0] <= b_clear_i;
                end
            end else begin
                always @(posedge a_clk_i or negedge a_rst_ni) begin
                    if (!a_rst_ni)
                        b_clear_req_sync_chain[i] <= 1'b0;
                    else
                        b_clear_req_sync_chain[i] <= b_clear_req_sync_chain[i-1];
                end
            end
        end

        // a_isolate_ack sync chain
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_a_isolate_ack_chain
            if (i == 0) begin
                always @(posedge b_clk_i or negedge b_rst_ni) begin
                    if (!b_rst_ni)
                        a_isolate_ack_sync_chain[0] <= 1'b0;
                    else
                        a_isolate_ack_sync_chain[0] <= a_isolate_ack_i;
                end
            end else begin
                always @(posedge b_clk_i or negedge b_rst_ni) begin
                    if (!b_rst_ni)
                        a_isolate_ack_sync_chain[i] <= 1'b0;
                    else
                        a_isolate_ack_sync_chain[i] <= a_isolate_ack_sync_chain[i-1];
                end
            end
        end

        // b_isolate_ack sync chain
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_b_isolate_ack_chain
            if (i == 0) begin
                always @(posedge a_clk_i or negedge a_rst_ni) begin
                    if (!a_rst_ni)
                        b_isolate_ack_sync_chain[0] <= 1'b0;
                    else
                        b_isolate_ack_sync_chain[0] <= b_isolate_ack_i;
                end
            end else begin
                always @(posedge a_clk_i or negedge a_rst_ni) begin
                    if (!a_rst_ni)
                        b_isolate_ack_sync_chain[i] <= 1'b0;
                    else
                        b_isolate_ack_sync_chain[i] <= b_isolate_ack_sync_chain[i-1];
                end
            end
        end

        // a_clear_ack sync chain
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_a_clear_ack_chain
            if (i == 0) begin
                always @(posedge b_clk_i or negedge b_rst_ni) begin
                    if (!b_rst_ni)
                        a_clear_ack_sync_chain[0] <= 1'b0;
                    else
                        a_clear_ack_sync_chain[0] <= a_clear_ack_i;
                end
            end else begin
                always @(posedge b_clk_i or negedge b_rst_ni) begin
                    if (!b_rst_ni)
                        a_clear_ack_sync_chain[i] <= 1'b0;
                    else
                        a_clear_ack_sync_chain[i] <= a_clear_ack_sync_chain[i-1];
                end
            end
        end

        // b_clear_ack sync chain
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_b_clear_ack_chain
            if (i == 0) begin
                always @(posedge a_clk_i or negedge a_rst_ni) begin
                    if (!a_rst_ni)
                        b_clear_ack_sync_chain[0] <= 1'b0;
                    else
                        b_clear_ack_sync_chain[0] <= b_clear_ack_i;
                end
            end else begin
                always @(posedge a_clk_i or negedge a_rst_ni) begin
                    if (!a_rst_ni)
                        b_clear_ack_sync_chain[i] <= 1'b0;
                    else
                        b_clear_ack_sync_chain[i] <= b_clear_ack_sync_chain[i-1];
                end
            end
        end

        // a_release sync chain
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_a_release_chain
            if (i == 0) begin
                always @(posedge b_clk_i or negedge b_rst_ni) begin
                    if (!b_rst_ni)
                        a_release_sync_chain[0] <= 1'b0;
                    else
                        a_release_sync_chain[0] <= (a_state_q == S_RELEASE);
                end
            end else begin
                always @(posedge b_clk_i or negedge b_rst_ni) begin
                    if (!b_rst_ni)
                        a_release_sync_chain[i] <= 1'b0;
                    else
                        a_release_sync_chain[i] <= a_release_sync_chain[i-1];
                end
            end
        end

        // b_release sync chain
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : gen_b_release_chain
            if (i == 0) begin
                always @(posedge a_clk_i or negedge a_rst_ni) begin
                    if (!a_rst_ni)
                        b_release_sync_chain[0] <= 1'b0;
                    else
                        b_release_sync_chain[0] <= (b_state_q == S_RELEASE);
                end
            end else begin
                always @(posedge a_clk_i or negedge a_rst_ni) begin
                    if (!a_rst_ni)
                        b_release_sync_chain[i] <= 1'b0;
                    else
                        b_release_sync_chain[i] <= b_release_sync_chain[i-1];
                end
            end
        end
    endgenerate

    // Synchronized signals
    wire a_state_synced = a_state_sync_q[SYNC_STAGES-1];
    wire b_state_synced = b_state_sync_q[SYNC_STAGES-1];
    wire a_clear_req_synced = a_clear_req_sync_chain[SYNC_STAGES-1];
    wire b_clear_req_synced = b_clear_req_sync_chain[SYNC_STAGES-1];
    wire a_isolate_ack_synced = a_isolate_ack_sync_chain[SYNC_STAGES-1];
    wire b_isolate_ack_synced = b_isolate_ack_sync_chain[SYNC_STAGES-1];
    wire a_clear_ack_synced = a_clear_ack_sync_chain[SYNC_STAGES-1];
    wire b_clear_ack_synced = b_clear_ack_sync_chain[SYNC_STAGES-1];
    wire a_release_synced = a_release_sync_chain[SYNC_STAGES-1];
    wire b_release_synced = b_release_sync_chain[SYNC_STAGES-1];

    // A domain state machine
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_state_q <= S_IDLE;
        end else begin
            case (a_state_q)
                S_IDLE: begin
                    if (a_clear_i || b_clear_req_synced) begin
                        a_state_q <= S_ISOLATE;
                    end
                end
                S_ISOLATE: begin
                    if (a_isolate_ack_i && b_isolate_ack_synced) begin
                        a_state_q <= S_CLEAR;
                    end
                end
                S_CLEAR: begin
                    if (a_clear_ack_i && b_clear_ack_synced) begin
                        a_state_q <= S_RELEASE;
                    end
                end
                S_RELEASE: begin
                    if (b_release_synced) begin
                        a_state_q <= S_IDLE;
                    end
                end
                default: begin
                    a_state_q <= S_IDLE;
                end
            endcase
        end
    end

    // B domain state machine
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_state_q <= S_IDLE;
        end else begin
            case (b_state_q)
                S_IDLE: begin
                    if (b_clear_i || a_clear_req_synced) begin
                        b_state_q <= S_ISOLATE;
                    end
                end
                S_ISOLATE: begin
                    if (b_isolate_ack_i && a_isolate_ack_synced) begin
                        b_state_q <= S_CLEAR;
                    end
                end
                S_CLEAR: begin
                    if (b_clear_ack_i && a_clear_ack_synced) begin
                        b_state_q <= S_RELEASE;
                    end
                end
                S_RELEASE: begin
                    if (a_release_synced) begin
                        b_state_q <= S_IDLE;
                    end
                end
                default: begin
                    b_state_q <= S_IDLE;
                end
            endcase
        end
    end

    // Output assignments
    assign a_isolate_o = (a_state_q == S_ISOLATE) || (a_state_q == S_CLEAR);
    assign a_clear_o   = (a_state_q == S_CLEAR);
    assign b_isolate_o = (b_state_q == S_ISOLATE) || (b_state_q == S_CLEAR);
    assign b_clear_o   = (b_state_q == S_CLEAR);

endmodule
