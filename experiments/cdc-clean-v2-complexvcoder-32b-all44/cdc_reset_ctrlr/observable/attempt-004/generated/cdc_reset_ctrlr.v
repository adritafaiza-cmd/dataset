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
    reg a_isolate;
    reg a_clear;
    reg b_isolate;
    reg b_clear;

    // CDC Handshakes
    wire a2b_isolate_local;
    wire a2b_isolate_remote;
    wire b2a_isolate_local;
    wire b2a_isolate_remote;
    wire a2b_clear_local;
    wire a2b_clear_remote;
    wire b2a_clear_local;
    wire b2a_clear_remote;

    // Instantiate CDC handshakes
    cdc_handshake #(SYNC_STAGES) a2b_isolate_handshake (
        .local(a_isolate_o),
        .remote(a2b_isolate_remote)
    );

    cdc_handshake #(SYNC_STAGES) b2a_isolate_handshake (
        .local(b_isolate_o),
        .remote(b2a_isolate_remote)
    );

    cdc_handshake #(SYNC_STAGES) a2b_clear_handshake (
        .local(a_clear_o),
        .remote(a2b_clear_remote)
    );

    cdc_handshake #(SYNC_STAGES) b2a_clear_handshake (
        .local(b_clear_o),
        .remote(b2a_clear_remote)
    );

    // Domain A logic
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate <= 0;
            a_clear   <= 0;
        end else begin
            if (a_clear_i && a_isolate_ack_i && !a_isolate) begin
                a_isolate <= 1;
            end else if (a_isolate && b_isolate_ack_i && !a_clear) begin
                a_clear <= 1;
            end else if (a_clear_ack_i) begin
                a_clear <= 0;
            end else if (!a_clear && a_isolate_ack_i) begin
                a_isolate <= 0;
            end
        end
    end

    // Domain B logic
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate <= 0;
            b_clear   <= 0;
        end else begin
            if (b_clear_i && b_isolate_ack_i && !b_isolate) begin
                b_isolate <= 1;
            end else if (b_isolate && a_isolate_ack_i && !b_clear) begin
                b_clear <= 1;
            end else if (b_clear_ack_i) begin
                b_clear <= 0;
            end else if (!b_clear && b_isolate_ack_i) begin
                b_isolate <= 0;
            end
        end
    end

    // Assign outputs
    assign a_isolate_o = a_isolate;
    assign a_clear_o   = a_clear;
    assign b_isolate_o = b_isolate;
    assign b_clear_o   = b_clear;

endmodule

// CDC Handshake module
module cdc_handshake #(
    parameter SYNC_STAGES = 2
)(
    input  local,
    output remote
);

    reg [SYNC_STAGES-1:0] sync_chain;

    // Synchronize local signal to remote clock domain
    always @(posedge local) begin
        sync_chain <= {sync_chain[SYNC_STAGES-2:0], local};
    end

    // Assign synchronized signal to remote output
    assign remote = sync_chain[SYNC_STAGES-1];

endmodule
