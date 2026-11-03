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

    // Internal signals
    logic a_isolate;
    logic b_isolate;
    logic a_clear_out;
    logic b_clear_out;

    // Synchronization of reset signals
    logic [SYNC_STAGES-1:0] a_rst_sync;
    logic [SYNC_STAGES-1:0] b_rst_sync;

    // Isolate-then-clear logic for side A
    always_ff @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate <= 1'b0;
            a_clear_out <= 1'b0;
        end else begin
            if (a_clear_i && a_isolate_ack_i && !a_clear_out) begin
                a_isolate <= 1'b1;
                a_clear_out <= 1'b1;
            end else if (a_isolate && a_clear_ack_i) begin
                a_isolate <= 1'b0;
                a_clear_out <= 1'b0;
            end
        end
    end

    // Isolate-then-clear logic for side B
    always_ff @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate <= 1'b0;
            b_clear_out <= 1'b0;
        end else begin
            if (b_clear_i && b_isolate_ack_i && !b_clear_out) begin
                b_isolate <= 1'b1;
                b_clear_out <= 1'b1;
            end else if (b_isolate && b_clear_ack_i) begin
                b_isolate <= 1'b0;
                b_clear_out <= 1'b0;
            end
        end
    end

    // Output assignments
    assign a_isolate_o = a_isolate;
    assign b_isolate_o = b_isolate;
    assign a_clear_o = a_clear_out;
    assign b_clear_o = b_clear_out;

    // Clock domain crossing for reset signals
    always_ff @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_rst_sync <= {SYNC_STAGES{1'b1}};
        end else begin
            a_rst_sync <= {a_rst_ni, a_rst_sync[SYNC_STAGES-2:0]};
        end
    end

    always_ff @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_rst_sync <= {SYNC_STAGES{1'b1}};
        end else begin
            b_rst_sync <= {b_rst_ni, b_rst_sync[SYNC_STAGES-2:0]};
        end
    end

endmodule
