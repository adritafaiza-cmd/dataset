Sure, here is the complete Verilog code for the cdc_fifo_2phase module:

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

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [LOG_DEPTH-1:0] head;
    reg [LOG_DEPTH-1:0] tail;
    reg [LOG_DEPTH-1:0] count;
    reg [LOG_DEPTH-1:0] next_head;
    reg [LOG_DEPTH-1:0] next_tail;
    reg [LOG_DEPTH-1:0] next_count;
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;

    assign src_ready_o = (count < DEPTH);
    assign dst_data_o = dst_data_reg;
    assign dst_valid_o = dst_valid_reg;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            head <= 0;
            tail <= 0;
            count <= 0;
        end else begin
            if (src_valid_i && src_ready_o) begin
                mem[head] <= src_data_i;
                next_head <= head + 1;
                next_count <= count + 1;
            end else begin
                next_head <= head;
                next_count <= count;
            end
            head <= next_head;
            count <= next_count;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            tail <= 0;
            dst_data_reg <= 0;
            dst_valid_reg <= 0;
        end else begin
            if (dst_ready_i && dst_valid_reg) begin
                next_tail <= tail + 1;
            end else begin
                next_tail <= tail;
            end
            tail <= next_tail;
            dst_data_reg <= mem[tail];
            dst_valid_reg <= (count > 0);
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (rst) begin
        shift_reg <= 8'b0;
        data_out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
        data_out <= shift_reg[7];
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (rst) begin
        shift_reg <= 8'b0;
        data_out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
        data_out <= shift_reg[7];
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

always @(posedge clk) begin
    if (rst) begin
        shift_reg <= 8'b0;
        data_out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
        data_out <= shift_reg[7];
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

always @(posedge clk) begin
    if (rst) begin
        shift_reg <= 8'b0;
        data_out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
        data_out <= shift_reg[7];
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
    clk = 0;
    rst = 1;
    data_in = 8