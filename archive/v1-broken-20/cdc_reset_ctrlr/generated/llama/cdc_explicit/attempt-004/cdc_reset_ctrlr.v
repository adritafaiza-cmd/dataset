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

    reg [1:0] a_state, b_state;
    reg a_isolate_sync, b_isolate_sync;
    reg a_clear_sync, b_clear_sync;
    reg a_isolate, b_isolate;
    reg a_clear, b_clear;

    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_state <= 0;
            a_isolate_sync <= 0;
            a_clear_sync <= 0;
            a_isolate <= 0;
            a_clear <= 0;
        end else begin
            case (a_state)
                0: begin
                    if (a_clear_i) begin
                        a_state <= 1;
                        a_isolate_sync <= 1;
                    end
                end
                1: begin
                    if (a_isolate_sync && b_isolate_sync) begin
                        a_state <= 2;
                        a_clear_sync <= 1;
                    end
                end
                2: begin
                    if (a_clear_sync && b_clear_sync) begin
                        a_state <= 3;
                    end
                end
                3: begin
                    if (a_clear_ack_i && b_clear_ack_i) begin
                        a_state <= 0;
                        a_isolate_sync <= 0;
                        a_clear_sync <= 0;
                    end
                end
            endcase
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_state <= 0;
            b_isolate_sync <= 0;
            b_clear_sync <= 0;
            b_isolate <= 0;
            b_clear <= 0;
        end else begin
            case (b_state)
                0: begin
                    if (b_clear_i) begin
                        b_state <= 1;
                        b_isolate_sync <= 1;
                    end
                end
                1: begin
                    if (a_isolate_sync && b_isolate_sync) begin
                        b_state <= 2;
                        b_clear_sync <= 1;
                    end
                end
                2: begin
                    if (a_clear_sync && b_clear_sync) begin
                        b_state <= 3;
                    end
                end
                3: begin
                    if (a_clear_ack_i && b_clear_ack_i) begin
                        b_state <= 0;
                        b_isolate_sync <= 0;
                        b_clear_sync <= 0;
                    end
                end
            endcase
        end
    end

    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate <= 0;
        end else if (a_isolate_sync) begin
            a_isolate <= 1;
        end else if (a_state == 3) begin
            a_isolate <= 0;
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate <= 0;
        end else if (b_isolate_sync) begin
            b_isolate <= 1;
        end else if (b_state == 3) begin
            b_isolate <= 0;
        end
    end

    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_clear <= 0;
        end else if (a_clear_sync) begin
            a_clear <= 1;
        end else if (a_state == 3) begin
            a_clear <= 0;
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_clear <= 0;
        end else if (b_clear_sync) begin
            b_clear <= 1;
        end else if (b_state == 3) begin
            b_clear <= 0;
        end
    end

    // CDC for a_isolate_sync
    reg [SYNC_STAGES-1:0] a_isolate_sync_cdc;
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            a_isolate_sync_cdc <= 0;
        end else begin
            a_isolate_sync_cdc <= {a_isolate_sync_cdc[SYNC_STAGES-2:0], a_isolate_sync};
        end
    end
    assign b_isolate_sync = a_isolate_sync_cdc[SYNC_STAGES-1];

    // CDC for b_isolate_sync
    reg [SYNC_STAGES-1:0] b_isolate_sync_cdc;
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            b_isolate_sync_cdc <= 0;
        end else begin
            b_isolate_sync_cdc <= {b_isolate_sync_cdc[SYNC_STAGES-2:0], b_isolate_sync};
        end
    end
    assign a_isolate_sync = b_isolate_sync_cdc[SYNC_STAGES-1];

    // CDC for a_clear_sync
    reg [SYNC_STAGES-1:0] a_clear_sync_cdc;
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            a_clear_sync_cdc <= 0;
        end else begin
            a_clear_sync_cdc <= {a_clear_sync_cdc[SYNC_STAGES-2:0], a_clear_sync};
        end
    end
    assign b_clear_sync = a_clear_sync_cdc[SYNC_STAGES-1];

    // CDC for b_clear_sync
    reg [SYNC_STAGES-1:0] b_clear_sync_cdc;
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            b_clear_sync_cdc <= 0;
        end else begin
            b_clear_sync_cdc <= {b_clear_sync_cdc[SYNC_STAGES-2:0], b_clear_sync};
        end
    end
    assign a_clear_sync = b_clear_sync_cdc[SYNC_STAGES-1];

    assign a_isolate_o = a_isolate;
    assign b_isolate_o = b_isolate;
    assign a_clear_o = a_clear;
    assign b_clear_o = b_clear;

endmodule
