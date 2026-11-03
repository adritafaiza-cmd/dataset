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
    reg [1:0] a_isolate_state;
    reg [1:0] a_clear_state;
    reg [1:0] b_isolate_state;
    reg [1:0] b_clear_state;

    // State definitions
    parameter IDLE = 2'b00;
    parameter ISOLATE = 2'b01;
    parameter CLEAR = 2'b10;

    // FSM for domain A
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate_state <= IDLE;
            a_clear_state <= IDLE;
        end else begin
            case (a_isolate_state)
                IDLE: begin
                    if (a_clear_i) begin
                        a_isolate_state <= ISOLATE;
                    end
                end
                ISOLATE: begin
                    if (a_isolate_ack_i) begin
                        a_isolate_state <= CLEAR;
                    end
                end
                CLEAR: begin
                    if (a_clear_ack_i) begin
                        a_isolate_state <= IDLE;
                    end
                end
                default: a_isolate_state <= IDLE;
            endcase
        end
    end

    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_clear_o <= 0;
        end else begin
            case (a_clear_state)
                IDLE: a_clear_o <= 0;
                ISOLATE: a_clear_o <= 0;
                CLEAR: a_clear_o <= 1;
                default: a_clear_o <= 0;
            endcase
        end
    end

    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (!a_rst_ni) begin
            a_isolate_o <= 0;
        end else begin
            case (a_isolate_state)
                IDLE: a_isolate_o <= 0;
                ISOLATE: a_isolate_o <= 1;
                CLEAR: a_isolate_o <= 0;
                default: a_isolate_o <= 0;
            endcase
        end
    end

    // FSM for domain B
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate_state <= IDLE;
            b_clear_state <= IDLE;
        end else begin
            case (b_isolate_state)
                IDLE: begin
                    if (b_clear_i) begin
                        b_isolate_state <= ISOLATE;
                    end
                end
                ISOLATE: begin
                    if (b_isolate_ack_i) begin
                        b_isolate_state <= CLEAR;
                    end
                end
                CLEAR: begin
                    if (b_clear_ack_i) begin
                        b_isolate_state <= IDLE;
                    end
                end
                default: b_isolate_state <= IDLE;
            endcase
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_clear_o <= 0;
        end else begin
            case (b_clear_state)
                IDLE: b_clear_o <= 0;
                ISOLATE: b_clear_o <= 0;
                CLEAR: b_clear_o <= 1;
                default: b_clear_o <= 0;
            endcase
        end
    end

    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (!b_rst_ni) begin
            b_isolate_o <= 0;
        end else begin
            case (b_isolate_state)
                IDLE: b_isolate_o <= 0;
                ISOLATE: b_isolate_o <= 1;
                CLEAR: b_isolate_o <= 0;
                default: b_isolate_o <= 0;
            endcase
        end
    end

endmodule
