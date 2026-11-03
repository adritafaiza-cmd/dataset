Sure, here is a Verilog-2001 implementation of a pipelined Wishbone clock-domain bridge. It uses two FIFOs to store incoming and outgoing requests, and two state machines to handle the clock domain crossing.

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

	// FIFOs to store incoming and outgoing requests
	reg [DW-1:0] wb_fifo_data [0:2**LGFIFO-1];
	reg [AW-1:0] wb_fifo_addr [0:2**LGFIFO-1];
	reg [DW/8-1:0] wb_fifo_sel [0:2**LGFIFO-1];
	reg [LGFIFO-1:0] wb_fifo_head;
	reg [LGFIFO-1:0] wb_fifo_tail;
	reg [LGFIFO-1:0] wb_fifo_count;
	reg [LGFIFO-1:0] xclk_fifo_head;
	reg [LGFIFO-1:0] xclk_fifo_tail;
	reg [LGFIFO-1:0] xclk_fifo_count;

	// State machine to handle incoming requests
	reg [1:0] wb_state;
	parameter IDLE = 2'b00, READY = 2'b01, STALL = 2'b10;
	always @(posedge i_wb_clk) begin
		if (i_reset) begin
			wb_state <= IDLE;
			wb_fifo_head <= 0;
			wb_fifo_tail <= 0;
			wb_fifo_count <= 0;
			o_wb_ack <= 0;
			o_wb_err <= 0;
		end else begin
			case (wb_state)
				IDLE: begin
					if (i_wb_cyc && i_wb_stb) begin
						if (wb_fifo_count < 2**LGFIFO) begin
							wb_fifo_data[wb_fifo_head] <= i_wb_data;
							wb_fifo_addr[wb_fifo_head] <= i_wb_addr;
							wb_fifo_sel[wb_fifo_head] <= i_wb_sel;
							wb_fifo_head <= wb_fifo_head + 1;
							wb_fifo_count <= wb_fifo_count + 1;
							wb_state <= READY;
						end else begin
							wb_state <= STALL;
						end
					end
				end
				READY: begin
					if (i_wb_cyc && i_wb_stb) begin
						if (wb_fifo_count < 2**LGFIFO) begin
							wb_fifo_data[wb_fifo_head] <= i_wb_data;
							wb_fifo_addr[wb_fifo_head] <= i_wb_addr;
							wb_fifo_sel[wb_fifo_head] <= i_wb_sel;
							wb_fifo_head <= wb_fifo_head + 1;
							wb_fifo_count <= wb_fifo_count + 1;
						end else begin
							wb_state <= STALL;
						end
					end else begin
						if (wb_fifo_count > 0) begin
							o_wb_ack <= 1;
							o_wb_data <= wb_fifo_data[wb_fifo_tail];
							o_wb_err <= i_xclk_err;
							wb_fifo_tail <= wb_fifo_tail + 1;
							wb_fifo_count <= wb_fifo_count - 1;
							wb_state <= IDLE;
						end else begin
							o_wb_ack <= 0;
							wb_state <= IDLE;
						end
					end
				end
				STALL: begin
					o_wb_ack <= 0;
					if (i_wb_cyc && i_wb_stb) begin
						if (wb_fifo_count < 2**LGFIFO) begin
							wb_fifo_data[wb_fifo_head] <= i_wb_data;
							wb_fifo_addr[wb_fifo_head] <= i_wb_addr;
							wb_fifo_sel[wb_fifo_head] <= i_wb_sel;
							wb_fifo_head <= wb_fifo_head + 1;
							wb_fifo_count <= wb_fifo_count + 1;
							wb_state <= READY;
						end
					end else begin
						wb_state <= IDLE;
					end
				end
			endcase
		end
	end

	// State machine to handle outgoing requests
	reg [1:0] xclk_state;
	parameter IDLE2 = 2'b00, READY2 = 2'b01, STALL2 = 2'b10;
	always @(posedge i_xclk_clk) begin
		if (i_reset) begin
			xclk_state <= IDLE2;
			xclk_fifo_head <= 0;
			xclk_fifo_tail <= 0;
			xclk_fifo_count <= 0;
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			case (xclk_state)
				IDLE2: begin
					if (wb_fifo_count > 0) begin
						o_xclk_cyc <= 1;
						o_xclk_stb <= 1;
						o_xclk_we <= i_wb_we;
						o_xclk_addr <= wb_fifo_addr[xclk_fifo_tail];
						o_xclk_data <= wb_fifo_data[xclk_fifo_tail];
						o_xclk_sel <= wb_fifo_sel[xclk_fifo_tail];
						xclk_fifo_tail <= xclk_fifo_tail + 1;
						xclk_fifo_count <= xclk_fifo_count - 1;
						xclk_state <= READY2;
					end
				end
				READY2: begin
					if (i_xclk_stall) begin
						xclk_state <= STALL2;
					end else if (wb_fifo_count > 0) begin
						o_xclk_cyc <= 1;
						o_xclk_stb <= 1;
						o_xclk_we <= i_wb_we;
						o_xclk_addr <= wb_fifo_addr[xclk_fifo_tail];
						o_xclk_data <= wb_fifo_data[xclk_fifo_tail];
						o_xclk_sel <= wb_fifo_sel[xclk_fifo_tail];
						xclk_fifo_tail <= xclk_fifo_tail + 1;
						xclk_fifo_count <= xclk_fifo_count - 1;
					end else begin
						o_xclk_cyc <= 0;
						o_xclk_stb <= 0;
						xclk_state <= IDLE2;
					end
				end
				STALL2: begin
					o_xclk_cyc <= 0;
					o_xclk_stb <= 0;
					if (wb_fifo_count > 0) begin
						o_xclk_cyc <= 1;
						o_xclk_stb <= 1;
						o_xclk_we <= i_wb_we;
						o_xclk_addr <= wb_fifo_addr[xclk_fifo_tail];
						o_xclk_data <= wb_fifo_data[xclk_fifo_tail];
						o_xclk_sel <= wb_fifo_sel[xclk_fifo_tail];
						xclk_fifo_tail <= xclk_fifo_tail + 1;
						xclk_fifo_count <= xclk_fifo_count - 1;
						xclk_state <= READY2;
					end else begin
						xclk_state <= IDLE2;
					end
				end
			endcase
		end
	end

	// Backpressure flag based on outstanding-request capacity
	assign o_wb_stall = (wb_fifo_count >= 2**LGFIFO);

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] temp;

