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

    // State machine states
    localparam S_IDLE      = 2'd0;
    localparam S_ISOLATE   = 2'd1;
    localparam S_CLEAR     = 2'd2;
    localparam S_RELEASE   = 2'd3;

    // A-domain state
    reg [1:0] a_state;
    reg       a_isolate_reg;
    reg       a_clear_reg;

    // B-domain state
    reg [1:0] b_state;
    reg       b_isolate_reg;
    reg       b_clear_reg;

    // Synchronizers for A -> B
    reg [SYNC_STAGES-1:0] a_isolate_sync;
    reg [SYNC_STAGES-1:0] a_clear_sync;

    // Synchronizers for B -> A
    reg [SYNC_STAGES-1:0] b_isolate_sync;
    reg [SYNC_STAGES-1:0] b_clear_sync;

    // Synchronized signals
    wire a_isolate_synced = a_isolate_sync[SYNC_STAGES-1];
    wire a_clear_synced   = a_clear_sync[SYNC_STAGES-1];
    wire b_isolate_synced = b_isolate_sync[SYNC_STAGES-1];
    wire b_clear_synced   = b_clear_sync[SYNC_STAGES-1];

    // A-domain logic
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_state       <= S_IDLE;
            a_isolate_reg <= 1'b0;
            a_clear_reg   <= 1'b0;
        end else begin
            case (a_state)
                S_IDLE: begin
                    a_isolate_reg <= 1'b0;
                    a_clear_reg   <= 1'b0;
                    if (a_clear_i) begin
                        a_state <= S_ISOLATE;
                    end
                end
                S_ISOLATE: begin
                    a_isolate_reg <= 1'b1;
                    a_clear_reg   <= 1'b0;
                    if (a_isolate_ack_i && b_isolate_synced) begin
                        a_state <= S_CLEAR;
                    end
                end
                S_CLEAR: begin
                    a_isolate_reg <= 1'b1;
                    a_clear_reg   <= 1'b1;
                    if (a_clear_ack_i && b_clear_synced) begin
                        a_state <= S_RELEASE;
                    end
                end
                S_RELEASE: begin
                    a_isolate_reg <= 1'b0;
                    a_clear_reg   <= 1'b0;
                    a_state       <= S_IDLE;
                end
                default: begin
                    a_state       <= S_IDLE;
                    a_isolate_reg <= 1'b0;
                    a_clear_reg   <= 1'b0;
                end
            endcase
        end
    end

    // B-domain logic
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_state       <= S_IDLE;
            b_isolate_reg <= 1'b0;
            b_clear_reg   <= 1'b0;
        end else begin
            case (b_state)
                S_IDLE: begin
                    b_isolate_reg <= 1'b0;
                    b_clear_reg   <= 1'b0;
                    if (b_clear_i) begin
                        b_state <= S_ISOLATE;
                    end
                end
                S_ISOLATE: begin
                    b_isolate_reg <= 1'b1;
                    b_clear_reg   <= 1'b0;
                    if (b_isolate_ack_i && a_isolate_synced) begin
                        b_state <= S_CLEAR;
                    end
                end
                S_CLEAR: begin
                    b_isolate_reg <= 1'b1;
                    b_clear_reg   <= 1'b1;
                    if (b_clear_ack_i && a_clear_synced) begin
                        b_state <= S_RELEASE;
                    end
                end
                S_RELEASE: begin
                    b_isolate_reg <= 1'b0;
                    b_clear_reg   <= 1'b0;
                    b_state       <= S_IDLE;
                end
                default: begin
                    b_state       <= S_IDLE;
                    b_isolate_reg <= 1'b0;
                    b_clear_reg   <= 1'b0;
                end
            endcase
        end
    end

    // Synchronizer A -> B: a_isolate
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            a_isolate_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            a_isolate_sync <= {a_isolate_sync[SYNC_STAGES-2:0], a_isolate_reg};
        end
    end

    // Synchronizer A -> B: a_clear
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            a_clear_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            a_clear_sync <= {a_clear_sync[SYNC_STAGES-2:0], a_clear_reg};
        end
    end

    // Synchronizer B -> A: b_isolate
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            b_isolate_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            b_isolate_sync <= {b_isolate_sync[SYNC_STAGES-2:0], b_isolate_reg};
        end
    end

    // Synchronizer B -> A: b_clear
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            b_clear_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            b_clear_sync <= {b_clear_sync[SYNC_STAGES-2:0], b_clear_reg};
        end
    end

    // Outputs
    assign a_isolate_o = a_isolate_reg;
    assign a_clear_o   = a_clear_reg;
    assign b_isolate_o = b_isolate_reg;
    assign b_clear_o   = b_clear_reg;

endmodule
