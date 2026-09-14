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

	localparam FIFO_SIZE = 2**LGFIFO;

	// Internal signals
	reg	[WIDTH-1:0]	fifo [0:FIFO_SIZE-1];
	reg	[0:LGFIFO:0]	wptr, rptr;
	reg	[0:LGFIFO:0]	count;

	// Write logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wptr <= 0;
			count <= 0;
			o_wr_full <= 0;
		end else begin
			if (i_wr && !o_wr_full) begin
				fifo[wptr] <= i_wr_data;
				wptr <= wptr + 1;
				count <= count + 1;
				if (count == FIFO_SIZE)
					o_wr_full <= 1;
			end
		end
	end

	// Read logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rptr <= 0;
			count <= 0;
			o_rd_empty <= 1;
		end else begin
			if (i_rd && !o_rd_empty) begin
				o_rd_data <= fifo[rptr];
				rptr <= rptr + 1;
				count <= count - 1;
				if (count == 0)
					o_rd_empty <= 1;
			end
		end
	end

	// Output logic
	assign o_wr_full = (count == FIFO_SIZE);
	assign o_rd_empty = (count == 0);

endmodule
