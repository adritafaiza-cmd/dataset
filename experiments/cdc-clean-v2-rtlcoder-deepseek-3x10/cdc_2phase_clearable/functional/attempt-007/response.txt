Sure, here is the complete Verilog code for the `cdc_2phase_clearable` module:

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
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  wire src_ready_wire;
  wire dst_valid_wire;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_ready_reg;
  reg dst_valid_reg;
  reg src_clear_pending_reg;
  reg dst_clear_pending_reg;
  reg [SYNC_STAGES-1:0] src_clear_sync_reg;
  reg [SYNC_STAGES-1:0] dst_clear_sync_reg;
  reg [SYNC_STAGES-1:0] src_valid_sync_reg;
  reg [SYNC_STAGES-1:0] dst_ready_sync_reg;
  reg [SYNC_STAGES-1:0] dst_valid_sync_reg;
  reg [SYNC_STAGES-1:0] src_ready_sync_reg;
  reg [SYNC_STAGES-1:0] dst_clear_pending_sync_reg;
  reg [SYNC_STAGES-1:0] src_clear_pending_sync_reg;

  // Synchronous clear signals
  always @(posedge src_clk_i) begin
    if (src_rst_ni == 1'b0) begin
      src_clear_sync_reg <= {SYNC_STAGES{1'b0}};
    end else begin
      src_clear_sync_reg <= {src_clear_sync_reg[SYNC_STAGES-2:0], src_clear_i};
    end
  end

  always @(posedge dst_clk_i) begin
    if (dst_rst_ni == 1'b0) begin
      dst_clear_sync_reg <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_clear_sync_reg <= {dst_clear_sync_reg[SYNC_STAGES-2:0], dst_clear_i};
    end
  end

  // Synchronous valid signals
  always @(posedge src_clk_i) begin
    if (src_rst_ni == 1'b0) begin
      src_valid_sync_reg <= {SYNC_STAGES{1'b0}};
    end else begin
      src_valid_sync_reg <= {src_valid_sync_reg[SYNC_STAGES-2:0], src_valid_i};
    end
  end

  always @(posedge dst_clk_i) begin
    if (dst_rst_ni == 1'b0) begin
      dst_ready_sync_reg <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_ready_sync_reg <= {dst_ready_sync_reg[SYNC_STAGES-2:0], dst_ready_i};
    end
  end

  always @(posedge dst_clk_i) begin
    if (dst_rst_ni == 1'b0) begin
      dst_valid_sync_reg <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_valid_sync_reg <= {dst_valid_sync_reg[SYNC_STAGES-2:0], dst_valid_wire};
    end
  end

  always @(posedge src_clk_i) begin
    if (src_rst_ni == 1'b0) begin
      src_ready_sync_reg <= {SYNC_STAGES{1'b0}};
    end else begin
      src_ready_sync_reg <= {src_ready_sync_reg[SYNC_STAGES-2:0], src_ready_wire};
    end
  end

  // Synchronous clear pending signals
  always @(posedge src_clk_i) begin
    if (src_rst_ni == 1'b0) begin
      src_clear_pending_sync_reg <= {SYNC_STAGES{1'b0}};
    end else begin
      src_clear_pending_sync_reg <= {src_clear_pending_sync_reg[SYNC_STAGES-2:0], src_clear_pending_reg};
    end
  end

  always @(posedge dst_clk_i) begin
    if (dst_rst_ni == 1'b0) begin
      dst_clear_pending_sync_reg <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_clear_pending_sync_reg <= {dst_clear_pending_sync_reg[SYNC_STAGES-2:0], dst_clear_pending_reg};
    end
  end

  // Source domain
  always @(posedge src_clk_i) begin
    if (src_rst_ni == 1'b0) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_clear_pending_reg <= 1'b0;
    end else begin
      if (src_clear_sync_reg[SYNC_STAGES-1] == 1'b1) begin
        src_data_reg <= {WIDTH{1'b0}};
        src_valid_reg <= 1'b0;
        src_clear_pending_reg <= 1'b1;
      end else if (src_valid_sync_reg[SYNC_STAGES-1] == 1'b1 && src_ready_sync_reg[SYNC_STAGES-1] == 1'b1) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1'b1;
        src_clear_pending_reg <= 1'b0;
      end else begin
        src_data_reg <= src_data_reg;
        src_valid_reg <= src_valid_reg;
        src_clear_pending_reg <= src_clear_pending_reg;
      end
    end
  end

  assign src_ready_wire = (src_valid_reg == 1'b0 || dst_ready_sync_reg[SYNC_STAGES-1] == 1'b1) && src_clear_sync_reg[SYNC_STAGES-1] == 1'b0;
  assign src_ready_o = src_ready_wire;
  assign src_clear_pending_o = src_clear_pending_sync_reg[SYNC_STAGES-1];

  // Destination domain
  always @(posedge dst_clk_i) begin
    if (dst_rst_ni == 1'b0) begin
      dst_data_reg <= {WIDTH{1'b0}};
      dst_ready_reg <= 1'b0;
      dst_valid_reg <= 1'b0;
      dst_clear_pending_reg <= 1'b0;
    end else begin
      if (dst_clear_sync_reg[SYNC_STAGES-1] == 1'b1) begin
        dst_data_reg <= {WIDTH{1'b0}};
        dst_ready_reg <= 1'b0;
        dst_valid_reg <= 1'b0;
        dst_clear_pending_reg <= 1'b1;
      end else if (src_valid_sync_reg[SYNC_STAGES-1] == 1'b1 && src_ready_sync_reg[SYNC_STAGES-1] == 1'b1) begin
        dst_data_reg <= src_data_i;
        dst_ready_reg <= 1'b1;
        dst_valid_reg <= 1'b1;
        dst_clear_pending_reg <= 1'b0;
      end else begin
        dst_data_reg <= dst_data_reg;
        dst_ready_reg <= dst_ready_reg;
        dst_valid_reg <= dst_valid_reg;
        dst_clear_pending_reg <= dst_clear_pending_reg;
      end
    end
  end

  assign dst_valid_wire = (dst_ready_reg == 1'b1 && src_valid_sync_reg[SYNC_STAGES-1] == 1'b1) && dst_clear_sync_reg[SYNC_STAGES-1] == 1'b0;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_wire;
  assign dst_clear_pending_o = dst_clear_pending_sync_reg[SYNC_STAGES-1];

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        out <= shift_reg[7];
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        out <= shift_reg[7];
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
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        out <= shift_reg[7];
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
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        out <= shift_reg[7];
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
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
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
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
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
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
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
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
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
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
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
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
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
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
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
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
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
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
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
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
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
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
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
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
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
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
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
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
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
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
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
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
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
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
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
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
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
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
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
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
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
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
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
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
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
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
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
    in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #20 in = 8'b01010101;
    #30 in = 8'b11001100;
    #40 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire