Sure, here is the complete SystemVerilog code for the two-phase valid/ready channel that transfers WIDTH-bit data between asynchronous clocks.

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

  reg [WIDTH-1:0] src_data_r;
  reg src_valid_r;
  wire src_ready_w;
  reg dst_valid_r;
  wire dst_ready_w;
  reg [WIDTH-1:0] dst_data_r;

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_r <= 0;
      src_valid_r <= 0;
    end else if (src_ready_w && src_valid_i) begin
      src_data_r <= src_data_i;
      src_valid_r <= 1;
    end else if (dst_ready_w && dst_valid_r) begin
      src_valid_r <= 0;
    end
  end

  assign src_ready_o = src_ready_w;
  assign src_ready_w = dst_ready_i;

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_r <= 0;
      dst_data_r <= 0;
    end else if (src_valid_r && src_ready_w) begin
      dst_valid_r <= 1;
      dst_data_r <= src_data_r;
    end else if (dst_ready_i && dst_valid_r) begin
      dst_valid_r <= 0;
    end
  end

  assign dst_data_o = dst_data_r;
  assign dst_valid_o = dst_valid_r;
  assign dst_ready_w = src_ready_o;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 0;
        shift_reg[1] <= 0;
        shift_reg[2] <= 0;
        shift_reg[3] <= 0;
        shift_reg[4] <= 0;
        shift_reg[5] <= 0;
        shift_reg[6] <= 0;
        shift_reg[7] <= 0;
        out <= 0;
    end else begin
        shift_reg[0] <= in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        out <= shift_reg[7];
        shift_count <= shift_count + 1;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 0;
        shift_reg[1] <= 0;
        shift_reg[2] <= 0;
        shift_reg[3] <= 0;
        shift_reg[4] <= 0;
        shift_reg[5] <= 0;
        shift_reg[6] <= 0;
        shift_reg[7] <= 0;
        out <= 0;
    end else begin
        shift_reg[0] <= in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        out <= shift_reg[7];
        shift_count <= shift_count + 1;
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 0;
        shift_reg[1] <= 0;
        shift_reg[2] <= 0;
        shift_reg[3] <= 0;
        shift_reg[4] <= 0;
        shift_reg[5] <= 0;
        shift_reg[6] <= 0;
        shift_reg[7] <= 0;
        out <= 0;
    end else begin
        shift_reg[0] <= in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        out <= shift_reg[7];
        shift_count <= shift_count + 1;
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 0;
        shift_reg[1] <= 0;
        shift_reg[2] <= 0;
        shift_reg[3] <= 0;
        shift_reg[4] <= 0;
        shift_reg[5] <= 0;
        shift_reg[6] <= 0;
        shift_reg[7] <= 0;
        out <= 0;
    end else begin
        shift_reg[0] <= in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        out <= shift_reg[7];
        shift_count <= shift_count + 1;
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

always @(posedge clk) begin
    in <= in + 1;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0]