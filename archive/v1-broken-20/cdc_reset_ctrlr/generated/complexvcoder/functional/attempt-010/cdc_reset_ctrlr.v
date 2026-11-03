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

    reg a_clear_reg;
    reg a_isolate_reg;
    reg b_clear_reg;
    reg b_isolate_reg;
    reg a_clear_ack_reg;
    reg a_isolate_ack_reg;
    reg b_clear_ack_reg;
    reg b_isolate_ack_reg;

    // Internal signals for synchronization
    reg [SYNC_STAGES-1:0] a_clear_sync;
    reg [SYNC_STAGES-1:0] a_isolate_sync;
    reg [SYNC_STAGES-1:0] b_clear_sync;
    reg [SYNC_STAGES-1:0] b_isolate_sync;
    reg [SYNC_STAGES-1:0] a_clear_ack_sync;
    reg [SYNC_STAGES-1:0] a_isolate_ack_sync;
    reg [SYNC_STAGES-1:0] b_clear_ack_sync;
    reg [SYNC_STAGES-1:0] b_isolate_ack_sync;

    // Registers for output signals
    reg a_clear_out;
    reg a_isolate_out;
    reg b_clear_out;
    reg b_isolate_out;

    // Synchronizers for input signals
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_clear_sync <= {SYNC_STAGES{1'b0}};
            a_isolate_sync <= {SYNC_STAGES{1'b0}};
            b_clear_sync <= {SYNC_STAGES{1'b0}};
            b_isolate_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            a_clear_sync <= {a_clear_sync[SYNC_STAGES-2:0], a_clear_i};
            a_isolate_sync <= {a_isolate_sync[SYNC_STAGES-2:0], a_isolate_ack_i};
            b_clear_sync <= {b_clear_sync[SYNC_STAGES-2:0], b_clear_i};
            b_isolate_sync <= {b_isolate_sync[SYNC_STAGES-2:0], b_isolate_ack_i};
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            a_clear_sync <= {SYNC_STAGES{1'b0}};
            a_isolate_sync <= {SYNC_STAGES{1'b0}};
            b_clear_sync <= {SYNC_STAGES{1'b0}};
            b_isolate_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            a_clear_sync <= {a_clear_sync[SYNC_STAGES-2:0], a_clear_i};
            a_isolate_sync <= {a_isolate_sync[SYNC_STAGES-2:0], a_isolate_ack_i};
            b_clear_sync <= {b_clear_sync[SYNC_STAGES-2:0], b_clear_i};
            b_isolate_sync <= {b_isolate_sync[SYNC_STAGES-2:0], b_isolate_ack_i};
        end
    end

    // Registers for output signals
    always @(posedge a_clk_i) begin
        if (!a_rst_ni) begin
            a_clear_out <= 1'b0;
            a_isolate_out <= 1'b0;
        end else begin
            a_clear_out <= (a_clear_sync[SYNC_STAGES-1] & b_clear_sync[SYNC_STAGES-1]) & (a_clear_ack_sync[SYNC_STAGES-1] & b_clear_ack_sync[SYNC_STAGES-1]);
            a_isolate_out <= (a_clear_sync[SYNC_STAGES-1] & b_clear_sync[SYNC_STAGES-1]) & (a_clear_ack_sync[SYNC_STAGES-1] & b_clear_ack_sync[SYNC_STAGES-1]);
        end
    end

    always @(posedge b_clk_i) begin
        if (!b_rst_ni) begin
            b_clear_out <= 1'b0;
            b_isolate_out <= 1'b0;
        end else begin
            b_clear_out <= (a_clear_sync[SYNC_STAGES-1] & b_clear_sync[SYNC_STAGES-1]) & (a_clear_ack_sync[SYNC_STAGES-1] & b_clear_ack_sync[SYNC_STAGES-1]);
            b_isolate_out <= (a_clear_sync[SYNC_STAGES-1] & b_clear_sync[SYNC_STAGES-1]) & (a_clear_ack_sync[SYNC_STAGES-1] & b_clear_ack_sync[SYNC_STAGES-1]);
        end
    end

    // Assign outputs
    assign a_clear_o = a_clear_out;
    assign a_isolate_o = a_isolate_out;
    assign b_clear_o = b_clear_out;
    assign b_isolate_o = b_isolate_out;

endmodule
