Here is the complete Verilog code for the pipelined Wishbone clock-domain bridge:

```
module wbxclk #(
		parameter	AW=32,
				DW=32,
				LGFIFO = 5
	) (
		input	wire			i_wb_clk, i_reset,
		input	wire			i_wb_cyc, i_wb_stb, i_wb_we,
		input	wire	[(AW-1):0]	i_wb_addr,
		input	wire	[(DW-1):0]	i_wb_data,
		input	wire	[(DW/8-1):0]	i_wb_sel,
		output	wire			o_wb_stall,
		output	reg			o_wb_ack,
		output	reg	[(DW-1):0]	o_wb_data,
		output	reg			o_wb_err,
		input	wire			i_xclk_clk,
		output	reg			o_xclk_cyc,
		output	reg			o_xclk_stb,
		output	reg			o_xclk_we,
		output	reg	[(AW-1):0]	o_xclk_addr,
		output	reg	[(DW-1):0]	o_xclk_data,
		output	reg	[(DW/8-1):0]	o_xclk_sel,
		input	wire			i_xclk_stall,
		input	wire			i_xclk_ack,
		input	wire	[(DW-1):0]	i_xclk_data,
		input	wire			i_xclk_err
	);

	reg [1:0] wb_state, wb_next_state;
	reg [1:0] xclk_state, xclk_next_state;
	reg [LGFIFO-1:0] wb_fifo_count, wb_fifo_next_count;
	reg [LGFIFO-1:0] xclk_fifo_count, xclk_fifo_next_count;
	reg [DW-1:0] wb_fifo_data, wb_fifo_next_data;
	reg [DW-1:0] xclk_fifo_data, xclk_fifo_next_data;

	// Wishbone state machine
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_state <= 2'b00;
			wb_fifo_count <= 0;
			wb_fifo_data <= 0;
		end else begin
			wb_state <= wb_next_state;
			wb_fifo_count <= wb_fifo_next_count;
			wb_fifo_data <= wb_fifo_next_data;
		end
	end

	always @* begin
		wb_next_state = wb_state;
		wb_fifo_next_count = wb_fifo_count;
		wb_fifo_next_data = wb_fifo_data;
		o_wb_ack = 0;
		o_wb_err = 0;
		o_wb_data = 0;
		o_wb_stall = 0;

		case (wb_state)
			2'b00: begin // Idle
				if (i_wb_cyc && i_wb_stb) begin
					wb_next_state = 2'b01;
					wb_fifo_next_count = wb_fifo_count + 1;
					wb_fifo_next_data = i_wb_data;
				end
			end
			2'b01: begin // Cycle in progress
				if (i_wb_cyc && i_wb_stb) begin
					wb_next_state = 2'b10;
					wb_fifo_next_count = wb_fifo_count + 1;
					wb_fifo_next_data = i_wb_data;
				end else if (i_wb_cyc && !i_wb_stb) begin
					wb_next_state = 2'b00;
					wb_fifo_next_count = wb_fifo_count - 1;
					wb_fifo_next_data = wb_fifo_data;
				end
			end
			2'b10: begin // Cycle complete
				if (i_wb_cyc && i_wb_stb) begin
					wb_next_state = 2'b11;
					wb_fifo_next_count = wb_fifo_count + 1;
					wb_fifo_next_data = i_wb_data;
				end else if (i_wb_cyc && !i_wb_stb) begin
					wb_next_state = 2'b00;
					wb_fifo_next_count = wb_fifo_count - 1;
					wb_fifo_next_data = wb_fifo_data;
				end
			end
			2'b11: begin // Ack in progress
				if (i_wb_cyc && i_wb_stb) begin
					wb_next_state = 2'b11;
					wb_fifo_next_count = wb_fifo_count + 1;
					wb_fifo_next_data = i_wb_data;
				end else if (i_wb_cyc && !i_wb_stb) begin
					wb_next_state = 2'b00;
					wb_fifo_next_count = wb_fifo_count - 1;
					wb_fifo_next_data = wb_fifo_data;
				end
				o_wb_ack = 1;
				o_wb_data = wb_fifo_data;
				o_wb_err = i_xclk_err;
			end
		endcase

		if (wb_fifo_count == 0) begin
			o_wb_stall = 0;
		end else if (wb_fifo_count == (1 << LGFIFO)) begin
			o_wb_stall = 1;
		end
	end

	// Xilinx clock state machine
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			xclk_state <= 2'b00;
			xclk_fifo_count <= 0;
			xclk_fifo_data <= 0;
		end else begin
			xclk_state <= xclk_next_state;
			xclk_fifo_count <= xclk_fifo_next_count;
			xclk_fifo_data <= xclk_fifo_next_data;
		end
	end

	always @* begin
		xclk_next_state = xclk_state;
		xclk_fifo_next_count = xclk_fifo_count;
		xclk_fifo_next_data = xclk_fifo_data;
		o_xclk_cyc = 0;
		o_xclk_stb = 0;
		o_xclk_we = 0;
		o_xclk_addr = 0;
		o_xclk_data = 0;
		o_xclk_sel = 0;

		case (xclk_state)
			2'b00: begin // Idle
				if (i_xclk_ack) begin
					xclk_next_state = 2'b01;
					xclk_fifo_next_count = xclk_fifo_count - 1;
					xclk_fifo_next_data = xclk_fifo_data;
				end
			end
			2'b01: begin // Cycle in progress
				if (i_xclk_ack) begin
					xclk_next_state = 2'b10;
					xclk_fifo_next_count = xclk_fifo_count - 1;
					xclk_fifo_next_data = xclk_fifo_data;
				end else if (!i_xclk_stall) begin
					xclk_next_state = 2'b00;
					xclk_fifo_next_count = xclk_fifo_count + 1;
					xclk_fifo_next_data = i_xclk_data;
				end
			end
			2'b10: begin // Cycle complete
				if (i_xclk_ack) begin
					xclk_next_state = 2'b11;
					xclk_fifo_next_count = xclk_fifo_count - 1;
					xclk_fifo_next_data = xclk_fifo_data;
				end else if (!i_xclk_stall) begin
					xclk_next_state = 2'b00;
					xclk_fifo_next_count = xclk_fifo_count + 1;
					xclk_fifo_next_data = i_xclk_data;
				end
			end
			2'b11: begin // Ack in progress
				if (!i_xclk_stall) begin
					xclk_next_state = 2'b00;
					xclk_fifo_next_count = xclk_fifo_count + 1;
					xclk_fifo_next_data = i_xclk_data;
				end
				o_xclk_cyc = 1;
				o_xclk_stb = 1;
				o_xclk_we = i_wb_we;
				o_xclk_addr = i_wb_addr;
				o_xclk_data = xclk_fifo_data;
				o_xclk_sel = i_wb_sel;
			end
		endcase

		if (xclk_fifo_count == 0) begin
			o_xclk_stb = 0;
		end else if (xclk_fifo_count == (1 << LGFIFO)) begin
			o_xclk_stb = 1;
		end
	end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        out <= shift_reg[7];
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        out <= shift_reg[7];
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
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        out <= shift_reg[7];
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
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        out <= shift_reg[7];
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
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        out <= shift_reg[7];
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
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        out <= shift_reg[7];
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
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        out <= shift_reg[7];
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
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        out <= shift_reg[7];
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
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        out <= shift_reg[7];
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
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        out <= shift_reg[7];
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
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        out <= shift_reg[7];
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
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        out <= shift_reg[7];
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
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        out <= shift_reg[7];
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
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        out <= shift_reg[7];
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
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        out <= shift_reg[7];
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
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], in};
        out <= shift_reg[7];
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
end

always #5 clk = ~clk;

initial begin
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b1