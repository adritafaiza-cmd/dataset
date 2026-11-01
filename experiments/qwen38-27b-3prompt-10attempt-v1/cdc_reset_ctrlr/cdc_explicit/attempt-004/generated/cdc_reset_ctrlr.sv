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

    // Internal state for domain A
    reg a_isolate_reg;
    reg a_clear_reg;
    reg a_b_isolate_synced;
    reg a_b_clear_synced;
    reg a_b_isolate_ack_synced;
    reg a_b_clear_ack_synced;

    // Internal state for domain B
    reg b_isolate_reg;
    reg b_clear_reg;
    reg b_a_isolate_synced;
    reg b_a_clear_synced;
    reg b_a_isolate_ack_synced;
    reg b_a_clear_ack_synced;

    // Synchronizer for a_isolate_o to domain B
    reg [SYNC_STAGES-1:0] a_isolate_sync;
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni)
            a_isolate_sync <= {SYNC_STAGES{1'b0}};
        else
            a_isolate_sync <= {a_isolate_sync[SYNC_STAGES-2:0], a_isolate_reg};
    end
    assign b_a_isolate_synced = a_isolate_sync[SYNC_STAGES-1];

    // Synchronizer for a_clear_o to domain B
    reg [SYNC_STAGES-1:0] a_clear_sync;
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni)
            a_clear_sync <= {SYNC_STAGES{1'b0}};
        else
            a_clear_sync <= {a_clear_sync[SYNC_STAGES-2:0], a_clear_reg};
    end
    assign b_a_clear_synced = a_clear_sync[SYNC_STAGES-1];

    // Synchronizer for a_isolate_ack_i to domain B
    reg [SYNC_STAGES-1:0] a_isolate_ack_sync;
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni)
            a_isolate_ack_sync <= {SYNC_STAGES{1'b0}};
        else
            a_isolate_ack_sync <= {a_isolate_ack_sync[SYNC_STAGES-2:0], a_isolate_ack_i};
    end
    assign b_a_isolate_ack_synced = a_isolate_ack_sync[SYNC_STAGES-1];

    // Synchronizer for a_clear_ack_i to domain B
    reg [SYNC_STAGES-1:0] a_clear_ack_sync;
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni)
            a_clear_ack_sync <= {SYNC_STAGES{1'b0}};
        else
            a_clear_ack_sync <= {a_clear_ack_sync[SYNC_STAGES-2:0], a_clear_ack_i};
    end
    assign b_a_clear_ack_synced = a_clear_ack_sync[SYNC_STAGES-1];

    // Synchronizer for b_isolate_o to domain A
    reg [SYNC_STAGES-1:0] b_isolate_sync;
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni)
            b_isolate_sync <= {SYNC_STAGES{1'b0}};
        else
            b_isolate_sync <= {b_isolate_sync[SYNC_STAGES-2:0], b_isolate_reg};
    end
    assign a_b_isolate_synced = b_isolate_sync[SYNC_STAGES-1];

    // Synchronizer for b_clear_o to domain A
    reg [SYNC_STAGES-1:0] b_clear_sync;
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni)
            b_clear_sync <= {SYNC_STAGES{1'b0}};
        else
            b_clear_sync <= {b_clear_sync[SYNC_STAGES-2:0], b_clear_reg};
    end
    assign a_b_clear_synced = b_clear_sync[SYNC_STAGES-1];

    // Synchronizer for b_isolate_ack_i to domain A
    reg [SYNC_STAGES-1:0] b_isolate_ack_sync;
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni)
            b_isolate_ack_sync <= {SYNC_STAGES{1'b0}};
        else
            b_isolate_ack_sync <= {b_isolate_ack_sync[SYNC_STAGES-2:0], b_isolate_ack_i};
    end
    assign a_b_isolate_ack_synced = b_isolate_ack_sync[SYNC_STAGES-1];

    // Synchronizer for b_clear_ack_i to domain A
    reg [SYNC_STAGES-1:0] b_clear_ack_sync;
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni)
            b_clear_ack_sync <= {SYNC_STAGES{1'b0}};
        else
            b_clear_ack_sync <= {b_clear_ack_sync[SYNC_STAGES-2:0], b_clear_ack_i};
    end
    assign a_b_clear_ack_synced = b_clear_ack_sync[SYNC_STAGES-1];

    // Domain A logic
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate_reg <= 1'b0;
            a_clear_reg   <= 1'b0;
        end else begin
            // Raise isolate if local clear requested or peer isolate is active
            if (a_clear_i || a_b_isolate_synced)
                a_isolate_reg <= 1'b1;
            else
                a_isolate_reg <= 1'b0;

            // Raise clear if isolate is active and both isolate acks are received
            if (a_isolate_reg && a_isolate_ack_i && a_b_isolate_ack_synced)
                a_clear_reg <= 1'b1;
            else
                a_clear_reg <= 1'b0;
        end
    end

    assign a_isolate_o = a_isolate_reg;
    assign a_clear_o   = a_clear_reg;

    // Domain B logic
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate_reg <= 1'b0;
            b_clear_reg   <= 1'b0;
        end else begin
            // Raise isolate if local clear requested or peer isolate is active
            if (b_clear_i || b_a_isolate_synced)
                b_isolate_reg <= 1'b1;
            else
                b_isolate_reg <= 1'b0;

            // Raise clear if isolate is active and both isolate acks are received
            if (b_isolate_reg && b_isolate_ack_i && b_a_isolate_ack_synced)
                b_clear_reg <= 1'b1;
            else
                b_clear_reg <= 1'b0;
        end
    end

    assign b_isolate_o = b_isolate_reg;
    assign b_clear_o   = b_clear_reg;

endmodule
