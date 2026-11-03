The following Verilog-2001 code implements a two-domain isolate-then-clear reset controller. The controller is designed to handle clock domain crossings between `a_clk_i` and `b_clk_i`. The resets are active-low.

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

    // Synchronize the reset signals
    reg [SYNC_STAGES-1:0] a_rst_sync;
    reg [SYNC_STAGES-1:0] b_rst_sync;
    always @(posedge a_clk_i) begin
        a_rst_sync <= {a_rst_sync[SYNC_STAGES-2:0], a_rst_ni};
    end
    always @(posedge b_clk_i) begin
        b_rst_sync <= {b_rst_sync[SYNC_STAGES-2:0], b_rst_ni};
    end

    // Define the states
    localparam IDLE = 2'b00;
    localparam CLEAR = 2'b01;
    localparam ISOLATE = 2'b10;
    reg [1:0] state_a;
    reg [1:0] state_b;

    // Define the signals
    reg a_clear_o_reg;
    reg a_isolate_o_reg;
    reg b_clear_o_reg;
    reg b_isolate_o_reg;

    // Define the logic
    always @(posedge a_clk_i) begin
        if (a_rst_sync[SYNC_STAGES-1] == 1'b0) begin
            state_a <= IDLE;
            a_clear_o_reg <= 1'b0;
            a_isolate_o_reg <= 1'b0;
        end else begin
            case (state_a)
                IDLE: begin
                    if (a_clear_i == 1'b1) begin
                        state_a <= CLEAR;
                        a_clear_o_reg <= 1'b1;
                    end else if (a_isolate_i == 1'b1) begin
                        state_a <= ISOLATE;
                        a_isolate_o_reg <= 1'b1;
                    end
                end
                CLEAR: begin
                    if (a_clear_ack_i == 1'b1) begin
                        state_a <= IDLE;
                        a_clear_o_reg <= 1'b0;
                    end
                end
                ISOLATE: begin
                    if (a_isolate_ack_i == 1'b1) begin
                        state_a <= IDLE;
                        a_isolate_o_reg <= 1'b0;
                    end
                end
            endcase
        end
    end

    always @(posedge b_clk_i) begin
        if (b_rst_sync[SYNC_STAGES-1] == 1'b0) begin
            state_b <= IDLE;
            b_clear_o_reg <= 1'b0;
            b_isolate_o_reg <= 1'b0;
        end else begin
            case (state_b)
                IDLE: begin
                    if (b_clear_i == 1'b1) begin
                        state_b <= CLEAR;
                        b_clear_o_reg <= 1'b1;
                    end else if (b_isolate_i == 1'b1) begin
                        state_b <= ISOLATE;
                        b_isolate_o_reg <= 1'b1;
                    end
                end
                CLEAR: begin
                    if (b_clear_ack_i == 1'b1) begin
                        state_b <= IDLE;
                        b_clear_o_reg <= 1'b0;
                    end
                end
                ISOLATE: begin
                    if (b_isolate_ack_i == 1'b1) begin
                        state_b <= IDLE;
                        b_isolate_o_reg <= 1'b0;
                    end
                end
            endcase
        end
    end

    // Assign the outputs
    assign a_clear_o = a_clear_o_reg;
    assign a_isolate_o = a_isolate_o_reg;
    assign b_clear_o = b_clear_o_reg;
    assign b_isolate_o = b_isolate_o_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

reg [7:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 8'b0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

reg [7:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 8'b0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

reg [7:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 8'b0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

reg [7:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 8'b0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
