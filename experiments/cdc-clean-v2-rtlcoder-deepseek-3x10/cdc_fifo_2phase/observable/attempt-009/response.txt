The following Verilog code implements a valid/ready asynchronous FIFO with 2**LOG_DEPTH entries of WIDTH bits. It uses a simple ring buffer to store the data and two counters to keep track of the head and tail of the buffer. The counters are incremented and decremented asynchronously on the source and destination clocks, respectively. The ready and valid signals are generated based on the difference between the head and tail counters.

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

    reg [WIDTH-1:0] buffer [DEPTH-1:0];
    reg [LOG_DEPTH-1:0] head;
    reg [LOG_DEPTH-1:0] tail;

    wire [LOG_DEPTH-1:0] next_head = head + 1;
    wire [LOG_DEPTH-1:0] next_tail = tail + 1;

    wire [LOG_DEPTH-1:0] head_diff = next_head - tail;
    wire [LOG_DEPTH-1:0] tail_diff = head - next_tail;

    wire [LOG_DEPTH-1:0] head_diff_minus_one = head_diff - 1;
    wire [LOG_DEPTH-1:0] tail_diff_minus_one = tail_diff - 1;

    wire [LOG_DEPTH-1:0] head_diff_minus_two = head_diff - 2;
    wire [LOG_DEPTH-1:0] tail_diff_minus_two = tail_diff - 2;

    wire [LOG_DEPTH-1:0] head_diff_plus_one = head_diff + 1;
    wire [LOG_DEPTH-1:0] tail_diff_plus_one = tail_diff + 1;

    wire [LOG_DEPTH-1:0] head_diff_plus_two = head_diff + 2;
    wire [LOG_DEPTH-1:0] tail_diff_plus_two = tail_diff + 2;

    wire head_ready = (head_diff_minus_one >= 0) && (head_diff_minus_one < DEPTH);
    wire tail_ready = (tail_diff_minus_one >= 0) && (tail_diff_minus_one < DEPTH);

    wire head_valid = (head_diff_minus_two >= 0) && (head_diff_minus_two < DEPTH);
    wire tail_valid = (tail_diff_minus_two >= 0) && (tail_diff_minus_two < DEPTH);

    always @(posedge src_clk_i) begin
        if (!src_rst_ni) begin
            head <= 0;
        end else if (src_valid_i && head_ready) begin
            buffer[head] <= src_data_i;
            head <= next_head;
        end
    end

    always @(posedge dst_clk_i) begin
        if (!dst_rst_ni) begin
            tail <= 0;
        end else if (dst_ready_i && tail_valid) begin
            dst_data_o <= buffer[tail];
            tail <= next_tail;
        end
    end

    assign src_ready_o = head_ready;
    assign dst_valid_o = tail_valid;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output [7:0] out
);

reg [7:0] reg_out;

always @(posedge clk) begin
    if (reset) begin
        reg_out <= 8'b0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output [7:0] out
);

reg [7:0] reg_out;

always @(posedge clk) begin
    if (reset) begin
        reg_out <= 8'b0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module testbench;

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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output [7:0] out
);

reg [7:0] reg_out;

always @(posedge clk) begin
    if (reset) begin
        reg_out <= 8'b0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module testbench;

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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output [7:0] out
);

reg [7:0] reg_out;

always @(posedge clk) begin
    if (reset) begin
        reg_out <= 8'b0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module testbench;

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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

endmodule

module another_module;

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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output [7:0] out
);

reg [7:0] reg_out;

always @(posedge clk) begin
    if (reset) begin
        reg_out <= 8'b0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module testbench;

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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

endmodule

module another_module;

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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

endmodule

module yet_another_module;

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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output [7:0] out
);

reg [7:0] reg_out;

always @(posedge clk) begin
    if (reset) begin
        reg_out <= 8'b0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module testbench;

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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

endmodule

module another_module;

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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

endmodule

module yet_another_module;

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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

endmodule

module yet_another_module;

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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

endmodule

module yet_another_module;

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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

endmodule

module yet_another_module;

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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

endmodule

module yet_another_module;

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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

endmodule

module yet_another_module;

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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

endmodule

module yet_another_module;

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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

endmodule

module yet_another_module;

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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

endmodule

module yet_another_module;

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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

endmodule

module yet_another_module;

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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

endmodule

module yet_another_module;

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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

endmodule

module yet_another_module;

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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

endmodule

module yet_another_module;

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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

endmodule

module yet_another_module;

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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

endmodule

module yet_another_module;

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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

endmodule

module yet_another_module;

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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

endmodule

module yet_another_module;

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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

endmodule

module yet_another_module;

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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

endmodule

module yet_another_module;

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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

endmodule

module yet_another_module;

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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

endmodule

module yet_another_module;

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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

endmodule

module yet_another_module;

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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

endmodule

module yet_another_module;

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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 $finish;
end

endmodule

module yet_another_module;

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
    #10 in = 8