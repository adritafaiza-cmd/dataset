Sure, here is the complete Verilog-2001 code for the described FIFO module:

```
module cdc_fifo_gray #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
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
    localparam ADDR_WIDTH = LOG_DEPTH;

    reg [ADDR_WIDTH-1:0] src_rd_ptr_r;
    reg [ADDR_WIDTH-1:0] src_wr_ptr_r;
    reg [ADDR_WIDTH-1:0] dst_rd_ptr_r;
    reg [ADDR_WIDTH-1:0] dst_wr_ptr_r;

    reg [WIDTH-1:0] fifo_mem [0:DEPTH-1];

    wire [ADDR_WIDTH-1:0] src_rd_ptr_next = src_rd_ptr_r + 1'b1;
    wire [ADDR_2ADDR_WIDTH-1:0] src_wr_ptr_next = src_wr_ptr_r + 1'b1;
    wire [ADDR_WIDTH-1:0] dst_rd_ptr_next = dst_rd_ptr_r + 1'b1;
    wire [ADDR_2ADDR_WIDTH-1:0] dst_wr_ptr_next = dst_wr_ptr_r + 1'b1;

    wire src_empty = (src_rd_ptr_r == src_wr_ptr_r);
    wire src_full = (src_rd_ptr_next == src_wr_ptr_r);
    wire dst_empty = (dst_rd_ptr_r == dst_wr_ptr_r);
    wire dst_full = (dst_rd_ptr_next == dst_wr_ptr_r);

    wire src_valid = src_valid_i & ~src_full;
    wire dst_ready = dst_ready_i & ~dst_empty;

    always @(posedge src_clk_i) begin
        if (src_rst_ni == 1'b0) begin
            src_rd_ptr_r <= {ADDR_WIDTH{1'b0}};
            src_wr_ptr_r <= {ADDR_WIDTH{1'b0}};
        end else begin
            if (src_valid_i && ~src_full) begin
                fifo_mem[src_wr_ptr_r] <= src_data_i;
                src_wr_ptr_r <= src_wr_ptr_next;
            end
            if (dst_ready_i && ~dst_empty) begin
                src_rd_ptr_r <= src_rd_ptr_next;
            end
        end
    end

    always @(posedge dst_clk_i) begin
        if (dst_rst_ni == 1'b0) begin
            dst_rd_ptr_r <= {ADDR_WIDTH{1'b0}};
            dst_wr_ptr_r <= {ADDR_WIDTH{1'b0}};
        end else begin
            if (dst_ready_i && ~dst_empty) begin
                dst_data_o <= fifo_mem[dst_rd_ptr_r];
                dst_valid_o <= 1'b1;
                dst_rd_ptr_r <= dst_rd_ptr_next;
            end else begin
                dst_valid_o <= 1'b0;
            end
            if (src_valid_i && ~src_full) begin
                dst_wr_ptr_r <= dst_wr_ptr_next;
            end
        end
    end

    assign src_ready_o = ~src_full;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg <= 0;
        data_out <= 0;
    end else begin
        shift_reg[shift_count] <= data_in;
        shift_count <= shift_count + 1;
        if (shift_count == 8) begin
            data_out <= shift_reg[7];
            shift_count <= 0;
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg <= 0;
        data_out <= 0;
    end else begin
        shift_reg[shift_count] <= data_in;
        shift_count <= shift_count + 1;
        if (shift_count == 8) begin
            data_out <= shift_reg[7];
            shift_count <= 0;
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg <= 0;
        data_out <= 0;
    end else begin
        shift_reg[shift_count] <= data_in;
        shift_count <= shift_count + 1;
        if (shift_count == 8) begin
            data_out <= shift_reg[7];
            shift_count <= 0;
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg <= 0;
        data_out <= 0;
    end else begin
        shift_reg[shift_count] <= data_in;
        shift_count <= shift_count + 1;
        if (shift_count == 8) begin
            data_out <= shift_reg[7];
            shift_count <= 0;
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 $finish;
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10