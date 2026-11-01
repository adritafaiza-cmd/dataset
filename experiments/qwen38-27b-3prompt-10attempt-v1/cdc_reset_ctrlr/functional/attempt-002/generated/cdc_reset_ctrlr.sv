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

    // State encoding
    localparam S_IDLE     = 2'd0;
    localparam S_ISOLATE  = 2'd1;
    localparam S_CLEAR    = 2'd2;
    localparam S_RELEASE  = 2'd3;

    // Synchronizers for b_clear_i into a domain
    reg [SYNC_STAGES-1:0] b_clear_sync_a;
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni)
            b_clear_sync_a <= {SYNC_STAGES{1'b0}};
        else
            b_clear_sync_a <= {b_clear_sync_a[SYNC_STAGES-2:0], b_clear_i};
    end
    wire b_clear_synced_a = b_clear_sync_a[SYNC_STAGES-1];

    // Synchronizers for a_clear_i into b domain
    reg [SYNC_STAGES-1:0] a_clear_sync_b;
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni)
            a_clear_sync_b <= {SYNC_STAGES{1'b0}};
        else
            a_clear_sync_b <= {a_clear_sync_b[SYNC_STAGES-2:0], a_clear_i};
    end
    wire a_clear_synced_b = a_clear_sync_b[SYNC_STAGES-1];

    // Synchronizers for b_isolate_ack_i into a domain
    reg [SYNC_STAGES-1:0] b_isolate_ack_sync_a;
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni)
            b_isolate_ack_sync_a <= {SYNC_STAGES{1'b0}};
        else
            b_isolate_ack_sync_a <= {b_isolate_ack_sync_a[SYNC_STAGES-2:0], b_isolate_ack_i};
    end
    wire b_isolate_ack_synced_a = b_isolate_ack_sync_a[SYNC_STAGES-1];

    // Synchronizers for a_isolate_ack_i into b domain
    reg [SYNC_STAGES-1:0] a_isolate_ack_sync_b;
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni)
            a_isolate_ack_sync_b <= {SYNC_STAGES{1'b0}};
        else
            a_isolate_ack_sync_b <= {a_isolate_ack_sync_b[SYNC_STAGES-2:0], a_isolate_ack_i};
    end
    wire a_isolate_ack_synced_b = a_isolate_ack_sync_b[SYNC_STAGES-1];

    // Synchronizers for b_clear_ack_i into a domain
    reg [SYNC_STAGES-1:0] b_clear_ack_sync_a;
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni)
            b_clear_ack_sync_a <= {SYNC_STAGES{1'b0}};
        else
            b_clear_ack_sync_a <= {b_clear_ack_sync_a[SYNC_STAGES-2:0], b_clear_ack_i};
    end
    wire b_clear_ack_synced_a = b_clear_ack_sync_a[SYNC_STAGES-1];

    // Synchronizers for a_clear_ack_i into b domain
    reg [SYNC_STAGES-1:0] a_clear_ack_sync_b;
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni)
            a_clear_ack_sync_b <= {SYNC_STAGES{1'b0}};
        else
            a_clear_ack_sync_b <= {a_clear_ack_sync_b[SYNC_STAGES-2:0], a_clear_ack_i};
    end
    wire a_clear_ack_synced_b = a_clear_ack_sync_b[SYNC_STAGES-1];

    // A-domain state machine
    reg [1:0] a_state;
    reg       a_isolate_reg;
    reg       a_clear_reg;

    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_state       <= S_IDLE;
            a_isolate_reg <= 1'b0;
            a_clear_reg   <= 1'b0;
        end else begin
            case (a_state)
                S_IDLE: begin
                    if (a_clear_i || b_clear_synced_a) begin
                        a_state       <= S_ISOLATE;
                        a_isolate_reg <= 1'b1;
                        a_clear_reg   <= 1'b0;
                    end
                end
                S_ISOLATE: begin
                    if (a_isolate_ack_i && b_isolate_ack_synced_a) begin
                        a_state       <= S_CLEAR;
                        a_isolate_reg <= 1'b1;
                        a_clear_reg   <= 1'b1;
                    end
                end
                S_CLEAR: begin
                    if (a_clear_ack_i && b_clear_ack_synced_a) begin
                        a_state       <= S_RELEASE;
                        a_isolate_reg <= 1'b1;
                        a_clear_reg   <= 1'b1;
                    end
                end
                S_RELEASE: begin
                    a_state       <= S_IDLE;
                    a_isolate_reg <= 1'b0;
                    a_clear_reg   <= 1'b0;
                end
                default: begin
                    a_state       <= S_IDLE;
                    a_isolate_reg <= 1'b0;
                    a_clear_reg   <= 1'b0;
                end
            endcase
        end
    end

    assign a_isolate_o = a_isolate_reg;
    assign a_clear_o   = a_clear_reg;

    // B-domain state machine
    reg [1:0] b_state;
    reg       b_isolate_reg;
    reg       b_clear_reg;

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_state       <= S_IDLE;
            b_isolate_reg <= 1'b0;
            b_clear_reg   <= 1'b0;
        end else begin
            case (b_state)
                S_IDLE: begin
                    if (b_clear_i || a_clear_synced_b) begin
                        b_state       <= S_ISOLATE;
                        b_isolate_reg <= 1'b1;
                        b_clear_reg   <= 1'b0;
                    end
                end
                S_ISOLATE: begin
                    if (b_isolate_ack_i && a_isolate_ack_synced_b) begin
                        b_state       <= S_CLEAR;
                        b_isolate_reg <= 1'b1;
                        b_clear_reg   <= 1'b1;
                    end
                end
                S_CLEAR: begin
                    if (b_clear_ack_i && a_clear_ack_synced_b) begin
                        b_state       <= S_RELEASE;
                        b_isolate_reg <= 1'b1;
                        b_clear_reg   <= 1'b1;
                    end
                end
                S_RELEASE: begin
                    b_state       <= S_IDLE;
                    b_isolate_reg <= 1'b0;
                    b_clear_reg   <= 1'b0;
                end
                default: begin
                    b_state       <= S_IDLE;
                    b_isolate_reg <= 1'b0;
                    b_clear_reg   <= 1'b0;
                end
            endcase
        end
    end

    assign b_isolate_o = b_isolate_reg;
    assign b_clear_o   = b_clear_reg;

endmodule
