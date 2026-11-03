Here is the complete Verilog-2001 code for the two-domain isolate-then-clear reset controller:

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

    // Local signals
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
    reg a_clear_i_sync;
    reg b_clear_i_sync;
    reg a_isolate_i_sync;
    reg b_isolate_i_sync;
    reg a_clear_ack_sync;
    reg b_clear_ack_sync;
    reg a_isolate_ack_sync;
    reg b_isolate_ack_sync;
    reg a_clear_o_sync;
    reg b_clear_o_sync;
    reg a_isolate_o_sync;
    reg b_isolate_o_sync;
    reg a_clear_i_sync_d1;
    reg b_clear_i_sync_d1;
    reg a_isolate_i_sync_d1;
    reg b_isolate_i_sync_d1;
    reg a_clear_ack_sync_d1;
    reg b_clear_ack_sync_d1;
    reg a_isolate_ack_sync_d1;
    reg b_isolate_ack_sync_d1;
    reg a_clear_o_sync_d1;
    reg b_clear_o_sync_d1;
    reg a_isolate_o_sync_d1;
    reg b_isolate_o_sync_d1;
    reg a_clear_i_sync_d2;
    reg b_clear_i_sync_d2;
    reg a_isolate_i_sync_d2;
    reg b_isolate_i_sync_d2;
    reg a_clear_ack_sync_d2;
    reg b_clear_ack_sync_d2;
    reg a_isolate_ack_sync_d2;
    reg b_isolate_ack_sync_d2;
    reg a_clear_o_sync_d2;
    reg b_clear_o_sync_d2;
    reg a_isolate_o_sync_d2;
    reg b_isolate_o_sync_d2;

    // Synchronize signals across clock domains
    always @(posedge a_clk_i) begin
        a_clear_i_sync <= a_clear_i;
        a_isolate_i_sync <= a_isolate_i;
        a_clear_ack_sync <= a_clear_ack_i;
        a_isolate_ack_sync <= a_isolate_ack_i;
        a_clear_o_sync <= a_clear_o_reg;
        a_isolate_o_sync <= a_isolate_o_reg;
    end

    always @(posedge b_clk_i) begin
        b_clear_i_sync <= b_clear_i;
        b_isolate_i_sync <= b_isolate_i;
        b_clear_ack_sync <= b_clear_ack_i;
        b_isolate_ack_sync <= b_isolate_ack_i;
        b_clear_o_sync <= b_clear_o_reg;
        b_isolate_o_sync <= b_isolate_o_reg;
    end

    // Synchronize signals across clock domains (delayed by 1 clock cycle)
    always @(posedge a_clk_i) begin
        a_clear_i_sync_d1 <= a_clear_i_sync;
        a_isolate_i_sync_d1 <= a_isolate_i_sync;
        a_clear_ack_sync_d1 <= a_clear_ack_sync;
        a_isolate_ack_sync_d1 <= a_isolate_ack_sync;
        a_clear_o_sync_d1 <= a_clear_o_sync;
        a_isolate_o_sync_d1 <= a_isolate_o_sync;
    end

    always @(posedge b_clk_i) begin
        b_clear_i_sync_d1 <= b_clear_i_sync;
        b_isolate_i_sync_d1 <= b_isolate_i_sync;
        b_clear_ack_sync_d1 <= b_clear_ack_sync;
        b_isolate_ack_sync_d1 <= b_isolate_ack_sync;
        b_clear_o_sync_d1 <= b_clear_o_sync;
        b_isolate_o_sync_d1 <= b_isolate_o_sync;
    end

    // Synchronize signals across clock domains (delayed by 2 clock cycles)
    always @(posedge a_clk_i) begin
        a_clear_i_sync_d2 <= a_clear_i_sync_d1;
        a_isolate_i_sync_d2 <= a_isolate_i_sync_d1;
        a_clear_ack_sync_d2 <= a_clear_ack_sync_d1;
        a_isolate_ack_sync_d2 <= a_isolate_ack_sync_d1;
        a_clear_o_sync_d2 <= a_clear_o_sync_d1;
        a_isolate_o_sync_d2 <= a_isolate_o_sync_d1;
    end

    always @(posedge b_clk_i) begin
        b_clear_i_sync_d2 <= b_clear_i_sync_d1;
        b_isolate_i_sync_d2 <= b_isolate_i_sync_d1;
        b_clear_ack_sync_d2 <= b_clear_ack_sync_d1;
        b_isolate_ack_sync_d2 <= b_isolate_ack_sync_d1;
        b_clear_o_sync_d2 <= b_clear_o_sync_d1;
        b_isolate_o_sync_d2 <= b_isolate_o_sync_d1;
    end

    // State machine for a_clk_i
    always @(posedge a_clk_i) begin
        if (!a_rst_ni) begin
            a_state <= 2'b00;
            a_clear_o_reg <= 1'b0;
            a_isolate_o_reg <= 1'b0;
        end else begin
            case (a_state)
                2'b00: begin // Idle
                    if (a_clear_i_sync_d2) begin
                        a_state <= 2'b01;
                        a_clear_o_reg <= 1'b1;
                        a_isolate_o_reg <= 1'b1;
                    end else if (a_isolate_i_sync_d2) begin
                        a_state <= 2'b10;
                        a_isolate_o_reg <= 1'b1;
                    end
                end
                2'b01: begin // Clear
                    if (a_clear_ack_sync_d2) begin
                        a_state <= 2'b11;
                        a_clear_o_reg <= 1'b0;
                    end
                end
                2'b10: begin // Isolate
                    if (a_isolate_ack_sync_d2) begin
                        a_state <= 2'b11;
                        a_isolate_o_reg <= 1'b0;
                    end
                end
                2'b11: begin // Released
                    if (a_clear_i_sync_d2) begin
                        a_state <= 2'b01;
                        a_clear_o_reg <= 1'b1;
                    end else if (a_isolate_i_sync_d2) begin
                        a_state <= 2'b10;
                        a_isolate_o_reg <= 1'b1;
                    end else begin
                        a_state <= 2'b00;
                    end
                end
            endcase
        end
    end

    // State machine for b_clk_i
    always @(posedge b_clk_i) begin
        if (!b_rst_ni) begin
            b_state <= 2'b00;
            b_clear_o_reg <= 1'b0;
            b_isolate_o_reg <= 1'b0;
        end else begin
            case (b_state)
                2'b00: begin // Idle
                    if (b_clear_i_sync_d2) begin
                        b_state <= 2'b01;
                        b_clear_o_reg <= 1'b1;
                        b_isolate_o_reg <= 1'b1;
                    end else if (b_isolate_i_sync_d2) begin
                        b_state <= 2'b10;
                        b_isolate_o_reg <= 1'b1;
                    end
                end
                2'b01: begin // Clear
                    if (b_clear_ack_sync_d2) begin
                        b_state <= 2'b11;
                        b_clear_o_reg <= 1'b0;
                    end
                end
                2'b10: begin // Isolate
                    if (b_isolate_ack_sync_d2) begin
                        b_state <= 2'b11;
                        b_isolate_o_reg <= 1'b0;
                    end
                end
                2'b11: begin // Released
                    if (b_clear_i_sync_d2) begin
                        b_state <= 2'b01;
                        b_clear_o_reg <= 1'b1;
                    end else if (b_isolate_i_sync_d2) begin
                        b_state <= 2'b10;
                        b_isolate_o_reg <= 1'b1;
                    end else begin
                        b_state <= 2'b00;
                    end
                end
            endcase
        end
    end

    // Output assignments
    assign a_clear_o = a_clear_o_sync_d2;
    assign a_isolate_o = a_isolate_o_sync_d2;
    assign b_clear_o = b_clear_o_sync_d2;
    assign b_isolate_o = b_isolate_o_sync_d2;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk) begin
    if (rst) begin
        reg1 <= 8'h00;
        reg2 <= 8'h00;
        out <= 8'h00;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst,
    input wire [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7