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

    // Internal signals for domain A
    reg a_isolate_req;
    reg a_clear_req;
    reg a_isolate_done;
    reg a_clear_done;
    reg a_isolate_o_reg;
    reg a_clear_o_reg;

    // Internal signals for domain B
    reg b_isolate_req;
    reg b_clear_req;
    reg b_isolate_done;
    reg b_clear_done;
    reg b_isolate_o_reg;
    reg b_clear_o_reg;

    // Synchronized signals
    reg [SYNC_STAGES-1:0] a_isolate_req_sync;
    reg [SYNC_STAGES-1:0] a_clear_req_sync;
    reg [SYNC_STAGES-1:0] b_isolate_req_sync;
    reg [SYNC_STAGES-1:0] b_clear_req_sync;
    reg [SYNC_STAGES-1:0] a_isolate_ack_sync;
    reg [SYNC_STAGES-1:0] a_clear_ack_sync;
    reg [SYNC_STAGES-1:0] b_isolate_ack_sync;
    reg [SYNC_STAGES-1:0] b_clear_ack_sync;

    // Domain A logic
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate_req <= 0;
            a_clear_req <= 0;
            a_isolate_done <= 0;
            a_clear_done <= 0;
            a_isolate_o_reg <= 0;
            a_clear_o_reg <= 0;
        end else begin
            // Request isolation if clear is requested and isolation is not done
            if (a_clear_i && !a_isolate_done) begin
                a_isolate_req <= 1;
            end

            // Synchronize signals from domain B
            a_isolate_req_sync <= {a_isolate_req_sync[SYNC_STAGES-2:0], b_isolate_req};
            a_clear_req_sync <= {a_clear_req_sync[SYNC_STAGES-2:0], b_clear_req};
            a_isolate_ack_sync <= {a_isolate_ack_sync[SYNC_STAGES-2:0], b_isolate_ack_i};
            a_clear_ack_sync <= {a_clear_ack_sync[SYNC_STAGES-2:0], b_clear_ack_i};

            // Set isolate output if request is high and ack from B is high
            if (a_isolate_req && a_isolate_ack_sync[SYNC_STAGES-1]) begin
                a_isolate_o_reg <= 1;
            end

            // Set isolate done if isolate output is high and ack from A is high
            if (a_isolate_o_reg && a_isolate_ack_i) begin
                a_isolate_done <= 1;
            end

            // Set clear output if isolate done and request is high
            if (a_isolate_done && a_isolate_req) begin
                a_clear_req <= 1;
                a_clear_o_reg <= 1;
            end

            // Set clear done if clear output is high and ack from B is high
            if (a_clear_o_reg && a_clear_ack_sync[SYNC_STAGES-1]) begin
                a_clear_done <= 1;
            end

            // Reset all signals if clear done
            if (a_clear_done) begin
                a_clear_o_reg <= 0;
                a_isolate_o_reg <= 0;
                a_isolate_req <= 0;
                a_clear_req <= 0;
                a_isolate_done <= 0;
            end
        end
    end

    // Domain B logic
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate_req <= 0;
            b_clear_req <= 0;
            b_isolate_done <= 0;
            b_clear_done <= 0;
            b_isolate_o_reg <= 0;
            b_clear_o_reg <= 0;
        end else begin
            // Request isolation if clear is requested and isolation is not done
            if (b_clear_i && !b_isolate_done) begin
                b_isolate_req <= 1;
            end

            // Synchronize signals from domain A
            b_isolate_req_sync <= {b_isolate_req_sync[SYNC_STAGES-2:0], a_isolate_req};
            b_clear_req_sync <= {b_clear_req_sync[SYNC_STAGES-2:0], a_clear_req};
            b_isolate_ack_sync <= {b_isolate_ack_sync[SYNC_STAGES-2:0], a_isolate_ack_i};
            b_clear_ack_sync <= {b_clear_ack_sync[SYNC_STAGES-2:0], a_clear_ack_i};

            // Set isolate output if request is high and ack from A is high
            if (b_isolate_req && b_isolate_ack_sync[SYNC_STAGES-1]) begin
                b_isolate_o_reg <= 1;
            end

            // Set isolate done if isolate output is high and ack from B is high
            if (b_isolate_o_reg && b_isolate_ack_i) begin
                b_isolate_done <= 1;
            end

            // Set clear output if isolate done and request is high
            if (b_isolate_done && b_isolate_req) begin
                b_clear_req <= 1;
                b_clear_o_reg <= 1;
            end

            // Set clear done if clear output is high and ack from A is high
            if (b_clear_o_reg && b_clear_ack_sync[SYNC_STAGES-1]) begin
                b_clear_done <= 1;
            end

            // Reset all signals if clear done
            if (b_clear_done) begin
                b_clear_o_reg <= 0;
                b_isolate_o_reg <= 0;
                b_isolate_req <= 0;
                b_clear_req <= 0;
                b_isolate_done <= 0;
            end
        end
    end

    // Assign outputs
    assign a_isolate_o = a_isolate_o_reg;
    assign a_clear_o = a_clear_o_reg;
    assign b_isolate_o = b_isolate_o_reg;
    assign b_clear_o = b_clear_o_reg;

endmodule
