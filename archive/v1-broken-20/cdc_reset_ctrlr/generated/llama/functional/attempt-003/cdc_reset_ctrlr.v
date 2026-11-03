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
        a_state <= 2'b00;
        a_isolate_sync <= 1'b0;
        a_clear_sync <= 1'b0;
        a_isolate <= 1'b0;
        a_clear <= 1'b0;
    end else begin
        case (a_state)
            2'b00: begin
                if (a_clear_i) begin
                    a_state <= 2'b01;
                end
            end
            2'b01: begin
                if (a_isolate_ack_i && b_isolate_sync) begin
                    a_state <= 2'b10;
                end
            end
            2'b10: begin
                if (a_clear_ack_i && b_clear_sync) begin
                    a_state <= 2'b11;
                end
            end
            2'b11: begin
                if (!a_clear_i && !b_clear_sync) begin
                    a_state <= 2'b00;
                end
            end
        endcase
        if (a_state == 2'b01) begin
            a_isolate <= 1'b1;
        end else if (a_state == 2'b11) begin
            a_isolate <= 1'b0;
        end
        if (a_state == 2'b10) begin
            a_clear <= 1'b1;
        end else if (a_state == 2'b11 || a_state == 2'b00) begin
            a_clear <= 1'b0;
        end
    end
end

always @(posedge b_clk_i or negedge b_rst_ni) begin
    if (!b_rst_ni) begin
        b_state <= 2'b00;
        b_isolate_sync <= 1'b0;
        b_clear_sync <= 1'b0;
        b_isolate <= 1'b0;
        b_clear <= 1'b0;
    end else begin
        case (b_state)
            2'b00: begin
                if (b_clear_i) begin
                    b_state <= 2'b01;
                end
            end
            2'b01: begin
                if (b_isolate_ack_i && a_isolate_sync) begin
                    b_state <= 2'b10;
                end
            end
            2'b10: begin
                if (b_clear_ack_i && a_clear_sync) begin
                    b_state <= 2'b11;
                end
            end
            2'b11: begin
                if (!b_clear_i && !a_clear_sync) begin
                    b_state <= 2'b00;
                end
            end
        endcase
        if (b_state == 2'b01) begin
            b_isolate <= 1'b1;
        end else if (b_state == 2'b11) begin
            b_isolate <= 1'b0;
        end
        if (b_state == 2'b10) begin
            b_clear <= 1'b1;
        end else if (b_state == 2'b11 || b_state == 2'b00) begin
            b_clear <= 1'b0;
        end
    end
end

genvar i;
generate
    for (i = 0; i < SYNC_STAGES; i = i + 1) begin
        reg a_isolate_sync_reg, b_isolate_sync_reg;
        reg a_clear_sync_reg, b_clear_sync_reg;
        if (i == 0) begin
            always @(posedge a_clk_i or negedge a_rst_ni) begin
                if (!a_rst_ni) begin
                    a_isolate_sync_reg <= 1'b0;
                    a_clear_sync_reg <= 1'b0;
                end else begin
                    a_isolate_sync_reg <= a_isolate;
                    a_clear_sync_reg <= a_clear;
                end
            end
            always @(posedge b_clk_i or negedge b_rst_ni) begin
                if (!b_rst_ni) begin
                    b_isolate_sync_reg <= 1'b0;
                    b_clear_sync_reg <= 1'b0;
                end else begin
                    b_isolate_sync_reg <= b_isolate;
                    b_clear_sync_reg <= b_clear;
                end
            end
        end else begin
            reg a_isolate_sync_prev, b_isolate_sync_prev;
            reg a_clear_sync_prev, b_clear_sync_prev;
            always @(posedge a_clk_i or negedge a_rst_ni) begin
                if (!a_rst_ni) begin
                    a_isolate_sync_reg <= 1'b0;
                    a_clear_sync_reg <= 1'b0;
                end else begin
                    a_isolate_sync_reg <= a_isolate_sync_prev;
                    a_clear_sync_reg <= a_clear_sync_prev;
                end
            end
            always @(posedge b_clk_i or negedge b_rst_ni) begin
                if (!b_rst_ni) begin
                    b_isolate_sync_reg <= 1'b0;
                    b_clear_sync_reg <= 1'b0;
                end else begin
                    b_isolate_sync_reg <= b_isolate_sync_prev;
                    b_clear_sync_reg <= b_clear_sync_prev;
                end
            end
            assign a_isolate_sync_prev = (i == 1) ? a_isolate : a_isolate_sync;
            assign b_isolate_sync_prev = (i == 1) ? b_isolate : b_isolate_sync;
            assign a_clear_sync_prev = (i == 1) ? a_clear : a_clear_sync;
            assign b_clear_sync_prev = (i == 1) ? b_clear : b_clear_sync;
        end
        if (i == SYNC_STAGES - 1) begin
            assign a_isolate_sync = a_isolate_sync_reg;
            assign b_isolate_sync = b_isolate_sync_reg;
            assign a_clear_sync = a_clear_sync_reg;
            assign b_clear_sync = b_clear_sync_reg;
        end
    end
endgenerate

assign a_isolate_o = a_isolate;
assign b_isolate_o = b_isolate;
assign a_clear_o = a_clear;
assign b_clear_o = b_clear;

endmodule
