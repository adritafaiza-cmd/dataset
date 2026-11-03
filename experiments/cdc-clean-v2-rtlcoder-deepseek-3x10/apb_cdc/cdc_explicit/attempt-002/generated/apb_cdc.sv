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

    // Internal signals
    reg [ADDR_WIDTH-1:0]    paddr_reg;
    reg [DATA_WIDTH-1:0]    pwdata_reg;
    reg [DATA_WIDTH/8-1:0]  pstrb_reg;
    reg [2:0]               pprot_reg;
    reg                     psel_reg;
    reg                     penable_reg;
    reg                     pwrite_reg;
    reg                     pready_reg;
    reg [DATA_WIDTH-1:0]    prdata_reg;
    reg                     pslverr_reg;

    // FIFO signals
    reg [ADDR_WIDTH-1:0]    fifo_paddr;
    reg [DATA_WIDTH-1:0]    fifo_pwdata;
    reg [DATA_WIDTH/8-1:0]  fifo_pstrb;
    reg [2:0]               fifo_pprot;
    reg                     fifo_psel;
    reg                     fifo_penable;
    reg                     fifo_pwrite;
    reg                     fifo_pready;
    reg [DATA_WIDTH-1:0]    fifo_prdata;
    reg                     fifo_pslverr;

    // FIFO write enable
    wire                    fifo_write = src_pready_o & src_psel_i & src_penable_i;

    // FIFO read enable
    wire                    fifo_read = dst_pready_i & fifo_pready;

    // FIFO full
    wire                    fifo_full = (fifo_write & ~fifo_pready) & (fifo_read & ~fifo_psel);

    // FIFO empty
    wire                    fifo_empty = (fifo_read & ~fifo_psel) & (fifo_write & ~fifo_pready);

    // FIFO write
    always @(posedge src_pclk_i) begin
        if (src_preset_ni == 1'b0) begin
            fifo_paddr <= 0;
            fifo_pwdata <= 0;
            fifo_pstrb <= 0;
            fifo_pprot <= 0;
            fifo_psel <= 0;
            fifo_penable <= 0;
            fifo_pwrite <= 0;
            fifo_pready <= 0;
            fifo_prdata <= 0;
            fifo_pslverr <= 0;
        end else if (fifo_write) begin
            fifo_paddr <= src_paddr_i;
            fifo_pwdata <= src_pwdata_i;
            fifo_pstrb <= src_pstrb_i;
            fifo_pprot <= src_pprot_i;
            fifo_psel <= src_psel_i;
            fifo_penable <= src_penable_i;
            fifo_pwrite <= src_pwrite_i;
            fifo_pready <= 1;
            fifo_prdata <= src_prdata_o;
            fifo_pslverr <= src_pslverr_o;
        end else if (fifo_read) begin
            fifo_paddr <= 0;
            fifo_pwdata <= 0;
            fifo_pstrb <= 0;
            fifo_pprot <= 0;
            fifo_psel <= 0;
            fifo_penable <= 0;
            fifo_pwrite <= 0;
            fifo_pready <= 0;
            fifo_prdata <= 0;
            fifo_pslverr <= 0;
        end
    end

    // FIFO read
    always @(posedge dst_pclk_i) begin
        if (dst_preset_ni == 1'b0) begin
            paddr_reg <= 0;
            pwdata_reg <= 0;
            pstrb_reg <= 0;
            pprot_reg <= 0;
            psel_reg <= 0;
            penable_reg <= 0;
            pwrite_reg <= 0;
            pready_reg <= 0;
            prdata_reg <= 0;
            pslverr_reg <= 0;
        end else if (fifo_read) begin
            paddr_reg <= fifo_paddr;
            pwdata_reg <= fifo_pwdata;
            pstrb_reg <= fifo_pstrb;
            pprot_reg <= fifo_pprot;
            psel_reg <= fifo_psel;
            penable_reg <= fifo_penable;
            pwrite_reg <= fifo_pwrite;
            pready_reg <= fifo_pready;
            prdata_reg <= fifo_prdata;
            pslverr_reg <= fifo_pslverr;
        end
    end

    // Output signals
    assign src_pready_o = pready_reg;
    assign src_prdata_o = prdata_reg;
    assign src_pslverr_o = pslverr_reg;
    assign dst_psel_o = psel_reg;
    assign dst_penable_o = penable_reg;
    assign dst_pwrite_o = pwrite_reg;
    assign dst_paddr_o = paddr_reg;
    assign dst_pwdata_o = pwdata_reg;
    assign dst_pstrb_o = pstrb_reg;
    assign dst_pprot_o = pprot_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk) begin
    if (reset) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk) begin
    if (reset) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

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
    data_in = 8'b0;
    #10 reset = 0;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk) begin
    if (reset) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

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
    data_in = 8'b0;
    #10 reset = 0;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk) begin
    if (reset) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

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
    data_in = 8'b0;
    #10 reset = 0;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk) begin
    if (reset) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

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
    data_in = 8'b0;
    #10 reset = 0;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk) begin
    if (reset) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

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
    data_in = 8'b0;
    #10 reset = 0;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk) begin
    if (reset) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

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
    data_in = 8'b0;
    #10 reset = 0;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk) begin
    if (reset) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

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
    data_in = 8'b0;
    #10 reset = 0;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk) begin
    if (reset) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

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
    data_in = 8'b0;
    #10 reset = 0;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk) begin
    if (reset) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

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
    data_in = 8'b0;
    #10 reset = 0;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk) begin
    if (reset) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

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
    data_in = 8'b0;
    #10 reset = 0;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk) begin
    if (reset) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

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
    data_in = 8'b0;
    #10 reset = 0;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk) begin
    if (reset) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

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
    data_in = 8'b0;
    #10 reset = 0;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk) begin
    if (reset) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

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
    data_in = 8'b0;
    #10 reset = 0;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk) begin
    if (reset) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

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
    data_in = 8'b0;
    #10 reset = 0;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk) begin
    if (reset) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

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
    data_in = 8'b0;
    #10 reset = 0;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk) begin
    if (reset) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

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
    data_in = 8'b0;
    #10 reset = 0;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk) begin
    if (reset) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

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
    data_in = 8'b0;
    #10 reset = 0;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk) begin
    if (reset) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

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
    data_in = 8'b0;
    #10 reset = 0;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk) begin
    if (reset) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

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
    data_in = 8'b0;
    #10 reset = 0;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output [7:0] data_out
);

reg [7:0] data_reg;

always @(posedge clk) begin
    if (reset) begin
        data_reg <= 8'b0;
    end else begin
        data_reg <= data_in;
    end
end

assign data_out = data_reg;

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
    data_in = 8'b0;
    #10 reset = 0;
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 $fin