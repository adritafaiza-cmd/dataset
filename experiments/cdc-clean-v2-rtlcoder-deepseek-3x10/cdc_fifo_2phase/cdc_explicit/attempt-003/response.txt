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

    reg [WIDTH-1:0] fifo [DEPTH-1:0];
    reg [LOG_DEPTH-1:0] head;
    reg [LOG_DEPTH-1:0] tail;
    reg [LOG_DEPTH-1:0] count;

    wire empty = (count == 0);
    wire full = (count == DEPTH);

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            head <= 0;
            tail <= 0;
            count <= 0;
        end else if (src_valid_i && !full) begin
            fifo[head] <= src_data_i;
            head <= head + 1;
            count <= count + 1;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            head <= 0;
            tail <= 0;
            count <= 0;
        end else if (dst_ready_i && !empty) begin
            dst_data_o <= fifo[tail];
            tail <= tail + 1;
            count <= count - 1;
        end
    end

    assign src_ready_o = !full;
    assign dst_valid_o = !empty;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk) begin
    if (rst) begin
        shift_reg <= 8'b0;
        count <= 3'b0;
        data_out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
        count <= count + 1;
        if (count == 3'b111) begin
            data_out <= shift_reg;
            count <= 3'b0;
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk) begin
    if (rst) begin
        shift_reg <= 8'b0;
        count <= 3'b0;
        data_out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
        count <= count + 1;
        if (count == 3'b111) begin
            data_out <= shift_reg;
            count <= 3'b0;
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst = 1;
    data_in = 8'b0;
    #10 rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk) begin
    if (rst) begin
        shift_reg <= 8'b0;
        count <= 3'b0;
        data_out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
        count <= count + 1;
        if (count == 3'b111) begin
            data_out <= shift_reg;
            count <= 3'b0;
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst = 1;
    data_in = 8'b0;
    #10 rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk) begin
    if (rst) begin
        shift_reg <= 8'b0;
        count <= 3'b0;
        data_out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
        count <= count + 1;
        if (count == 3'b111) begin
            data_out <= shift_reg;
            count <= 3'b0;
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst = 1;
    data_in = 8'b0;
    #10 rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst = 1;
    data_in = 8'b0;
    #10 rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst = 1;
    data_in = 8'b0;
    #10 rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst = 1;
    data_in = 8'b0;
    #10 rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst = 1;
    data_in = 8'b0;
    #10 rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst = 1;
    data_in = 8'b0;
    #10 rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst = 1;
    data_in = 8'b0;
    #10 rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst = 1;
    data_in = 8'b0;
    #10 rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst = 1;
    data_in = 8'b0;
    #10 rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst = 1;
    data_in = 8'b0;
    #10 rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst = 1;
    data_in = 8'b0;
    #10 rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst = 1;
    data_in = 8'b0;
    #10 rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst = 1;
    data_in = 8'b0;
    #10 rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst = 1;
    data_in = 8'b0;
    #10 rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst = 1;
    data_in = 8'b0;
    #10 rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst = 1;
    data_in = 8'b0;
    #10 rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst = 1;
    data_in = 8'b0;
    #10 rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst = 1;
    data_in = 8'b0;
    #10 rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst = 1;
    data_in = 8'b0;
    #10 rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst = 1;
    data_in = 8'b0;
    #10 rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst = 1;
    data_in = 8'b0;
    #10 rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst = 1;
    data_in = 8'b0;
    #10 rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst = 1;
    data_in = 8'b0;
    #10 rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst = 1;
    data_in = 8'b0;
    #10 rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst = 1;
    data_in = 8'b0;
    #10 rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst = 1;
    data_in = 8'b0;
    #10 rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst = 1;
    data_in = 8'b0;
    #10 rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst = 1;
    data_in = 8'b0;
    #10 rst = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg rst;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
   