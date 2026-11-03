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

	reg [1:0] wb_state, xclk_state;
	reg [LGFIFO:0] wb_fifo_count, xclk_fifo_count;
	reg [LGFIFO:0] wb_fifo_ptr, xclk_fifo_ptr;
	reg [LGFIFO:0] wb_fifo_ptr_next, xclk_fifo_ptr_next;
	reg [DW-1:0] wb_fifo [0:(1<<LGFIFO)-1];
	reg [DW-1:0] xclk_fifo [0:(1<<LGFIFO)-1];

	always @(posedge i_wb_clk) begin
		if (i_reset) begin
			wb_state <= 2'b00;
			wb_fifo_count <= 0;
			wb_fifo_ptr <= 0;
			wb_fifo_ptr_next <= 0;
			o_wb_ack <= 0;
			o_wb_err <= 0;
			o_wb_data <= 0;
		end else begin
			case (wb_state)
				2'b00: begin // IDLE
					if (i_wb_cyc && i_wb_stb) begin
						wb_fifo[wb_fifo_ptr] <= {i_wb_we, i_wb_sel, i_wb_addr, i_wb_data};
						wb_fifo_count <= wb_fifo_count + 1;
						wb_fifo_ptr_next <= wb_fifo_ptr + 1;
						wb_state <= 2'b01;
					end
				end
				2'b01: begin // WAIT
					if (wb_fifo_count > 0) begin
						wb_fifo_count <= wb_fifo_count - 1;
						wb_fifo_ptr <= wb_fifo_ptr_next;
						wb_state <= 2'b10;
					end else begin
						wb_state <= 2'b00;
					end
				end
				2'b10: begin // FORWARD
					o_xclk_cyc <= 1;
					o_xclk_stb <= 1;
					o_xclk_we <= wb_fifo[wb_fifo_ptr][DW-1];
					o_xclk_sel <= wb_fifo[wb_fifo_ptr][DW-2:DW-DW/8];
					o_xclk_addr <= wb_fifo[wb_fifo_ptr][AW-1:0];
					o_xclk_data <= wb_fifo[wb_fifo_ptr][DW-1:0];
					o_xclk_sel <= wb_fifo[wb_fifo_ptr][DW-2:DW-DW/8];
					wb_fifo_count <= wb_fifo_count - 1;
					wb_fifo_ptr <= wb_fifo_ptr_next;
					wb_state <= 2'b11;
				end
				2'b11: begin // WAIT ACK
					if (i_xclk_ack) begin
						o_xclk_cyc <= 0;
						o_xclk_stb <= 0;
						o_wb_ack <= 1;
						wb_state <= 2'b00;
					end else if (i_xclk_err) begin
						o_xclk_cyc <= 0;
						o_xclk_stb <= 0;
						o_wb_err <= 1;
						wb_state <= 2'b00;
					end
				end
			endcase
		end
	end

	always @(posedge i_xclk_clk) begin
		if (i_reset) begin
			xclk_state <= 2'b00;
			xclk_fifo_count <= 0;
			xclk_fifo_ptr <= 0;
			xclk_fifo_ptr_next <= 0;
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
		end else begin
			case (xclk_state)
				2'b00: begin // IDLE
					if (i_xclk_cyc && i_xclk_stb) begin
						xclk_fifo[xclk_fifo_ptr] <= {i_xclk_we, i_xclk_sel, i_xclk_addr, i_xclk_data};
						xclk_fifo_count <= xclk_fifo_count + 1;
						xclk_fifo_ptr_next <= xclk_fifo_ptr + 1;
						xclk_state <= 2'b01;
					end
				end
				2'b01: begin // WAIT
					if (xclk_fifo_count > 0) begin
						xclk_fifo_count <= xclk_fifo_count - 1;
						xclk_fifo_ptr <= xclk_fifo_ptr_next;
						xclk_state <= 2'b10;
					end else begin
						xclk_state <= 2'b00;
					end
				end
				2'b10: begin // FORWARD
					o_wb_ack <= 1;
					o_wb_err <= xclk_fifo[xclk_fifo_ptr][DW-1];
					o_wb_data <= xclk_fifo[xclk_fifo_ptr][DW-1:0];
					xclk_fifo_count <= xclk_fifo_count - 1;
					xclk_fifo_ptr <= xclk_fifo_ptr_next;
					xclk_state <= 2'b11;
				end
				2'b11: begin // WAIT ACK
					if (i_wb_ack) begin
						o_wb_ack <= 0;
						xclk_state <= 2'b00;
					end else if (i_wb_err) begin
						o_wb_err <= 0;
						xclk_state <= 2'b00;
					end
				end
			endcase
		end
	end

	assign o_wb_stall = (wb_fifo_count == (1<<LGFIFO));
	assign o_xclk_stall = (xclk_fifo_count == (1<<LGFIFO));

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
        end
    end
end

assign data_out = shift_reg[index];

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
        end
    end
end

assign data_out = shift_reg[index];

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
        end
    end
end

assign data_out = shift_reg[index];

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
        end
    end
end

assign data_out = shift_reg[index];

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
        end
    end
end

assign data_out = shift_reg[index];

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
        end
    end
end

assign data_out = shift_reg[index];

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
        end
    end
end

assign data_out = shift_reg[index];

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
        end
    end
end

assign data_out = shift_reg[index];

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
        end
    end
end

assign data_out = shift_reg[index];

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    output wire [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
        end
    end
end

assign data_out = shift_reg[index];

endmodule