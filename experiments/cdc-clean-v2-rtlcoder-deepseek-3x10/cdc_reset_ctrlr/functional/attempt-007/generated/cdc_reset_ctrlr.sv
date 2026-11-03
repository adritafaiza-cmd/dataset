Sure, here is the complete Verilog code for the two-domain isolate-then-clear reset controller:

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
    reg [SYNC_STAGES-1:0] a_isolate_sync;
    reg [SYNC_STAGES-1:0] a_clear_sync;
    reg [SYNC_STAGES-1:0] b_isolate_sync;
    reg [SYNC_STAGES-1:0] b_clear_sync;

    // Synchronize signals
    always @(posedge a_clk_i) begin
        a_isolate_sync <= {a_isolate_sync[SYNC_STAGES-2:0], a_isolate_i};
        a_clear_sync <= {a_clear_sync[SYNC_STAGES-2:0], a_clear_i};
    end

    always @(posedge b_clk_i) begin
        b_isolate_sync <= {b_isolate_sync[SYNC_STAGES-2:0], b_isolate_i};
        b_clear_sync <= {b_clear_sync[SYNC_STAGES-2:0], b_clear_i};
    end

    // State machine
    reg [2:0] a_state;
    reg [2:0] b_state;

    always @(posedge a_clk_i) begin
        if (!a_rst_ni) begin
            a_state <= 3'b000;
            a_isolate_o <= 1'b0;
            a_clear_o <= 1'b0;
        end else begin
            case (a_state)
                3'b000: begin // Idle
                    if (a_clear_sync[SYNC_STAGES-1] && !a_clear_sync[SYNC_STAGES-2]) begin
                        a_state <= 3'b001; // Active
                        a_isolate_o <= 1'b1;
                    end
                end
                3'b001: begin // Active
                    if (a_isolate_ack_i && a_clear_sync[SYNC_STAGES-1] && !a_clear_sync[SYNC_STAGES-2]) begin
                        a_state <= 3'b010; // Done
                        a_isolate_o <= 1'b0;
                    end
                end
                3'b010: begin // Done
                    if (a_clear_ack_i && a_clear_sync[SYNC_STAGES-1] && !a_clear_sync[SYNC_STAGES-2]) begin
                        a_state <= 3'b011; // Released
                        a_clear_o <= 1'b1;
                    end
                end
                3'b011: begin // Released
                    if (a_clear_ack_i && !a_clear_sync[SYNC_STAGES-1] && !a_clear_sync[SYNC_STAGES-2]) begin
                        a_state <= 3'b000; // Idle
                        a_clear_o <= 1'b0;
                    end
                end
            endcase
        end
    end

    always @(posedge b_clk_i) begin
        if (!b_rst_ni) begin
            b_state <= 3'b000;
            b_isolate_o <= 1'b0;
            b_clear_o <= 1'b0;
        end else begin
            case (b_state)
                3'b000: begin // Idle
                    if (b_clear_sync[SYNC_STAGES-1] && !b_clear_sync[SYNC_STAGES-2]) begin
                        b_state <= 3'b001; // Active
                        b_isolate_o <= 1'b1;
                    end
                end
                3'b001: begin // Active
                    if (b_isolate_ack_i && b_clear_sync[SYNC_STAGES-1] && !b_clear_sync[SYNC_STAGES-2]) begin
                        b_state <= 3'b010; // Done
                        b_isolate_o <= 1'b0;
                    end
                end
                3'b010: begin // Done
                    if (b_clear_ack_i && b_clear_sync[SYNC_STAGES-1] && !b_clear_sync[SYNC_STAGES-2]) begin
                        b_state <= 3'b011; // Released
                        b_clear_o <= 1'b1;
                    end
                end
                3'b011: begin // Released
                    if (b_clear_ack_i && !b_clear_sync[SYNC_STAGES-1] && !b_clear_sync[SYNC_STAGES-2]) begin
                        b_state <= 3'b000; // Idle
                        b_clear_o <= 1'b0;
                    end
                end
            endcase
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1, reg2;

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
    input clk,
    input rst,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1, reg2;

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

