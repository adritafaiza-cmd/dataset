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
      ready_reg <= 0;
    end else begin
      if (dst_ready_i && valid_reg) begin
        valid_reg <= 0;
        ready_reg <= 1;
      end else if (src_valid_i && ready_reg) begin
        data_reg <= src_data_i;
        valid_reg <= 1;
        ready_reg <= 0;
      end
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>//
// Copyright 2018 Ettus Research, a National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//

`timescale 1ns/1ps

module axi_stream_monitor #(
    parameter DATA_WIDTH = 32,
    parameter TUSER_WIDTH = 1
) (
    input wire clk,
    input wire rst,
    input wire s_axis_tvalid,
    input wire [DATA_WIDTH-1:0] s_axis_tdata,
    input wire [TUSER_WIDTH-1:0] s_axis_tuser,
    input wire s_axis_tlast,
    output reg s_axis_tready
);

reg [DATA_WIDTH-1:0] data_reg;
reg [TUSER_WIDTH-1:0] user_reg;
reg last_reg;

always @(posedge clk) begin
    if (rst) begin
        s_axis_tready <= 1'b0;
        data_reg <= {DATA_WIDTH{1'b0}};
        user_reg <= {TUSER_WIDTH{1'b0}};
        last_reg <= 1'b0;
    end else begin
        if (s_axis_tvalid && s_axis_tready) begin
            data_reg <= s_axis_tdata;
            user_reg <= s_axis_tuser;
            last_reg <= s_axis_tlast;
        end
        s_axis_tready <= 1'b1;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>//
// Copyright 2018 Ettus Research, a National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//

`timescale 1ns/1ps

module axi_stream_monitor_tb;

parameter DATA_WIDTH = 32;
parameter TUSER_WIDTH = 1;

reg clk;
reg rst;
reg s_axis_tvalid;
reg [DATA_WIDTH-1:0] s_axis_tdata;
reg [TUSER_WIDTH-1:0] s_axis_tuser;
reg s_axis_tlast;
wire s_axis_tready;

axi_stream_monitor #(
    .DATA_WIDTH(DATA_WIDTH),
    .TUSER_WIDTH(TUSER_WIDTH)
) dut (
    .clk(clk),
    .rst(rst),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tuser(s_axis_tuser),
    .s_axis_tlast(s_axis_tlast),
    .s_axis_tready(s_axis_tready)
);

initial begin
    clk = 0;
    rst = 1;
    s_axis_tvalid = 0;
    s_axis_tdata = 0;
    s_axis_tuser = 0;
    s_axis_tlast = 0;
    #10 rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10 s_axis_tvalid = 1;
    s_axis_tdata = 32'hdeadbeef;
    s_axis_tuser = 1'b1;
    s_axis_tlast = 1'b1;
    #10 s_axis_tvalid = 0;
    #100 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        count <= 3'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        count <= count + 1;
        if (count == 3'b111) begin
            out <= shift_reg[7:0];
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        count <= 3'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        count <= count + 1;
        if (count == 3'b111) begin
            out <= shift_reg[7:0];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        count <= 3'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        count <= count + 1;
        if (count == 3'b111) begin
            out <= shift_reg[7:0];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 8'b0;
