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
    reg a_to_b_clear_sync_o;
    reg b_to_a_clear_sync_o;
    reg a_to_b_isolate_sync_o;
    reg b_to_a_isolate_sync_o;
    reg a_to_b_clear_ack_sync_o;
    reg b_to_a_clear_ack_sync_o;
    reg a_to_b_isolate_ack_sync_o;
    reg b_to_a_isolate_ack_sync_o;
    reg a_clear_req;
    reg b_clear_req;
    reg a_isolate_req;
    reg b_isolate_req;
    reg a_clear_ack;
    reg b_clear_ack;
    reg a_isolate_ack;
    reg b_isolate_ack;
    reg [1:0] a_isolate_state;
    reg [1:0] b_isolate_state;
    reg [1:0] a_clear_state;
    reg [1:0] b_clear_state;
    reg a_clear_o_reg;
    reg b_clear_o_reg;
    reg a_isolate_o_reg;
    reg b_isolate_o_reg;

    // CDC Sync instances
    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) a_to_b_clear_sync (
        .clk_i(b_clk_i),
        .data_i(a_clear_i),
        .data_o(a_to_b_clear_sync_o)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) b_to_a_clear_sync (
        .clk_i(a_clk_i),
        .data_i(b_clear_i),
        .data_o(b_to_a_clear_sync_o)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) a_to_b_isolate_sync (
        .clk_i(b_clk_i),
        .data_i(a_isolate_o_reg),
        .data_o(a_to_b_isolate_sync_o)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) b_to_a_isolate_sync (
        .clk_i(a_clk_i),
        .data_i(b_isolate_o_reg),
        .data_o(b_to_a_isolate_sync_o)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) a_to_b_clear_ack_sync (
        .clk_i(b_clk_i),
        .data_i(a_clear_ack_i),
        .data_o(a_to_b_clear_ack_sync_o)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) b_to_a_clear_ack_sync (
        .clk_i(a_clk_i),
        .data_i(b_clear_ack_i),
        .data_o(b_to_a_clear_ack_sync_o)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) a_to_b_isolate_ack_sync (
        .clk_i(b_clk_i),
        .data_i(a_isolate_ack_i),
        .data_o(a_to_b_isolate_ack_sync_o)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) b_to_a_isolate_ack_sync (
        .clk_i(a_clk_i),
        .data_i(b_isolate_ack_i),
        .data_o(b_to_a_isolate_ack_sync_o)
    );

    // Connections
    assign a_clear_req = a_to_b_clear_sync_o;
    assign b_clear_req = b_to_a_clear_sync_o;
    assign a_isolate_req = a_to_b_isolate_sync_o;
    assign b_isolate_req = b_to_a_isolate_sync_o;
    assign a_clear_ack = a_to_b_clear_ack_sync_o;
    assign b_clear_ack = b_to_a_clear_ack_sync_o;
    assign a_isolate_ack = a_to_b_isolate_ack_sync_o;
    assign b_isolate_ack = b_to_a_isolate_ack_sync_o;

    // a_clk_i domain logic
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate_state <= 2'b00;
            a_clear_state <= 2'b00;
            a_isolate_o_reg <= 1'b0;
            a_clear_o_reg <= 1'b0;
        end else begin
            case (a_isolate_state)
                2'b00: begin // Idle
                    if (a_clear_req) begin
                        a_isolate_o_reg <= 1'b1;
                        a_isolate_state <= 2'b01; // Isolate Active
                    end
                end
                2'b01: begin // Isolate Active
                    if (a_isolate_ack) begin
                        a_isolate_state <= 2'b10; // Isolate Done
                    end
                end
                2'b10: begin // Isolate Done
                    a_clear_o_reg <= 1'b1;
                    a_isolate_state <= 2'b11; // Clear Active
                end
                2'b11: begin // Clear Active
                    if (a_clear_ack) begin
                        a_clear_o_reg <= 1'b0;
                        a_isolate_o_reg <= 1'b0;
                        a_isolate_state <= 2'b00; // Idle
                    end
                end
                default: a_isolate_state <= 2'b00; // Idle
            endcase
        end
    end

    // b_clk_i domain logic
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate_state <= 2'b00;
            b_clear_state <= 2'b00;
            b_isolate_o_reg <= 1'b0;
            b_clear_o_reg <= 1'b0;
        end else begin
            case (b_isolate_state)
                2'b00: begin // Idle
                    if (b_clear_req) begin
                        b_isolate_o_reg <= 1'b1;
                        b_isolate_state <= 2'b01; // Isolate Active
                    end
                end
                2'b01: begin // Isolate Active
                    if (b_isolate_ack) begin
                        b_isolate_state <= 2'b10; // Isolate Done
                    end
                end
                2'b10: begin // Isolate Done
                    b_clear_o_reg <= 1'b1;
                    b_isolate_state <= 2'b11; // Clear Active
                end
                2'b11: begin // Clear Active
                    if (b_clear_ack) begin
                        b_clear_o_reg <= 1'b0;
                        b_isolate_o_reg <= 1'b0;
                        b_isolate_state <= 2'b00; // Idle
                    end
                end
                default: b_isolate_state <= 2'b00; // Idle
            endcase
        end
    end

    // Outputs
    assign a_clear_o = a_clear_o_reg;
    assign a_isolate_o = a_isolate_o_reg;
    assign b_clear_o = b_clear_o_reg;
    assign b_isolate_o = b_isolate_o_reg;

endmodule

module cdc_sync #(
    parameter SYNC_STAGES = 2
)(
    input  clk_i,
    input  data_i,
    output data_o
);

    reg [SYNC_STAGES:0] sync_reg;

    always @(posedge clk_i) begin
        sync_reg <= {sync_reg[SYNC_STAGES-1:0], data_i};
    end

    assign data_o = sync_reg[SYNC_STAGES];

endmodule
