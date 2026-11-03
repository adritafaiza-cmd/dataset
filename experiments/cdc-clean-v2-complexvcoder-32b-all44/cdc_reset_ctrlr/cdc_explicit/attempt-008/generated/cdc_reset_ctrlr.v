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
    reg  clear_sync_a;
    reg  clear_sync_b;
    reg  isolate_ack_sync_a;
    reg  isolate_ack_sync_b;
    reg  clear_ack_sync_a;
    reg  clear_ack_sync_b;
    reg  a_isolate_req;
    reg  b_isolate_req;
    reg  a_clear_req;
    reg  b_clear_req;
    reg [1:0] a_state;
    reg [1:0] b_state;

    // States
    localparam IDLE = 2'b00;
    localparam ISOLATE = 2'b01;
    localparam CLEAR = 2'b10;
    localparam RELEASE = 2'b11;

    // CDC synchronization instances
    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) u_a_clear_sync (
        .clk(b_clk_i),
        .rst_ni(b_rst_ni),
        .clear_in(a_clear_i),
        .ack_in(1'b0),
        .sync_out(clear_sync_b)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) u_b_clear_sync (
        .clk(a_clk_i),
        .rst_ni(a_rst_ni),
        .clear_in(b_clear_i),
        .ack_in(1'b0),
        .sync_out(clear_sync_a)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) u_a_isolate_ack_sync (
        .clk(b_clk_i),
        .rst_ni(b_rst_ni),
        .clear_in(1'b0),
        .ack_in(a_isolate_ack_i),
        .sync_out(isolate_ack_sync_b)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) u_b_isolate_ack_sync (
        .clk(a_clk_i),
        .rst_ni(a_rst_ni),
        .clear_in(1'b0),
        .ack_in(b_isolate_ack_i),
        .sync_out(isolate_ack_sync_a)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) u_a_clear_ack_sync (
        .clk(b_clk_i),
        .rst_ni(b_rst_ni),
        .clear_in(1'b0),
        .ack_in(a_clear_ack_i),
        .sync_out(clear_ack_sync_b)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) u_b_clear_ack_sync (
        .clk(a_clk_i),
        .rst_ni(a_rst_ni),
        .clear_in(1'b0),
        .ack_in(b_clear_ack_i),
        .sync_out(clear_ack_sync_a)
    );

    // Domain A state machine
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate_o <= 1'b0;
            a_clear_o <= 1'b0;
            a_clear_req <= 1'b0;
            a_isolate_req <= 1'b0;
            a_state <= IDLE;
        end else begin
            case (a_state)
                IDLE: begin
                    if (a_clear_i && !a_clear_req) begin
                        a_clear_req <= 1'b1;
                    end
                    if (a_clear_req) begin
                        a_isolate_o <= 1'b1;
                        a_isolate_req <= 1'b1;
                        a_state <= ISOLATE;
                    end
                end
                ISOLATE: begin
                    if (isolate_ack_sync_b) begin
                        a_clear_o <= 1'b1;
                        a_state <= CLEAR;
                    end
                end
                CLEAR: begin
                    if (clear_ack_sync_b) begin
                        a_clear_o <= 1'b0;
                        a_state <= RELEASE;
                    end
                end
                RELEASE: begin
                    if (isolate_ack_sync_b && clear_ack_sync_b) begin
                        a_isolate_o <= 1'b0;
                        a_clear_req <= 1'b0;
                        a_isolate_req <= 1'b0;
                        a_state <= IDLE;
                    end
                end
                default: a_state <= IDLE;
            endcase
        end
    end

    // Domain B state machine
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate_o <= 1'b0;
            b_clear_o <= 1'b0;
            b_clear_req <= 1'b0;
            b_isolate_req <= 1'b0;
            b_state <= IDLE;
        end else begin
            case (b_state)
                IDLE: begin
                    if (b_clear_i && !b_clear_req) begin
                        b_clear_req <= 1'b1;
                    end
                    if (b_clear_req) begin
                        b_isolate_o <= 1'b1;
                        b_isolate_req <= 1'b1;
                        b_state <= ISOLATE;
                    end
                end
                ISOLATE: begin
                    if (isolate_ack_sync_a) begin
                        b_clear_o <= 1'b1;
                        b_state <= CLEAR;
                    end
                end
                CLEAR: begin
                    if (clear_ack_sync_a) begin
                        b_clear_o <= 1'b0;
                        b_state <= RELEASE;
                    end
                end
                RELEASE: begin
                    if (isolate_ack_sync_a && clear_ack_sync_a) begin
                        b_isolate_o <= 1'b0;
                        b_clear_req <= 1'b0;
                        b_isolate_req <= 1'b0;
                        b_state <= IDLE;
                    end
                end
                default: b_state <= IDLE;
            endcase
        end
    end

endmodule

module cdc_sync #(
    parameter SYNC_STAGES = 2
)(
    input  clk,
    input  rst_ni,
    input  clear_in,
    input  ack_in,
    output sync_out
);

    reg [SYNC_STAGES-1:0] sync_reg;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_reg <= {SYNC_STAGES{1'b0}};
        end else begin
            sync_reg <= {sync_reg[SYNC_STAGES-2:0], clear_in};
        end
    end

    assign sync_out = sync_reg[SYNC_STAGES-1];

endmodule
