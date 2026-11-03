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
	localparam ADDR_WIDTH = $clog2(FIFO_SIZE);

	reg [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
	reg [WIDTH-1:0] mem [0:FIFO_SIZE-1];
	reg [0:0] full, empty;

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			full <= 0;
		end else begin
			if (i_wr && !full) begin
				mem[wr_ptr] <= i_wr_data;
				wr_ptr <= wr_ptr + 1;
				full <= (wr_ptr == rd_ptr);
			end
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
			empty <= 1;
		end else begin
			if (i_rd && !empty) begin
				rd_ptr <= rd_ptr + 1;
				empty <= (wr_ptr == rd_ptr);
			end
		end
	end

	assign o_wr_full = full;
	assign o_rd_empty = empty;

	generate
		if (OPT_REGISTER_READS) begin : reg_reads
			reg [WIDTH-1:0] rd_data_reg;
			always @(posedge i_rclk or negedge i_rd_reset_n) begin
				if (!i_rd_reset_n)
					rd_data_reg <= 0;
				else if (i_rd && !empty)
					rd_data_reg <= mem[rd_ptr];
			end
			assign o_rd_data = rd_data_reg;
		end else begin : non_reg_reads
			assign o_rd_data = mem[rd_ptr];
		end
	endgenerate

endmodule
