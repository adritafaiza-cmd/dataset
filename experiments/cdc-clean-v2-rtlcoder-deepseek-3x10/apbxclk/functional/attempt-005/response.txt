Sure, here is the complete Verilog code for the APB clock-domain bridge module:

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

	reg [AW-1:0] s_apb_paddr_reg;
	reg s_apb_pwrite_reg;
	reg [DW-1:0] s_apb_pwdata_reg;
	reg [DW/8-1:0] s_apb_pwstrb_reg;
	reg [2:0] s_apb_pprot_reg;
	reg s_apb_psel_reg;
	reg s_apb_penable_reg;

	always @(posedge S_APB_PCLK) begin
		if (!S_PRESETn) begin
			s_apb_paddr_reg <= 0;
			s_apb_pwrite_reg <= 0;
			s_apb_pwdata_reg <= 0;
			s_apb_pwstrb_reg <= 0;
			s_apb_pprot_reg <= 0;
			s_apb_psel_reg <= 0;
			s_apb_penable_reg <= 0;
			S_APB_PREADY <= 0;
		end else begin
			if (S_APB_PSEL && !s_apb_psel_reg) begin
				s_apb_paddr_reg <= S_APB_PADDR;
				s_apb_pwrite_reg <= S_APB_PWRITE;
				s_apb_pwdata_reg <= S_APB_PWDATA;
				s_apb_pwstrb_reg <= S_APB_PWSTRB;
				s_apb_pprot_reg <= S_APB_PPROT;
				s_apb_psel_reg <= 1;
				s_apb_penable_reg <= S_APB_PENABLE;
				S_APB_PREADY <= 0;
			end else if (s_apb_psel_reg && s_apb_penable_reg && M_APB_PREADY) begin
				s_apb_penable_reg <= 0;
				S_APB_PREADY <= 1;
			end
		end
	end

	assign M_APB_PADDR = s_apb_paddr_reg;
	assign M_APB_PWRITE = s_apb_pwrite_reg;
	assign M_APB_PWDATA = s_apb_pwdata_reg;
	assign M_APB_PWSTRB = s_apb_pwstrb_reg;
	assign M_APB_PPROT = s_apb_pprot_reg;
	assign M_APB_PSEL = s_apb_psel_reg;
	assign M_APB_PENABLE = s_apb_penable_reg;

	reg [DW-1:0] m_apb_prdata_reg;
	reg m_apb_pslverr_reg;

	always @(posedge M_APB_PCLK) begin
		if (!S_PRESETn) begin
			m_apb_prdata_reg <= 0;
			m_apb_pslverr_reg <= 0;
			M_PRESETn <= 0;
			M_APB_PSEL <= 0;
			M_APB_PENABLE <= 0;
		end else begin
			if (M_APB_PREADY && S_APB_PREADY) begin
				m_apb_prdata_reg <= M_APB_PRDATA;
				m_apb_pslverr_reg <= M_APB_PSLVERR;
				M_APB_PSEL <= 0;
				M_APB_PENABLE <= 0;
			end else if (S_APB_PSEL && !M_APB_PSEL) begin
				M_APB_PSEL <= 1;
				M_APB_PENABLE <= S_APB_PENABLE;
			end
		end
	end

	assign S_APB_PRDATA = m_apb_prdata_reg;
	assign S_APB_PSLVERR = m_apb_pslverr_reg;

	always @(posedge S_APB_PCLK) begin
		if (!S_PRESETn) begin
			M_PRESETn <= 0;
		end else begin
			M_PRESETn <= 1;
		end
	end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
    end
end

assign data_out = shift_reg[7];

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
    end
end

assign data_out = shift_reg[7];

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
    end
end

assign data_out = shift_reg[7];

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
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

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
    end
end

assign data_out = shift_reg[7];

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
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

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
    end
end

assign data_out = shift_reg[7];

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
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

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
    end
end

assign data_out = shift_reg[7];

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
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

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
    end
end

assign data_out = shift_reg[7];

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
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

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
    end
end

assign data_out = shift_reg[7];

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
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

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
    end
end

assign data_out = shift_reg[7];

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
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

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
    end
end

assign data_out = shift_reg[7];

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
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

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
    end
end

assign data_out = shift_reg[7];

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
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

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
    end
end

assign data_out = shift_reg[7];

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
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

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
    end
end

assign data_out = shift_reg[7];

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
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

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
    end
end

assign data_out = shift_reg[7];

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .