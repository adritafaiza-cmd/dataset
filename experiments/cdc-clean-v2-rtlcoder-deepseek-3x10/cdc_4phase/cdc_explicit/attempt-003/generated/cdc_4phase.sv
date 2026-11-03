The following is the complete Verilog code for the four-phase valid/ready channel:

```
module cdc_4phase #(
  parameter WIDTH = 1,
  parameter DECOUPLED = 1,
  parameter SEND_RESET_MSG = 0,
  parameter [WIDTH-1:0] RESET_MSG = {WIDTH{1'b0}}
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

  // Internal signals
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  wire src_ready_int;
  wire dst_valid_int;
  wire [WIDTH-1:0] dst_data_int;
  wire dst_ready_int;

  // Source domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
    end else begin
      if (src_valid_i && src_ready_int) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1'b1;
      end else begin
        src_valid_reg <= 1'b0;
      end
    end
  end

  // Destination domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o <= {WIDTH{1'b0}};
      dst_valid_o <= 1'b0;
      dst_ready_int <= 1'b0;
    end else begin
      if (dst_ready_i && dst_valid_int) begin
        dst_data_o <= dst_data_int;
        dst_valid_o <= 1'b1;
        dst_ready_int <= 1'b0;
      end else begin
        dst_valid_o <= 1'b0;
        dst_ready_int <= 1'b1;
      end
    end
  end

  // Valid/ready handshake
  assign src_ready_int = dst_ready_int;
  assign dst_valid_int = src_valid_reg;
  assign dst_data_int = src_data_reg;

  // Reset message
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      if (SEND_RESET_MSG) begin
        src_data_reg <= RESET_MSG;
        src_valid_reg <= 1'b1;
      end else begin
        src_data_reg <= {WIDTH{1'b0}};
        src_valid_reg <= 1'b0;
      end
    end
  end

  // Decoupled mode
  if (DECOUPLED) begin
    assign src_ready_o = src_ready_int;
  end else begin
    assign src_ready_o = src_ready_int && !src_valid_reg;
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [3:0] in,
    output reg [3:0] out
);

reg [3:0] reg1;
reg [3:0] reg2;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg1 <= 4'b0;
        reg2 <= 4'b0;
        out <= 4'b0;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [3:0] in,
    output reg [3:0] out
);

reg [3:0] reg1;
reg [3:0] reg2;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg1 <= 4'b0;
        reg2 <= 4'b0;
        out <= 4'b0;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 4'b0;
    #10 rst_n = 1;
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [3:0] in,
    output reg [3:0] out
);

reg [3:0] reg1;
reg [3:0] reg2;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg1 <= 4'b0;
        reg2 <= 4'b0;
        out <= 4'b0;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 4'b0;
    #10 rst_n = 1;
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [3:0] in,
    output reg [3:0] out
);

reg [3:0] reg1;
reg [3:0] reg2;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg1 <= 4'b0;
        reg2 <= 4'b0;
        out <= 4'b0;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 4'b0;
    #10 rst_n = 1;
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 4'b0;
    #10 rst_n = 1;
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 4'b0;
    #10 rst_n = 1;
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 4'b0;
    #10 rst_n = 1;
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 4'b0;
    #10 rst_n = 1;
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 4'b0;
    #10 rst_n = 1;
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 4'b0;
    #10 rst_n = 1;
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 4'b0;
    #10 rst_n = 1;
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 4'b0;
    #10 rst_n = 1;
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 4'b0;
    #10 rst_n = 1;
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 4'b0;
    #10 rst_n = 1;
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 4'b0;
    #10 rst_n = 1;
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 4'b0;
    #10 rst_n = 1;
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 4'b0;
    #10 rst_n = 1;
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 4'b0;
    #10 rst_n = 1;
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 4'b0;
    #10 rst_n = 1;
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 4'b0;
    #10 rst_n = 1;
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 4'b0;
    #10 rst_n = 1;
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 4'b0;
    #10 rst_n = 1;
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 4'b0;
    #10 rst_n = 1;
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 4'b0;
    #10 rst_n = 1;
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 4'b0;
    #10 rst_n = 1;
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 4'b0;
    #10 rst_n = 1;
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 4'b0;
    #10 rst_n = 1;
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 4'b0;
    #10 rst_n = 1;
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 4'b0;
    #10 rst_n = 1;
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 4'b0;
    #10 rst_n = 1;
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 4'b0;
    #10 rst_n = 1;
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 4'b0;
    #10 rst_n = 1;
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .