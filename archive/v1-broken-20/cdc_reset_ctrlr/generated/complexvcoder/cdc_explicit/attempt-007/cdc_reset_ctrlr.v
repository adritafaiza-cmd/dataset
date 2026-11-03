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

    logic a_isolate_req;
    logic a_clear_req;
    logic b_isolate_req;
    logic b_clear_req;
    logic a_isolate_out;
    logic a_clear_out;
    logic b_isolate_out;
    logic b_clear_out;

    assign a_clear_o = a_clear_out;
    assign a_isolate_o = a_isolate_out;
    assign b_clear_o = b_clear_out;
    assign b_isolate_o = b_isolate_out;

    always_ff @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate_req <= 0;
            a_clear_req <= 0;
        end else begin
            a_isolate_req <= a_clear_i;
            a_clear_req <= a_clear_i;
        end
    end

    always_ff @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate_req <= 0;
            b_clear_req <= 0;
        end else begin
            b_isolate_req <= b_clear_i;
            b_clear_req <= b_clear_i;
        end
    end

    always_ff @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate_out <= 0;
            a_clear_out <= 0;
        end else begin
            if (a_isolate_req && a_isolate_ack_i) begin
                a_isolate_out <= 1;
            end
            if (a_clear_req && a_clear_ack_i) begin
                a_clear_out <= 1;
            end
            if (a_clear_ack_i && b_clear_ack_i) begin
                a_isolate_out <= 0;
                a_clear_out <= 0;
            end
        end
    end

    always_ff @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate_out <= 0;
            b_clear_out <= 0;
        end else begin
            if (b_isolate_req && b_isolate_ack_i) begin
                b_isolate_out <= 1;
            end
            if (b_clear_req && b_clear_ack_i) begin
                b_clear_out <= 1;
            end
            if (a_clear_ack_i && b_clear_ack_i) begin
                b_isolate_out <= 0;
                b_clear_out <= 0;
            end
        end
    end

endmodule
