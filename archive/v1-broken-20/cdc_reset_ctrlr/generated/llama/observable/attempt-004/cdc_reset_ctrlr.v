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

reg [1:0] a_state;
reg [1:0] b_state;

reg a_isolate_sync;
reg a_clear_sync;
reg b_isolate_sync;
reg b_clear_sync;

reg [SYNC_STAGES-1:0] a_isolate_sync_reg;
reg [SYNC_STAGES-1:0] a_clear_sync_reg;
reg [SYNC_STAGES-1:0] b_isolate_sync_reg;
reg [SYNC_STAGES-1:0] b_clear_sync_reg;

always @(posedge a_clk_i or negedge a_rst_ni) begin
    if (!a_rst_ni) begin
        a_state <= 2'b00;
        a_isolate_o <= 1'b0;
        a_clear_o <= 1'b0;
        a_isolate_sync_reg <= {SYNC_STAGES{1'b0}};
        a_clear_sync_reg <= {SYNC_STAGES{1'b0}};
    end else begin
        case (a_state)
            2'b00: begin
                if (a_clear_i) begin
                    a_state <= 2'b01;
                    a_isolate_o <= 1'b1;
                end
            end
            2'b01: begin
                if (a_isolate_ack_i && b_isolate_sync) begin
                    a_state <= 2'b10;
                    a_clear_o <= 1'b1;
                end
            end
            2'b10: begin
                if (a_clear_ack_i && b_clear_sync) begin
                    a_state <= 2'b00;
                    a_isolate_o <= 1'b0;
                    a_clear_o <= 1'b0;
                end
            end
        endcase
        a_isolate_sync_reg[0] <= b_isolate_o;
        for (genvar i = 1; i < SYNC_STAGES; i++) begin
            a_isolate_sync_reg[i] <= a_isolate_sync_reg[i-1];
        end
        a_isolate_sync <= a_isolate_sync_reg[SYNC_STAGES-1];
        a_clear_sync_reg[0] <= b_clear_o;
        for (genvar i = 1; i < SYNC_STAGES; i++) begin
            a_clear_sync_reg[i] <= a_clear_sync_reg[i-1];
        end
        a_clear_sync <= a_clear_sync_reg[SYNC_STAGES-1];
    end
end

always @(posedge b_clk_i or negedge b_rst_ni) begin
    if (!b_rst_ni) begin
        b_state <= 2'b00;
        b_isolate_o <= 1'b0;
        b_clear_o <= 1'b0;
        b_isolate_sync_reg <= {SYNC_STAGES{1'b0}};
        b_clear_sync_reg <= {SYNC_STAGES{1'b0}};
    end else begin
        case (b_state)
            2'b00: begin
                if (b_clear_i) begin
                    b_state <= 2'b01;
                    b_isolate_o <= 1'b1;
                end
            end
            2'b01: begin
                if (b_isolate_ack_i && a_isolate_sync) begin
                    b_state <= 2'b10;
                    b_clear_o <= 1'b1;
                end
            end
            2'b10: begin
                if (b_clear_ack_i && a_clear_sync) begin
                    b_state <= 2'b00;
                    b_isolate_o <= 1'b0;
                    b_clear_o <= 1'b0;
                end
            end
        endcase
        b_isolate_sync_reg[0] <= a_isolate_o;
        for (genvar i = 1; i < SYNC_STAGES; i++) begin
            b_isolate_sync_reg[i] <= b_isolate_sync_reg[i-1];
        end
        b_isolate_sync <= b_isolate_sync_reg[SYNC_STAGES-1];
        b_clear_sync_reg[0] <= a_clear_o;
        for (genvar i = 1; i < SYNC_STAGES; i++) begin
            b_clear_sync_reg[i] <= b_clear_sync_reg[i-1];
        end
        b_clear_sync <= b_clear_sync_reg[SYNC_STAGES-1];
    end
end

endmodule
