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

reg [SYNC_STAGES-1:0] a_clear_sync;
reg [SYNC_STAGES-1:0] b_clear_sync;
reg [SYNC_STAGES-1:0] a_isolate_sync;
reg [SYNC_STAGES-1:0] b_isolate_sync;

reg a_clear_int;
reg a_isolate_int;
reg b_clear_int;
reg b_isolate_int;

reg a_state;
reg b_state;

always @(posedge a_clk_i or negedge a_rst_ni) begin
    if (!a_rst_ni) begin
        a_clear_sync <= {SYNC_STAGES{1'b0}};
        a_isolate_sync <= {SYNC_STAGES{1'b0}};
        a_state <= 1'b0;
    end else begin
        if (a_clear_i) begin
            a_clear_sync[0] <= 1'b1;
        end
        for (int i = 1; i < SYNC_STAGES; i++) begin
            a_clear_sync[i] <= a_clear_sync[i-1];
        end
        if (a_isolate_ack_i) begin
            a_isolate_sync[0] <= 1'b1;
        end
        for (int i = 1; i < SYNC_STAGES; i++) begin
            a_isolate_sync[i] <= a_isolate_sync[i-1];
        end
        case (a_state)
            1'b0: begin
                if (a_clear_sync[SYNC_STAGES-1]) begin
                    a_state <= 1'b1;
                end
            end
            1'b1: begin
                if (a_isolate_sync[SYNC_STAGES-1] && a_isolate_ack_i) begin
                    a_state <= 1'b2;
                end
            end
            1'b2: begin
                if (a_clear_ack_i) begin
                    a_state <= 1'b3;
                end
            end
            1'b3: begin
                if (!a_clear_i) begin
                    a_state <= 1'b0;
                end
            end
        endcase
    end
end

always @(posedge b_clk_i or negedge b_rst_ni) begin
    if (!b_rst_ni) begin
        b_clear_sync <= {SYNC_STAGES{1'b0}};
        b_isolate_sync <= {SYNC_STAGES{1'b0}};
        b_state <= 1'b0;
    end else begin
        if (b_clear_i) begin
            b_clear_sync[0] <= 1'b1;
        end
        for (int i = 1; i < SYNC_STAGES; i++) begin
            b_clear_sync[i] <= b_clear_sync[i-1];
        end
        if (b_isolate_ack_i) begin
            b_isolate_sync[0] <= 1'b1;
        end
        for (int i = 1; i < SYNC_STAGES; i++) begin
            b_isolate_sync[i] <= b_isolate_sync[i-1];
        end
        case (b_state)
            1'b0: begin
                if (b_clear_sync[SYNC_STAGES-1]) begin
                    b_state <= 1'b1;
                end
            end
            1'b1: begin
                if (b_isolate_sync[SYNC_STAGES-1] && b_isolate_ack_i) begin
                    b_state <= 1'b2;
                end
            end
            1'b2: begin
                if (b_clear_ack_i) begin
                    b_state <= 1'b3;
                end
            end
            1'b3: begin
                if (!b_clear_i) begin
                    b_state <= 1'b0;
                end
            end
        endcase
    end
end

always @(posedge a_clk_i or negedge a_rst_ni) begin
    if (!a_rst_ni) begin
        a_clear_int <= 1'b0;
        a_isolate_int <= 1'b0;
    end else begin
        case (a_state)
            1'b1: begin
                a_isolate_int <= 1'b1;
            end
            1'b2: begin
                a_clear_int <= 1'b1;
            end
            1'b3: begin
                a_isolate_int <= 1'b0;
                a_clear_int <= 1'b0;
            end
        endcase
    end
end

always @(posedge b_clk_i or negedge b_rst_ni) begin
    if (!b_rst_ni) begin
        b_clear_int <= 1'b0;
        b_isolate_int <= 1'b0;
    end else begin
        case (b_state)
            1'b1: begin
                b_isolate_int <= 1'b1;
            end
            1'b2: begin
                b_clear_int <= 1'b1;
            end
            1'b3: begin
                b_isolate_int <= 1'b0;
                b_clear_int <= 1'b0;
            end
        endcase
    end
end

assign a_clear_o = a_clear_int && b_clear_int;
assign a_isolate_o = a_isolate_int && b_isolate_int;
assign b_clear_o = a_clear_int && b_clear_int;
assign b_isolate_o = a_isolate_int && b_isolate_int;

endmodule
