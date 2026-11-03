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

	reg [AW-1:0] s_paddr;
	reg s_pwrite;
	reg [DW-1:0] s_pwdata;
	reg [DW/8-1:0] s_pwstrb;
	reg [2:0] s_pprot;
	reg s_pready;
	reg [DW-1:0] s_prdata;
	reg s_pslverr;
	reg m_pready;
	reg [AW-1:0] m_paddr;
	reg m_pwrite;
	reg [DW-1:0] m_pwdata;
	reg [DW/8-1:0] m_pwstrb;
	reg [2:0] m_pprot;
	reg [DW-1:0] m_prdata;
	reg m_pslverr;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (~S_PRESETn) begin
			s_paddr <= 0;
			s_pwrite <= 0;
			s_pwdata <= 0;
			s_pwstrb <= 0;
			s_pprot <= 0;
			s_pready <= 0;
			s_prdata <= 0;
			s_pslverr <= 0;
		end else begin
			if (S_APB_PSEL && S_APB_PENABLE) begin
				s_paddr <= S_APB_PADDR;
				s_pwrite <= S_APB_PWRITE;
				s_pwdata <= S_APB_PWDATA;
				s_pwstrb <= S_APB_PWSTRB;
				s_pprot <= S_APB_PPROT;
				s_pready <= 1;
			end else begin
				s_pready <= 0;
			end
			if (s_pready && M_APB_PREADY) begin
				s_prdata <= M_APB_PRDATA;
				s_pslverr <= M_APB_PSLVERR;
			end
		end
	end

	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (~S_PRESETn) begin
			m_paddr <= 0;
			m_pwrite <= 0;
			m_pwdata <= 0;
			m_pwstrb <= 0;
			m_pprot <= 0;
			m_pready <= 0;
			m_prdata <= 0;
			m_pslverr <= 0;
		end else begin
			if (s_pready && M_APB_PREADY) begin
				m_paddr <= s_paddr;
				m_pwrite <= s_pwrite;
				m_pwdata <= s_pwdata;
				m_pwstrb <= s_pwstrb;
				m_pprot <= s_pprot;
				m_pready <= 1;
			end else begin
				m_pready <= 0;
			end
			if (m_pready && S_APB_PSEL && S_APB_PENABLE) begin
				m_prdata <= s_prdata;
				m_pslverr <= s_pslverr;
			end
		end
	end

	assign M_PRESETn = S_PRESETn;
	assign M_APB_PSEL = s_pready;
	assign M_APB_PENABLE = s_pready;
	assign M_APB_PADDR = s_paddr;
	assign M_APB_PWRITE = s_pwrite;
	assign M_APB_PWDATA = s_pwdata;
	assign M_APB_PWSTRB = s_pwstrb;
	assign M_APB_PPROT = s_pprot;
	assign S_APB_PREADY = m_pready;
	assign S_APB_PRDATA = m_prdata;
	assign S_APB_PSLVERR = m_pslverr;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] in,
    output reg [31:0] out
);

reg [31:0] reg1;
reg [31:0] reg2;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg1 <= 0;
        reg2 <= 0;
        out <= 0;
    end else begin
        reg1 <= in;
        reg2 <= reg1;
        out <= reg2;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] in,
    output reg [31:0] out
);

reg [31:0] reg1;
reg [31:0] reg2;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg1 <= 0;
        reg2 <= 0;
        out <= 0;
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
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] in,
    output reg [31:0] out
);

reg [31:0] reg1;
reg [31:0] reg2;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg1 <= 0;
        reg2 <= 0;
        out <= 0;
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
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] in,
    output reg [31:0] out
);

reg [31:0] reg1;
reg [31:0] reg2;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg1 <= 0;
        reg2 <= 0;
        out <= 0;
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
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_2();

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] in,
    output reg [31:0] out
);

reg [31:0] reg1;
reg [31:0] reg2;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg1 <= 0;
        reg2 <= 0;
        out <= 0;
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
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_2();

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_3();

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_4();

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_5();

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_6();

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_7();

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_8();

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_9();

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_10();

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_11();

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_12();

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_13();

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_14();

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_15();

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_16();

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_17();

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_18();

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_19();

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_20();

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_21();

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_22();

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_23();

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_24();

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_25();

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_26();

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb_27();

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)