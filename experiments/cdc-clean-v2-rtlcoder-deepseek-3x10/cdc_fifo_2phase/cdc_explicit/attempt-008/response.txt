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
    reg [LOG_DEPTH-1:0] count_next;
    reg [LOG_DEPTH-1:0] count_next_next;

    wire [LOG_DEPTH-1:0] head_next;
    wire [LOG_DEPTH-1:0] tail_next;

    assign head_next = (src_valid_i && src_ready_o) ? (head + 1'b1) : head;
    assign tail_next = (dst_valid_o && dst_ready_i) ? (tail + 1'b1) : tail;

    always @(posedge src_clk_i) begin
        if (!src_rst_ni) begin
            head <= 0;
            count <= 0;
        end else begin
            head <= head_next;
            count <= count_next;
        end
    end

    always @(posedge dst_clk_i) begin
        if (!dst_rst_ni) begin
            tail <= 0;
            count_next <= 0;
            count_next_next <= 0;
        end else begin
            tail <= tail_next;
            count_next <= count_next_next;
        end
    end

    assign src_ready_o = (count < DEPTH);
    assign dst_valid_o = (count > 0);

    always @(posedge src_clk_i) begin
        if (src_valid_i && src_ready_o) begin
            mem[head] <= src_data_i;
        end
    end

    always @(posedge dst_clk_i) begin
        if (dst_valid_o && dst_ready_i) begin
            dst_data_o <= mem[tail];
        end
    end

    always @(posedge src_clk_i) begin
        if (src_valid_i && src_ready_o) begin
            count_next <= count + 1'b1;
        end
    end

    always @(posedge dst_clk_i) begin
        if (dst_valid_o && dst_ready_i) begin
            count_next_next <= count - 1'b1;
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] data_in;

    // Outputs
    wire [7:0] data_out;

    // Instantiate the DUT
    top dut (.clk(clk), .reset(reset), .data_in(data_in), .data_out(data_out));

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        reset = 1;
        #10 reset = 0;
    end

    // Data input generation
    initial begin
        data_in = 8'h00;
        #10 data_in = 8'h01;
        #10 data_in = 8'h02;
        #10 data_in = 8'h03;
        #10 data_in = 8'h04;
        #10 data_in = 8'h05;
        #10 data_in = 8'h06;
        #10 data_in = 8'h07;
        #10 data_in = 8'h08;
        #10 data_in = 8'h09;
        #10 data_in = 8'h0a;
        #10 data_in = 8'h0b;
        #10 data_in = 8'h0c;
        #10 data_in = 8'h0d;
        #10 data_in = 8'h0e;
        #10 data_in = 8'h0f;
        #10 $finish;
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(input clk, input reset, input [7:0] data_in, output [7:0] data_out);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 8'h00;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top(
    input clk,
    input reset,
    input [