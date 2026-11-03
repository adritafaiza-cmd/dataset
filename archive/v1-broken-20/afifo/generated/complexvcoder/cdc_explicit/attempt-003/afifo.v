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

	parameter FIFO_SIZE = 1 << LGFIFO;

	localparam [LGFIFO:0] ADDR_WIDTH = LGFIFO + 1;
	localparam [ADDR_WIDTH-1:0] FULL_MASK = {1'b0, {(ADDR_WIDTH-1){1'b1}}};
	localparam [ADDR_WIDTH-1:0] EMPTY_MASK = {1'b1, {(ADDR_WIDTH-1){1'b0}}};

	reg [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
	reg [WIDTH-1:0] mem [0:FIFO_SIZE-1];
	reg wr_valid, rd_valid;

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			rd_ptr <= 0;
			wr_valid <= 0;
			rd_valid <= 0;
			o_wr_full <= 0;
		end else begin
			if (WRITE_ON_POSEDGE && i_wr && !o_wr_full) begin
				mem[wr_ptr] <= i_wr_data;
				wr_ptr <= wr_ptr + 1;
				wr_valid <= 1;
			end else if (!WRITE_ON_POSEDGE && i_wr && !o_wr_full) begin
				mem[wr_ptr] <= i_wr_data;
				wr_ptr <= wr_ptr + 1;
				wr_valid <= 1;
			end

			if (i_rd && !o_rd_empty) begin
				rd_ptr <= rd_ptr + 1;
				rd_valid <= 1;
			end

			o_wr_full <= (wr_ptr + 1 == rd_ptr) || (wr_ptr == 0 && rd_ptr == FULL_MASK);
			o_rd_empty <= wr_ptr == rd_ptr;
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_data <= 0;
		end else begin
			if (OPT_REGISTER_READS) begin
				o_rd_data <= mem[rd_ptr];
			end else begin
				o_rd_data <= mem[rd_ptr];
			end
		end
	end

endmodule
