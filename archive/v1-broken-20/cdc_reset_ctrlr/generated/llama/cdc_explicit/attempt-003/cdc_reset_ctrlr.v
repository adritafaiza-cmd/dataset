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
    reg a_isolate_meta, b_isolate_meta;
    reg a_clear_meta, b_clear_meta;

    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_state <= 0;
            a_isolate_sync <= 0;
            a_clear_sync <= 0;
            a_isolate_meta <= 0;
            a_clear_meta <= 0;
        end else begin
            case (a_state)
                0: begin
                    if (a_clear_i) begin
                        a_state <= 1;
                    end
                end
                1: begin
                    if (a_isolate_ack_i && b_isolate_sync) begin
                        a_state <= 2;
                    end
                end
                2: begin
                    if (a_clear_ack_i && b_clear_sync) begin
                        a_state <= 3;
                    end
                end
                3: begin
                    if (!a_clear_i && !b_clear_sync) begin
                        a_state <= 0;
                    end
                end
            endcase

            if (a_clear_i) begin
                a_isolate_meta <= 1;
            end else if (a_state == 3) begin
                a_isolate_meta <= 0;
            end

            if (a_state == 1) begin
                a_isolate_sync <= 1;
            end else if (a_state == 3) begin
                a_isolate_sync <= 0;
            end

            if (a_state == 2) begin
                a_clear_sync <= 1;
            end else if (a_state == 3) begin
                a_clear_sync <= 0;
            end
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_state <= 0;
            b_isolate_sync <= 0;
            b_clear_sync <= 0;
            b_isolate_meta <= 0;
            b_clear_meta <= 0;
        end else begin
            case (b_state)
                0: begin
                    if (b_clear_i) begin
                        b_state <= 1;
                    end
                end
                1: begin
                    if (b_isolate_ack_i && a_isolate_sync) begin
                        b_state <= 2;
                    end
                end
                2: begin
                    if (b_clear_ack_i && a_clear_sync) begin
                        b_state <= 3;
                    end
                end
                3: begin
                    if (!b_clear_i && !a_clear_sync) begin
                        b_state <= 0;
                    end
                end
            endcase

            if (b_clear_i) begin
                b_isolate_meta <= 1;
            end else if (b_state == 3) begin
                b_isolate_meta <= 0;
            end

            if (b_state == 1) begin
                b_isolate_sync <= 1;
            end else if (b_state == 3) begin
                b_isolate_sync <= 0;
            end

            if (b_state == 2) begin
                b_clear_sync <= 1;
            end else if (b_state == 3) begin
                b_clear_sync <= 0;
            end
        end
    end

    assign a_isolate_o = a_isolate_meta;
    assign b_isolate_o = b_isolate_meta;
    assign a_clear_o = a_clear_meta;
    assign b_clear_o = b_clear_meta;

    // CDC synchronization
    reg [SYNC_STAGES-1:0] a_isolate_sync_reg;
    reg [SYNC_STAGES-1:0] b_isolate_sync_reg;
    reg [SYNC_STAGES-1:0] a_clear_sync_reg;
    reg [SYNC_STAGES-1:0] b_clear_sync_reg;

    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate_sync_reg <= {SYNC_STAGES{1'b0}};
            a_clear_sync_reg <= {SYNC_STAGES{1'b0}};
        end else begin
            a_isolate_sync_reg <= {a_isolate_sync, a_isolate_sync_reg[SYNC_STAGES-1:1]};
            a_clear_sync_reg <= {a_clear_sync, a_clear_sync_reg[SYNC_STAGES-1:1]};
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate_sync_reg <= {SYNC_STAGES{1'b0}};
            b_clear_sync_reg <= {SYNC_STAGES{1'b0}};
        end else begin
            b_isolate_sync_reg <= {b_isolate_sync, b_isolate_sync_reg[SYNC_STAGES-1:1]};
            b_clear_sync_reg <= {b_clear_sync, b_clear_sync_reg[SYNC_STAGES-1:1]};
        end
    end

    assign a_isolate_sync = a_isolate_sync_reg[0];
    assign b_isolate_sync = b_isolate_sync_reg[0];
    assign a_clear_sync = a_clear_sync_reg[0];
    assign b_clear_sync = b_clear_sync_reg[0];

    // meta signals
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate_meta <= 0;
            a_clear_meta <= 0;
        end else begin
            if (a_state == 1) begin
                a_isolate_meta <= 1;
            end else if (a_state == 3) begin
                a_isolate_meta <= 0;
            end

            if (a_state == 2) begin
                a_clear_meta <= 1;
            end else if (a_state == 3) begin
                a_clear_meta <= 0;
            end
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate_meta <= 0;
            b_clear_meta <= 0;
        end else begin
            if (b_state == 1) begin
                b_isolate_meta <= 1;
            end else if (b_state == 3) begin
                b_isolate_meta <= 0;
            end

            if (b_state == 2) begin
                b_clear_meta <= 1;
            end else if (b_state == 3) begin
                b_clear_meta <= 0;
            end
        end
    end

endmodule
