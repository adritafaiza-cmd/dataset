Sure, here is the complete Verilog code for the four-phase valid/ready channel:

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
  reg [WIDTH-1:0] src_data_r;
  reg src_valid_r;
  wire src_ready_w;
  reg [WIDTH-1:0] dst_data_r;
  reg dst_valid_r;
  wire dst_ready_w;
  reg [1:0] state_r;

  // State machine
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      state_r <= 2'b00;
      src_data_r <= RESET_MSG;
      src_valid_r <= 1'b0;
    end else begin
      case (state_r)
        2'b00: begin // Idle
          if (src_valid_i && src_ready_w) begin
            src_data_r <= src_data_i;
            src_valid_r <= 1'b1;
            state_r <= 2'b01;
          end
        end
        2'b01: begin // Transfer
          if (dst_ready_w) begin
            dst_data_r <= src_data_r;
            dst_valid_r <= 1'b1;
            src_valid_r <= 1'b0;
            state_r <= 2'b10;
          end
        end
        2'b10: begin // Wait for handshake
          if (dst_ready_w) begin
            dst_valid_r <= 1'b0;
            state_r <= 2'b00;
          end
        end
      endcase
    end
  end

  // Source ready
  assign src_ready_o = (state_r == 2'b00) ? src_ready_w : 1'b0;

  // Destination data
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o <= {WIDTH{1'b0}};
    end else begin
      dst_data_o <= dst_data_r;
    end
  end

  // Destination valid
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_o <= 1'b0;
    end else begin
      dst_valid_o <= dst_valid_r;
    end
  end

  // Destination ready
  assign dst_ready_w = (state_r == 2'b00) ? dst_ready_i : 1'b0;

  // Source ready
  assign src_ready_w = (state_r == 2'b00) ? 1'b1 : 1'b0;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [3:0] in,
    output reg [3:0] out
);

reg [3:0] reg_out;

always @(posedge clk) begin
    if (reset) begin
        reg_out <= 4'b0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [3:0] in,
    output reg [3:0] out
);

reg [3:0] reg_out;

always @(posedge clk) begin
    if (reset) begin
        reg_out <= 4'b0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [3:0] in,
    output reg [3:0] out
);

reg [3:0] reg_out;

always @(posedge clk) begin
    if (reset) begin
        reg_out <= 4'b0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [3:0] in,
    output reg [3:0] out
);

reg [3:0] reg_out;

always @(posedge clk) begin
    if (reset) begin
        reg_out <= 4'b0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    reset = 1;
    in = 4'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 4'b1010;
    #10 in = 4'b0101;
    #10 in = 4'b1100;
    #10 in = 4'b0011;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [3:0] in;
wire [3:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
);

initial begin
    clk