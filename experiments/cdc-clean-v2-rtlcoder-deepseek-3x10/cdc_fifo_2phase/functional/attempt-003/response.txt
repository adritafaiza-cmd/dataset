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

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [LOG_DEPTH-1:0] head;
    reg [LOG_DEPTH-1:0] tail;
    reg [LOG_DEPTH-1:0] count;

    wire [LOG_DEPTH-1:0] next_head = head + 1;
    wire [LOG_DEPTH-1:0] next_tail = tail + 1;

    assign src_ready_o = (count < DEPTH);
    assign dst_valid_o = (count > 0);
    assign dst_data_o = mem[tail];

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            head <= 0;
            count <= 0;
        end else if (src_valid_i && src_ready_o) begin
            mem[head] <= src_data_i;
            head <= next_head;
            count <= count + 1;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            tail <= 0;
            count <= 0;
        end else if (dst_valid_o && dst_ready_i) begin
            tail <= next_tail;
            count <= count - 1;
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] data_in,
    input valid_in,
    output reg [7:0] data_out,
    output reg valid_out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        shift_reg <= 8'b0;
        count <= 3'b0;
        data_out <= 8'b0;
        valid_out <= 1'b0;
    end else begin
        if (valid_in) begin
            shift_reg <= {shift_reg[6:0], data_in};
            count <= count + 1;
        end
        if (count == 3'b111) begin
            data_out <= shift_reg;
            valid_out <= 1'b1;
            count <= 3'b0;
        end else begin
            valid_out <= 1'b0;
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] data_in,
    input valid_in,
    output reg [7:0] data_out,
    output reg valid_out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        shift_reg <= 8'b0;
        count <= 3'b0;
        data_out <= 8'b0;
        valid_out <= 1'b0;
    end else begin
        if (valid_in) begin
            shift_reg <= {shift_reg[6:0], data_in};
            count <= count + 1;
        end
        if (count == 3'b111) begin
            data_out <= shift_reg;
            valid_out <= 1'b1;
            count <= 3'b0;
        end else begin
            valid_out <= 1'b0;
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
reg valid_in;
wire [7:0] data_out;
wire valid_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .valid_in(valid_in),
    .data_out(data_out),
    .valid_out(valid_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    valid_in = 0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    valid_in = 1;
    #10 valid_in = 0;
    #10 data_in = 8'b01010101;
    valid_in = 1;
    #10 valid_in = 0;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] data_in,
    input valid_in,
    output reg [7:0] data_out,
    output reg valid_out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        shift_reg <= 8'b0;
        count <= 3'b0;
        data_out <= 8'b0;
        valid_out <= 1'b0;
    end else begin
        if (valid_in) begin
            shift_reg <= {shift_reg[6:0], data_in};
            count <= count + 1;
        end
        if (count == 3'b111) begin
            data_out <= shift_reg;
            valid_out <= 1'b1;
            count <= 3'b0;
        end else begin
            valid_out <= 1'b0;
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
reg valid_in;
wire [7:0] data_out;
wire valid_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .valid_in(valid_in),
    .data_out(data_out),
    .valid_out(valid_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    valid_in = 0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    valid_in = 1;
    #10 valid_in = 0;
    #10 data_in = 8'b01010101;
    valid_in = 1;
    #10 valid_in = 0;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] data_in,
    input valid_in,
    output reg [7:0] data_out,
    output reg valid_out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        shift_reg <= 8'b0;
        count <= 3'b0;
        data_out <= 8'b0;
        valid_out <= 1'b0;
    end else begin
        if (valid_in) begin
            shift_reg <= {shift_reg[6:0], data_in};
            count <= count + 1;
        end
        if (count == 3'b111) begin
            data_out <= shift_reg;
            valid_out <= 1'b1;
            count <= 3'b0;
        end else begin
            valid_out <= 1'b0;
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
reg valid_in;
wire [7:0] data_out;
wire valid_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .valid_in(valid_in),
    .data_out(data_out),
    .valid_out(valid_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    valid_in = 0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    valid_in = 1;
    #10 valid_in = 0;
    #10 data_in = 8'b01010101;
    valid_in = 1;
    #10 valid_in = 0;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
reg valid_in;
wire [7:0] data_out;
wire valid_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .valid_in(valid_in),
    .data_out(data_out),
    .valid_out(valid_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    valid_in = 0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    valid_in = 1;
    #10 valid_in = 0;
    #10 data_in = 8'b01010101;
    valid_in = 1;
    #10 valid_in = 0;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
reg valid_in;
wire [7:0] data_out;
wire valid_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .valid_in(valid_in),
    .data_out(data_out),
    .valid_out(valid_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    valid_in = 0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    valid_in = 1;
    #10 valid_in = 0;
    #10 data_in = 8'b01010101;
    valid_in = 1;
    #10 valid_in = 0;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
reg valid_in;
wire [7:0] data_out;
wire valid_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .valid_in(valid_in),
    .data_out(data_out),
    .valid_out(valid_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    valid_in = 0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    valid_in = 1;
    #10 valid_in = 0;
    #10 data_in = 8'b01010101;
    valid_in = 1;
    #10 valid_in = 0;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
reg valid_in;
wire [7:0] data_out;
wire valid_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .valid_in(valid_in),
    .data_out(data_out),
    .valid_out(valid_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    valid_in = 0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    valid_in = 1;
    #10 valid_in = 0;
    #10 data_in = 8'b01010101;
    valid_in = 1;
    #10 valid_in = 0;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
reg valid_in;
wire [7:0] data_out;
wire valid_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .valid_in(valid_in),
    .data_out(data_out),
    .valid_out(valid_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    valid_in = 0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    valid_in = 1;
    #10 valid_in = 0;
    #10 data_in = 8'b01010101;
    valid_in = 1;
    #10 valid_in = 0;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
reg valid_in;
wire [7:0] data_out;
wire valid_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .valid_in(valid_in),
    .data_out(data_out),
    .valid_out(valid_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    valid_in = 0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    valid_in = 1;
    #10 valid_in = 0;
    #10 data_in = 8'b01010101;
    valid_in = 1;
    #10 valid_in = 0;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
reg valid_in;
wire [7:0] data_out;
wire valid_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .valid_in(valid_in),
    .data_out(data_out),
    .valid_out(valid_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    valid_in = 0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    valid_in = 1;
    #10 valid_in = 0;
    #10 data_in = 8'b01010101;
    valid_in = 1;
    #10 valid_in = 0;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
reg valid_in;
wire [7:0] data_out;
wire valid_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .valid_in(valid_in),
    .data_out(data_out),
    .valid_out(valid_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    valid_in = 0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    valid_in = 1;
    #10 valid_in = 0;
    #10 data_in = 8'b01010101;
    valid_in = 1;
    #10 valid_in = 0;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
reg valid_in;
wire [7:0] data_out;
wire valid_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .valid_in(valid_in),
    .data_out(data_out),
    .valid_out(valid_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    valid_in = 0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    valid_in = 1;
    #10 valid_in = 0;
    #10 data_in = 8'b01010101;
    valid_in = 1;
    #10 valid_in = 0;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
reg valid_in;
wire [7:0] data_out;
wire valid_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .valid_in(valid_in),
    .data_out(data_out),
    .valid_out(valid_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    valid_in = 0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    valid_in = 1;
    #10 valid_in = 0;
    #10 data_in = 8'b01010101;
    valid_in = 1;
    #10 valid_in = 0;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
reg valid_in;
wire [7:0] data_out;
wire valid_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .valid_in(valid_in),
    .data_out(data_out),
    .valid_out(valid_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    valid_in = 0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    valid_in = 1;
    #10 valid_in = 0;
    #10 data_in = 8'b01010101;
    valid_in = 1;
    #10 valid_in = 0;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
reg valid_in;
wire [7:0] data_out;
wire valid_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .valid_in(valid_in),
    .data_out(data_out),
    .valid_out(valid_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    valid_in = 0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    valid_in = 1;
    #10 valid_in = 0;
    #10 data_in = 8'b01010101;
    valid_in = 1;
    #10 valid_in = 0;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
reg valid_in;
wire [7:0] data_out;
wire valid_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .valid_in(valid_in),
    .data_out(data_out),
    .valid_out(valid_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    valid_in = 0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    valid_in = 1;
    #10 valid_in = 0;
    #10 data_in = 8'b01010101;
    valid_in = 1;
    #10 valid_in = 0;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
reg valid_in;
wire [7:0] data_out;
wire valid_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .valid_in(valid_in),
    .data_out(data_out),
    .valid_out(valid_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    valid_in = 0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    valid_in = 1;
    #10 valid_in = 0;
    #10 data_in = 8'b01010101;
    valid_in = 1;
    #10 valid_in = 0;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
reg valid_in;
wire [7:0] data_out;
wire valid_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .valid_in(valid_in),
    .data_out(data_out),
    .valid_out(valid_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    valid_in = 0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    valid_in = 1;
    #10 valid_in = 0;
    #10 data_in = 8'b01010101;
    valid_in = 1;
    #10 valid_in = 0;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
reg valid_in;
wire [7:0] data_out;
wire valid_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .valid_in(valid_in),
    .data_out(data_out),
    .valid_out(valid_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    valid_in = 0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    valid_in = 1;
    #10 valid_in = 0;
    #10 data_in = 8'b01010101;
    valid_in = 1;
    #10 valid_in = 0;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
reg valid_in;
wire [7:0] data_out;
wire valid_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .valid_in(valid_in),
    .data_out(data_out),
    .valid_out(valid_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    valid_in = 0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    valid_in = 1;
    #10 valid_in = 0;
    #10 data_in = 8'b01010101;
    valid_in = 1;
    #10 valid_in = 0;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
reg valid_in;
wire [7:0] data_out;
wire valid_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .valid_in(valid_in),
    .data_out(data_out),
    .valid_out(valid_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    valid_in = 0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    valid_in = 1;
    #10 valid_in = 0;
    #10 data_in = 8'b01010101;
    valid_in = 1;
    #10 valid_in = 0;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
reg valid_in;
wire [7:0] data_out;
wire valid_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .valid_in(valid_in),
    .data_out(data_out),
    .valid_out(valid_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    valid_in = 0;
    #10 rst_n = 1;
    #10 data_in = 8'b10101010;
    valid_in = 1;
    #10 valid_in = 0;
    #10 data_in = 8'b01010101;
    valid_in = 1;
    #10 valid_in = 0;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
reg valid_in;
wire [7:0] data_out;
wire valid_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .valid_in(valid_in),
    .data_out(data_out),
    .valid_out(valid_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'b0;
    valid_in = 0;
    #10 rst_n = 1;
    #10 data_in = 8'b