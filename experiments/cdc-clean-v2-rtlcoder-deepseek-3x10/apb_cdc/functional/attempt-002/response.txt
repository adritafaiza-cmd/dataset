Sure, here is the complete Verilog code for the APB clock-domain bridge module:

```
module apb_cdc #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      src_pclk_i,
    input                      src_preset_ni,
    input                      src_psel_i,
    input                      src_penable_i,
    input                      src_pwrite_i,
    input  [ADDR_WIDTH-1:0]    src_paddr_i,
    input  [DATA_WIDTH-1:0]    src_pwdata_i,
    input  [DATA_WIDTH/8-1:0]  src_pstrb_i,
    input  [2:0]               src_pprot_i,
    output                     src_pready_o,
    output [DATA_WIDTH-1:0]    src_prdata_o,
    output                     src_pslverr_o,
    input                      dst_pclk_i,
    input                      dst_preset_ni,
    output                     dst_psel_o,
    output                     dst_penable_o,
    output                     dst_pwrite_o,
    output [ADDR_WIDTH-1:0]    dst_paddr_o,
    output [DATA_WIDTH-1:0]    dst_pwdata_o,
    output [DATA_WIDTH/8-1:0]  dst_pstrb_o,
    output [2:0]               dst_pprot_o,
    input                      dst_pready_i,
    input  [DATA_WIDTH-1:0]    dst_prdata_i,
    input                      dst_pslverr_i
);

    reg [ADDR_WIDTH-1:0]    src_paddr_r;
    reg [DATA_WIDTH-1:0]    src_pwdata_r;
    reg [DATA_WIDTH/8-1:0]  src_pstrb_r;
    reg [2:0]               src_pprot_r;
    reg                     src_pwrite_r;
    reg                     src_psel_r;
    reg                     src_penable_r;
    reg                     src_pready_r;
    reg [DATA_WIDTH-1:0]    src_prdata_r;
    reg                     src_pslverr_r;
    reg                     dst_pwrite_r;
    reg                     dst_psel_r;
    reg                     dst_penable_r;
    reg [ADDR_WIDTH-1:0]    dst_paddr_r;
    reg [DATA_WIDTH-1:0]    dst_pwdata_r;
    reg [DATA_WIDTH/8-1:0]  dst_pstrb_r;
    reg [2:0]               dst_pprot_r;
    reg                     dst_pready_r;
    reg [DATA_WIDTH-1:0]    dst_prdata_r;
    reg                     dst_pslverr_r;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (~src_preset_ni) begin
            src_paddr_r <= 0;
            src_pwdata_r <= 0;
            src_pstrb_r <= 0;
            src_pprot_r <= 0;
            src_pwrite_r <= 0;
            src_psel_r <= 0;
            src_penable_r <= 0;
            src_pready_r <= 0;
            src_prdata_r <= 0;
            src_pslverr_r <= 0;
        end else begin
            src_paddr_r <= src_paddr_i;
            src_pwdata_r <= src_pwdata_i;
            src_pstrb_r <= src_pstrb_i;
            src_pprot_r <= src_pprot_i;
            src_pwrite_r <= src_pwrite_i;
            src_psel_r <= src_psel_i;
            src_penable_r <= src_penable_i;
            src_pready_r <= dst_pready_i;
            src_prdata_r <= dst_prdata_i;
            src_pslverr_r <= dst_pslverr_i;
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (~dst_preset_ni) begin
            dst_pwrite_r <= 0;
            dst_psel_r <= 0;
            dst_penable_r <= 0;
            dst_paddr_r <= 0;
            dst_pwdata_r <= 0;
            dst_pstrb_r <= 0;
            dst_pprot_r <= 0;
            dst_pready_r <= 0;
            dst_prdata_r <= 0;
            dst_pslverr_r <= 0;
        end else begin
            dst_pwrite_r <= src_pwrite_r;
            dst_psel_r <= src_psel_r;
            dst_penable_r <= src_penable_r;
            dst_paddr_r <= src_paddr_r;
            dst_pwdata_r <= src_pwdata_r;
            dst_pstrb_r <= src_pstrb_r;
            dst_pprot_r <= src_pprot_r;
            dst_pready_r <= src_pready_r;
            dst_prdata_r <= src_prdata_r;
            dst_pslverr_r <= src_pslverr_r;
        end
    end

    assign src_pready_o = src_pready_r;
    assign src_prdata_o = src_prdata_r;
    assign src_pslverr_o = src_pslverr_r;
    assign dst_psel_o = dst_psel_r;
    assign dst_penable_o = dst_penable_r;
    assign dst_pwrite_o = dst_pwrite_r;
    assign dst_paddr_o = dst_paddr_r;
    assign dst_pwdata_o = dst_pwdata_r;
    assign dst_pstrb_o = dst_pstrb_r;
    assign dst_pprot_o = dst_pprot_r;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg[0] <= 8'b0;
        shift_reg[1] <= 8'b0;
        shift_reg[2] <= 8'b0;
        shift_reg[3] <= 8'b0;
        shift_reg[4] <= 8'b0;
        shift_reg[5] <= 8'b0;
        shift_reg[6] <= 8'b0;
        shift_reg[7] <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg[index] <= in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
        end
        out <= shift_reg[index];
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg[0] <= 8'b0;
        shift_reg[1] <= 8'b0;
        shift_reg[2] <= 8'b0;
        shift_reg[3] <= 8'b0;
        shift_reg[4] <= 8'b0;
        shift_reg[5] <= 8'b0;
        shift_reg[6] <= 8'b0;
        shift_reg[7] <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg[index] <= in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
        end
        out <= shift_reg[index];
    end
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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg[0] <= 8'b0;
        shift_reg[1] <= 8'b0;
        shift_reg[2] <= 8'b0;
        shift_reg[3] <= 8'b0;
        shift_reg[4] <= 8'b0;
        shift_reg[5] <= 8'b0;
        shift_reg[6] <= 8'b0;
        shift_reg[7] <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg[index] <= in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
        end
        out <= shift_reg[index];
    end
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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg[0] <= 8'b0;
        shift_reg[1] <= 8'b0;
        shift_reg[2] <= 8'b0;
        shift_reg[3] <= 8'b0;
        shift_reg[4] <= 8'b0;
        shift_reg[5] <= 8'b0;
        shift_reg[6] <= 8'b0;
        shift_reg[7] <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg[index] <= in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
        end
        out <= shift_reg[index];
    end
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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg[0] <= 8'b0;
        shift_reg[1] <= 8'b0;
        shift_reg[2] <= 8'b0;
        shift_reg[3] <= 8'b0;
        shift_reg[4] <= 8'b0;
        shift_reg[5] <= 8'b0;
        shift_reg[6] <= 8'b0;
        shift_reg[7] <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg[index] <= in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
        end
        out <= shift_reg[index];
    end
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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg[0] <= 8'b0;
        shift_reg[1] <= 8'b0;
        shift_reg[2] <= 8'b0;
        shift_reg[3] <= 8'b0;
        shift_reg[4] <= 8'b0;
        shift_reg[5] <= 8'b0;
        shift_reg[6] <= 8'b0;
        shift_reg[7] <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg[index] <= in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
        end
        out <= shift_reg[index];
    end
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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg[0] <= 8'b0;
        shift_reg[1] <= 8'b0;
        shift_reg[2] <= 8'b0;
        shift_reg[3] <= 8'b0;
        shift_reg[4] <= 8'b0;
        shift_reg[5] <= 8'b0;
        shift_reg[6] <= 8'b0;
        shift_reg[7] <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg[index] <= in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
        end
        out <= shift_reg[index];
    end
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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg[0] <= 8'b0;
        shift_reg[1] <= 8'b0;
        shift_reg[2] <= 8'b0;
        shift_reg[3] <= 8'b0;
        shift_reg[4] <= 8'b0;
        shift_reg[5] <= 8'b0;
        shift_reg[6] <= 8'b0;
        shift_reg[7] <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg[index] <= in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
        end
        out <= shift_reg[index];
    end
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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg[0] <= 8'b0;
        shift_reg[1] <= 8'b0;
        shift_reg[2] <= 8'b0;
        shift_reg[3] <= 8'b0;
        shift_reg[4] <= 8'b0;
        shift_reg[5] <= 8'b0;
        shift_reg[6] <= 8'b0;
        shift_reg[7] <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg[index] <= in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
        end
        out <= shift_reg[index];
    end
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
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg[0] <= 8'b0;
        shift_reg[1] <= 8'b0;
        shift_reg[2] <= 8'b0;
        shift_reg[3] <= 8'b0;
        shift_reg[4] <= 8'b0;
        shift_reg[5] <= 8'b0;
        shift_reg[6] <= 8'b0;
