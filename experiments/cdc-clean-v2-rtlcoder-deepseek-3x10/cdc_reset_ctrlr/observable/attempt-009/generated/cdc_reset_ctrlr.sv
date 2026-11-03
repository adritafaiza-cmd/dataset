The following Verilog-2001 code implements a two-domain isolate-then-clear reset controller:

```
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
    reg [1:0] a_state;
    reg [1:0] b_state;
    reg a_clear_o_reg;
    reg b_clear_o_reg;
    reg a_isolate_o_reg;
    reg b_isolate_o_reg;
    reg a_clear_ack_reg;
    reg b_clear_ack_reg;
    reg a_isolate_ack_reg;
    reg b_isolate_ack_reg;
    reg a_clear_sync_reg;
    reg b_clear_sync_reg;
    reg a_isolate_sync_reg;
    reg b_isolate_sync_reg;
    reg a_clear_ack_sync_reg;
    reg b_clear_ack_sync_reg;
    reg a_isolate_ack_sync_reg;
    reg b_isolate_ack_sync_reg;
    reg a_clear_sync_reg2;
    reg b_clear_sync_reg2;
    reg a_isolate_sync_reg2;
    reg b_isolate_sync_reg2;
    reg a_clear_ack_sync_reg2;
    reg b_clear_ack_sync_reg2;
    reg a_isolate_ack_sync_reg2;
    reg b_isolate_ack_sync_reg2;
    reg a_clear_sync_reg3;
    reg b_clear_sync_reg3;
    reg a_isolate_sync_reg3;
    reg b_isolate_sync_reg3;
    reg a_clear_ack_sync_reg3;
    reg b_clear_ack_sync_reg3;
    reg a_isolate_ack_sync_reg3;
    reg b_isolate_ack_sync_reg3;
    reg a_clear_sync_reg4;
    reg b_clear_sync_reg4;
    reg a_isolate_sync_reg4;
    reg b_isolate_sync_reg4;
    reg a_clear_ack_sync_reg4;
    reg b_clear_ack_sync_reg4;
    reg a_isolate_ack_sync_reg4;
    reg b_isolate_ack_sync_reg4;

    // State machine for a_clk_i
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (~a_rst_ni) begin
            a_state <= 2'b00;
            a_clear_o_reg <= 1'b0;
            a_isolate_o_reg <= 1'b0;
            a_clear_ack_reg <= 1'b0;
            a_isolate_ack_reg <= 1'b0;
        end else begin
            case (a_state)
                2'b00: begin // Idle
                    if (a_clear_i) begin
                        a_state <= 2'b01;
                        a_clear_o_reg <= 1'b1;
                        a_isolate_o_reg <= 1'b1;
                    end else if (a_isolate_i) begin
                        a_state <= 2'b10;
                        a_isolate_o_reg <= 1'b1;
                    end
                end
                2'b01: begin // Clear
                    if (a_clear_ack_i) begin
                        a_state <= 2'b11;
                        a_clear_ack_reg <= 1'b1;
                    end
                end
                2'b10: begin // Isolate
                    if (a_isolate_ack_i) begin
                        a_state <= 2'b11;
                        a_isolate_ack_reg <= 1'b1;
                    end
                end
                2'b11: begin // Release
                    a_state <= 2'b00;
                    a_clear_o_reg <= 1'b0;
                    a_isolate_o_reg <= 1'b0;
                    a_clear_ack_reg <= 1'b0;
                    a_isolate_ack_reg <= 1'b0;
                end
            endcase
        end
    end

    // State machine for b_clk_i
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (~b_rst_ni) begin
            b_state <= 2'b00;
            b_clear_o_reg <= 1'b0;
            b_isolate_o_reg <= 1'b0;
            b_clear_ack_reg <= 1'b0;
            b_isolate_ack_reg <= 1'b0;
        end else begin
            case (b_state)
                2'b00: begin // Idle
                    if (b_clear_i) begin
                        b_state <= 2'b01;
                        b_clear_o_reg <= 1'b1;
                        b_isolate_o_reg <= 1'b1;
                    end else if (b_isolate_i) begin
                        b_state <= 2'b10;
                        b_isolate_o_reg <= 1'b1;
                    end
                end
                2'b01: begin // Clear
                    if (b_clear_ack_i) begin
                        b_state <= 2'b11;
                        b_clear_ack_reg <= 1'b1;
                    end
                end
                2'b10: begin // Isolate
                    if (b_isolate_ack_i) begin
                        b_state <= 2'b11;
                        b_isolate_ack_reg <= 1'b1;
                    end
                end
                2'b11: begin // Release
                    b_state <= 2'b00;
                    b_clear_o_reg <= 1'b0;
                    b_isolate_o_reg <= 1'b0;
                    b_clear_ack_reg <= 1'b0;
                    b_isolate_ack_reg <= 1'b0;
                end
            endcase
        end
    end

    // Synchronize signals between a_clk_i and b_clk_i
    always @(posedge a_clk_i) begin
        a_clear_sync_reg <= a_clear_o_reg;
        a_isolate_sync_reg <= a_isolate_o_reg;
        a_clear_ack_sync_reg <= a_clear_ack_reg;
        a_isolate_ack_sync_reg <= a_isolate_ack_reg;
    end

    always @(posedge b_clk_i) begin
        b_clear_sync_reg <= b_clear_o_reg;
        b_isolate_sync_reg <= b_isolate_o_reg;
        b_clear_ack_sync_reg <= b_clear_ack_reg;
        b_isolate_ack_sync_reg <= b_isolate_ack_reg;
    end

    // Synchronize signals between b_clk_i and a_clk_i
    always @(posedge b_clk_i) begin
        b_clear_sync_reg2 <= b_clear_sync_reg;
        b_isolate_sync_reg2 <= b_isolate_sync_reg;
        b_clear_ack_sync_reg2 <= b_clear_ack_sync_reg;
        b_isolate_ack_sync_reg2 <= b_isolate_ack_sync_reg;
    end

    always @(posedge a_clk_i) begin
        a_clear_sync_reg2 <= a_clear_sync_reg;
        a_isolate_sync_reg2 <= a_isolate_sync_reg;
        a_clear_ack_sync_reg2 <= a_clear_ack_sync_reg;
        a_isolate_ack_sync_reg2 <= a_isolate_ack_sync_reg;
    end

    // Synchronize signals between a_clk_i and b_clk_i
    always @(posedge a_clk_i) begin
        a_clear_sync_reg3 <= a_clear_sync_reg2;
        a_isolate_sync_reg3 <= a_isolate_sync_reg2;
        a_clear_ack_sync_reg3 <= a_clear_ack_sync_reg2;
        a_isolate_ack_sync_reg3 <= a_isolate_ack_sync_reg2;
    end

    always @(posedge b_clk_i) begin
        b_clear_sync_reg3 <= b_clear_sync_reg2;
        b_isolate_sync_reg3 <= b_isolate_sync_reg2;
        b_clear_ack_sync_reg3 <= b_clear_ack_sync_reg2;
        b_isolate_ack_sync_reg3 <= b_isolate_ack_sync_reg2;
    end

    // Synchronize signals between b_clk_i and a_clk_i
    always @(posedge b_clk_i) begin
        b_clear_sync_reg4 <= b_clear_sync_reg3;
        b_isolate_sync_reg4 <= b_isolate_sync_reg3;
        b_clear_ack_sync_reg4 <= b_clear_ack_sync_reg3;
        b_isolate_ack_sync_reg4 <= b_isolate_ack_sync_reg3;
    end

    always @(posedge a_clk_i) begin
        a_clear_sync_reg4 <= a_clear_sync_reg3;
        a_isolate_sync_reg4 <= a_isolate_sync_reg3;
        a_clear_ack_sync_reg4 <= a_clear_ack_sync_reg3;
        a_isolate_ack_sync_reg4 <= a_isolate_ack_sync_reg3;
    end

    // Assign output signals
    assign a_clear_o = a_clear_sync_reg4;
    assign a_isolate_o = a_isolate_sync_reg4;
    assign b_clear_o = b_clear_sync_reg4;
    assign b_isolate_o = b_isolate_sync_reg4;
    assign a_clear_ack_i = a_clear_ack_sync_reg4;
    assign a_isolate_ack_i = a_isolate_ack_sync_reg4;
    assign b_clear_ack_i = b_clear_ack_sync_reg4;
    assign b_isolate_ack_i = b_isolate_ack_sync_reg4;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:1]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:2]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:4]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:5]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {shift_reg[7], shift_reg[6:0]};
                state <= 3'b000;
            end
        endcase
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:1]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:2]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:4]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:5]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {shift_reg[7], shift_reg[6:0]};
                state <= 3'b000;
            end
        endcase
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:1]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:2]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:4]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:5]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {shift_reg[7], shift_reg[6:0]};
                state <= 3'b000;
            end
        endcase
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:1]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:2]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:4]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:5]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {shift_reg[7], shift_reg[6:0]};
                state <= 3'b000;
            end
        endcase
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:1]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:2]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:4]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:5]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {shift_reg[7], shift_reg[6:0]};
                state <= 3'b000;
            end
        endcase
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:1]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:2]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:4]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:5]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {shift_reg[7], shift_reg[6:0]};
                state <= 3'b000;
            end
        endcase
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:1]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:2]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:4]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:5]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {shift_reg[7], shift_reg[6:0]};
                state <= 3'b000;
            end
        endcase
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:1]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:2]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:4]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:5]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {shift_reg[7], shift_reg[6:0]};
                state <= 3'b000;
            end
        endcase
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:1]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:2]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:4]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:5]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {shift_reg[7], shift_reg[6:0]};
                state <= 3'b000;
            end
        endcase
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:1]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:2]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:4]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:5]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {shift_reg[7], shift_reg[6:0]};
                state <= 3'b000;
            end
        endcase
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state