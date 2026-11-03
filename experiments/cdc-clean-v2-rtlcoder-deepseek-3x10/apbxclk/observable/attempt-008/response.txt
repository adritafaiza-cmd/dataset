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
	reg s_psel;
	reg s_penable;
	reg [DW-1:0] s_prdata;
	reg s_pslverr;

	reg [AW-1:0] m_paddr;
	reg m_pwrite;
	reg [DW-1:0] m_pwdata;
	reg [DW/8-1:0] m_pwstrb;
	reg [2:0] m_pprot;
	reg m_pready;
	reg m_psel;
	reg m_penable;
	reg [DW-1:0] m_prdata;
	reg m_pslverr;

	always @(posedge S_APB_PCLK) begin
		if (!S_PRESETn) begin
			s_paddr <= 0;
			s_pwrite <= 0;
			s_pwdata <= 0;
			s_pwstrb <= 0;
			s_pprot <= 0;
			s_pready <= 0;
			s_psel <= 0;
			s_penable <= 0;
			s_prdata <= 0;
			s_pslverr <= 0;
		end else begin
			s_paddr <= S_APB_PADDR;
			s_pwrite <= S_APB_PWRITE;
			s_pwdata <= S_APB_PWDATA;
			s_pwstrb <= S_APB_PWSTRB;
			s_pprot <= S_APB_PPROT;
			s_pready <= S_APB_PREADY;
			s_psel <= S_APB_PSEL;
			s_penable <= S_APB_PENABLE;
			s_prdata <= S_APB_PRDATA;
			s_pslverr <= S_APB_PSLVERR;
		end
	end

	always @(posedge M_APB_PCLK) begin
		if (!M_PRESETn) begin
			m_paddr <= 0;
			m_pwrite <= 0;
			m_pwdata <= 0;
			m_pwstrb <= 0;
			m_pprot <= 0;
			m_pready <= 0;
			m_psel <= 0;
			m_penable <= 0;
			m_prdata <= 0;
			m_pslverr <= 0;
		end else begin
			m_paddr <= M_APB_PADDR;
			m_pwrite <= M_APB_PWRITE;
			m_pwdata <= M_APB_PWDATA;
			m_pwstrb <= M_APB_PWSTRB;
			m_pprot <= M_APB_PPROT;
			m_pready <= M_APB_PREADY;
			m_psel <= M_APB_PSEL;
			m_penable <= M_APB_PENABLE;
			m_prdata <= M_APB_PRDATA;
			m_pslverr <= M_APB_PSLVERR;
		end
	end

	always @(posedge S_APB_PCLK) begin
		if (!S_PRESETn) begin
			M_PRESETn <= 0;
			M_APB_PSEL <= 0;
			M_APB_PENABLE <= 0;
			M_APB_PADDR <= 0;
			M_APB_PWRITE <= 0;
			M_APB_PWDATA <= 0;
			M_APB_PWSTRB <= 0;
			M_APB_PPROT <= 0;
		end else begin
			M_PRESETn <= 1;
			M_APB_PSEL <= s_psel;
			M_APB_PENABLE <= s_penable;
			M_APB_PADDR <= s_paddr;
			M_APB_PWRITE <= s_pwrite;
			M_APB_PWDATA <= s_pwdata;
			M_APB_PWSTRB <= s_pwstrb;
			M_APB_PPROT <= s_pprot;
		end
	end

	always @(posedge M_APB_PCLK) begin
		if (!M_PRESETn) begin
			S_APB_PREADY <= 0;
			S_APB_PRDATA <= 0;
			S_APB_PSLVERR <= 0;
		end else begin
			S_APB_PREADY <= m_pready;
			S_APB_PRDATA <= m_prdata;
			S_APB_PSLVERR <= m_pslverr;
		end
	end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        count <= 3'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        count <= count + 1;
        if (count == 3'b111) begin
            out <= shift_reg[7:0];
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        count <= 3'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        count <= count + 1;
        if (count == 3'b111) begin
            out <= shift_reg[7:0];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
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

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        count <= 3'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        count <= count + 1;
        if (count == 3'b111) begin
            out <= shift_reg[7:0];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
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

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        count <= 3'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        count <= count + 1;
        if (count == 3'b111) begin
            out <= shift_reg[7:0];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
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

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        count <= 3'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        count <= count + 1;
        if (count == 3'b111) begin
            out <= shift_reg[7:0];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
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

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        count <= 3'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        count <= count + 1;
        if (count == 3'b111) begin
            out <= shift_reg[7:0];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
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

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        count <= 3'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        count <= count + 1;
        if (count == 3'b111) begin
            out <= shift_reg[7:0];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
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

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        count <= 3'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        count <= count + 1;
        if (count == 3'b111) begin
            out <= shift_reg[7:0];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
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

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        count <= 3'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        count <= count + 1;
        if (count == 3'b111) begin
            out <= shift_reg[7:0];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
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

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        count <= 3'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        count <= count + 1;
        if (count == 3'b111) begin
            out <= shift_reg[7:0];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
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

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] count;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        count <= 3'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        count <= count + 1;
        if (count == 3'b111) begin
            out <= shift_reg[7:0];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] in;
wire [7:0] out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out