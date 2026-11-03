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
    reg [SYNC_STAGES-1:0] a_isolate_sync;
    reg [SYNC_STAGES-1:0] b_clear_sync;
    reg [SYNC_STAGES-1:0] b_isolate_sync;

    reg a_isolate_req;
    reg a_clear_req;
    reg a_isolate_done;
    reg a_clear_done;
    reg a_release_done;

    reg b_isolate_req;
    reg b_clear_req;
    reg b_isolate_done;
    reg b_clear_done;
    reg b_release_done;

    // Synchronization for a_clear_i and a_isolate_ack_i
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_clear_sync <= {SYNC_STAGES{1'b0}};
            a_isolate_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            a_clear_sync <= {a_clear_sync[SYNC_STAGES-2:0], a_clear_i};
            a_isolate_sync <= {a_isolate_sync[SYNC_STAGES-2:0], a_isolate_ack_i};
        end
    end

    // Synchronization for b_clear_i and b_isolate_ack_i
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_clear_sync <= {SYNC_STAGES{1'b0}};
            b_isolate_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            b_clear_sync <= {b_clear_sync[SYNC_STAGES-2:0], b_clear_i};
            b_isolate_sync <= {b_isolate_sync[SYNC_STAGES-2:0], b_isolate_ack_i};
        end
    end

    // State machine for A side
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate_req <= 1'b0;
            a_clear_req <= 1'b0;
            a_isolate_done <= 1'b0;
            a_clear_done <= 1'b0;
            a_release_done <= 1'b0;
        end else begin
            case ({a_isolate_req, a_isolate_done, a_clear_req, a_clear_done, a_release_done})
                5'b00000: begin // IDLE
                    if (a_clear_sync[SYNC_STAGES-1]) begin
                        a_isolate_req <= 1'b1;
                    end
                end
                5'b10000: begin // ISOLATE
                    if (a_isolate_sync[SYNC_STAGES-1]) begin
                        a_isolate_req <= 1'b0;
                        a_isolate_done <= 1'b1;
                        a_clear_req <= 1'b1;
                    end
                end
                5'b01000: begin // ISOLATE_DONE
                    if (b_isolate_sync[SYNC_STAGES-1]) begin
                        a_clear_req <= 1'b1;
                    end
                end
                5'b01100: begin // CLEAR
                    if (a_clear_ack_i) begin
                        a_clear_req <= 1'b0;
                        a_clear_done <= 1'b1;
                    end
                end
                5'b01110: begin // CLEAR_DONE
                    if (b_clear_sync[SYNC_STAGES-1]) begin
                        a_release_done <= 1'b1;
                    end
                end
                5'b01111: begin // RELEASE
                    if (b_isolate_sync[SYNC_STAGES-1]) begin
                        a_isolate_done <= 1'b0;
                        a_clear_done <= 1'b0;
                        a_release_done <= 1'b0;
                    end
                end
                default: begin
                    a_isolate_req <= 1'b0;
                    a_clear_req <= 1'b0;
                    a_isolate_done <= 1'b0;
                    a_clear_done <= 1'b0;
                    a_release_done <= 1'b0;
                end
            endcase
        end
    end

    // State machine for B side
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate_req <= 1'b0;
            b_clear_req <= 1'b0;
            b_isolate_done <= 1'b0;
            b_clear_done <= 1'b0;
            b_release_done <= 1'b0;
        end else begin
            case ({b_isolate_req, b_isolate_done, b_clear_req, b_clear_done, b_release_done})
                5'b00000: begin // IDLE
                    if (b_clear_sync[SYNC_STAGES-1]) begin
                        b_isolate_req <= 1'b1;
                    end
                end
                5'b10000: begin // ISOLATE
                    if (b_isolate_sync[SYNC_STAGES-1]) begin
                        b_isolate_req <= 1'b0;
                        b_isolate_done <= 1'b1;
                        b_clear_req <= 1'b1;
                    end
                end
                5'b01000: begin // ISOLATE_DONE
                    if (a_isolate_sync[SYNC_STAGES-1]) begin
                        b_clear_req <= 1'b1;
                    end
                end
                5'b01100: begin // CLEAR
                    if (b_clear_ack_i) begin
                        b_clear_req <= 1'b0;
                        b_clear_done <= 1'b1;
                    end
                end
                5'b01110: begin // CLEAR_DONE
                    if (a_clear_sync[SYNC_STAGES-1]) begin
                        b_release_done <= 1'b1;
                    end
                end
                5'b01111: begin // RELEASE
                    if (a_isolate_sync[SYNC_STAGES-1]) begin
                        b_isolate_done <= 1'b0;
                        b_clear_done <= 1'b0;
                        b_release_done <= 1'b0;
                    end
                end
                default: begin
                    b_isolate_req <= 1'b0;
                    b_clear_req <= 1'b0;
                    b_isolate_done <= 1'b0;
                    b_clear_done <= 1'b0;
                    b_release_done <= 1'b0;
                end
            endcase
        end
    end

    // Outputs for A side
    assign a_isolate_o = a_isolate_req;
    assign a_clear_o = a_clear_req && a_isolate_done;

    // Outputs for B side
    assign b_isolate_o = b_isolate_req;
    assign b_clear_o = b_clear_req && b_isolate_done;

endmodule
