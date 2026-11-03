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
    reg [SYNC_STAGES-1:0] a_clear_sync;
    reg [SYNC_STAGES-1:0] b_clear_sync;
    reg [SYNC_STAGES-1:0] a_isolate_sync;
    reg [SYNC_STAGES-1:0] b_isolate_sync;

    reg a_isolate_req;
    reg a_clear_req;
    reg a_clear_done;
    reg a_isolate_done;

    reg b_isolate_req;
    reg b_clear_req;
    reg b_clear_done;
    reg b_isolate_done;

    // Synchronization flops for a_clear_i and b_clear_i
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_clear_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            a_clear_sync <= {a_clear_sync[SYNC_STAGES-2:0], a_clear_i};
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_clear_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            b_clear_sync <= {b_clear_sync[SYNC_STAGES-2:0], b_clear_i};
        end
    end

    // Synchronization flops for a_isolate_o and b_isolate_o
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            a_isolate_sync <= {a_isolate_sync[SYNC_STAGES-2:0], a_isolate_o};
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            b_isolate_sync <= {b_isolate_sync[SYNC_STAGES-2:0], b_isolate_o};
        end
    end

    // State machine for A side
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate_req <= 1'b0;
            a_clear_req <= 1'b0;
            a_clear_done <= 1'b0;
            a_isolate_done <= 1'b0;
        end else begin
            case ({a_isolate_done, a_clear_done, a_isolate_ack_i, a_clear_ack_i, a_clear_sync[SYNC_STAGES-1]})
                5'b00111: begin // Isolate done, clear done, acks received, clear requested
                    a_isolate_req <= 1'b0;
                    a_clear_req <= 1'b0;
                    a_clear_done <= 1'b0;
                    a_isolate_done <= 1'b0;
                end
                5'b00011: begin // Isolate done, clear not done, acks received, clear requested
                    a_clear_req <= 1'b1;
                end
                5'b00110: begin // Isolate done, clear done, acks not received, clear requested
                    a_clear_done <= 1'b0;
                end
                5'b00010: begin // Isolate done, clear not done, acks not received, clear requested
                    a_clear_req <= 1'b1;
                    a_clear_done <= 1'b0;
                end
                5'b00101: begin // Isolate done, clear done, acks received, no clear request
                    a_isolate_req <= 1'b0;
                    a_clear_req <= 1'b0;
                    a_clear_done <= 1'b0;
                    a_isolate_done <= 1'b0;
                end
                5'b00001: begin // Isolate done, clear not done, acks received, no clear request
                    a_isolate_req <= 1'b0;
                    a_clear_req <= 1'b0;
                    a_clear_done <= 1'b0;
                    a_isolate_done <= 1'b0;
                end
                5'b00100: begin // Isolate done, clear done, acks not received, no clear request
                    a_isolate_req <= 1'b0;
                    a_clear_done <= 1'b0;
                end
                5'b00000: begin // Isolate done, clear not done, acks not received, no clear request
                    a_isolate_req <= 1'b0;
                    a_clear_req <= 1'b0;
                    a_clear_done <= 1'b0;
                end
                5'b10111: begin // Isolate not done, clear done, acks received, clear requested
                    a_isolate_req <= 1'b1;
                    a_clear_req <= 1'b0;
                    a_clear_done <= 1'b0;
                end
                5'b10011: begin // Isolate not done, clear not done, acks received, clear requested
                    a_isolate_req <= 1'b1;
                    a_clear_req <= 1'b1;
                end
                5'b10110: begin // Isolate not done, clear done, acks not received, clear requested
                    a_isolate_req <= 1'b1;
                    a_clear_done <= 1'b0;
                end
                5'b10010: begin // Isolate not done, clear not done, acks not received, clear requested
                    a_isolate_req <= 1'b1;
                    a_clear_req <= 1'b1;
                    a_clear_done <= 1'b0;
                end
                5'b10101: begin // Isolate not done, clear done, acks received, no clear request
                    a_isolate_req <= 1'b1;
                    a_clear_req <= 1'b0;
                    a_clear_done <= 1'b0;
                end
                5'b10001: begin // Isolate not done, clear not done, acks received, no clear request
                    a_isolate_req <= 1'b1;
                    a_clear_req <= 1'b0;
                    a_clear_done <= 1'b0;
                end
                5'b10100: begin // Isolate not done, clear done, acks not received, no clear request
                    a_isolate_req <= 1'b1;
                    a_clear_done <= 1'b0;
                end
                5'b10000: begin // Isolate not done, clear not done, acks not received, no clear request
                    a_isolate_req <= 1'b1;
                    a_clear_req <= 1'b0;
                    a_clear_done <= 1'b0;
                end
                5'b01111: begin // Isolate done, clear not done, acks received, clear requested
                    a_clear_req <= 1'b1;
                end
                5'b01011: begin // Isolate done, clear not done, acks received, no clear request
                    a_isolate_req <= 1'b0;
                    a_clear_req <= 1'b0;
                    a_clear_done <= 1'b0;
                    a_isolate_done <= 1'b0;
                end
                5'b01110: begin // Isolate done, clear not done, acks not received, clear requested
                    a_clear_req <= 1'b1;
                    a_clear_done <= 1'b0;
                end
                5'b01010: begin // Isolate done, clear not done, acks not received, no clear request
                    a_isolate_req <= 1'b0;
                    a_clear_req <= 1'b0;
                    a_clear_done <= 1'b0;
                    a_isolate_done <= 1'b0;
                end
                5'b01101: begin // Isolate done, clear done, acks received, clear requested
                    a_isolate_req <= 1'b0;
                    a_clear_req <= 1'b0;
                    a_clear_done <= 1'b0;
                    a_isolate_done <= 1'b0;
                end
                5'b01001: begin // Isolate done, clear done, acks received, no clear request
                    a_isolate_req <= 1'b0;
                    a_clear_req <= 1'b0;
                    a_clear_done <= 1'b0;
                    a_isolate_done <= 1'b0;
                end
                5'b01100: begin // Isolate done, clear done, acks not received, clear requested
                    a_isolate_req <= 1'b0;
                    a_clear_done <= 1'b0;
                end
                5'b01000: begin // Isolate done, clear done, acks not received, no clear request
                    a_isolate_req <= 1'b0;
                    a_clear_req <= 1'b0;
                    a_clear_done <= 1'b0;
                end
                default: begin
                    a_isolate_req <= 1'b0;
                    a_clear_req <= 1'b0;
                    a_clear_done <= 1'b0;
                    a_isolate_done <= 1'b0;
                end
            endcase
        end
    end

    // State machine for B side
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate_req <= 1'b0;
            b_clear_req <= 1'b0;
            b_clear_done <= 1'b0;
            b_isolate_done <= 1'b0;
        end else begin
            case ({b_isolate_done, b_clear_done, b_isolate_ack_i, b_clear_ack_i, b_clear_sync[SYNC_STAGES-1]})
                5'b00111: begin // Isolate done, clear done, acks received, clear requested
                    b_isolate_req <= 1'b0;
                    b_clear_req <= 1'b0;
                    b_clear_done <= 1'b0;
                    b_isolate_done <= 1'b0;
                end
                5'b00011: begin // Isolate done, clear not done, acks received, clear requested
                    b_clear_req <= 1'b1;
                end
                5'b00110: begin // Isolate done, clear done, acks not received, clear requested
                    b_clear_done <= 1'b0;
                end
                5'b00010: begin // Isolate done, clear not done, acks not received, clear requested
                    b_clear_req <= 1'b1;
                    b_clear_done <= 1'b0;
                end
                5'b00101: begin // Isolate done, clear done, acks received, no clear request
                    b_isolate_req <= 1'b0;
                    b_clear_req <= 1'b0;
                    b_clear_done <= 1'b0;
                    b_isolate_done <= 1'b0;
                end
                5'b00001: begin // Isolate done, clear not done, acks received, no clear request
                    b_isolate_req <= 1'b0;
                    b_clear_req <= 1'b0;
                    b_clear_done <= 1'b0;
                    b_isolate_done <= 1'b0;
                end
                5'b00100: begin // Isolate done, clear done, acks not received, no clear request
                    b_isolate_req <= 1'b0;
                    b_clear_done <= 1'b0;
                end
                5'b00000: begin // Isolate done, clear not done, acks not received, no clear request
                    b_isolate_req <= 1'b0;
                    b_clear_req <= 1'b0;
                    b_clear_done <= 1'b0;
                end
                5'b10111: begin // Isolate not done, clear done, acks received, clear requested
                    b_isolate_req <= 1'b1;
                    b_clear_req <= 1'b0;
                    b_clear_done <= 1'b0;
                end
                5'b10011: begin // Isolate not done, clear not done, acks received, clear requested
                    b_isolate_req <= 1'b1;
                    b_clear_req <= 1'b1;
                end
                5'b10110: begin // Isolate not done, clear done, acks not received, clear requested
                    b_isolate_req <= 1'b1;
                    b_clear_done <= 1'b0;
                end
                5'b10010: begin // Isolate not done, clear not done, acks not received, clear requested
                    b_isolate_req <= 1'b1;
                    b_clear_req <= 1'b1;
                    b_clear_done <= 1'b0;
                end
                5'b10101: begin // Isolate not done, clear done, acks received, no clear request
                    b_isolate_req <= 1'b1;
                    b_clear_req <= 1'b0;
                    b_clear_done <= 1'b0;
                end
                5'b10001: begin // Isolate not done, clear not done, acks received, no clear request
                    b_isolate_req <= 1'b1;
                    b_clear_req <= 1'b0;
                    b_clear_done <= 1'b0;
                end
                5'b10100: begin // Isolate not done, clear done, acks not received, no clear request
                    b_isolate_req <= 1'b1;
                    b_clear_done <= 1'b0;
                end
                5'b10000: begin // Isolate not done, clear not done, acks not received, no clear request
                    b_isolate_req <= 1'b1;
                    b_clear_req <= 1'b0;
                    b_clear_done <= 1'b0;
                end
                5'b01111: begin // Isolate done, clear not done, acks received, clear requested
                    b_clear_req <= 1'b1;
                end
                5'b01011: begin // Isolate done, clear not done, acks received, no clear request
                    b_isolate_req <= 1'b0;
                    b_clear_req <= 1'b0;
                    b_clear_done <= 1'b0;
                    b_isolate_done <= 1'b0;
                end
                5'b01110: begin // Isolate done, clear not done, acks not received, clear requested
                    b_clear_req <= 1'b1;
                    b_clear_done <= 1'b0;
                end
                5'b01010: begin // Isolate done, clear not done, acks not received, no clear request
                    b_isolate_req <= 1'b0;
                    b_clear_req <= 1'b0;
                    b_clear_done <= 1'b0;
                    b_isolate_done <= 1'b0;
                end
                5'b01101: begin // Isolate done, clear done, acks received, clear requested
                    b_isolate_req <= 1'b0;
                    b_clear_req <= 1'b0;
                    b_clear_done <= 1'b0;
                    b_isolate_done <= 1'b0;
                end
                5'b01001: begin // Isolate done, clear done, acks received, no clear request
                    b_isolate_req <= 1'b0;
                    b_clear_req <= 1'b0;
                    b_clear_done <= 1'b0;
                    b_isolate_done <= 1'b0;
                end
                5'b01100: begin // Isolate done, clear done, acks not received, clear requested
                    b_isolate_req <= 1'b0;
                    b_clear_done <= 1'b0;
                end
                5'b01000: begin // Isolate done, clear done, acks not received, no clear request
                    b_isolate_req <= 1'b0;
                    b_clear_req <= 1'b0;
                    b_clear_done <= 1'b0;
                end
                default: begin
                    b_isolate_req <= 1'b0;
                    b_clear_req <= 1'b0;
                    b_clear_done <= 1'b0;
                    b_isolate_done <= 1'b0;
                end
            endcase
        end
    end

    // Outputs for A side
    assign a_isolate_o = a_isolate_req;
    assign a_clear_o = a_clear_req & a_isolate_done;

    // Outputs for B side
    assign b_isolate_o = b_isolate_req;
    assign b_clear_o = b_clear_req & b_isolate_done;

endmodule
