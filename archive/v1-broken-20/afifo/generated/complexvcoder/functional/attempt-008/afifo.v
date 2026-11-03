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

	localparam FIFO_SIZE = 1 << LGFIFO;
	localparam ADDR_WIDTH = LGFIFO;
	localparam FULL = FIFO_SIZE - 1;

	reg [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
	reg [WIDTH-1:0] mem [0:FIFO_SIZE-1];
	reg [NFF-1:0] wr_cnt, rd_cnt;

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			wr_cnt <= 0;
		end else if (i_wr && !o_wr_full) begin
			mem[wr_ptr] <= i_wr_data;
			wr_ptr <= wr_ptr + 1;
			wr_cnt <= wr_cnt + 1;
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
			rd_cnt <= 0;
		end else if (i_rd && !o_rd_empty) begin
			rd_ptr <= rd_ptr + 1;
			rd_cnt <= rd_cnt - 1;
		end
	end

	assign o_wr_full = (wr_cnt == FULL);
	assign o_rd_empty = (rd_cnt == 0);

	assign o_rd_data = (OPT_REGISTER_READS) ? mem[rd_ptr] : mem[rd_ptr + 1];

endmodule
