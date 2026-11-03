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

	reg	[WIDTH-1:0]	ram[2**LGFIFO-1:0];
	reg	[LGFIFO-1:0]	wr_ptr, rd_ptr;
	reg	[LGFIFO:0]	wr_cnt, rd_cnt;
	reg			wr_full, rd_empty;
	reg			wr_sync, rd_sync;
	reg	[NFF-1:0]	wr_sync_ff, rd_sync_ff;

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			wr_cnt <= 0;
			wr_full <= 0;
			wr_sync <= 0;
		end else if (i_wr && !wr_full) begin
			if (WRITE_ON_POSEDGE) begin
				ram[wr_ptr] <= i_wr_data;
				wr_ptr <= wr_ptr + 1;
				wr_cnt <= wr_cnt + 1;
				if (wr_cnt == (2**LGFIFO - 1)) begin
					wr_full <= 1;
				end
			end
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
			rd_cnt <= 0;
			rd_empty <= 1;
		end else if (i_rd && !rd_empty) begin
			if (OPT_REGISTER_READS) begin
				o_rd_data <= ram[rd_ptr];
			end
			rd_ptr <= rd_ptr + 1;
			rd_cnt <= rd_cnt + 1;
			if (rd_cnt == (2**LGFIFO - 1)) begin
				rd_empty <= 1;
			end
		end
	end

	always @(posedge i_wclk) begin
		wr_sync_ff[0] <= i_wr;
		for (int i = 1; i < NFF; i++) begin
			wr_sync_ff[i] <= wr_sync_ff[i-1];
		end
		wr_sync <= wr_sync_ff[NFF-1];
	end

	always @(posedge i_rclk) begin
		rd_sync_ff[0] <= i_rd;
		for (int i = 1; i < NFF; i++) begin
			rd_sync_ff[i] <= rd_sync_ff[i-1];
		end
		rd_sync <= rd_sync_ff[NFF-1];
	end

	always @(posedge i_wclk) begin
		if (WRITE_ON_POSEDGE) begin
			if (i_wr && !wr_full) begin
				wr_sync <= 1;
			end else begin
				wr_sync <= 0;
			end
		end else begin
			if (i_wr && !wr_full) begin
				wr_sync <= 0;
			end else begin
				wr_sync <= 1;
			end
		end
	end

	always @(posedge i_rclk) begin
		if (OPT_REGISTER_READS) begin
			o_rd_empty <= rd_empty;
		end else begin
			o_rd_empty <= (rd_cnt == 0);
		end
	end

	assign o_wr_full = wr_full;

endmodule
