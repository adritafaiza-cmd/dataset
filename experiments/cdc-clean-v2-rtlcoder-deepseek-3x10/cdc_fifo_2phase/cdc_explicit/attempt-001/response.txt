Here is the complete Verilog code for the cdc_fifo_2phase module:

```
module cdc_fifo_2phase #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    localparam DEPTH = 1 << LOG_DEPTH;

    reg [WIDTH-1:0] fifo [0:DEPTH-1];
    reg [LOG_DEPTH-1:0] head;
    reg [LOG_DEPTH-1:0] tail;
    reg [LOG_DEPTH-1:0] count;

    wire [LOG_DEPTH-1:0] next_head = head + 1;
    wire [LOG_DEPTH-1:0] next_tail = tail + 1;

    assign src_ready_o = (count < DEPTH);
    assign dst_valid_o = (count > 0);

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            head <= 0;
            tail <= 0;
            count <= 0;
        end else if (src_valid_i && src_ready_o) begin
            fifo[head] <= src_data_i;
            head <= next_head;
            count <= count + 1;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            head <= 0;
            tail <= 0;
            count <= 0;
        end else if (dst_valid_o && dst_ready_i) begin
            dst_data_o <= fifo[tail];
            tail <= next_tail;
            count <= count - 1;
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (rst) begin
        index <= 0;
        shift_reg <= '{8{8'h00}};
        out <= 8'h00;
    end else begin
        shift_reg[index] <= in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            out <= shift_reg[0];
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (rst) begin
        index <= 0;
        shift_reg <= '{8{8'h00}};
        out <= 8'h00;
    end else begin
        shift_reg[index] <= in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            out <= shift_reg[0];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (rst) begin
        index <= 0;
        shift_reg <= '{8{8'h00}};
        out <= 8'h00;
    end else begin
        shift_reg[index] <= in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            out <= shift_reg[0];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (rst) begin
        index <= 0;
        shift_reg <= '{8{8'h00}};
        out <= 8'h00;
    end else begin
        shift_reg[index] <= in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            out <= shift_reg[0];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10 rst = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst(rst),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 8'h00;
    #10