always @(posedge clk) begin
    if (reset) begin
        temp <= 8'b0;
        out <= 8'b0;
    end else begin
        temp <= in;
        out <= temp;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] temp;

always @(posedge clk) begin
    if (reset) begin
        temp <= 8'b0;
        out <= 8'b0;
    end else begin
        temp <= in;
        out <= temp;
    end
end

endmodule

module testbench();

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

reg [7:0] temp;

always @(posedge clk) begin
    if (reset) begin
        temp <= 8'b0;
        out <= 8'b0;
    end else begin
        temp <= in;
        out <= temp;
    end
end

endmodule

module testbench();

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

reg [7:0] temp;

always @(posedge clk) begin
    if (reset) begin
        temp <= 8'b0;
        out <= 8'b0;
    end else begin
        temp <= in;
        out <= temp;
    end
end

endmodule

module testbench();

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

reg [7:0] temp;

always @(posedge clk) begin
    if (reset) begin
        temp <= 8'b0;
        out <= 8'b0;
    end else begin
        temp <= in;
        out <= temp;
    end
end

endmodule

module testbench();

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

reg [7:0] temp;

always @(posedge clk) begin
    if (reset) begin
        temp <= 8'b0;
        out <= 8'b0;
    end else begin
        temp <= in;
        out <= temp;
    end
end

endmodule

module testbench();

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

reg [7:0] temp;

always @(posedge clk) begin
    if (reset) begin
        temp <= 8'b0;
        out <= 8'b0;
    end else begin
        temp <= in;
        out <= temp;
    end
end

endmodule

module testbench();

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

reg [7:0] temp;

always @(posedge clk) begin
    if (reset) begin
        temp <= 8'b0;
        out <= 8'b0;
    end else begin
        temp <= in;
        out <= temp;
    end
end

endmodule

module testbench();

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

reg [7:0] temp;

always @(posedge clk) begin
    if (reset) begin
        temp <= 8'b0;
        out <= 8'b0;
    end else begin
        temp <= in;
        out <= temp;
    end
end

endmodule

module testbench();

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

reg [7:0] temp;

always @(posedge clk) begin
    if (reset) begin
        temp <= 8'b0;
        out <= 8'b0;
    end else begin
        temp <= in;
        out <= temp;
    end
end

endmodule

module testbench();

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
    #10 in = 8'b