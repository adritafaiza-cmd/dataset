Sure, here is the complete Verilog-2001 code for the pipelined Wishbone clock-domain bridge:

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

	// Pipeline registers
	reg [AW-1:0] wb_addr_reg;
	reg [DW-1:0] wb_data_reg;
	reg [DW/8-1:0] wb_sel_reg;
	reg wb_cyc_reg;
	reg wb_stb_reg;
	reg wb_we_reg;
	reg xclk_cyc_reg;
	reg xclk_stb_reg;
	reg xclk_we_reg;
	reg [AW-1:0] xclk_addr_reg;
	reg [DW-1:0] xclk_data_reg;
	reg [DW/8-1:0] xclk_sel_reg;
	reg xclk_stall_reg;
	reg xclk_ack_reg;
	reg xclk_err_reg;
	reg [DW-1:0] xclk_data_reg_q;
	reg xclk_err_reg_q;

	// FIFO signals
	reg [LGFIFO-1:0] wb_fifo_count;
	reg [LGFIFO-1:0] xclk_fifo_count;
	reg wb_fifo_full;
	reg xclk_fifo_full;
	reg wb_fifo_empty;
	reg xclk_fifo_empty;
	reg wb_fifo_push;
	reg xclk_fifo_push;
	reg wb_fifo_pop;
	reg xclk_fifo_pop;

	// Pipeline registers
	always @(posedge i_wb_clk) begin
		if (i_reset) begin
			wb_addr_reg <= 0;
			wb_data_reg <= 0;
			wb_sel_reg <= 0;
			wb_cyc_reg <= 0;
			wb_stb_reg <= 0;
			wb_we_reg <= 0;
			xclk_cyc_reg <= 0;
			xclk_stb_reg <= 0;
			xclk_we_reg <= 0;
			xclk_addr_reg <= 0;
			xclk_data_reg <= 0;
			xclk_sel_reg <= 0;
			xclk_stall_reg <= 0;
			xclk_ack_reg <= 0;
			xclk_err_reg <= 0;
			xclk_data_reg_q <= 0;
			xclk_err_reg_q <= 0;
		end else begin
			wb_addr_reg <= i_wb_addr;
			wb_data_reg <= i_wb_data;
			wb_sel_reg <= i_wb_sel;
			wb_cyc_reg <= i_wb_cyc;
			wb_stb_reg <= i_wb_stb;
			wb_we_reg <= i_wb_we;
			xclk_cyc_reg <= o_xclk_cyc;
			xclk_stb_reg <= o_xclk_stb;
			xclk_we_reg <= o_xclk_we;
			xclk_addr_reg <= o_xclk_addr;
			xclk_data_reg <= o_xclk_data;
			xclk_sel_reg <= o_xclk_sel;
			xclk_stall_reg <= i_xclk_stall;
			xclk_ack_reg <= i_xclk_ack;
			xclk_err_reg <= i_xclk_err;
			xclk_data_reg_q <= i_xclk_data;
			xclk_err_reg_q <= i_xclk_err;
		end
	end

	// FIFO count
	always @(posedge i_wb_clk) begin
		if (i_reset) begin
			wb_fifo_count <= 0;
			xclk_fifo_count <= 0;
		end else begin
			if (wb_fifo_push && !wb_fifo_pop) begin
				wb_fifo_count <= wb_fifo_count + 1;
			end
			if (xclk_fifo_push && !xclk_fifo_pop) begin
				xclk_fifo_count <= xclk_fifo_count + 1;
			end
			if (!wb_fifo_push && wb_fifo_pop) begin
				wb_fifo_count <= wb_fifo_count - 1;
			end
			if (!xclk_fifo_push && xclk_fifo_pop) begin
				xclk_fifo_count <= xclk_fifo_count - 1;
			end
		end
	end

	// FIFO full/empty signals
	assign wb_fifo_full = (wb_fifo_count == (1 << LGFIFO));
	assign xclk_fifo_full = (xclk_fifo_count == (1 << LGFIFO));
	assign wb_fifo_empty = (wb_fifo_count == 0);
	assign xclk_fifo_empty = (xclk_fifo_count == 0);

	// FIFO push/pop signals
	always @(posedge i_wb_clk) begin
		if (i_reset) begin
			wb_fifo_push <= 0;
			xclk_fifo_push <= 0;
		end else begin
			if (!wb_fifo_full && wb_cyc_reg && wb_stb_reg && !wb_fifo_empty) begin
				wb_fifo_push <= 1;
			end else begin
				wb_fifo_push <= 0;
			end
			if (!xclk_fifo_full && xclk_cyc_reg && xclk_stb_reg && !xclk_fifo_empty) begin
				xclk_fifo_push <= 1;
			end else begin
				xclk_fifo_push <= 0;
			end
		end
	end

	// FIFO pop signals
	always @(posedge i_wb_clk) begin
		if (i_reset) begin
			wb_fifo_pop <= 0;
			xclk_fifo_pop <= 0;
		end else begin
			if (wb_fifo_full && !wb_fifo_empty) begin
				wb_fifo_pop <= 1;
			end else begin
				wb_fifo_pop <= 0;
			end
			if (xclk_fifo_full && !xclk_fifo_empty) begin
				xclk_fifo_pop <= 1;
			end else begin
				xclk_fifo_pop <= 0;
			end
		end
	end

	// Wishbone to Xilinx clock domain bridge
	always @(posedge i_wb_clk) begin
		if (i_reset) begin
			o_wb_ack <= 0;
			o_wb_data <= 0;
			o_wb_err <= 0;
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			if (wb_cyc_reg && wb_stb_reg && !wb_fifo_full) begin
				wb_fifo_push <= 1;
			end
			if (xclk_cyc_reg && xclk_stb_reg && !xclk_fifo_full) begin
				xclk_fifo_push <= 1;
			end
			if (!wb_fifo_empty) begin
				o_wb_ack <= 1;
				o_wb_data <= wb_data_reg;
				o_wb_err <= 0;
				wb_fifo_pop <= 1;
			end else begin
				o_wb_ack <= 0;
				o_wb_data <= 0;
				o_wb_err <= 0;
			end
			if (!xclk_fifo_empty) begin
				o_xclk_cyc <= 1;
				o_xclk_stb <= 1;
				o_xclk_we <= xclk_we_reg;
				o_xclk_addr <= xclk_addr_reg;
				o_xclk_data <= xclk_data_reg;
				o_xclk_sel <= xclk_sel_reg;
				xclk_fifo_pop <= 1;
			end else begin
				o_xclk_cyc <= 0;
				o_xclk_stb <= 0;
				o_xclk_we <= 0;
				o_xclk_addr <= 0;
				o_xclk_data <= 0;
				o_xclk_sel <= 0;
			end
		end
	end

	// Xilinx to Wishbone clock domain bridge
	always @(posedge i_xclk_clk) begin
		if (i_reset) begin
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
			xclk_cyc_reg <= 0;
			xclk_stb_reg <= 0;
			xclk_we_reg <= 0;
			xclk_addr_reg <= 0;
			xclk_data_reg <= 0;
			xclk_sel_reg <= 0;
			xclk_stall_reg <= 0;
			xclk_ack_reg <= 0;
			xclk_err_reg <= 0;
			xclk_data_reg_q <= 0;
			xclk_err_reg_q <= 0;
		end else begin
			if (xclk_cyc_reg && xclk_stb_reg && !xclk_fifo_full) begin
				xclk_fifo_push <= 1;
			end
			if (!xclk_fifo_empty) begin
				o_xclk_cyc <= 1;
				o_xclk_stb <= 1;
				o_xclk_we <= xclk_we_reg;
				o_xclk_addr <= xclk_addr_reg;
				o_xclk_data <= xclk_data_reg;
				o_xclk_sel <= xclk_sel_reg;
				xclk_fifo_pop <= 1;
			end else begin
				o_xclk_cyc <= 0;
				o_xclk_stb <= 0;
				o_xclk_we <= 0;
				o_xclk_addr <= 0;
				o_xclk_data <= 0;
				o_xclk_sel <= 0;
			end
			if (xclk_ack_reg) begin
				xclk_data_reg_q <= xclk_data_reg;
				xclk_err_reg_q <= xclk_err_reg;
			end
			if (xclk_stall_reg) begin
				xclk_cyc_reg <= 0;
				xclk_stb_reg <= 0;
				xclk_we_reg <= 0;
				xclk_addr_reg <= 0;
				xclk_data_reg <= 0;
				xclk_sel_reg <= 0;
			end else begin
				xclk_cyc_reg <= o_xclk_cyc;
				xclk_stb_reg <= o_xclk_stb;
				xclk_we_reg <= o_xclk_we;
				xclk_addr_reg <= o_xclk_addr;
				xclk_data_reg <= o_xclk_data;
				xclk_sel_reg <= o_xclk_sel;
			end
		end
	end

	// Wishbone stall signal
	assign o_wb_stall = wb_fifo_full;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
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
            count <= 3'b0;
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
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
            count <= 3'b0;
        end
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
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
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
            count <= 3'b0;
        end
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
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
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
            count <= 3'b0;
        end
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
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

always #5 clk = ~clk;

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
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

always #5 clk = ~clk;

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
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

always #5 clk = ~clk;

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
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

always #5 clk = ~clk;

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
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

always #5 clk = ~clk;

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
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

always #5 clk = ~clk;

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
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

always #5 clk = ~clk;

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
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

always #5 clk = ~clk;

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
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

always #5 clk = ~clk;

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
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

always #5 clk = ~clk;

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
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

always #5 clk = ~clk;

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
    #10 in = 8'b10101010;
    #10 in = 8'b01010101;
    #10 in = 8'b11001100;
    #10 in = 8'b00110011;
    #10 in = 8'b11110000;
    #10 in = 8'b00001111;
    #10 $finish;
end

always #5 clk = ~clk;

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
    #10 in = 8'b10101010;