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

	localparam DEPTH = 1 << LGFIFO;
	localparam ADDR_W = LGFIFO;
	localparam CNT_W = LGFIFO + 1;
	localparam GRAY_W = LGFIFO + 1;

	// Write side
	reg [ADDR_W-1:0] w_addr;
	reg [ADDR_W-1:0] w_addr_gray;
	reg [CNT_W-1:0]  w_count;
	reg [WIDTH-1:0]  mem [0:DEPTH-1];

	// Read side
	reg [ADDR_W-1:0] r_addr;
	reg [ADDR_W-1:0] r_addr_gray;
	reg [CNT_W-1:0]  r_count;
	reg [WIDTH-1:0]  r_data_reg;
	reg              r_data_valid;

	// Synchronizers
	reg [GRAY_W-1:0] w_gray_rsync [0:NFF-1];
	reg [GRAY_W-1:0] r_gray_wsync [0:NFF-1];

	// Binary to Gray
	function [GRAY_W-1:0] bin2gray;
		input [CNT_W-1:0] bin;
		begin
			bin2gray = (bin >> 1) ^ bin;
		end
	endfunction

	// Gray to Binary
	function [CNT_W-1:0] gray2bin;
		input [GRAY_W-1:0] gray;
		reg [CNT_W-1:0]   bin;
		integer i;
		begin
			bin[GRAY_W-1] = gray[GRAY_W-1];
			for (i = GRAY_W-2; i >= 0; i = i - 1)
				bin[i] = gray[i] ^ bin[i+1];
			gray2bin = bin;
		end
	endfunction

	// Write clock domain
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			w_addr      <= {ADDR_W{1'b0}};
			w_addr_gray <= {GRAY_W{1'b0}};
			w_count     <= {CNT_W{1'b0}};
			o_wr_full   <= 1'b0;
		end else begin
			if (i_wr && !o_wr_full) begin
				mem[w_addr] <= i_wr_data;
				w_addr <= w_addr + 1'b1;
				w_count <= w_count + 1'b1;
			end
			w_addr_gray <= bin2gray(w_addr);
			o_wr_full   <= (w_count == DEPTH);
		end
	end

	// Read clock domain
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			r_addr       <= {ADDR_W{1'b0}};
			r_addr_gray  <= {GRAY_W{1'b0}};
			r_count      <= {CNT_W{1'b0}};
			r_data_reg   <= {WIDTH{1'b0}};
			r_data_valid <= 1'b0;
			o_rd_empty   <= 1'b1;
			o_rd_data    <= {WIDTH{1'b0}};
		end else begin
			// Read from memory
			if (i_rd && !o_rd_empty) begin
				r_data_reg   <= mem[r_addr];
				r_data_valid <= 1'b1;
				r_addr       <= r_addr + 1'b1;
				r_count      <= r_count + 1'b1;
			end else begin
				r_data_valid <= 1'b0;
			end

			r_addr_gray <= bin2gray(r_addr);
			o_rd_empty  <= (r_count == 0);

			if (OPT_REGISTER_READS) begin
				if (r_data_valid)
					o_rd_data <= r_data_reg;
			end else begin
				o_rd_data <= mem[r_addr];
			end
		end
	end

	// Synchronize write gray pointer to read domain
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			w_gray_rsync[0] <= {GRAY_W{1'b0}};
			w_gray_rsync[1] <= {GRAY_W{1'b0}};
			if (NFF > 2) begin
				w_gray_rsync[2] <= {GRAY_W{1'b0}};
				if (NFF > 3) begin
					w_gray_rsync[3] <= {GRAY_W{1'b0}};
					if (NFF > 4) begin
						w_gray_rsync[4] <= {GRAY_W{1'b0}};
						if (NFF > 5) begin
							w_gray_rsync[5] <= {GRAY_W{1'b0}};
							if (NFF > 6) begin
								w_gray_rsync[6] <= {GRAY_W{1'b0}};
								if (NFF > 7) begin
									w_gray_rsync[7] <= {GRAY_W{1'b0}};
								end
							end
						end
					end
				end
			end
		end else begin
			w_gray_rsync[0] <= w_addr_gray;
			w_gray_rsync[1] <= w_gray_rsync[0];
			if (NFF > 2) begin
				w_gray_rsync[2] <= w_gray_rsync[1];
				if (NFF > 3) begin
					w_gray_rsync[3] <= w_gray_rsync[2];
					if (NFF > 4) begin
						w_gray_rsync[4] <= w_gray_rsync[3];
						if (NFF > 5) begin
							w_gray_rsync[5] <= w_gray_rsync[4];
							if (NFF > 6) begin
								w_gray_rsync[6] <= w_gray_rsync[5];
								if (NFF > 7) begin
									w_gray_rsync[7] <= w_gray_rsync[6];
								end
							end
						end
					end
				end
			end
		end
	end

	// Synchronize read gray pointer to write domain
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			r_gray_wsync[0] <= {GRAY_W{1'b0}};
			r_gray_wsync[1] <= {GRAY_W{1'b0}};
			if (NFF > 2) begin
				r_gray_wsync[2] <= {GRAY_W{1'b0}};
				if (NFF > 3) begin
					r_gray_wsync[3] <= {GRAY_W{1'b0}};
					if (NFF > 4) begin
						r_gray_wsync[4] <= {GRAY_W{1'b0}};
						if (NFF > 5) begin
							r_gray_wsync[5] <= {GRAY_W{1'b0}};
							if (NFF > 6) begin
								r_gray_wsync[6] <= {GRAY_W{1'b0}};
								if (NFF > 7) begin
									r_gray_wsync[7] <= {GRAY_W{1'b0}};
								end
							end
						end
					end
				end
			end
		end else begin
			r_gray_wsync[0] <= r_addr_gray;
			r_gray_wsync[1] <= r_gray_wsync[0];
			if (NFF > 2) begin
				r_gray_wsync[2] <= r_gray_wsync[1];
				if (NFF > 3) begin
					r_gray_wsync[3] <= r_gray_wsync[2];
					if (NFF > 4) begin
						r_gray_wsync[4] <= r_gray_wsync[3];
						if (NFF > 5) begin
							r_gray_wsync[5] <= r_gray_wsync[4];
							if (NFF > 6) begin
								r_gray_wsync[6] <= r_gray_wsync[5];
								if (NFF > 7) begin
									r_gray_wsync[7] <= r_gray_wsync[6];
								end
							end
						end
					end
				end
			end
		end
	end

endmodule
