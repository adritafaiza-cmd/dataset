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

	reg [WIDTH-1:0]	ram[2**LGFIFO-1:0];
	reg [LGFIFO-1:0]	wr_ptr, rd_ptr;
	reg [LGFIFO-1:0]	wr_ptr_gray, rd_ptr_gray;
	reg [LGFIFO-1:0]	wr_ptr_sync, rd_ptr_sync;
	reg [LGFIFO-1:0]	wr_ptr_sync_gray, rd_ptr_sync_gray;
	reg			wr_en, rd_en;
	reg			wr_full, rd_empty;
	reg [NFF-1:0]	wr_sync;
	reg [NFF-1:0]	rd_sync;
	reg [NFF-1:0]	wr_reset_sync;
	reg [NFF-1:0]	rd_reset_sync;

	always @(posedge i_wclk) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			wr_ptr_gray <= 0;
			wr_sync <= 0;
			wr_reset_sync <= 0;
		end else begin
			wr_reset_sync <= {wr_reset_sync[NFF-2:0], ~i_wr_reset_n};
			if (wr_reset_sync[NFF-1]) begin
				wr_ptr <= 0;
				wr_ptr_gray <= 0;
			end
			if (i_wr && !o_wr_full) begin
				if (WRITE_ON_POSEDGE) begin
					ram[wr_ptr] <= i_wr_data;
					wr_ptr <= wr_ptr + 1;
					wr_ptr_gray <= wr_ptr_gray + 1;
				end else begin
					ram[wr_ptr] <= i_wr_data;
					wr_ptr <= wr_ptr + 1;
					wr_ptr_gray <= wr_ptr_gray + 1;
				end
			end
			wr_sync <= {wr_sync[NFF-2:0], i_wr};
		end
	end

	always @(posedge i_rclk) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
			rd_ptr_gray <= 0;
			rd_sync <= 0;
			rd_reset_sync <= 0;
		end else begin
			rd_reset_sync <= {rd_reset_sync[NFF-2:0], ~i_rd_reset_n};
			if (rd_reset_sync[NFF-1]) begin
				rd_ptr <= 0;
				rd_ptr_gray <= 0;
			end
			if (i_rd && !o_rd_empty) begin
				rd_ptr <= rd_ptr + 1;
				rd_ptr_gray <= rd_ptr_gray + 1;
			end
			rd_sync <= {rd_sync[NFF-2:0], i_rd};
		end
	end

	always @(posedge i_wclk) begin
		if (!i_wr_reset_n) begin
			wr_ptr_sync <= 0;
			wr_ptr_sync_gray <= 0;
		end else begin
			wr_ptr_sync <= wr_ptr;
			wr_ptr_sync_gray <= wr_ptr_gray;
		end
	end

	always @(posedge i_rclk) begin
		if (!i_rd_reset_n) begin
			rd_ptr_sync <= 0;
			rd_ptr_sync_gray <= 0;
		end else begin
			rd_ptr_sync <= rd_ptr;
			rd_ptr_sync_gray <= rd_ptr_gray;
		end
	end

	always @(posedge i_wclk) begin
		if (!i_wr_reset_n) begin
			o_wr_full <= 0;
		end else begin
			if (wr_ptr_sync == (2**LGFIFO - 1)) begin
				o_wr_full <= 1;
			end else begin
				o_wr_full <= 0;
			end
		end
	end

	always @(posedge i_rclk) begin
		if (!i_rd_reset_n) begin
			o_rd_empty <= 1;
			if (OPT_REGISTER_READS) begin
				o_rd_data <= 0;
			end
		end else begin
			if (rd_ptr_sync == wr_ptr_sync) begin
				o_rd_empty <= 1;
			end else begin
				o_rd_empty <= 0;
			end
			if (OPT_REGISTER_READS) begin
				if (i_rd && !o_rd_empty) begin
					o_rd_data <= ram[rd_ptr_sync];
				end
			end
		end
	end

	always @(*) begin
		if (!OPT_REGISTER_READS) begin
			if (rd_ptr_sync == wr_ptr_sync) begin
				o_rd_data <= 0;
			end else begin
				o_rd_data <= ram[rd_ptr_sync];
			end
		end
	end

endmodule
