Sure, here is a Verilog-2001 implementation of a pipelined Wishbone clock-domain bridge. This implementation uses two FIFOs to store incoming and outgoing requests, and two state machines to handle the clock domain crossing.

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

	localparam	FIFO_DEPTH = 1 << LGFIFO;

	// FIFOs to store incoming and outgoing requests
	reg [DW-1:0] wb_fifo [FIFO_DEPTH-1:0];
	reg [DW-1:0] xclk_fifo [FIFO_DEPTH-1:0];
	reg [LGFIFO-1:0] wb_fifo_head;
	reg [LGFIFO-1:0] wb_fifo_tail;
	reg [LGFIFO-1:0] xclk_fifo_head;
	reg [LGFIFO-1:0] xclk_fifo_tail;

	// State machine to handle incoming requests
	reg [1:0] wb_state;
	localparam IDLE = 2'b00, READY = 2'b01, STALL = 2'b10;
	always @(posedge i_wb_clk) begin
		if (i_reset) begin
			wb_state <= IDLE;
			wb_fifo_head <= 0;
			wb_fifo_tail <= 0;
			o_wb_ack <= 0;
			o_wb_err <= 0;
		end else begin
			case (wb_state)
				IDLE: begin
					if (i_wb_cyc && i_wb_stb) begin
						wb_fifo[wb_fifo_head] <= {i_wb_addr, i_wb_data, i_wb_sel};
						wb_fifo_head <= wb_fifo_head + 1;
						wb_state <= READY;
					end
				end
				READY: begin
					if (i_xclk_stall) begin
						wb_state <= STALL;
					end else if (i_xclk_ack) begin
						wb_fifo_tail <= wb_fifo_tail + 1;
						o_wb_ack <= 1;
						wb_state <= IDLE;
					end
				end
				STALL: begin
					if (!i_xclk_stall) begin
						wb_state <= READY;
					end
				end
			endcase
		end
	end

	// State machine to handle outgoing requests
	reg [1:0] xclk_state;
	localparam IDLE = 2'b00, READY = 2'b01, STALL = 2'b10;
	always @(posedge i_xclk_clk) begin
		if (i_reset) begin
			xclk_state <= IDLE;
			xclk_fifo_head <= 0;
			xclk_fifo_tail <= 0;
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			case (xclk_state)
				IDLE: begin
					if (wb_fifo_head != wb_fifo_tail) begin
						xclk_fifo[xclk_fifo_head] <= wb_fifo[wb_fifo_tail];
						xclk_fifo_head <= xclk_fifo_head + 1;
						wb_fifo_tail <= wb_fifo_tail + 1;
						o_xclk_cyc <= 1;
						o_xclk_stb <= 1;
						o_xclk_we <= xclk_fifo[xclk_fifo_tail][DW-1];
						o_xclk_addr <= xclk_fifo[xclk_fifo_tail][AW-1:0];
						o_xclk_data <= xclk_fifo[xclk_fifo_tail][DW-1:0];
						o_xclk_sel <= xclk_fifo[xclk_fifo_tail][DW/8-1:0];
						xclk_state <= READY;
					end
				end
				READY: begin
					if (i_wb_stall) begin
						xclk_state <= STALL;
					end else if (i_wb_ack) begin
						xclk_fifo_tail <= xclk_fifo_tail + 1;
						o_xclk_cyc <= 0;
						o_xclk_stb <= 0;
						o_xclk_we <= 0;
						o_xclk_addr <= 0;
						o_xclk_data <= 0;
						o_xclk_sel <= 0;
						xclk_state <= IDLE;
					end
				end
				STALL: begin
					if (!i_wb_stall) begin
						xclk_state <= READY;
					end
				end
			endcase
		end
	end

	// Backpressure flag based on outstanding-request capacity
	assign o_wb_stall = (wb_fifo_head - wb_fifo_tail) >= FIFO_DEPTH;

	// Output data and error signals
	always @(posedge i_xclk_clk) begin
		if (i_reset) begin
			o_wb_data <= 0;
			o_wb_err <= 0;
		end else begin
			if (i_wb_cyc && i_wb_stb) begin
				o_wb_data <= i_xclk_data;
				o_wb_err <= i_xclk_err;
			end
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
        shift_reg <= '{8{8'h00}};
        out <= 8'h00;
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
        shift_reg <= '{8{8'h00}};
        out <= 8'h00;
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
    in = 8'h00;
    #10 reset = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

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
        shift_reg <= '{8{8'h00}};
        out <= 8'h00;
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
    in = 8'h00;
    #10 reset = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

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
        shift_reg <= '{8{8'h00}};
        out <= 8'h00;
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
    in = 8'h00;
    #10 reset = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
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
    in = 8'h00;
    #10 reset = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
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
    in = 8'h00;
    #10 reset = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
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
    in = 8'h00;
    #10 reset = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
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
    in = 8'h00;
    #10 reset = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
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
    in = 8'h00;
    #10 reset = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
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
    in = 8'h00;
    #10 reset = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
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
    in = 8'h00;
    #10 reset = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
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
    in = 8'h00;
    #10 reset = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
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
    in = 8'h00;
    #10 reset = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
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
    in = 8'h00;
    #10 reset = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
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
    in = 8'h00;
    #10 reset = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
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
    in = 8'h00;
    #10 reset = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
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
    in = 8'h00;
    #10 reset = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
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
    in = 8'h00;
    #10 reset = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
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
    in = 8'h00;
    #10 reset = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
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
    in = 8'h00;
    #10 reset = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
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
    in = 8'h00;
    #10 reset = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
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
    in = 8'h00;
    #10 reset = 0;
    #10 in = 8'h01;
    #10 in = 8'h02;
    #10 in = 8'h03;
    #10 in = 8'h04;
    #10 in = 8'h05;
    #10 in = 8'h06;
    #10 in = 8'h07;
    #10 in = 8'h08;
    #10 in = 8'h09;
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