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
	localparam FIFO_MASK = FIFO_SIZE - 1;

	// Internal signals
	reg [LGFIFO-1:0] wr_ptr;
	reg [LGFIFO-1:0] rd_ptr;
	reg [WIDTH-1:0] mem [0:FIFO_SIZE-1];
	reg [0:0] wr_cnt;
	reg [0:0] rd_cnt;

	// Write logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			wr_cnt <= 0;
			o_wr_full <= 0;
		end else begin
			if (i_wr && !o_wr_full) begin
				mem[wr_ptr] <= i_wr_data;
				wr_ptr <= wr_ptr + 1;
				wr_cnt <= wr_cnt + 1;
				if (wr_cnt == FIFO_SIZE) begin
					o_wr_full <= 1;
				end
			end
		end
	end

	// Read logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
			rd_cnt <= 0;
			o_rd_empty <= 1;
			o_rd_data <= 0;
		end else begin
			if (i_rd && !o_rd_empty) begin
				o_rd_data <= mem[rd_ptr];
				rd_ptr <= rd_ptr + 1;
				rd_cnt <= rd_cnt - 1;
				if (rd_cnt == 0) begin
					o_rd_empty <= 0;
				end
			end
		end
	end

	// Output flags
	assign o_wr_full = (wr_cnt == FIFO_SIZE);
	assign o_rd_empty = (rd_cnt == 0);

endmodule
