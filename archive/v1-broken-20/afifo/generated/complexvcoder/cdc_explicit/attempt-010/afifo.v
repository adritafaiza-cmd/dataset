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

	parameter FIFO_SIZE = 2**LGFIFO;
	parameter FIFO_HALF = FIFO_SIZE / 2;

	// Internal signals
	reg [LGFIFO-1:0] wr_ptr;
	reg [LGFIFO-1:0] rd_ptr;
	reg [WIDTH-1:0] mem [0:FIFO_SIZE-1];
	reg [0:0] wr_en;
	reg [0:0] rd_en;
	reg [0:0] wr_full;
	reg [0:0] rd_empty;

	// Write logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			wr_en <= 0;
		end else if (i_wr && !wr_full) begin
			mem[wr_ptr] <= i_wr_data;
			wr_ptr <= wr_ptr + 1;
			wr_en <= 1;
		end else begin
			wr_en <= 0;
		end
		if (wr_ptr == FIFO_SIZE - 1) begin
			wr_full <= 1;
		end else begin
			wr_full <= 0;
		end
	end

	// Read logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
			rd_en <= 0;
		end else if (i_rd && !rd_empty) begin
			o_rd_data <= mem[rd_ptr];
			rd_ptr <= rd_ptr + 1;
			rd_en <= 1;
		end else begin
			rd_en <= 0;
		end
		if (rd_ptr == FIFO_SIZE - 1) begin
			rd_empty <= 1;
		end else begin
			rd_empty <= 0;
		end
	end

	// Assign outputs
	assign o_wr_full = wr_full;
	assign o_rd_empty = rd_empty;

endmodule
