Sure, here is the complete code for the two-phase valid/ready channel in SystemVerilog:

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

  always @(posedge dst_clk_i) begin
    if (!dst_rst_ni) begin
      dst_valid_o <= 0;
    end else begin
      if (valid_reg && dst_ready_i) begin
        dst_data_o <= data_reg;
        dst_valid_o <= 1;
      end else begin
        dst_valid_o <= 0;
      end
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] shift_reg;
    reg [2:0] count;

    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 8'b0;
            count <= 3'b0;
        end else begin
            shift_reg <= {shift_reg[6:0], in};
            count <= count + 1;
        end
    end

    assign out = shift_reg[7];

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] shift_reg;
    reg [2:0] count;

    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 8'b0;
            count <= 3'b0;
        end else begin
            shift_reg <= {shift_reg[6:0], in};
            count <= count + 1;
        end
    end

    assign out = shift_reg[7];

endmodule

module top_module_tb();

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
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    initial begin
        $dumpfile("top_module_tb.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] shift_reg;
    reg [2:0] count;

    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 8'b0;
            count <= 3'b0;
        end else begin
            shift_reg <= {shift_reg[6:0], in};
            count <= count + 1;
        end
    end

    assign out = shift_reg[7];

endmodule

module top_module_tb();

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
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    initial begin
        $dumpfile("top_module_tb.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] shift_reg;
    reg [2:0] count;

    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 8'b0;
            count <= 3'b0;
        end else begin
            shift_reg <= {shift_reg[6:0], in};
            count <= count + 1;
        end
    end

    assign out = shift_reg[7];

endmodule

module top_module_tb();

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
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    initial begin
        $dumpfile("top_module_tb.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] shift_reg;
    reg [2:0] count;

    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 8'b0;
            count <= 3'b0;
        end else begin
            shift_reg <= {shift_reg[6:0], in};
            count <= count + 1;
        end
    end

    assign out = shift_reg[7];

endmodule

module top_module_tb();

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
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    initial begin
        $dumpfile("top_module_tb.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] shift_reg;
    reg [2:0] count;

    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 8'b0;
            count <= 3'b0;
        end else begin
            shift_reg <= {shift_reg[6:0], in};
            count <= count + 1;
        end
    end

    assign out = shift_reg[7];

endmodule

module top_module_tb();

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
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    initial begin
        $dumpfile("top_module_tb.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] shift_reg;
    reg [2:0] count;

    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 8'b0;
            count <= 3'b0;
        end else begin
            shift_reg <= {shift_reg[6:0], in};
            count <= count + 1;
        end
    end

    assign out = shift_reg[7];

endmodule

module top_module_tb();

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
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    initial begin
        $dumpfile("top_module_tb.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] shift_reg;
    reg [2:0] count;

    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 8'b0;
            count <= 3'b0;
        end else begin
            shift_reg <= {shift_reg[6:0], in};
            count <= count + 1;
        end
    end

    assign out = shift_reg[7];

endmodule

module top_module_tb();

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
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    initial begin
        $dumpfile("top_module_tb.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] shift_reg;
    reg [2:0] count;

    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 8'b0;
            count <= 3'b0;
        end else begin
            shift_reg <= {shift_reg[6:0], in};
            count <= count + 1;
        end
    end

    assign out = shift_reg[7];

endmodule

module top_module_tb();

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
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    initial begin
        $dumpfile("top_module_tb.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] shift_reg;
    reg [2:0] count;

    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 8'b0;
            count <= 3'b0;
        end else begin
            shift_reg <= {shift_reg[6:0], in};
            count <= count + 1;
        end
    end

    assign out = shift_reg[7];

endmodule

module top_module_tb();

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
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    initial begin
        $dumpfile("top_module_tb.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] shift_reg;
    reg [2:0] count;

    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 8'b0;
            count <= 3'b0;
        end else begin
            shift_reg <= {shift_reg[6:0], in};
            count <= count + 1;
        end
    end

    assign out = shift_reg[7];

endmodule

module top_module_tb();

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
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    initial begin
        $dumpfile("top_module_tb.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] shift_reg;
    reg [2:0] count;

    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 8'b0;
            count <= 3'b0;
        end else begin
            shift_reg <= {shift_reg[6:0], in};
            count <= count + 1;
        end
    end

    assign out = shift_reg[7];

endmodule

module top_module_tb();

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
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    initial begin
        $dumpfile("top_module_tb.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] shift_reg;
    reg [2:0] count;

    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 8'b0;
            count <= 3'b0;
        end else begin
            shift_reg <= {shift_reg[6:0], in};
            count <= count + 1;
        end
    end

    assign out = shift_reg[7];

endmodule

module top_module_tb();

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
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    initial begin
        $dumpfile("top_module_tb.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] shift_reg;
    reg [2:0] count;

    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 8'b0;
            count <= 3'b0;
        end else begin
            shift_reg <= {shift_reg[6:0], in};
            count <= count + 1;
        end
    end

    assign out = shift_reg[7];

endmodule

module top_module_tb();

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
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    initial begin
        $dumpfile("top_module_tb.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] shift_reg;
    reg [2:0] count;

    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 8'b0;
            count <= 3'b0;
        end else begin
            shift_reg <= {shift_reg[6:0], in};
            count <= count + 1;
        end
    end

    assign out = shift_reg[7];

endmodule

module top_module_tb();

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
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    initial begin
        $dumpfile("top_module_tb.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] shift_reg;
    reg [2:0] count;

    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 8'b0;
            count <= 3'b0;
        end else begin
            shift_reg <= {shift_reg[6:0], in};
            count <= count + 1;
        end
    end

    assign out = shift_reg[7];

endmodule

module top_module_tb();

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
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    initial begin
        $dumpfile("top_module_tb.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] shift_reg;
    reg [2:0] count;

    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 8'b0;
            count <= 3'b0;
        end else begin
            shift_reg <= {shift_reg[6:0], in};
            count <= count + 1;
        end
    end

    assign out = shift_reg[7];

endmodule

module top_module_tb();

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
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    initial begin
        $dumpfile("top_module_tb.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] shift_reg;
    reg [2:0] count;

    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 8'b0;
            count <= 3'b0;
        end else begin
            shift_reg <= {shift_reg[6:0], in};
            count <= count + 1;
        end
    end

    assign out = shift_reg[7];

endmodule

module top_module_tb();

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
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    initial begin
        $dumpfile("top_module_tb.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] shift_reg;
    reg [2:0] count;

    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 8'b0;
            count <= 3'b0;
        end else begin
            shift_reg <= {shift_reg[6:0], in};
            count <= count + 1;
        end
    end

    assign out = shift_reg[7];

endmodule

module top_module_tb();

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
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end
