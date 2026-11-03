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

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      valid_reg <= 1'b0;
      ready_reg <= 1'b0;
    end else begin
      if (src_valid_i && src_ready_o) begin
        data_reg <= src_data_i;
        valid_reg <= 1'b1;
        ready_reg <= 1'b0;
      end else if (valid_reg && dst_ready_i) begin
        valid_reg <= 1'b0;
        ready_reg <= 1'b1;
      end
    end
  end

  assign src_ready_o = ready_reg;
  assign dst_data_o = data_reg;
  assign dst_valid_o = valid_reg;

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      valid_reg <= 1'b0;
      ready_reg <= 1'b1;
    end else begin
      if (dst_valid_o && dst_ready_i) begin
        valid_reg <= 1'b0;
        ready_reg <= 1'b1;
      end else if (!valid_reg && src_ready_o) begin
        valid_reg <= 1'b1;
        ready_reg <= 1'b0;
      end
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [31:0] in,
    output [31:0] out
);

reg [31:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [31:0] in,
    output [31:0] out
);

reg [31:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [31:0] in,
    output [31:0] out
);

reg [31:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [31:0] in,
    output [31:0] out
);

reg [31:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;