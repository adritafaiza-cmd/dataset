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

	reg [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
	reg [WIDTH-1:0] mem [0:FIFO_SIZE-1];
	reg [ADDR_WIDTH-1:0] wr_next, rd_next;
	wire [ADDR_WIDTH-1:0] wr_diff, rd_diff;

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			o_wr_full <= 0;
		end else begin
			wr_next <= wr_ptr;
			if (i_wr && !o_wr_full) begin
				mem[wr_ptr] <= i_wr_data;
				wr_next <= wr_ptr + 1;
				if (wr_next == FIFO_SIZE) begin
					wr_next <= 0;
				end
				if (wr_next == rd_ptr) begin
					o_wr_full <= 1;
				end
			end
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
			o_rd_empty <= 1;
		end else begin
			rd_next <= rd_ptr;
			if (i_rd && !o_rd_empty) begin
				o_rd_data <= mem[rd_ptr];
				rd_next <= rd_ptr + 1;
				if (rd_next == FIFO_SIZE) begin
					rd_next <= 0;
				end
				o_rd_empty <= (rd_next == wr_ptr);
			end
		end
	end

	assign wr_diff = wr_ptr - rd_ptr;
	assign rd_diff = rd_ptr - wr_ptr;
	assign o_wr_full = (wr_diff == (FIFO_SIZE - 1)) || (wr_next == rd_ptr);
	assign o_rd_empty = (rd_diff == FIFO_SIZE) || (wr_ptr == rd_next);

endmodule
