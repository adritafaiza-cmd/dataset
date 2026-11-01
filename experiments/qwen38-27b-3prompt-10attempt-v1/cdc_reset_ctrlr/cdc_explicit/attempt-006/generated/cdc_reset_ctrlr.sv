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

    // Internal state for domain A
    reg a_isolate_req;
    reg a_clear_req;
    reg a_isolate_done;
    reg a_clear_done;

    // Internal state for domain B
    reg b_isolate_req;
    reg b_clear_req;
    reg b_isolate_done;
    reg b_clear_done;

    // Synchronizers for signals crossing from A to B
    reg [SYNC_STAGES-1:0] a_isolate_req_sync;
    reg [SYNC_STAGES-1:0] a_clear_req_sync;
    reg [SYNC_STAGES-1:0] a_isolate_done_sync;
    reg [SYNC_STAGES-1:0] a_clear_done_sync;

    // Synchronizers for signals crossing from B to A
    reg [SYNC_STAGES-1:0] b_isolate_req_sync;
    reg [SYNC_STAGES-1:0] b_clear_req_sync;
    reg [SYNC_STAGES-1:0] b_isolate_done_sync;
    reg [SYNC_STAGES-1:0] b_clear_done_sync;

    // Synchronized versions
    wire a_isolate_req_b = a_isolate_req_sync[SYNC_STAGES-1];
    wire a_clear_req_b   = a_clear_req_sync[SYNC_STAGES-1];
    wire a_isolate_done_b = a_isolate_done_sync[SYNC_STAGES-1];
    wire a_clear_done_b   = a_clear_done_sync[SYNC_STAGES-1];

    wire b_isolate_req_a = b_isolate_req_sync[SYNC_STAGES-1];
    wire b_clear_req_a   = b_clear_req_sync[SYNC_STAGES-1];
    wire b_isolate_done_a = b_isolate_done_sync[SYNC_STAGES-1];
    wire b_clear_done_a   = b_clear_done_sync[SYNC_STAGES-1];

    // Synchronizer for A to B: a_isolate_req
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni)
            a_isolate_req_sync <= {SYNC_STAGES{1'b0}};
        else
            a_isolate_req_sync <= {a_isolate_req_sync[SYNC_STAGES-2:0], a_isolate_req};
    end

    // Synchronizer for A to B: a_clear_req
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni)
            a_clear_req_sync <= {SYNC_STAGES{1'b0}};
        else
            a_clear_req_sync <= {a_clear_req_sync[SYNC_STAGES-2:0], a_clear_req};
    end

    // Synchronizer for A to B: a_isolate_done
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni)
            a_isolate_done_sync <= {SYNC_STAGES{1'b0}};
        else
            a_isolate_done_sync <= {a_isolate_done_sync[SYNC_STAGES-2:0], a_isolate_done};
    end

    // Synchronizer for A to B: a_clear_done
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni)
            a_clear_done_sync <= {SYNC_STAGES{1'b0}};
        else
            a_clear_done_sync <= {a_clear_done_sync[SYNC_STAGES-2:0], a_clear_done};
    end

    // Synchronizer for B to A: b_isolate_req
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni)
            b_isolate_req_sync <= {SYNC_STAGES{1'b0}};
        else
            b_isolate_req_sync <= {b_isolate_req_sync[SYNC_STAGES-2:0], b_isolate_req};
    end

    // Synchronizer for B to A: b_clear_req
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni)
            b_clear_req_sync <= {SYNC_STAGES{1'b0}};
        else
            b_clear_req_sync <= {b_clear_req_sync[SYNC_STAGES-2:0], b_clear_req};
    end

    // Synchronizer for B to A: b_isolate_done
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni)
            b_isolate_done_sync <= {SYNC_STAGES{1'b0}};
        else
            b_isolate_done_sync <= {b_isolate_done_sync[SYNC_STAGES-2:0], b_isolate_done};
    end

    // Synchronizer for B to A: b_clear_done
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni)
            b_clear_done_sync <= {SYNC_STAGES{1'b0}};
        else
            b_clear_done_sync <= {b_clear_done_sync[SYNC_STAGES-2:0], b_clear_done};
    end

    // Domain A logic
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate_req  <= 1'b0;
            a_clear_req    <= 1'b0;
            a_isolate_done <= 1'b0;
            a_clear_done   <= 1'b0;
        end else begin
            // Isolate request: raise when either side requests clear
            if (a_clear_i || b_clear_req_a)
                a_isolate_req <= 1'b1;
            else
                a_isolate_req <= 1'b0;

            // Isolate done: when both sides have isolated
            if (a_isolate_req && b_isolate_req_a)
                a_isolate_done <= 1'b1;
            else
                a_isolate_done <= 1'b0;

            // Clear request: raise when both sides are isolated
            if (a_isolate_done && b_isolate_done_a)
                a_clear_req <= 1'b1;
            else
                a_clear_req <= 1'b0;

            // Clear done: when both sides have cleared
            if (a_clear_req && b_clear_req_a)
                a_clear_done <= 1'b1;
            else
                a_clear_done <= 1'b0;
        end
    end

    // Domain B logic
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate_req  <= 1'b0;
            b_clear_req    <= 1'b0;
            b_isolate_done <= 1'b0;
            b_clear_done   <= 1'b0;
        end else begin
            // Isolate request: raise when either side requests clear
            if (b_clear_i || a_clear_req_b)
                b_isolate_req <= 1'b1;
            else
                b_isolate_req <= 1'b0;

            // Isolate done: when both sides have isolated
            if (b_isolate_req && a_isolate_req_b)
                b_isolate_done <= 1'b1;
            else
                b_isolate_done <= 1'b0;

            // Clear request: raise when both sides are isolated
            if (b_isolate_done && a_isolate_done_b)
                b_clear_req <= 1'b1;
            else
                b_clear_req <= 1'b0;

            // Clear done: when both sides have cleared
            if (b_clear_req && a_clear_req_b)
                b_clear_done <= 1'b1;
            else
                b_clear_done <= 1'b0;
        end
    end

    // Output assignments
    assign a_isolate_o = a_isolate_req;
    assign a_clear_o   = a_clear_req;
    assign b_isolate_o = b_isolate_req;
    assign b_clear_o   = b_clear_req;

endmodule
