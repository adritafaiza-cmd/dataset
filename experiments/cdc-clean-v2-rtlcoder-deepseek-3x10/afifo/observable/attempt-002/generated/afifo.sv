Here is the complete Verilog-2001 code for the asynchronous FIFO module:

```
module afifo #(
		parameter	LGFIFO = 3,
		parameter	WIDTH  = 16,
		parameter	NFF    = 2,
		parameter [0:0]	WRITE_ON_POSEDGE = 1'b1,
		parameter [0:0]	OPT_REGISTER_READS = 1'b1
	) (
		input	wire			i_wclk, i_wr_reset_n, i_wr,
		input	wire	[WIDTH-1:0]	i_wr_data,
		output	reg			o_wr_full,
		input	wire			i_rclk, i_rd_reset_n, i_rd,
		output	reg	[WIDTH-1:0]	o_rd_data,
		output	reg			o_rd_empty
	);

	localparam DEPTH = 1 << LGFIFO;
	localparam ADDR_WIDTH = LGFIFO;

	reg [WIDTH-1:0] mem [0:DEPTH-1];
	reg [ADDR_WIDTH-1:0] wr_ptr;
	reg [ADDR_WIDTH-1:0] rd_ptr;
	reg [ADDR_WIDTH-1:0] next_wr_ptr;
	reg [ADDR_WIDTH-1:0] next_rd_ptr;
	reg [ADDR_WIDTH-1:0] wr_ptr_ff [0:NFF-1];
	reg [ADDR_WIDTH-1:0] rd_ptr_ff [0:NFF-1];

	assign o_wr_full = (next_wr_ptr == rd_ptr_ff[NFF-1]);
	assign o_rd_empty = (wr_ptr_ff[NFF-1] == next_rd_ptr);

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= {ADDR_WIDTH{1'b0}};
			next_wr_ptr <= {ADDR_WIDTH{1'b0}};
			wr_ptr_ff <= {ADDR_WIDTH{1'b0}};
		end else begin
			wr_ptr <= next_wr_ptr;
			next_wr_ptr <= (wr_ptr == DEPTH-1) ? {ADDR_WIDTH{1'b0}} : wr_ptr + 1;
			wr_ptr_ff[0] <= next_wr_ptr;
			for (int i = 1; i < NFF; i = i + 1) begin
				wr_ptr_ff[i] <= wr_ptr_ff[i-1];
			end
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= {ADDR_WIDTH{1'b0}};
			next_rd_ptr <= {ADDR_WIDTH{1'b0}};
			rd_ptr_ff <= {ADDR_WIDTH{1'b0}};
		end else begin
			rd_ptr <= next_rd_ptr;
			next_rd_ptr <= (rd_ptr == DEPTH-1) ? {ADDR_WIDTH{1'b0}} : rd_ptr + 1;
			rd_ptr_ff[0] <= next_rd_ptr;
			for (int i = 1; i < NFF; i = i + 1) begin
				rd_ptr_ff[i] <= rd_ptr_ff[i-1];
			end
		end
	end

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			mem <= '{default: '0};
		end else begin
			if (i_wr && !o_wr_full) begin
				mem[wr_ptr] <= i_wr_data;
			end
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_data <= {WIDTH{1'b0}};
		end else begin
			if (i_rd && !o_rd_empty) begin
				o_rd_data <= mem[rd_ptr];
			end
		end
	end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire reset,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] shift_reg;
    reg [2:0] count;

    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 8'b0;
            count <= 3'b0;
        end else begin
            shift_reg <= {shift_reg[6:0], in};
            count <= count + 1;
        end
    end

    assign out = shift_reg[7];

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire reset,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] shift_reg;
    reg [2:0] count;

    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 8'b0;
            count <= 3'b0;
        end else begin
            shift_reg <= {shift_reg[6:0], in};
            count <= count + 1;
        end
    end

    assign out = shift_reg[7];

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
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 