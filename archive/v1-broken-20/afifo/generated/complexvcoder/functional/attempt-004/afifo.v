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

	// Internal signals
	localparam FIFO_SIZE = 2**LGFIFO;
	localparam ADDR_WIDTH = LGFIFO;
	wire [ADDR_WIDTH-1:0] wr_ptr, rd_ptr, wr_ptr_next, rd_ptr_next;
	wire [WIDTH-1:0] mem [0:FIFO_SIZE-1];
	wire [ADDR_WIDTH:0] count;

	// Write pointer logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
		end else if (i_wr && !o_wr_full) begin
			wr_ptr <= wr_ptr_next;
		end
	end

	assign wr_ptr_next = (wr_ptr + 1) % FIFO_SIZE;

	// Read pointer logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
		end else if (i_rd && !o_rd_empty) begin
			rd_ptr <= rd_ptr_next;
		end
	end

	assign rd_ptr_next = (rd_ptr + 1) % FIFO_SIZE;

	// FIFO full and empty flags
	assign count = wr_ptr - rd_ptr;
	assign o_wr_full = (count == FIFO_SIZE);
	assign o_rd_empty = (count == 0);

	// FIFO memory
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			mem <= '{default: 0};
		end else if (i_wr && !o_wr_full) begin
			mem[wr_ptr] <= i_wr_data;
		end
	end

	// Read data output
	assign o_rd_data = mem[rd_ptr];

endmodule
