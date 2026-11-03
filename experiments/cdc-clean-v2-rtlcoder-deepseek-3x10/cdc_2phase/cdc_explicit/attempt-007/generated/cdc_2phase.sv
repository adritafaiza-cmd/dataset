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

  reg [WIDTH-1:0] src_data_r;
  reg src_valid_r;
  wire src_ready_w;
  reg dst_valid_r;
  wire dst_ready_w;
  reg [WIDTH-1:0] dst_data_r;

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_r <= {WIDTH{1'b0}};
      src_valid_r <= 1'b0;
    end else begin
      src_data_r <= src_data_i;
      src_valid_r <= src_valid_i;
    end
  end

  assign src_ready_o = src_ready_w;

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_r <= 1'b0;
      dst_data_r <= {WIDTH{1'b0}};
    end else begin
      dst_valid_r <= dst_valid_o;
      dst_data_r <= dst_data_o;
    end
  end

  assign dst_ready_w = dst_ready_i;

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_w <= 1'b0;
    end else begin
      src_ready_w <= dst_ready_i;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_o <= 1'b0;
      dst_data_o <= {WIDTH{1'b0}};
    end else begin
      dst_valid_o <= src_valid_r;
      dst_data_o <= src_data_r;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        data_out <= 8'b0;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            data_out <= shift_reg[7];
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        data_out <= 8'b0;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            data_out <= shift_reg[7];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 data_in = 8'b11110000;
    #10 data_in = 8'b00001111;
    #10 data_in = 8'b10001000;
    #10 data_in = 8'b01110111;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        data_out <= 8'b0;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            data_out <= shift_reg[7];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 data_in = 8'b11110000;
    #10 data_in = 8'b00001111;
    #10 data_in = 8'b10001000;
    #10 data_in = 8'b01110111;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        data_out <= 8'b0;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            data_out <= shift_reg[7];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 data_in = 8'b11110000;
    #10 data_in = 8'b00001111;
    #10 data_in = 8'b10001000;
    #10 data_in = 8'b01110111;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        data_out <= 8'b0;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            data_out <= shift_reg[7];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 data_in = 8'b11110000;
    #10 data_in = 8'b00001111;
    #10 data_in = 8'b10001000;
    #10 data_in = 8'b01110111;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        data_out <= 8'b0;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            data_out <= shift_reg[7];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 data_in = 8'b11110000;
    #10 data_in = 8'b00001111;
    #10 data_in = 8'b10001000;
    #10 data_in = 8'b01110111;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        data_out <= 8'b0;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            data_out <= shift_reg[7];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 data_in = 8'b11110000;
    #10 data_in = 8'b00001111;
    #10 data_in = 8'b10001000;
    #10 data_in = 8'b01110111;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        data_out <= 8'b0;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            data_out <= shift_reg[7];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 data_in = 8'b11110000;
    #10 data_in = 8'b00001111;
    #10 data_in = 8'b10001000;
    #10 data_in = 8'b01110111;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        data_out <= 8'b0;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            data_out <= shift_reg[7];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 data_in = 8'b11110000;
    #10 data_in = 8'b00001111;
    #10 data_in = 8'b10001000;
    #10 data_in = 8'b01110111;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        data_out <= 8'b0;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            data_out <= shift_reg[7];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 data_in = 8'b11110000;
    #10 data_in = 8'b00001111;
    #10 data_in = 8'b10001000;
    #10 data_in = 8'b01110111;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        data_out <= 8'b0;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            data_out <= shift_reg[7];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 data_in = 8'b11110000;
    #10 data_in = 8'b00001111;
    #10 data_in = 8'b10001000;
    #10 data_in = 8'b01110111;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        data_out <= 8'b0;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            data_out <= shift_reg[7];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 data_in = 8'b11110000;
    #10 data_in = 8'b00001111;
    #10 data_in = 8'b10001000;
    #10 data_in = 8'b01110111;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        data_out <= 8'b0;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            data_out <= shift_reg[7];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 data_in = 8'b11110000;
    #10 data_in = 8'b00001111;
    #10 data_in = 8'b10001000;
    #10 data_in = 8'b01110111;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        data_out <= 8'b0;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            data_out <= shift_reg[7];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 data_in = 8'b11110000;
    #10 data_in = 8'b00001111;
    #10 data_in = 8'b10001000;
    #10 data_in = 8'b01110111;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        data_out <= 8'b0;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            data_out <= shift_reg[7];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 data_in = 8'b11110000;
    #10 data_in = 8'b00001111;
    #10 data_in = 8'b10001000;
    #10 data_in = 8'b01110111;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        data_out <= 8'b0;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            data_out <= shift_reg[7];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 data_in = 