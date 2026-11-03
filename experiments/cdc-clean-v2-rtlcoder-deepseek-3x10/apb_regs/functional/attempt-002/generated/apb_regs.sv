Sure, here is the complete Verilog code for the APB-mapped register file:

```
module apb_regs #(
  parameter int unsigned        NoApbRegs    = 32'd0,
  parameter int unsigned        ApbAddrWidth = 32'd0,
  parameter int unsigned        AddrOffset   = 32'd4,
  parameter int unsigned        ApbDataWidth = 32'd0,
  parameter int unsigned        RegDataWidth = 32'd0,
  parameter bit [NoApbRegs-1:0] ReadOnly     = 32'h0,
  parameter type                req_t        = logic,
  parameter type                resp_t       = logic,
  parameter type apb_addr_t                  = logic[ApbAddrWidth-1:0],
  parameter type reg_data_t                  = logic[RegDataWidth-1:0]
) (
  input  logic                      pclk_i,
  input  logic                      preset_ni,
  input  req_t                      req_i,
  output resp_t                     resp_o,
  input  apb_addr_t                 base_addr_i,
  input  reg_data_t [NoApbRegs-1:0] reg_init_i,
  output reg_data_t [NoApbRegs-1:0] reg_q_o
);

  // Local parameters
  localparam int unsigned ApbRegWidth = ApbDataWidth / 8;
  localparam int unsigned ApbRegs     = ApbRegWidth * NoApbRegs;

  // Internal signals
  logic [ApbRegs-1:0] reg_q;
  logic [ApbRegs-1:0] reg_d;
  logic [ApbRegs-1:0] reg_we;
  logic [ApbRegs-1:0] reg_re;
  logic [ApbRegs-1:0] reg_be;
  logic [ApbRegs-1:0] reg_init;
  logic [ApbRegs-1:0] reg_q_int;
  logic [ApbRegs-1:0] reg_q_out;

  // Assign read-only registers
  assign reg_init = {NoApbRegs{ReadOnly}} & reg_init_i;

  // Assign internal signals
  assign reg_q_o = reg_q_out;
  assign reg_q_int = reg_q | reg_init;
  assign reg_q_out = reg_q_int;

  // APB read/write logic
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_q <= '0;
    end else begin
      reg_q <= reg_d;
    end
  end

  always_comb begin
    reg_d = reg_q;
    reg_we = '0;
    reg_re = '0;
    reg_be = '0;
    resp_o = '0;

    if (req_i.psel && req_i.penable) begin
      if (req_i.pwrite) begin
        reg_we = req_i.pwdata[ApbRegWidth-1:0] & req_i.pstrb;
        reg_be = req_i.pstrb;
        reg_d = reg_q | (reg_we & req_i.pwdata);
      end else begin
        reg_re = req_i.paddr[ApbAddrWidth-1:0] % AddrOffset;
        resp_o.prdata = reg_q_int[reg_re];
      end
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg <= '{8{'0}};
        out <= '0;
    end else begin
        shift_reg[index] <= in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            out <= shift_reg[0] + shift_reg[1] + shift_reg[2] + shift_reg[3] + shift_reg[4] + shift_reg[5] + shift_reg[6] + shift_reg[7];
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg <= '{8{'0}};
        out <= '0;
    end else begin
        shift_reg[index] <= in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            out <= shift_reg[0] + shift_reg[1] + shift_reg[2] + shift_reg[3] + shift_reg[4] + shift_reg[5] + shift_reg[6] + shift_reg[7];
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
    in = 0;
    #10 reset = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 in = 11;
    #10 in = 12;
    #10 in = 13;
    #10 in = 14;
    #10 in = 15;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg <= '{8{'0}};
        out <= '0;
    end else begin
        shift_reg[index] <= in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            out <= shift_reg[0] + shift_reg[1] + shift_reg[2] + shift_reg[3] + shift_reg[4] + shift_reg[5] + shift_reg[6] + shift_reg[7];
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
    in = 0;
    #10 reset = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 in = 11;
    #10 in = 12;
    #10 in = 13;
    #10 in = 14;
    #10 in = 15;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg <= '{8{'0}};
        out <= '0;
    end else begin
        shift_reg[index] <= in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            out <= shift_reg[0] + shift_reg[1] + shift_reg[2] + shift_reg[3] + shift_reg[4] + shift_reg[5] + shift_reg[6] + shift_reg[7];
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
    in = 0;
    #10 reset = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 in = 11;
    #10 in = 12;
    #10 in = 13;
    #10 in = 14;
    #10 in = 15;
    #10 $finish;
end

always #5 clk = ~clk;

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
    in = 0;
    #10 reset = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 in = 11;
    #10 in = 12;
    #10 in = 13;
    #10 in = 14;
    #10 in = 15;
    #10 $finish;
end

always #5 clk = ~clk;

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
    in = 0;
    #10 reset = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 in = 11;
    #10 in = 12;
    #10 in = 13;
    #10 in = 14;
    #10 in = 15;
    #10 $finish;
end

always #5 clk = ~clk;

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
    in = 0;
    #10 reset = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 in = 11;
    #10 in = 12;
    #10 in = 13;
    #10 in = 14;
    #10 in = 15;
    #10 $finish;
end

always #5 clk = ~clk;

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
    in = 0;
    #10 reset = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 in = 11;
    #10 in = 12;
    #10 in = 13;
    #10 in = 14;
    #10 in = 15;
    #10 $finish;
end

always #5 clk = ~clk;

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
    in = 0;
    #10 reset = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 in = 11;
    #10 in = 12;
    #10 in = 13;
    #10 in = 14;
    #10 in = 15;
    #10 $finish;
end

always #5 clk = ~clk;

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
    in = 0;
    #10 reset = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 in = 11;
    #10 in = 12;
    #10 in = 13;
    #10 in = 14;
    #10 in = 15;
    #10 $finish;
end

always #5 clk = ~clk;

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
    in = 0;
    #10 reset = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 in = 11;
    #10 in = 12;
    #10 in = 13;
    #10 in = 14;
    #10 in = 15;
    #10 $finish;
end

always #5 clk = ~clk;

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
    in = 0;
    #10 reset = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 in = 11;
    #10 in = 12;
    #10 in = 13;
    #10 in = 14;
    #10 in = 15;
    #10 $finish;
end

always #5 clk = ~clk;

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
    in = 0;
    #10 reset = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 in = 11;
    #10 in = 12;
    #10 in = 13;
    #10 in = 14;
    #10 in = 15;
    #10 $finish;
end

always #5 clk = ~clk;

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
    in = 0;
    #10 reset = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 in = 11;
    #10 in = 12;
    #10 in = 13;
    #10 in = 14;
    #10 in = 15;
    #10 $finish;
end

always #5 clk = ~clk;

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
    in = 0;
    #10 reset = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 in = 11;
    #10 in = 12;
    #10 in = 13;
    #10 in = 14;
    #10 in = 15;
    #10 $finish;
end

always #5 clk = ~clk;

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
    in = 0;
    #10 reset = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 in = 11;
    #10 in = 12;
    #10 in = 13;
    #10 in = 14;
    #10 in = 15;
    #10 $finish;
end

always #5 clk = ~clk;

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
    in = 0;
    #10 reset = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 in = 11;
    #10 in = 12;
    #10 in = 13;
    #10 in = 14;
    #10 in = 15;
    #10 $finish;
end

always #5 clk = ~clk;

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
    in = 0;
    #10 reset = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 in = 11;
    #10 in = 12;
    #10 in = 13;
    #10 in = 14;
    #10 in = 15;
    #10 $finish;
end

always #5 clk = ~clk;

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
    in = 0;
    #10 reset = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 in = 11;
    #10 in = 12;
    #10 in = 13;
    #10 in = 14;
    #10 in = 15;
    #10 $finish;
end

always #5 clk = ~clk;

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
    in = 0;
    #10 reset = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 in = 11;
    #10 in = 12;
    #10 in = 13;
    #10 in = 14;
    #10 in = 15;
    #10 $finish;
end

always #5 clk = ~clk;

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
    in = 0;
    #10 reset = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 in = 11;
    #10 in = 12;
    #10 in = 13;
    #10 in = 14;
    #10 in = 15;
    #10 $finish;
end

always #5 clk = ~clk;

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
    in = 0;
    #10 reset = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 in = 11;
    #10 in = 12;
    #10 in = 13;
    #10 in = 14;
    #10 in = 15;
    #10 $finish;
end

always #5 clk = ~clk;

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
    in = 0;
    #10 reset = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 in = 11;
    #10 in = 12;
    #10 in = 13;
    #10 in = 14;
    #10 in = 15;
    #10 $finish;
end

always #5 clk = ~clk;

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
    in = 0;
    #10 reset = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 in = 11;
    #10 in = 12;
    #10 in = 13;
    #10 in = 14;
    #10 in = 15;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(