endmodule

module top_module_tb();

reg clk, rst;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 in = 8'h0a;
    #10 in = 8'h0b;
    #10 in = 8'h0c;
    #10 in = 8'h0d;
    #10 in = 8'h0e;
    #10 in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1, reg2;

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

endmodule

module top_module_tb();

reg clk, rst;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 in = 8'h0a;
    #10 in = 8'h0b;
    #10 in = 8'h0c;
    #10 in = 8'h0d;
    #10 in = 8'h0e;
    #10 in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1, reg2;

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

endmodule

module top_module_tb();

reg clk, rst;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 in = 8'h0a;
    #10 in = 8'h0b;
    #10 in = 8'h0c;
    #10 in = 8'h0d;
    #10 in = 8'h0e;
    #10 in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_2();

reg clk, rst;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 in = 8'h0a;
    #10 in = 8'h0b;
    #10 in = 8'h0c;
    #10 in = 8'h0d;
    #10 in = 8'h0e;
    #10 in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_3();

reg clk, rst;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 in = 8'h0a;
    #10 in = 8'h0b;
    #10 in = 8'h0c;
    #10 in = 8'h0d;
    #10 in = 8'h0e;
    #10 in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_4();

reg clk, rst;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 in = 8'h0a;
    #10 in = 8'h0b;
    #10 in = 8'h0c;
    #10 in = 8'h0d;
    #10 in = 8'h0e;
    #10 in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_5();

reg clk, rst;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 in = 8'h0a;
    #10 in = 8'h0b;
    #10 in = 8'h0c;
    #10 in = 8'h0d;
    #10 in = 8'h0e;
    #10 in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_6();

reg clk, rst;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 in = 8'h0a;
    #10 in = 8'h0b;
    #10 in = 8'h0c;
    #10 in = 8'h0d;
    #10 in = 8'h0e;
    #10 in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_7();

reg clk, rst;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 in = 8'h0a;
    #10 in = 8'h0b;
    #10 in = 8'h0c;
    #10 in = 8'h0d;
    #10 in = 8'h0e;
    #10 in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_8();

reg clk, rst;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 in = 8'h0a;
    #10 in = 8'h0b;
    #10 in = 8'h0c;
    #10 in = 8'h0d;
    #10 in = 8'h0e;
    #10 in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_9();

reg clk, rst;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 in = 8'h0a;
    #10 in = 8'h0b;
    #10 in = 8'h0c;
    #10 in = 8'h0d;
    #10 in = 8'h0e;
    #10 in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_10();

reg clk, rst;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 in = 8'h0a;
    #10 in = 8'h0b;
    #10 in = 8'h0c;
    #10 in = 8'h0d;
    #10 in = 8'h0e;
    #10 in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_11();

reg clk, rst;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 in = 8'h0a;
    #10 in = 8'h0b;
    #10 in = 8'h0c;
    #10 in = 8'h0d;
    #10 in = 8'h0e;
    #10 in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_12();

reg clk, rst;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 in = 8'h0a;
    #10 in = 8'h0b;
    #10 in = 8'h0c;
    #10 in = 8'h0d;
    #10 in = 8'h0e;
    #10 in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_13();

reg clk, rst;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 in = 8'h0a;
    #10 in = 8'h0b;
    #10 in = 8'h0c;
    #10 in = 8'h0d;
    #10 in = 8'h0e;
    #10 in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_14();

reg clk, rst;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 in = 8'h0a;
    #10 in = 8'h0b;
    #10 in = 8'h0c;
    #10 in = 8'h0d;
    #10 in = 8'h0e;
    #10 in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_15();

reg clk, rst;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 in = 8'h0a;
    #10 in = 8'h0b;
    #10 in = 8'h0c;
    #10 in = 8'h0d;
    #10 in = 8'h0e;
    #10 in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_16();

reg clk, rst;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 in = 8'h0a;
    #10 in = 8'h0b;
    #10 in = 8'h0c;
    #10 in = 8'h0d;
    #10 in = 8'h0e;
    #10 in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_17();

reg clk, rst;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;