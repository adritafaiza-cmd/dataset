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

	localparam FIFO_DEPTH = 2**LGFIFO;

	// Internal signals
	reg [LGFIFO-1:0] wr_ptr, rd_ptr;
	reg [WIDTH-1:0] mem [0:FIFO_DEPTH-1];
	reg wr_en, rd_en;
	wire [LGFIFO-1:0] wr_next, rd_next;

	// Write logic
	assign wr_next = (wr_ptr + 1) % FIFO_DEPTH;
	assign wr_en = i_wr && o_wr_full == 1'b0;

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			o_wr_full <= 1'b0;
		end else if (wr_en) begin
			mem[wr_ptr] <= i_wr_data;
			wr_ptr <= wr_next;
			o_wr_full <= wr_next == rd_ptr;
		end
	end

	// Read logic
	assign rd_next = (rd_ptr + 1) % FIFO_DEPTH;
	assign rd_en = i_rd && o_rd_empty == 1'b0;

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
			o_rd_empty <= 1'b1;
			o_rd_data <= 0;
		end else if (rd_en) begin
			o_rd_data <= mem[rd_ptr];
			rd_ptr <= rd_next;
			o_rd_empty <= rd_next == wr_ptr;
		end
	end

endmodule
