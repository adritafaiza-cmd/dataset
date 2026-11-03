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
	reg wr_ff, rd_ff;

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wptr <= 0;
			wptr_gray <= 0;
			wr_sync <= 0;
			o_wr_full <= 0;
		end else if (i_wr && !o_wr_full) begin
			if (WRITE_ON_POSEDGE) begin
				mem[wptr] <= i_wr_data;
				wptr <= wptr + 1;
				wptr_gray <= (wptr + 1) >> 1;
			end
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rptr <= 0;
			rptr_gray <= 0;
			rd_sync <= 0;
			o_rd_empty <= 1;
			if (OPT_REGISTER_READS) begin
				o_rd_data <= 0;
			end
		end else if (i_rd && !o_rd_empty) begin
			if (OPT_REGISTER_READS) begin
				o_rd_data <= mem[rptr];
			end
			rptr <= rptr + 1;
			rptr_gray <= (rptr + 1) >> 1;
		end
	end

	always @(posedge i_wclk) begin
		wr_sync[0] <= i_wr;
		for (int i = 1; i < NFF; i++) begin
			wr_sync[i] <= wr_sync[i-1];
		end
		wr_ff <= wr_sync[NFF-1];
	end

	always @(posedge i_rclk) begin
		rd_sync[0] <= i_rd;
		for (int i = 1; i < NFF; i++) begin
			rd_sync[i] <= rd_sync[i-1];
		end
		rd_ff <= rd_sync[NFF-1];
	end

	always @(posedge i_wclk) begin
		wptr_sync <= wptr_gray;
	end

	always @(posedge i_rclk) begin
		rptr_sync <= rptr_gray;
	end

	always @(posedge i_rclk) begin
		if (OPT_REGISTER_READS) begin
			o_rd_data <= mem[rptr];
		end
		o_rd_empty <= (rptr_sync == wptr_sync) ? 1'b1 : 1'b0;
	end

	always @(posedge i_wclk) begin
		o_wr_full <= (wptr == (2**LGFIFO - 1)) ? 1'b1 : 1'b0;
	end

endmodule
