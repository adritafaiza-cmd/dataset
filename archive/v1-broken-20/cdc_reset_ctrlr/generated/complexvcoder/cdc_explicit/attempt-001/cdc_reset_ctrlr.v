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

    reg a_clear_reg, a_isolate_reg;
    reg b_clear_reg, b_isolate_reg;
    reg [SYNC_STAGES-1:0] a_clear_ack_sync, a_isolate_ack_sync;
    reg [SYNC_STAGES-1:0] b_clear_ack_sync, b_isolate_ack_sync;

    assign a_clear_o = a_clear_reg;
    assign a_isolate_o = a_isolate_reg;
    assign b_clear_o = b_clear_reg;
    assign b_isolate_o = b_isolate_reg;

    // Synchronize clear and isolate requests across clock domains
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_clear_reg <= 1'b0;
            a_isolate_reg <= 1'b0;
        end else begin
            a_clear_reg <= a_clear_i;
            a_isolate_reg <= 1'b0;
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_clear_reg <= 1'b0;
            b_isolate_reg <= 1'b0;
        end else begin
            b_clear_reg <= b_clear_i;
            b_isolate_reg <= 1'b0;
        end
    end

    // Synchronize isolate acks across clock domains
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate_ack_sync <= 0;
        end else begin
            a_isolate_ack_sync <= {a_isolate_ack_sync[SYNC_STAGES-2:0], a_isolate_ack_i};
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate_ack_sync <= 0;
        end else begin
            b_isolate_ack_sync <= {b_isolate_ack_sync[SYNC_STAGES-2:0], b_isolate_ack_i};
        end
    end

    // Synchronize clear acks across clock domains
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_clear_ack_sync <= 0;
        end else begin
            a_clear_ack_sync <= {a_clear_ack_sync[SYNC_STAGES-2:0], a_clear_ack_i};
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_clear_ack_sync <= 0;
        end else begin
            b_clear_ack_sync <= {b_clear_ack_sync[SYNC_STAGES-2:0], b_clear_ack_i};
        end
    end

    // Control clear and isolate signals
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_clear_o <= 1'b0;
            a_isolate_o <= 1'b0;
        end else if (a_clear_reg) begin
            if (|a_isolate_ack_sync) begin
                if (|a_clear_ack_sync) begin
                    a_isolate_o <= 1'b0;
                    a_clear_o <= 1'b0;
                end
            end
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_clear_o <= 1'b0;
            b_isolate_o <= 1'b0;
        end else if (b_clear_reg) begin
            if (|b_isolate_ack_sync) begin
                if (|b_clear_ack_sync) begin
                    b_isolate_o <= 1'b0;
                    b_clear_o <= 1'b0;
                end
            end
        end
    end

endmodule
