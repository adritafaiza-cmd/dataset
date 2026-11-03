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

    // Internal signals for synchronization
    wire b_clear_synced;
    wire a_clear_synced;
    wire b_isolate_synced;
    wire a_isolate_synced;
    wire b_clear_ack_synced;
    wire a_clear_ack_synced;
    wire b_isolate_ack_synced;
    wire a_isolate_ack_synced;

    // Internal signals for state machines
    reg  a_isolate;
    reg  b_isolate;
    reg  a_clear_reg;
    reg  b_clear_reg;
    reg [1:0] a_state;
    reg [1:0] b_state;

    // Synchronization stages
    sync_stage #(.SYNC_STAGES(SYNC_STAGES)) a_clear_sync (
        .sync_in  (b_clear_i),
        .clk      (a_clk_i),
        .rst_ni   (a_rst_ni),
        .sync_out (b_clear_synced)
    );

    sync_stage #(.SYNC_STAGES(SYNC_STAGES)) b_clear_sync (
        .sync_in  (a_clear_i),
        .clk      (b_clk_i),
        .rst_ni   (b_rst_ni),
        .sync_out (a_clear_synced)
    );

    sync_stage #(.SYNC_STAGES(SYNC_STAGES)) a_isolate_sync (
        .sync_in  (b_isolate),
        .clk      (a_clk_i),
        .rst_ni   (a_rst_ni),
        .sync_out (b_isolate_synced)
    );

    sync_stage #(.SYNC_STAGES(SYNC_STAGES)) b_isolate_sync (
        .sync_in  (a_isolate),
        .clk      (b_clk_i),
        .rst_ni   (b_rst_ni),
        .sync_out (a_isolate_synced)
    );

    sync_stage #(.SYNC_STAGES(SYNC_STAGES)) a_clear_ack_sync (
        .sync_in  (b_clear_ack_i),
        .clk      (a_clk_i),
        .rst_ni   (a_rst_ni),
        .sync_out (b_clear_ack_synced)
    );

    sync_stage #(.SYNC_STAGES(SYNC_STAGES)) b_clear_ack_sync (
        .sync_in  (a_clear_ack_i),
        .clk      (b_clk_i),
        .rst_ni   (b_rst_ni),
        .sync_out (a_clear_ack_synced)
    );

    sync_stage #(.SYNC_STAGES(SYNC_STAGES)) a_isolate_ack_sync (
        .sync_in  (b_isolate_ack_i),
        .clk      (a_clk_i),
        .rst_ni   (a_rst_ni),
        .sync_out (b_isolate_ack_synced)
    );

    sync_stage #(.SYNC_STAGES(SYNC_STAGES)) b_isolate_ack_sync (
        .sync_in  (a_isolate_ack_i),
        .clk      (b_clk_i),
        .rst_ni   (b_rst_ni),
        .sync_out (a_isolate_ack_synced)
    );

    // State machine for domain A
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_state <= 2'b00;
            a_isolate <= 1'b0;
            a_clear_reg <= 1'b0;
        end else begin
            case (a_state)
                2'b00: begin // IDLE
                    if (a_clear_i) begin
                        a_state <= 2'b01; // ACTIVE
                    end
                end
                2'b01: begin // ACTIVE
                    a_isolate <= 1'b1;
                    if (b_isolate_ack_synced) begin
                        a_state <= 2'b10; // DONE
                    end
                end
                2'b10: begin // DONE
                    a_clear_reg <= 1'b1;
                    if (b_clear_ack_synced) begin
                        a_state <= 2'b11; // RELEASED
                    end
                end
                2'b11: begin // RELEASED
                    a_isolate <= 1'b0;
                    a_clear_reg <= 1'b0;
                    if (b_isolate_synced) begin
                        a_state <= 2'b00; // IDLE
                    end
                end
                default: begin
                    a_state <= 2'b00;
                end
            endcase
        end
    end

    // State machine for domain B
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_state <= 2'b00;
            b_isolate <= 1'b0;
            b_clear_reg <= 1'b0;
        end else begin
            case (b_state)
                2'b00: begin // IDLE
                    if (b_clear_i) begin
                        b_state <= 2'b01; // ACTIVE
                    end
                end
                2'b01: begin // ACTIVE
                    b_isolate <= 1'b1;
                    if (a_isolate_ack_synced) begin
                        b_state <= 2'b10; // DONE
                    end
                end
                2'b10: begin // DONE
                    b_clear_reg <= 1'b1;
                    if (a_clear_ack_synced) begin
                        b_state <= 2'b11; // RELEASED
                    end
                end
                2'b11: begin // RELEASED
                    b_isolate <= 1'b0;
                    b_clear_reg <= 1'b0;
                    if (a_isolate_synced) begin
                        b_state <= 2'b00; // IDLE
                    end
                end
                default: begin
                    b_state <= 2'b00;
                end
            endcase
        end
    end

    // Assign outputs
    assign a_clear_o = a_clear_reg;
    assign a_isolate_o = a_isolate;
    assign b_clear_o = b_clear_reg;
    assign b_isolate_o = b_isolate;

endmodule

module sync_stage #(
    parameter SYNC_STAGES = 2
)(
    input  sync_in,
    input  clk,
    input  rst_ni,
    output sync_out
);

    reg [SYNC_STAGES-1:0] sync_stages;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_stages <= {SYNC_STAGES{1'b0}};
        end else begin
            sync_stages <= {sync_stages[SYNC_STAGES-2:0], sync_in};
        end
    end

    assign sync_out = sync_stages[SYNC_STAGES-1];

endmodule
