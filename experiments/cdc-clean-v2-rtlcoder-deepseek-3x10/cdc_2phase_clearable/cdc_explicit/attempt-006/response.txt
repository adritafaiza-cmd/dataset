Here is the complete Verilog code for the cdc_2phase_clearable module:

```
module cdc_2phase_clearable #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3,
  parameter CLEAR_ON_ASYNC_RESET = 1
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  src_clear_i,
  output src_clear_pending_o,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,
  input  dst_rst_ni,
  input  dst_clk_i,
  input  dst_clear_i,
  output dst_clear_pending_o,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);

  // Internal signals
  reg [WIDTH-1:0] data_reg;
  reg valid_reg;
  reg ready_reg;
  reg clear_pending_reg;
  reg [SYNC_STAGES-1:0] sync_reg;
  wire clear_pending_wire;
  wire ready_wire;
  wire valid_wire;

  // Clear logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      clear_pending_reg <= 1'b0;
    end else if (src_clear_i) begin
      clear_pending_reg <= 1'b1;
    end else if (ready_wire) begin
      clear_pending_reg <= 1'b0;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      clear_pending_reg <= 1'b0;
    end else if (dst_clear_i) begin
      clear_pending_reg <= 1'b1;
    end else if (valid_wire) begin
      clear_pending_reg <= 1'b0;
    end
  end

  // Ready logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      ready_reg <= 1'b0;
    end else if (src_valid_i && ready_wire) begin
      ready_reg <= 1'b1;
    end else if (valid_wire) begin
      ready_reg <= 1'b0;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      ready_reg <= 1'b0;
    end else if (dst_valid_o && dst_ready_i) begin
      ready_reg <= 1'b1;
    end else if (valid_wire) begin
      ready_reg <= 1'b0;
    end
  end

  // Valid logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      valid_reg <= 1'b0;
    end else if (src_valid_i && ready_wire) begin
      valid_reg <= 1'b1;
    end else if (valid_wire) begin
      valid_reg <= 1'b0;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      valid_reg <= 1'b0;
    end else if (dst_valid_o && dst_ready_i) begin
      valid_reg <= 1'b1;
    end else if (valid_wire) begin
      valid_reg <= 1'b0;
    end
  end

  // Data logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      data_reg <= {WIDTH{1'b0}};
    end else if (src_valid_i && ready_wire) begin
      data_reg <= src_data_i;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      data_reg <= {WIDTH{1'b0}};
    end else if (dst_valid_o && dst_ready_i) begin
      data_reg <= data_reg;
    end
  end

  // Synchronization logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      sync_reg <= {SYNC_STAGES{1'b0}};
    end else if (src_valid_i && ready_wire) begin
      sync_reg <= {sync_reg[SYNC_STAGES-2:0], 1'b1};
    end else if (valid_wire) begin
      sync_reg <= {sync_reg[SYNC_STAGES-2:0], 1'b0};
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      sync_reg <= {SYNC_STAGES{1'b0}};
    end else if (dst_valid_o && dst_ready_i) begin
      sync_reg <= {sync_reg[SYNC_STAGES-2:0], 1'b1};
    end else if (valid_wire) begin
      sync_reg <= {sync_reg[SYNC_STAGES-2:0], 1'b0};
    end
  end

  // Output assignments
  assign src_clear_pending_o = clear_pending_reg;
  assign src_ready_o = ready_reg;
  assign dst_clear_pending_o = clear_pending_reg;
  assign dst_data_o = data_reg;
  assign dst_valid_o = valid_reg;

  // Ready and valid wire assignments
  assign ready_wire = (sync_reg[SYNC_STAGES-1] == 1'b1) ? ready_reg : 1'b0;
  assign valid_wire = (sync_reg[SYNC_STAGES-1] == 1'b1) ? valid_reg : 1'b0;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

reg [7:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 8'b0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

reg [7:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 8'b0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

reg [7:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 8'b0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

reg [7:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 8'b0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_2();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

reg [7:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 8'b0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_2();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_3();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_4();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_5();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_6();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_7();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_8();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_9();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_10();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_11();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_12();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_13();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_14();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_15();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_16();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_17();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_18();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_19();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_20();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_21();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_22();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_23();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_24();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 8'b0;
    #10 rst_n = 1;
    #10 in = 8'b10101010;
    #10 in = 8'b01010