The following Verilog code implements a clearable valid/ready asynchronous FIFO. The code uses gray code synchronization for clock domain crossing. The module interface is defined in the question.

```
module cdc_fifo_gray_clearable #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input                  src_clear_i,
    output                 src_clear_pending_o,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    input                  dst_clear_i,
    output                 dst_clear_pending_o,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    // Gray code synchronization
    reg [LOG_DEPTH-1:0] gray_sync_src_to_dst;
    reg [LOG_DEPTH-1:0] gray_sync_dst_to_src;
    reg [LOG_DEPTH-1:0] gray_sync_dst_to_src_next;
    reg [LOG_DEPTH-1:0] gray_sync_src_to_dst_next;
    reg [LOG_DEPTH-1:0] gray_sync_dst_to_src_gray;
    reg [LOG_DEPTH-1:0] gray_sync_src_to_dst_gray;
    reg [LOG_DEPTH-1:0] gray_sync_dst_to_src_gray_next;
    reg [LOG_DEPTH-1:0] gray_sync_src_to_dst_gray_next;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            gray_sync_src_to_dst <= 0;
            gray_sync_src_to_dst_gray <= 0;
        end else begin
            gray_sync_src_to_dst <= gray_sync_src_to_dst_next;
            gray_sync_src_to_dst_gray <= gray_sync_src_to_dst_gray_next;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            gray_sync_dst_to_src <= 0;
            gray_sync_dst_to_src_gray <= 0;
        end else begin
            gray_sync_dst_to_src <= gray_sync_dst_to_src_next;
            gray_sync_dst_to_src_gray <= gray_sync_dst_to_src_gray_next;
        end
    end

    always @(*) begin
        gray_sync_src_to_dst_next = gray_sync_src_to_dst + 1;
        gray_sync_src_to_dst_gray_next = gray_sync_src_to_dst_gray ^ gray_sync_src_to_dst_next;
        gray_sync_dst_to_src_next = gray_sync_dst_to_src + 1;
        gray_sync_dst_to_src_gray_next = gray_sync_dst_to_src_gray ^ gray_sync_dst_to_src_next;
    end

    // FIFO data
    reg [WIDTH-1:0] fifo_data [0:2**LOG_DEPTH-1];
    reg [LOG_DEPTH-1:0] fifo_head;
    reg [LOG_DEPTH-1:0] fifo_tail;
    reg [LOG_DEPTH-1:0] fifo_head_next;
    reg [LOG_DEPTH-1:0] fifo_tail_next;
    reg [LOG_DEPTH-1:0] fifo_head_gray;
    reg [LOG_DEPTH-1:0] fifo_tail_gray;
    reg [LOG_DEPTH-1:0] fifo_head_gray_next;
    reg [LOG_DEPTH-1:0] fifo_tail_gray_next;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            fifo_head <= 0;
            fifo_tail <= 0;
            fifo_head_gray <= 0;
            fifo_tail_gray <= 0;
        end else begin
            fifo_head <= fifo_head_next;
            fifo_tail <= fifo_tail_next;
            fifo_head_gray <= fifo_head_gray_next;
            fifo_tail_gray <= fifo_tail_gray_next;
        end
    end

    always @(*) begin
        fifo_head_next = fifo_head;
        fifo_tail_next = fifo_tail;
        fifo_head_gray_next = fifo_head_gray;
        fifo_tail_gray_next = fifo_tail_gray;
        if (src_valid_i && src_ready_o) begin
            fifo_data[fifo_head] = src_data_i;
            fifo_head_next = fifo_head + 1;
            fifo_head_gray_next = fifo_head_gray ^ fifo_head_next;
        end
        if (dst_ready_i && dst_valid_o) begin
            dst_data_o = fifo_data[fifo_tail];
            fifo_tail_next = fifo_tail + 1;
            fifo_tail_gray_next = fifo_tail_gray ^ fifo_tail_next;
        end
    end

    // Clear logic
    reg [LOG_DEPTH-1:0] clear_ptr;
    reg [LOG_DEPTH-1:0] clear_ptr_next;
    reg [LOG_DEPTH-1:0] clear_ptr_gray;
    reg [LOG_DEPTH-1:0] clear_ptr_gray_next;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            clear_ptr <= 0;
            clear_ptr_gray <= 0;
        end else begin
            clear_ptr <= clear_ptr_next;
            clear_ptr_gray <= clear_ptr_gray_next;
        end
    end

    always @(*) begin
        clear_ptr_next = clear_ptr;
        clear_ptr_gray_next = clear_ptr_gray;
        if (src_clear_i) begin
            clear_ptr_next = 0;
            clear_ptr_gray_next = 0;
        end
    end

    assign src_clear_pending_o = (clear_ptr_gray != gray_sync_dst_to_src_gray) && (clear_ptr_gray != gray_sync_dst_to_src);
    assign dst_clear_pending_o = (clear_ptr_gray != gray_sync_src_to_dst_gray) && (clear_ptr_gray != gray_sync_src_to_dst);

    // Valid/ready logic
    reg src_ready_reg;
    reg dst_valid_reg;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ready_reg <= 1;
        end else begin
            src_ready_reg <= src_ready_o;
        end
    end

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_reg <= 0;
        end else begin
            dst_valid_reg <= dst_valid_o;
        end
    end

    assign src_ready_o = src_ready_reg && (fifo_head_gray != fifo_tail_gray) && (fifo_head_gray != fifo_tail);
    assign dst_valid_o = dst_valid_reg && (fifo_head_gray != fifo_tail_gray) && (fifo_head_gray != fifo_tail);

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] in,
    output [7:0] out
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] in,
    output [7:0] out
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

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] in,
    output [7:0] out
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

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] in,
    output [7:0] out
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

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] in,
    output [7:0] out
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

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] in,
    output [7:0] out
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

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] in,
    output [7:0] out
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

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] in,
    output [7:0] out
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

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] in,
    output [7:0] out
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

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] in,
    output [7:0] out
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

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] in,
    output [7:0] out
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

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] in,
    output [7:0] out
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

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] in,
    output [7:0] out
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

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] in,
    output [7:0] out
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

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] in,
    output [7:0] out
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

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] in,
    output [7:0] out
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

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] in,
    output [7:0] out
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

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] in,
    output [7:0] out
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

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] in,
    output [7:0] out
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

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
