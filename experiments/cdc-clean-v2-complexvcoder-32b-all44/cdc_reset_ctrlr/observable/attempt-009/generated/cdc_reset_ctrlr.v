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
    wire a_clear_req_sync;
    wire b_clear_req_sync;
    wire a_clear_ack;
    wire b_clear_ack;

    // Isolate signals
    reg  a_isolate;
    reg  b_isolate;

    // Clear signals
    reg  a_clear;
    reg  b_clear;

    // CDC handshakes
    cdc_handshake #(
        .SYNC_STAGES(SYNC_STAGES)
    ) a_to_b_handshake (
        .local_clk_i(a_clk_i),
        .local_rst_ni(a_rst_ni),
        .local_req_i(a_clear_i),
        .local_ack_o(a_clear_ack),
        .remote_clk_i(b_clk_i),
        .remote_rst_ni(b_rst_ni),
        .remote_req_i(b_clear_req_sync),
        .remote_ack_o(b_clear_ack_i)
    );

    cdc_handshake #(
        .SYNC_STAGES(SYNC_STAGES)
    ) b_to_a_handshake (
        .local_clk_i(b_clk_i),
        .local_rst_ni(b_rst_ni),
        .local_req_i(b_clear_i),
        .local_ack_o(b_clear_ack),
        .remote_clk_i(a_clk_i),
        .remote_rst_ni(a_rst_ni),
        .remote_req_i(a_clear_req_sync),
        .remote_ack_o(a_clear_ack_i)
    );

    // Synchronize clear requests
    cdc_handshake #(
        .SYNC_STAGES(SYNC_STAGES)
    ) a_to_b_clear_req_sync (
        .local_clk_i(a_clk_i),
        .local_rst_ni(a_rst_ni),
        .local_req_i(a_clear_i),
        .local_ack_o(),
        .remote_clk_i(b_clk_i),
        .remote_rst_ni(b_rst_ni),
        .remote_req_i(a_clear_req_sync),
        .remote_ack_o()
    );

    cdc_handshake #(
        .SYNC_STAGES(SYNC_STAGES)
    ) b_to_a_clear_req_sync (
        .local_clk_i(b_clk_i),
        .local_rst_ni(b_rst_ni),
        .local_req_i(b_clear_i),
        .local_ack_o(),
        .remote_clk_i(a_clk_i),
        .remote_rst_ni(a_rst_ni),
        .remote_req_i(b_clear_req_sync),
        .remote_ack_o()
    );

    // State machines for a_clk_i domain
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate <= 1'b1;
            a_clear <= 1'b0;
        end else begin
            case ({a_isolate, a_clear, a_clear_ack, a_isolate_ack_i})
                4'b1000: begin // Isolate both sides
                    a_isolate <= 1'b1;
                    a_clear <= 1'b0;
                end
                4'b1010: begin // Wait for isolate acknowledgment
                    a_isolate <= 1'b1;
                    a_clear <= 1'b0;
                end
                4'b1011: begin // Start clear
                    a_isolate <= 1'b1;
                    a_clear <= 1'b1;
                end
                4'b1111: begin // Wait for clear acknowledgment
                    a_isolate <= 1'b1;
                    a_clear <= 1'b1;
                end
                4'b1101: begin // Drop clear
                    a_isolate <= 1'b1;
                    a_clear <= 1'b0;
                end
                4'b0101: begin // Wait for isolate release acknowledgment
                    a_isolate <= 1'b0;
                    a_clear <= 1'b0;
                end
                4'b0001: begin // Release isolation
                    a_isolate <= 1'b0;
                    a_clear <= 1'b0;
                end
            endcase
        end
    end

    // State machines for b_clk_i domain
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate <= 1'b1;
            b_clear <= 1'b0;
        end else begin
            case ({b_isolate, b_clear, b_clear_ack, b_isolate_ack_i})
                4'b1000: begin // Isolate both sides
                    b_isolate <= 1'b1;
                    b_clear <= 1'b0;
                end
                4'b1010: begin // Wait for isolate acknowledgment
                    b_isolate <= 1'b1;
                    b_clear <= 1'b0;
                end
                4'b1011: begin // Start clear
                    b_isolate <= 1'b1;
                    b_clear <= 1'b1;
                end
                4'b1111: begin // Wait for clear acknowledgment
                    b_isolate <= 1'b1;
                    b_clear <= 1'b1;
                end
                4'b1101: begin // Drop clear
                    b_isolate <= 1'b1;
                    b_clear <= 1'b0;
                end
                4'b0101: begin // Wait for isolate release acknowledgment
                    b_isolate <= 1'b0;
                    b_clear <= 1'b0;
                end
                4'b0001: begin // Release isolation
                    b_isolate <= 1'b0;
                    b_clear <= 1'b0;
                end
            endcase
        end
    end

    // Assign outputs
    assign a_isolate_o = a_isolate;
    assign a_clear_o = a_clear;
    assign b_isolate_o = b_isolate;
    assign b_clear_o = b_clear;

endmodule

module cdc_handshake #(
    parameter SYNC_STAGES = 2
)(
    input  local_clk_i,
    input  local_rst_ni,
    input  local_req_i,
    output local_ack_o,
    input  remote_clk_i,
    input  remote_rst_ni,
    input  remote_req_i,
    output remote_ack_o
);

    reg [SYNC_STAGES-1:0] req_sync;
    reg [SYNC_STAGES-1:0] ack_sync;

    // Synchronize local request to remote clock domain
    always @(posedge remote_clk_i or negedge remote_rst_ni) begin
        if (!remote_rst_ni) begin
            req_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            req_sync <= {req_sync[SYNC_STAGES-2:0], local_req_i};
        end
    end

    // Generate remote acknowledgment based on synchronized request and local response
    always @(posedge remote_clk_i or negedge remote_rst_ni) begin
        if (!remote_rst_ni) begin
            remote_ack_o <= 1'b0;
        end else begin
            remote_ack_o <= req_sync[SYNC_STAGES-1] & !remote_req_i;
        end
    end

    // Synchronize remote request to local clock domain
    always @(posedge local_clk_i or negedge local_rst_ni) begin
        if (!local_rst_ni) begin
            ack_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            ack_sync <= {ack_sync[SYNC_STAGES-2:0], remote_req_i};
        end
    end

    // Generate local acknowledgment based on synchronized request and local response
    always @(posedge local_clk_i or negedge local_rst_ni) begin
        if (!local_rst_ni) begin
            local_ack_o <= 1'b0;
        end else begin
            local_ack_o <= ack_sync[SYNC_STAGES-1] & !local_req_i;
        end
    end

endmodule
