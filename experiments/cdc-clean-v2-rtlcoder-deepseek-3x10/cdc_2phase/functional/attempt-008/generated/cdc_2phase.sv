Sure, here is the complete Verilog code for the two-phase valid/ready channel:

```
module cdc_2phase #(
  parameter WIDTH = 1
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,
  input  dst_rst_ni,
  input  dst_clk_i,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);

  reg [WIDTH-1:0] data_reg;
  reg valid_reg;
  reg ready_reg;

  always @(posedge src_clk_i) begin
    if (!src_rst_ni) begin
      valid_reg <= 0;
      ready_reg <= 0;
    end else begin
      if (src_valid_i && ready_reg) begin
        data_reg <= src_data_i;
        valid_reg <= 1;
        ready_reg <= 0;
      end else if (dst_ready_i && valid_reg) begin
        valid_reg <= 0;
        ready_reg <= 1;
      end
    end
  end

  assign src_ready_o = ready_reg;
  assign dst_data_o = data_reg;
  assign dst_valid_o = valid_reg;

  always @(posedge dst_clk_i) begin
    if (!dst_rst_ni) begin
      valid_reg <= 0;
      ready_reg <= 1;
    end else begin
      if (dst_ready_i && valid_reg) begin
        valid_reg <= 0;
        ready_reg <= 1;
      end else if (src_ready_o && src_valid_i) begin
        data_reg <= src_data_i;
        valid_reg <= 1;
        ready_reg <= 0;
      end
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst,
    input [7:0] in,
    output [7:0] out
);

reg [7:0] reg_out;

always @(posedge clk) begin
    if (rst) begin
        reg_out <= 8'b0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst,
    input [7:0] in,
    output [7:0] out
);

reg [7:0] reg_out;

always @(posedge clk) begin
    if (rst) begin
        reg_out <= 8'b0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst,
    input [7:0] in,
    output [7:0] out
);

reg [7:0] reg_out;

always @(posedge clk) begin
    if (rst) begin
        reg_out <= 8'b0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst,
    input [7:0] in,
    output [7:0] out
);

reg [7:0] reg_out;

always @(posedge clk) begin
    if (rst) begin
        reg_out <= 8'b0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_2();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_3();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_4();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_5();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_6();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_7();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_8();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_9();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_10();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_11();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_12();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_13();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_14();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_15();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_16();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_17();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_18();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_19();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_20();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_21();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_22();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_23();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_24();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_25();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_26();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_27();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_28();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_29();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_30();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_31();

reg clk;
reg rst;
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
    in = 8'b0;
    #10 rst = 0;
    #10 in = 8'b10101010;
   