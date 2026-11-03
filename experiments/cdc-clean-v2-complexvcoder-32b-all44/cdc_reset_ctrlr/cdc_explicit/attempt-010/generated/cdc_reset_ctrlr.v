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
    reg a_clear_sync_b;
    reg b_clear_sync_a;
    reg a_clear_ack_sync_b;
    reg b_clear_ack_sync_a;
    reg a_isolate_ack_sync_b;
    reg b_isolate_ack_sync_a;

    reg a_clear_o_reg;
    reg a_isolate_o_reg;
    reg b_clear_o_reg;
    reg b_isolate_o_reg;

    reg [2:0] a_state;
    reg [2:0] b_state;

    reg a_req_clear;
    reg b_req_clear;
    reg a_isolate_done;
    reg b_isolate_done;
    reg a_clear_done;
    reg b_clear_done;

    // State definitions
    localparam IDLE = 3'b000;
    localparam ISOLATE = 3'b001;
    localparam WAIT_ISOLATE_ACK = 3'b010;
    localparam CLEAR = 3'b011;
    localparam WAIT_CLEAR_ACK = 3'b100;
    localparam RELEASE = 3'b101;

    // Synchronizers
    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) a_clear_sync (
        .async_in(a_clear_i),
        .sync_out(a_clear_sync_b),
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) b_clear_sync (
        .async_in(b_clear_i),
        .sync_out(b_clear_sync_a),
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) a_clear_ack_sync (
        .async_in(a_clear_ack_i),
        .sync_out(a_clear_ack_sync_b),
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) b_clear_ack_sync (
        .async_in(b_clear_ack_i),
        .sync_out(b_clear_ack_sync_a),
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) a_isolate_ack_sync (
        .async_in(a_isolate_ack_i),
        .sync_out(a_isolate_ack_sync_b),
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) b_isolate_ack_sync (
        .async_in(b_isolate_ack_i),
        .sync_out(b_isolate_ack_sync_a),
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni)
    );

    // A side state machine
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_state <= IDLE;
            a_clear_o_reg <= 0;
            a_isolate_o_reg <= 0;
        end else begin
            case (a_state)
                IDLE: begin
                    a_req_clear <= a_clear_i | b_clear_sync_a;
                    if (a_req_clear) begin
                        a_isolate_o_reg <= 1;
                        a_state <= ISOLATE;
                    end
                end
                ISOLATE: begin
                    if (a_isolate_ack_sync_b & b_isolate_ack_sync_a) begin
                        a_state <= WAIT_ISOLATE_ACK;
                    end
                end
                WAIT_ISOLATE_ACK: begin
                    a_isolate_o_reg <= 0;
                    a_clear_o_reg <= 1;
                    a_state <= CLEAR;
                end
                CLEAR: begin
                    if (a_clear_ack_sync_b & b_clear_ack_sync_a) begin
                        a_state <= WAIT_CLEAR_ACK;
                    end
                end
                WAIT_CLEAR_ACK: begin
                    a_clear_o_reg <= 0;
                    a_state <= RELEASE;
                end
                RELEASE: begin
                    a_state <= IDLE;
                end
            endcase
        end
    end

    // B side state machine
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_state <= IDLE;
            b_clear_o_reg <= 0;
            b_isolate_o_reg <= 0;
        end else begin
            case (b_state)
                IDLE: begin
                    b_req_clear <= b_clear_i | a_clear_sync_b;
                    if (b_req_clear) begin
                        b_isolate_o_reg <= 1;
                        b_state <= ISOLATE;
                    end
                end
                ISOLATE: begin
                    if (a_isolate_ack_sync_b & b_isolate_ack_sync_a) begin
                        b_state <= WAIT_ISOLATE_ACK;
                    end
                end
                WAIT_ISOLATE_ACK: begin
                    b_isolate_o_reg <= 0;
                    b_clear_o_reg <= 1;
                    b_state <= CLEAR;
                end
                CLEAR: begin
                    if (a_clear_ack_sync_b & b_clear_ack_sync_a) begin
                        b_state <= WAIT_CLEAR_ACK;
                    end
                end
                WAIT_CLEAR_ACK: begin
                    b_clear_o_reg <= 0;
                    b_state <= RELEASE;
                end
                RELEASE: begin
                    b_state <= IDLE;
                end
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
    input  async_in,
    output sync_out,
    input  clk_i,
    input  rst_ni
);

    reg [SYNC_STAGES-1:0] sync_reg;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg <= 0;
        end else begin
            sync_reg[0] <= async_in;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                sync_reg[i] <= sync_reg[i-1];
            end
        end
    end

    assign sync_out = sync_reg[SYNC_STAGES-1];

endmodule
