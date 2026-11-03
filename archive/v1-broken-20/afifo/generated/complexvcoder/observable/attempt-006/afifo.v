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

	localparam [LGFIFO+1:0] ADDR_WIDTH = LGFIFO + 1;

	// Internal signals
	reg [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
	reg [WIDTH-1:0] mem [0:FIFO_SIZE-1];
	reg wr_clk_crossed_wr, rd_clk_crossed_rd;

	// Write clock domain crossing
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			wr_clk_crossed_wr <= 0;
		end else begin
			wr_clk_crossed_wr <= i_wr;
			if (WRITE_ON_POSEDGE) begin
				if (i_wr) begin
					wr_ptr <= wr_ptr + 1;
				end
			end else begin
				if (i_wr) begin
					wr_ptr <= wr_ptr + 1;
				end
			end
		end
	end

	// Read clock domain crossing
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
			rd_clk_crossed_rd <= 0;
		end else begin
			rd_clk_crossed_rd <= i_rd;
			if (i_rd) begin
				rd_ptr <= rd_ptr + 1;
			end
		end
	end

	// FIFO logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			o_wr_full <= 0;
		end else begin
			if (WRITE_ON_POSEDGE) begin
				if (i_wr && !o_wr_full) begin
					mem[wr_ptr] <= i_wr_data;
				end
			end else begin
				if (i_wr && !o_wr_full) begin
					mem[wr_ptr] <= i_wr_data;
				end
			end
			if (wr_ptr == rd_ptr) begin
				o_wr_full <= 1;
			end else begin
				o_wr_full <= 0;
			end
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_empty <= 1;
			o_rd_data <= 0;
		end else begin
			if (i_rd && !o_rd_empty) begin
				o_rd_data <= mem[rd_ptr];
			end
			if (wr_ptr == rd_ptr) begin
				o_rd_empty <= 1;
			end else begin
				o_rd_empty <= 0;
			end
		end
	end

endmodule
