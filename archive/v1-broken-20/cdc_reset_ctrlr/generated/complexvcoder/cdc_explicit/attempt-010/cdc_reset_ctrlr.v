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
    logic a_clear_sync_o;
    logic a_isolate_sync_o;
    logic b_clear_sync_o;
    logic b_isolate_sync_o;
    logic a_clear_ack_sync_o;
    logic a_isolate_ack_sync_o;
    logic b_clear_ack_sync_o;
    logic b_isolate_ack_sync_o;

    // Asynchronous to synchronous converters
    cdc_sync #(.WIDTH(1), .SYNC_STAGES(SYNC_STAGES)) a_sync (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .data_i(a_clear_i),
        .data_o(a_clear_sync_o)
    );

    cdc_sync #(.WIDTH(1), .SYNC_STAGES(SYNC_STAGES)) b_sync (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .data_i(b_clear_i),
        .data_o(b_clear_sync_o)
    );

    cdc_sync #(.WIDTH(1), .SYNC_STAGES(SYNC_STAGES)) a_isolate_sync (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .data_i(a_isolate_o),
        .data_o(a_isolate_sync_o)
    );

    cdc_sync #(.WIDTH(1), .SYNC_STAGES(SYNC_STAGES)) b_isolate_sync (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .data_i(b_isolate_o),
        .data_o(b_isolate_sync_o)
    );

    cdc_sync #(.WIDTH(1), .SYNC_STAGES(SYNC_STAGES)) a_clear_ack_sync (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .data_i(a_clear_ack_i),
        .data_o(a_clear_ack_sync_o)
    );

    cdc_sync #(.WIDTH(1), .SYNC_STAGES(SYNC_STAGES)) b_clear_ack_sync (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .data_i(b_clear_ack_i),
        .data_o(b_clear_ack_sync_o)
    );

    cdc_sync #(.WIDTH(1), .SYNC_STAGES(SYNC_STAGES)) a_isolate_ack_sync (
        .clk_i(a_clk_i),
        .rst_ni(a_rst_ni),
        .data_i(a_isolate_ack_i),
        .data_o(a_isolate_ack_sync_o)
    );

    cdc_sync #(.WIDTH(1), .SYNC_STAGES(SYNC_STAGES)) b_isolate_ack_sync (
        .clk_i(b_clk_i),
        .rst_ni(b_rst_ni),
        .data_i(b_isolate_ack_i),
        .data_o(b_isolate_ack_sync_o)
    );

    // Internal signals for state machine
    logic [1:0] a_state;
    logic [1:0] b_state;

    // State definitions
    localparam IDLE = 2'b00;
    localparam ISOLATE = 2'b01;
    localparam CLEAR = 2'b10;

    // State machine for domain A
    always_ff @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_state <= IDLE;
        end else begin
            case (a_state)
                IDLE: begin
                    if (a_clear_i) begin
                        a_state <= ISOLATE;
                    end
                end
                ISOLATE: begin
                    if (a_isolate_ack_i) begin
                        a_state <= CLEAR;
                    end
                end
                CLEAR: begin
                    if (a_clear_ack_i) begin
                        a_state <= IDLE;
                    end
                end
                default: a_state <= IDLE;
            endcase
        end
    end

    // State machine for domain B
    always_ff @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_state <= IDLE;
        end else begin
            case (b_state)
                IDLE: begin
                    if (b_clear_i) begin
                        b_state <= ISOLATE;
                    end
                end
                ISOLATE: begin
                    if (b_isolate_ack_i) begin
                        b_state <= CLEAR;
                    end
                end
                CLEAR: begin
                    if (b_clear_ack_i) begin
                        b_state <= IDLE;
                    end
                end
                default: b_state <= IDLE;
            endcase
        end
    end

    // Output logic
    assign a_clear_o = (a_state == CLEAR) ? 1'b1 : 1'b0;
    assign a_isolate_o = (a_state == ISOLATE) ? 1'b1 : 1'b0;
    assign b_clear_o = (b_state == CLEAR) ? 1'b1 : 1'b0;
    assign b_isolate_o = (b_state == ISOLATE) ? 1'b1 : 1'b0;

endmodule

module cdc_sync #(
    parameter WIDTH = 1,
    parameter SYNC_STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  [WIDTH-1:0] data_i,
    output [WIDTH-1:0] data_o
);

    logic [WIDTH-1:0] shift_reg [SYNC_STAGES];

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (int i = 0; i < SYNC_STAGES; i++) begin
                shift_reg[i] <= 0;
            end
        end else begin
            shift_reg[0] <= data_i;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                shift_reg[i] <= shift_reg[i-1];
            end
        end
    end

    assign data_o = shift_reg[SYNC_STAGES-1];

endmodule
