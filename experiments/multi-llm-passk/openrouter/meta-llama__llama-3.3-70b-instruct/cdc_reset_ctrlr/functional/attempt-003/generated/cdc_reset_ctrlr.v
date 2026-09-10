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
reg a_isolate, a_clear;
reg b_isolate, b_clear;

always @(posedge a_clk_i or negedge a_rst_ni) begin
    if (!a_rst_ni) begin
        a_state <= 0;
        a_isolate <= 1'b0;
        a_clear <= 1'b0;
    end else begin
        case (a_state)
            2'b00: begin
                if (a_clear_i) begin
                    a_state <= 2'b01;
                    a_isolate <= 1'b1;
                end
            end
            2'b01: begin
                if (a_isolate_ack_i) begin
                    a_state <= 2'b10;
                    a_clear <= 1'b1;
                end
            end
            2'b10: begin
                if (a_clear_ack_i) begin
                    a_state <= 2'b11;
                end
            end
            2'b11: begin
                if (!a_clear_i) begin
                    a_state <= 2'b00;
                    a_isolate <= 1'b0;
                    a_clear <= 1'b0;
                end
            end
        endcase
    end
end

always @(posedge b_clk_i or negedge b_rst_ni) begin
    if (!b_rst_ni) begin
        b_state <= 0;
        b_isolate <= 1'b0;
        b_clear <= 1'b0;
    end else begin
        case (b_state)
            2'b00: begin
                if (b_clear_i) begin
                    b_state <= 2'b01;
                    b_isolate <= 1'b1;
                end
            end
            2'b01: begin
                if (b_isolate_ack_i) begin
                    b_state <= 2'b10;
                    b_clear <= 1'b1;
                end
            end
            2'b10: begin
                if (b_clear_ack_i) begin
                    b_state <= 2'b11;
                end
            end
            2'b11: begin
                if (!b_clear_i) begin
                    b_state <= 2'b00;
                    b_isolate <= 1'b0;
                    b_clear <= 1'b0;
                end
            end
        endcase
    end
end

reg [SYNC_STAGES-1:0] a_isolate_sync;
reg [SYNC_STAGES-1:0] a_clear_sync;
reg [SYNC_STAGES-1:0] b_isolate_sync;
reg [SYNC_STAGES-1:0] b_clear_sync;

always @(posedge a_clk_i or negedge a_rst_ni) begin
    if (!a_rst_ni) begin
        a_isolate_sync <= {SYNC_STAGES{1'b0}};
        a_clear_sync <= {SYNC_STAGES{1'b0}};
    end else begin
        a_isolate_sync[0] <= a_isolate;
        a_clear_sync[0] <= a_clear;
        for (genvar i = 1; i < SYNC_STAGES; i++) begin
            a_isolate_sync[i] <= a_isolate_sync[i-1];
            a_clear_sync[i] <= a_clear_sync[i-1];
        end
    end
end

always @(posedge b_clk_i or negedge b_rst_ni) begin
    if (!b_rst_ni) begin
        b_isolate_sync <= {SYNC_STAGES{1'b0}};
        b_clear_sync <= {SYNC_STAGES{1'b0}};
    end else begin
        b_isolate_sync[0] <= b_isolate;
        b_clear_sync[0] <= b_clear;
        for (genvar i = 1; i < SYNC_STAGES; i++) begin
            b_isolate_sync[i] <= b_isolate_sync[i-1];
            b_clear_sync[i] <= b_clear_sync[i-1];
        end
    end
end

assign a_isolate_o = a_isolate_sync[SYNC_STAGES-1] | b_isolate_sync[SYNC_STAGES-1];
assign a_clear_o = a_clear_sync[SYNC_STAGES-1] & b_clear_sync[SYNC_STAGES-1];
assign b_isolate_o = b_isolate_sync[SYNC_STAGES-1] | a_isolate_sync[SYNC_STAGES-1];
assign b_clear_o = b_clear_sync[SYNC_STAGES-1] & a_clear_sync[SYNC_STAGES-1];

endmodule
