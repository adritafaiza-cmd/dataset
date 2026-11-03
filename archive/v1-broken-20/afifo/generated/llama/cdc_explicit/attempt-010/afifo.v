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

	reg [WIDTH-1:0] mem [2**LGFIFO-1:0];
	reg [LGFIFO-1:0] wptr, rptr;
	reg [LGFIFO-1:0] wptr_gray, rptr_gray;
	reg [LGFIFO-1:0] wptr_sync, rptr_sync;
	reg [NFF-1:0] wr_sync, rd_sync;
	reg wr_en, rd_en;
	reg full, empty;

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wptr <= 0;
			wptr_gray <= 0;
			wr_sync <= 0;
			o_wr_full <= 0;
		end else if (i_wr && !full) begin
			if (WRITE_ON_POSEDGE) begin
				mem[wptr] <= i_wr_data;
				wptr <= wptr + 1;
				wptr_gray <= wptr_gray + 1;
			end
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rptr <= 0;
			rptr_gray <= 0;
			rd_sync <= 0;
			o_rd_empty <= 1;
		end else if (i_rd && !empty) begin
			if (OPT_REGISTER_READS) begin
				o_rd_data <= mem[rptr];
				o_rd_empty <= 0;
			end
			rptr <= rptr + 1;
			rptr_gray <= rptr_gray + 1;
		end
	end

	always @(posedge i_wclk) begin
		wr_sync[0] <= i_wr;
		for (int i = 1; i < NFF; i++) begin
			wr_sync[i] <= wr_sync[i-1];
		end
	end

	always @(posedge i_rclk) begin
		rd_sync[0] <= i_rd;
		for (int i = 1; i < NFF; i++) begin
			rd_sync[i] <= rd_sync[i-1];
		end
	end

	always @(posedge i_wclk) begin
		wptr_sync <= wptr_gray;
	end

	always @(posedge i_rclk) begin
		rptr_sync <= rptr_gray;
	end

	always @(posedge i_wclk) begin
		full <= (wptr == (2**LGFIFO - 1));
	end

	always @(posedge i_rclk) begin
		empty <= (rptr == wptr_sync);
	end

	always @(posedge i_wclk) begin
		o_wr_full <= full;
	end

	always @(posedge i_rclk) begin
		if (OPT_REGISTER_READS) begin
			o_rd_empty <= empty;
		end else begin
			o_rd_empty <= (rptr == wptr_sync);
		end
	end

endmodule
