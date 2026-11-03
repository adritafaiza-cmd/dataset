Here is the complete Verilog-2001 code for the described module:

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

    // Internal signals
    reg [WIDTH-1:0]         fifo [0:(1<<LOG_DEPTH)-1];
    reg [LOG_DEPTH-1:0]     head;
    reg [LOG_DEPTH-1:0]     tail;
    reg                     full;
    reg                     empty;
    reg                     src_ready;
    reg                     dst_valid;
    wire                    dst_ready;
    wire                    src_valid;
    wire [WIDTH-1:0]        src_data;
    wire                    dst_ready_d1;

    // Assignments
    assign src_ready_o = src_ready;
    assign dst_data_o = fifo[tail];
    assign dst_valid_o = dst_valid;
    assign src_valid = src_valid_i & src_ready;
    assign src_data = src_data_i;
    assign dst_ready = dst_ready_i & ~dst_valid;

    // Synchronous logic
    always @(posedge src_clk_i) begin
        if (~src_rst_ni) begin
            head <= 0;
            full <= 0;
            src_ready <= 1;
        end else begin
            if (src_valid) begin
                fifo[head] <= src_data;
                head <= head + 1;
                if (head == tail) begin
                    full <= 1;
                end
                src_ready <= ~full;
            end
        end
    end

    always @(posedge dst_clk_i) begin
        if (~dst_rst_ni) begin
            tail <= 0;
            empty <= 1;
            dst_valid <= 0;
        end else begin
            if (dst_ready) begin
                tail <= tail + 1;
                if (tail == head) begin
                    empty <= 1;
                end
                dst_valid <= ~empty;
            end
        end
    end

    // Asynchronous logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (~src_rst_ni) begin
            src_ready <= 1;
        end else begin
            if (src_valid) begin
                if (full) begin
                    src_ready <= 0;
                end else begin
                    src_ready <= 1;
                end
            end
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (~dst_rst_ni) begin
            empty <= 1;
            dst_valid <= 0;
        end else begin
            if (dst_ready) begin
                if (empty) begin
                    dst_valid <= 0;
                end else begin
                    dst_valid <= 1;
                end
            end
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in[0]};
    end
end

assign out = shift_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in[0]};
    end
end

assign out = shift_reg;

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
    output [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in[0]};
    end
end

assign out = shift_reg;

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
    output [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in[0]};
    end
end

assign out = shift_reg;

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
    #30 in = 8'b11001100