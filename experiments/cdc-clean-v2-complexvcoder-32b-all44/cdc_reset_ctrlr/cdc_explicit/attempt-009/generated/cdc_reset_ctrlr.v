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
    reg    a_clear_synced;
    reg    b_clear_synced;
    reg    a_clear_ack_synced;
    reg    b_clear_ack_synced;
    reg    a_isolate_ack_synced;
    reg    b_isolate_ack_synced;
    reg    a_clear;
    reg    a_isolate;
    reg    b_clear;
    reg    b_isolate;
    reg [2:0] a_state;
    reg [2:0] b_state;

    // State definitions
    localparam IDLE = 3'b000;
    localparam ISOLATE = 3'b001;
    localparam WAIT_ISOLATE_ACK = 3'b010;
    localparam CLEAR = 3'b011;
    localparam WAIT_CLEAR_ACK = 3'b100;
    localparam RELEASE = 3'b101;

    // CDC synchronization modules
    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) a_clear_sync (
        .data_in(a_clear_i),
        .clk(b_clk_i),
        .rst_ni(b_rst_ni),
        .data_out(a_clear_synced)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) b_clear_sync (
        .data_in(b_clear_i),
        .clk(a_clk_i),
        .rst_ni(a_rst_ni),
        .data_out(b_clear_synced)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) a_clear_ack_sync (
        .data_in(a_clear_ack_i),
        .clk(b_clk_i),
        .rst_ni(b_rst_ni),
        .data_out(a_clear_ack_synced)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) b_clear_ack_sync (
        .data_in(b_clear_ack_i),
        .clk(a_clk_i),
        .rst_ni(a_rst_ni),
        .data_out(b_clear_ack_synced)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) a_isolate_ack_sync (
        .data_in(a_isolate_ack_i),
        .clk(b_clk_i),
        .rst_ni(b_rst_ni),
        .data_out(a_isolate_ack_synced)
    );

    cdc_sync #(.SYNC_STAGES(SYNC_STAGES)) b_isolate_ack_sync (
        .data_in(b_isolate_ack_i),
        .clk(a_clk_i),
        .rst_ni(a_rst_ni),
        .data_out(b_isolate_ack_synced)
    );

    // State machine for domain A
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_state <= IDLE;
            a_clear <= 0;
            a_isolate <= 0;
        end else begin
            case (a_state)
                IDLE: begin
                    if (a_clear_i || b_clear_synced) begin
                        a_state <= ISOLATE;
                    end
                end
                ISOLATE: begin
                    a_isolate <= 1;
                    a_state <= WAIT_ISOLATE_ACK;
                end
                WAIT_ISOLATE_ACK: begin
                    if (a_isolate_ack_i && b_isolate_ack_synced) begin
                        a_state <= CLEAR;
                    end
                end
                CLEAR: begin
                    a_clear <= 1;
                    a_state <= WAIT_CLEAR_ACK;
                end
                WAIT_CLEAR_ACK: begin
                    if (a_clear_ack_i && b_clear_ack_synced) begin
                        a_state <= RELEASE;
                    end
                end
                RELEASE: begin
                    a_clear <= 0;
                    a_isolate <= 0;
                    a_state <= IDLE;
                end
                default: begin
                    a_state <= IDLE;
                end
            endcase
        end
    end

    // State machine for domain B
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_state <= IDLE;
            b_clear <= 0;
            b_isolate <= 0;
        end else begin
            case (b_state)
                IDLE: begin
                    if (b_clear_i || a_clear_synced) begin
                        b_state <= ISOLATE;
                    end
                end
                ISOLATE: begin
                    b_isolate <= 1;
                    b_state <= WAIT_ISOLATE_ACK;
                end
                WAIT_ISOLATE_ACK: begin
                    if (b_isolate_ack_i && a_isolate_ack_synced) begin
                        b_state <= CLEAR;
                    end
                end
                CLEAR: begin
                    b_clear <= 1;
                    b_state <= WAIT_CLEAR_ACK;
                end
                WAIT_CLEAR_ACK: begin
                    if (b_clear_ack_i && a_clear_ack_synced) begin
                        b_state <= RELEASE;
                    end
                end
                RELEASE: begin
                    b_clear <= 0;
                    b_isolate <= 0;
                    b_state <= IDLE;
                end
                default: begin
                    b_state <= IDLE;
                end
            endcase
        end
    end

    // Output assignments
    assign a_clear_o = a_clear;
    assign a_isolate_o = a_isolate;
    assign b_clear_o = b_clear;
    assign b_isolate_o = b_isolate;

endmodule

module cdc_sync #(
    parameter SYNC_STAGES = 2
)(
    input  data_in,
    input  clk,
    input  rst_ni,
    output data_out
);

    reg [SYNC_STAGES-1:0] sync_chain;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_chain <= 0;
        end else begin
            sync_chain <= {sync_chain[SYNC_STAGES-2:0], data_in};
        end
    end

    assign data_out = sync_chain[SYNC_STAGES-1];

endmodule
