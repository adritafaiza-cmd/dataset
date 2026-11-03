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

    reg a_clear_req;
    reg b_clear_req;
    reg a_isolate_req;
    reg b_isolate_req;

    reg a_clear;
    reg b_clear;
    reg a_isolate;
    reg b_isolate;

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

    // Synchronization flops for a_isolate_ack_i and b_isolate_ack_i
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            a_isolate_sync <= {a_isolate_sync[SYNC_STAGES-2:0], a_isolate_ack_i};
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            b_isolate_sync <= {b_isolate_sync[SYNC_STAGES-2:0], b_isolate_ack_i};
        end
    end

    // State machine for a_clk_i domain
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_clear_req <= 1'b0;
            a_isolate_req <= 1'b0;
            a_clear <= 1'b0;
            a_isolate <= 1'b0;
        end else begin
            case ({a_isolate, a_clear, a_isolate_req, a_clear_req, a_clear_sync[SYNC_STAGES-1], a_isolate_sync[SYNC_STAGES-1]})
                6'b000000: begin // Idle
                    if (a_clear_sync[SYNC_STAGES-1]) begin
                        a_isolate_req <= 1'b1;
                    end
                end
                6'b001000: begin // Isolate requested
                    a_isolate <= 1'b1;
                    a_isolate_req <= 1'b0;
                end
                6'b011000: begin // Isolate active
                    if (a_isolate_sync[SYNC_STAGES-1]) begin
                        a_clear_req <= 1'b1;
                    end
                end
                6'b011100: begin // Clear requested
                    a_clear <= 1'b1;
                    a_clear_req <= 1'b0;
                end
                6'b011110: begin // Clear active
                    if (a_clear_ack_i) begin
                        a_clear <= 1'b0;
                    end
                end
                6'b010110: begin // Clear done
                    if (b_isolate_sync[SYNC_STAGES-1]) begin
                        a_isolate <= 1'b0;
                    end
                end
                default: begin
                    a_clear_req <= 1'b0;
                    a_isolate_req <= 1'b0;
                    a_clear <= 1'b0;
                    a_isolate <= 1'b0;
                end
            endcase
        end
    end

    // State machine for b_clk_i domain
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_clear_req <= 1'b0;
            b_isolate_req <= 1'b0;
            b_clear <= 1'b0;
            b_isolate <= 1'b0;
        end else begin
            case ({b_isolate, b_clear, b_isolate_req, b_clear_req, b_clear_sync[SYNC_STAGES-1], b_isolate_sync[SYNC_STAGES-1]})
                6'b000000: begin // Idle
                    if (b_clear_sync[SYNC_STAGES-1]) begin
                        b_isolate_req <= 1'b1;
                    end
                end
                6'b001000: begin // Isolate requested
                    b_isolate <= 1'b1;
                    b_isolate_req <= 1'b0;
                end
                6'b011000: begin // Isolate active
                    if (b_isolate_sync[SYNC_STAGES-1]) begin
                        b_clear_req <= 1'b1;
                    end
                end
                6'b011100: begin // Clear requested
                    b_clear <= 1'b1;
                    b_clear_req <= 1'b0;
                end
                6'b011110: begin // Clear active
                    if (b_clear_ack_i) begin
                        b_clear <= 1'b0;
                    end
                end
                6'b010110: begin // Clear done
                    if (a_isolate_sync[SYNC_STAGES-1]) begin
                        b_isolate <= 1'b0;
                    end
                end
                default: begin
                    b_clear_req <= 1'b0;
                    b_isolate_req <= 1'b0;
                    b_clear <= 1'b0;
                    b_isolate <= 1'b0;
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
