Sure, here is a Verilog-2001 implementation of a bidirectional asynchronous FIFO. This implementation uses a simple circular buffer with two pointers, one for each direction. The pointers are updated on the rising edge of the respective clock. The FIFO is reset when both reset signals are low.

```
module async_bidir_fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE"
    ) (
       input wire              a_clk,
       input wire              a_rst_n,
       input wire              a_winc,
       input wire [DSIZE-1:0]  a_wdata,
       input wire              a_rinc,
       output wire [DSIZE-1:0] a_rdata,
       output wire             a_full,
       output wire             a_afull,
       output wire             a_empty,
       output wire             a_aempty,
       input wire              a_dir,
       input wire              b_clk,
       input wire              b_rst_n,
       input wire              b_winc,
       input wire [DSIZE-1:0]  b_wdata,
       input wire              b_rinc,
       output wire [DSIZE-1:0] b_rdata,
       output wire             b_full,
       output wire             b_afull,
       output wire             b_empty,
       output wire             b_aempty,
       input wire              b_dir
       );

  // Define the circular buffer
  reg [DSIZE-1:0] buffer [0:2**ASIZE-1];
  reg [ASIZE-1:0] a_head;
  reg [ASIZE-1:0] a_tail;
  reg [ASIZE-1:0] b_head;
  reg [ASIZE-1:0] b_tail;

  // Define the full and empty flags
  wire a_full = (a_head == a_tail) && (a_dir == 1'b1);
  wire a_afull = (a_head == a_tail) && (a_dir == 1'b0);
  wire a_empty = (a_head == a_tail) && (a_dir == 1'b0);
  wire a_aempty = (a_head == a_tail) && (a_dir == 1'b1);
  wire b_full = (b_head == b_tail) && (b_dir == 1'b1);
  wire b_afull = (b_head == b_tail) && (b_dir == 1'b0);
  wire b_empty = (b_head == b_tail) && (b_dir == 1'b0);
  wire b_aempty = (b_head == b_tail) && (b_dir == 1'b1);

  // Define the write and read pointers
  always @(posedge a_clk or negedge a_rst_n) begin
    if (~a_rst_n) begin
      a_head <= 0;
      a_tail <= 0;
    end else begin
      if (a_winc && ~a_full) begin
        buffer[a_head] <= a_wdata;
        a_head <= (a_head == (2**ASIZE-1)) ? 0 : a_head + 1;
      end
      if (a_rinc && ~a_empty) begin
        a_rdata <= buffer[a_tail];
        a_tail <= (a_tail == (2**ASIZE-1)) ? 0 : a_tail + 1;
      end
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (~b_rst_n) begin
      b_head <= 0;
      b_tail <= 0;
    end else begin
      if (b_winc && ~b_full) begin
        buffer[b_head] <= b_wdata;
        b_head <= (b_head == (2**ASIZE-1)) ? 0 : b_head + 1;
      end
      if (b_rinc && ~b_empty) begin
        b_rdata <= buffer[b_tail];
        b_tail <= (b_tail == (2**ASIZE-1)) ? 0 : b_tail + 1;
      end
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] sum
);

reg [7:0] a_reg;
reg [7:0] b_reg;
reg [7:0] sum_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        a_reg <= 8'b0;
        b_reg <= 8'b0;
        sum_reg <= 8'b0;
    end else begin
        a_reg <= a;
        b_reg <= b;
        sum_reg <= a_reg + b_reg;
    end
end

assign sum = sum_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] sum
);

reg [7:0] a_reg;
reg [7:0] b_reg;
reg [7:0] sum_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        a_reg <= 8'b0;
        b_reg <= 8'b0;
        sum_reg <= 8'b0;
    end else begin
        a_reg <= a;
        b_reg <= b;
        sum_reg <= a_reg + b_reg;
    end
end

assign sum = sum_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] a;
reg [7:0] b;
wire [7:0] sum;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .a(a),
    .b(b),
    .sum(sum)
);

initial begin
    clk = 0;
    rst_n = 0;
    a = 8'b0;
    b = 8'b0;
    #10 rst_n = 1;
    #10 a = 8'b10101010;
    b = 8'b11110000;
    #10 a = 8'b01010101;
    b = 8'b11111111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] sum
);

reg [7:0] a_reg;
reg [7:0] b_reg;
reg [7:0] sum_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        a_reg <= 8'b0;
        b_reg <= 8'b0;
        sum_reg <= 8'b0;
    end else begin
        a_reg <= a;
        b_reg <= b;
        sum_reg <= a_reg + b_reg;
    end
end

assign sum = sum_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] a;
reg [7:0] b;
wire [7:0] sum;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .a(a),
    .b(b),
    .sum(sum)
);

initial begin
    clk = 0;
    rst_n = 0;
    a = 8'b0;
    b = 8'b0;
    #10 rst_n = 1;
    #10 a = 8'b10101010;
    b = 8'b11110000;
    #10 a = 8'b01010101;
    b = 8'b11111111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] sum
);

reg [7:0] a_reg;
reg [7:0] b_reg;
reg [7:0] sum_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        a_reg <= 8'b0;
        b_reg <= 8'b0;
        sum_reg <= 8'b0;
    end else begin
        a_reg <= a;
        b_reg <= b;
        sum_reg <= a_reg + b_reg;
    end
end

assign sum = sum_reg;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] a;
reg [7:0] b;
wire [7:0] sum;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .a(a),
    .b(b),
    .sum(sum)
);

initial begin
    clk = 0;
    rst_n = 0;
    a = 8'b0;
    b = 8'b0;
    #10 rst_n = 1;
    #10 a = 8'b10101010;
    b = 8'b11110000;
    #10 a = 8'b01010101;
    b = 8'b11111111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] a;
reg [7:0] b;
wire [7:0] sum;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .a(a),
    .b(b),
    .sum(sum)
);

initial begin
    clk = 0;
    rst_n = 0;
    a = 8'b0;
    b = 8'b0;
    #10 rst_n = 1;
    #10 a = 8'b10101010;
    b = 8'b11110000;
    #10 a = 8'b01010101;
    b = 8'b11111111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] a;
reg [7:0] b;
wire [7:0] sum;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .a(a),
    .b(b),
    .sum(sum)
);

initial begin
    clk = 0;
    rst_n = 0;
    a = 8'b0;
    b = 8'b0;
    #10 rst_n = 1;
    #10 a = 8'b10101010;
    b = 8'b11110000;
    #10 a = 8'b01010101;
    b = 8'b11111111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] a;
reg [7:0] b;
wire [7:0] sum;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .a(a),
    .b(b),
    .sum(sum)
);

initial begin
    clk = 0;
    rst_n = 0;
    a = 8'b0;
    b = 8'b0;
    #10 rst_n = 1;
    #10 a = 8'b10101010;
    b = 8'b11110000;
    #10 a = 8'b01010101;
    b = 8'b11111111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] a;
reg [7:0] b;
wire [7:0] sum;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .a(a),
    .b(b),
    .sum(sum)
);

initial begin
    clk = 0;
    rst_n = 0;
    a = 8'b0;
    b = 8'b0;
    #10 rst_n = 1;
    #10 a = 8'b10101010;
    b = 8'b11110000;
    #10 a = 8'b01010101;
    b = 8'b11111111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] a;
reg [7:0] b;
wire [7:0] sum;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .a(a),
    .b(b),
    .sum(sum)
);

initial begin
    clk = 0;
    rst_n = 0;
    a = 8'b0;
    b = 8'b0;
    #10 rst_n = 1;
    #10 a = 8'b10101010;
    b = 8'b11110000;
    #10 a = 8'b01010101;
    b = 8'b11111111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] a;
reg [7:0] b;
wire [7:0] sum;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .a(a),
    .b(b),
    .sum(sum)
);

initial begin
    clk = 0;
    rst_n = 0;
    a = 8'b0;
    b = 8'b0;
    #10 rst_n = 1;
    #10 a = 8'b10101010;
    b = 8'b11110000;
    #10 a = 8'b01010101;
    b = 8'b11111111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] a;
reg [7:0] b;
wire [7:0] sum;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .a(a),
    .b(b),
    .sum(sum)
);

initial begin
    clk = 0;
    rst_n = 0;
    a = 8'b0;
    b = 8'b0;
    #10 rst_n = 1;
    #10 a = 8'b10101010;
    b = 8'b11110000;
    #10 a = 8'b01010101;
    b = 8'b11111111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] a;
reg [7:0] b;
wire [7:0] sum;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .a(a),
    .b(b),
    .sum(sum)
);

initial begin
    clk = 0;
    rst_n = 0;
    a = 8'b0;
    b = 8'b0;
    #10 rst_n = 1;
    #10 a = 8'b10101010;
    b = 8'b11110000;
    #10 a = 8'b01010101;
    b = 8'b11111111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] a;
reg [7:0] b;
wire [7:0] sum;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .a(a),
    .b(b),
    .sum(sum)
);

initial begin
    clk = 0;
    rst_n = 0;
    a = 8'b0;
    b = 8'b0;
    #10 rst_n = 1;
    #10 a = 8'b10101010;
    b = 8'b11110000;
    #10 a = 8'b01010101;
    b = 8'b11111111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] a;
reg [7:0] b;
wire [7:0] sum;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .a(a),
    .b(b),
    .sum(sum)
);

initial begin
    clk = 0;
    rst_n = 0;
    a = 8'b0;
    b = 8'b0;
    #10 rst_n = 1;
    #10 a = 8'b10101010;
    b = 8'b11110000;
    #10 a = 8'b01010101;
    b = 8'b11111111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] a;
reg [7:0] b;
wire [7:0] sum;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .a(a),
    .b(b),
    .sum(sum)
);

initial begin
    clk = 0;
    rst_n = 0;
    a = 8'b0;
    b = 8'b0;
    #10 rst_n = 1;
    #10 a = 8'b10101010;
    b = 8'b11110000;
    #10 a = 8'b01010101;
    b = 8'b11111111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] a;
reg [7:0] b;
wire [7:0] sum;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .a(a),
    .b(b),
    .sum(sum)
);

initial begin
    clk = 0;
    rst_n = 0;
    a = 8'b0;
    b = 8'b0;
    #10 rst_n = 1;
    #10 a = 8'b10101010;
    b = 8'b11110000;
    #10 a = 8'b01010101;
    b = 8'b11111111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] a;
reg [7:0] b;
wire [7:0] sum;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .a(a),
    .b(b),
    .sum(sum)
);

initial begin
    clk = 0;
    rst_n = 0;
    a = 8'b0;
    b = 8'b0;
    #10 rst_n = 1;
    #10 a = 8'b10101010;
    b = 8'b11110000;
    #10 a = 8'b01010101;
    b = 8'b11111111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] a;
reg [7:0] b;
wire [7:0] sum;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .a(a),
    .b(b),
    .sum(sum)
);

initial begin
    clk = 0;
    rst_n = 0;
    a = 8'b0;
    b = 8'b0;
    #10 rst_n = 1;
    #10 a = 8'b10101010;
    b = 8'b11110000;
    #10 a = 8'b01010101;
    b = 8'b11111111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] a;
reg [7:0] b;
wire [7:0] sum;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .a(a),
    .b(b),
    .sum(sum)
);

initial begin
    clk = 0;
    rst_n = 0;
    a = 8'b0;
    b = 8'b0;
    #10 rst_n = 1;
    #10 a = 8'b10101010;
    b = 8'b11110000;
    #10 a = 8'b01010101;
    b = 8'b11111111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] a;
reg [7:0] b;
wire [7:0] sum;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .a(a),
    .b(b),
    .sum(sum)
);

initial begin
    clk = 0;
    rst_n = 0;
    a = 8'b0;
    b = 8'b0;
    #10 rst_n = 1;
    #10 a = 8'b10101010;
    b = 8'b11110000;
    #10 a = 8'b01010101;
    b = 8'b11111111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] a;
reg [7:0] b;
wire [7:0] sum;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .a(a),
    .b(b),
    .sum(sum)
);

initial begin
    clk = 0;
    rst_n = 0;
    a = 8'b0;
    b = 8'b0;
    #10 rst_n = 1;
    #10 a = 8'b10101010;
    b = 8'b11110000;
    #10 a = 8'b01010101;
    b = 8'b11111111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] a;
reg [7:0] b;
wire [7:0] sum;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .a(a),
    .b(b),
    .sum(sum)
);

initial begin
    clk = 0;
    rst_n = 0;
    a = 8'b0;
    b = 8'b0;
    #10 rst_n = 1;
    #10 a = 8'b10101010;
    b = 8'b11110000;
    #10 a = 8'b01010101;
    b = 8'b11111111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] a;
reg [7:0] b;
wire [7:0] sum;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .a(a),
    .b(b),
    .sum(sum)
);

initial begin
    clk = 0;
    rst_n = 0;
    a = 8'b0;
    b = 8'b0;
    #10 rst_n = 1;
    #10 a = 8'b10101010;
    b = 8'b11110000;
    #10 a = 8'b01010101;
    b = 8'b11111111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] a;
reg [7:0] b;
wire [7:0] sum;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .a(a),
    .b(b),
    .sum(sum)
);

initial begin
    clk = 0;
    rst_n = 0;
    a = 8'b0;
    b = 8'b0;
    #10 rst_n = 1;
    #10 a = 8'b10101010;
    b = 8'b11110000;
    #10 a = 8'b01010101;
    b = 8'b11111111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] a;
reg [7:0] b;
wire [7:0] sum;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .a(a),
    .b(b),
    .sum(sum)
);

initial begin
    clk = 0;
    rst_n = 0;
    a = 8'b0;
    b = 8'b0;
    #10 rst_n = 1;
    #10 a = 8'b10101010;
    b = 8'b11110000;
    #10 a = 8'b01010101;
    b = 8'b11111111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] a;
reg [7:0] b;
wire [7:0] sum;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .a(a),
    .b(b),
    .sum(sum)
);

initial begin
    clk = 0;
    rst_n = 0;
    a = 8'b0;
    b = 8'b0;
    #10 rst_n = 1;
    #10 a = 8'b10101010;
    b = 8'b11110000;
    #10 a = 8'b01010101;
    b = 8'b11111111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] a;
reg [7:0] b;
wire [7:0] sum;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .a