Sure, here is the complete Verilog-2001 code for the APB clock-domain bridge:

```
module apbxclk #(
		parameter	C_APB_ADDR_WIDTH = 12,
		parameter	C_APB_DATA_WIDTH = 32,
		parameter [0:0]	OPT_REGISTERED = 1'b0,
		localparam	AW = C_APB_ADDR_WIDTH,
		localparam	DW = C_APB_DATA_WIDTH
	) (
		input	wire			S_APB_PCLK, S_PRESETn,
		input	wire			S_APB_PSEL,
		input	wire			S_APB_PENABLE,
		output	reg			S_APB_PREADY,
		input	wire	[AW-1:0]	S_APB_PADDR,
		input	wire			S_APB_PWRITE,
		input	wire	[DW-1:0]	S_APB_PWDATA,
		input	wire	[DW/8-1:0]	S_APB_PWSTRB,
		input	wire	[2:0]		S_APB_PPROT,
		output	wire	[DW-1:0]	S_APB_PRDATA,
		output	wire			S_APB_PSLVERR,
		input	wire			M_APB_PCLK,
		output	reg			M_PRESETn,
		output	reg			M_APB_PSEL,
		output	reg			M_APB_PENABLE,
		input	wire			M_APB_PREADY,
		output	wire	[AW-1:0]	M_APB_PADDR,
		output	wire			M_APB_PWRITE,
		output	wire	[DW-1:0]	M_APB_PWDATA,
		output	wire	[DW/8-1:0]	M_APB_PWSTRB,
		output	wire	[2:0]		M_APB_PPROT,
		input	wire	[DW-1:0]	M_APB_PRDATA,
		input	wire			M_APB_PSLVERR
	);

	reg [AW-1:0] S_APB_PADDR_sync;
	reg S_APB_PWRITE_sync;
	reg [DW-1:0] S_APB_PWDATA_sync;
	reg [DW/8-1:0] S_APB_PWSTRB_sync;
	reg [2:0] S_APB_PPROT_sync;

	reg [AW-1:0] M_APB_PADDR_sync;
	reg M_APB_PWRITE_sync;
	reg [DW-1:0] M_APB_PWDATA_sync;
	reg [DW/8-1:0] M_APB_PWSTRB_sync;
	reg [2:0] M_APB_PPROT_sync;

	reg S_APB_PSEL_sync;
	reg S_APB_PENABLE_sync;
	reg M_APB_PSEL_sync;
	reg M_APB_PENABLE_sync;

	reg S_APB_PREADY_sync;
	reg M_APB_PREADY_sync;

	reg S_APB_PSLVERR_sync;
	reg M_APB_PSLVERR_sync;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (~S_PRESETn) begin
			S_APB_PADDR_sync <= 0;
			S_APB_PWRITE_sync <= 0;
			S_APB_PWDATA_sync <= 0;
			S_APB_PWSTRB_sync <= 0;
			S_APB_PPROT_sync <= 0;
			S_APB_PSEL_sync <= 0;
			S_APB_PENABLE_sync <= 0;
			S_APB_PREADY_sync <= 0;
			S_APB_PSLVERR_sync <= 0;
		end else begin
			S_APB_PADDR_sync <= S_APB_PADDR;
			S_APB_PWRITE_sync <= S_APB_PWRITE;
			S_APB_PWDATA_sync <= S_APB_PWDATA;
			S_APB_PWSTRB_sync <= S_APB_PWSTRB;
			S_APB_PPROT_sync <= S_APB_PPROT;
			S_APB_PSEL_sync <= S_APB_PSEL;
			S_APB_PENABLE_sync <= S_APB_PENABLE;
			S_APB_PREADY_sync <= S_APB_PREADY;
			S_APB_PSLVERR_sync <= S_APB_PSLVERR;
		end
	end

	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (~S_PRESETn) begin
			M_APB_PADDR_sync <= 0;
			M_APB_PWRITE_sync <= 0;
			M_APB_PWDATA_sync <= 0;
			M_APB_PWSTRB_sync <= 0;
			M_APB_PPROT_sync <= 0;
			M_APB_PSEL_sync <= 0;
			M_APB_PENABLE_sync <= 0;
			M_APB_PREADY_sync <= 0;
			M_APB_PSLVERR_sync <= 0;
		end else begin
			M_APB_PADDR_sync <= M_APB_PADDR;
			M_APB_PWRITE_sync <= M_APB_PWRITE;
			M_APB_PWDATA_sync <= M_APB_PWDATA;
			M_APB_PWSTRB_sync <= M_APB_PWSTRB;
			M_APB_PPROT_sync <= M_APB_PPROT;
			M_APB_PSEL_sync <= M_APB_PSEL;
			M_APB_PENABLE_sync <= M_APB_PENABLE;
			M_APB_PREADY_sync <= M_APB_PREADY;
			M_APB_PSLVERR_sync <= M_APB_PSLVERR;
		end
	end

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (~S_PRESETn) begin
			M_PRESETn <= 0;
			M_APB_PSEL <= 0;
			M_APB_PENABLE <= 0;
			S_APB_PREADY <= 0;
		end else begin
			M_PRESETn <= S_PRESETn;
			M_APB_PSEL <= S_APB_PSEL_sync;
			M_APB_PENABLE <= S_APB_PENABLE_sync;
			S_APB_PREADY <= M_APB_PREADY_sync;
		end
	end

	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (~S_PRESETn) begin
			M_APB_PADDR <= 0;
			M_APB_PWRITE <= 0;
			M_APB_PWDATA <= 0;
			M_APB_PWSTRB <= 0;
			M_APB_PPROT <= 0;
			S_APB_PRDATA <= 0;
			S_APB_PSLVERR <= 0;
		end else begin
			M_APB_PADDR <= M_APB_PADDR_sync;
			M_APB_PWRITE <= M_APB_PWRITE_sync;
			M_APB_PWDATA <= M_APB_PWDATA_sync;
			M_APB_PWSTRB <= M_APB_PWSTRB_sync;
			M_APB_PPROT <= M_APB_PPROT_sync;
			S_APB_PRDATA <= M_APB_PRDATA;
			S_APB_PSLVERR <= M_APB_PSLVERR_sync;
		end
	end

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (~S_PRESETn) begin
			S_APB_PADDR <= 0;
			S_APB_PWRITE <= 0;
			S_APB_PWDATA <= 0;
			S_APB_PWSTRB <= 0;
			S_APB_PPROT <= 0;
			M_APB_PRDATA <= 0;
			M_APB_PSLVERR <= 0;
		end else begin
			S_APB_PADDR <= S_APB_PADDR_sync;
			S_APB_PWRITE <= S_APB_PWRITE_sync;
			S_APB_PWDATA <= S_APB_PWDATA_sync;
			S_APB_PWSTRB <= S_APB_PWSTRB_sync;
			S_APB_PPROT <= S_APB_PPROT_sync;
			M_APB_PRDATA <= S_APB_PRDATA;
			M_APB_PSLVERR <= S_APB_PSLVERR_sync;
		end
	end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg1 <= 8'b0;
        reg2 <= 8'b0;
        out <= 8'b0;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg1 <= 8'b0;
        reg2 <= 8'b0;
        out <= 8'b0;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
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
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg1 <= 8'b0;
        reg2 <= 8'b0;
        out <= 8'b0;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
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
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] reg1;
reg [7:0] reg2;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg1 <= 8'b0;
        reg2 <= 8'b0;
        out <= 8'b0;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule

module top_module_tb();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
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
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_2();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
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
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_3();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
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
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_4();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
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
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_5();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
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
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_6();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
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
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_7();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
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
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_8();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
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
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_9();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
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
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_10();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
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
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_11();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
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
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_12();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
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
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_13();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
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
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_14();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
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
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_15();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
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
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_16();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
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
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_17();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
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
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_18();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
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
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_19();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
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
    #10 in = 8'b00110011;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_20();

reg clk;
reg rst_n;
reg [7:0] in;
wire [7:0] out;

top_module dut(
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
    #10 in = 8'b