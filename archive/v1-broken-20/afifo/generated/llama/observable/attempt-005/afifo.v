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
	reg [LGFIFO-1:0] wptr, rptr, wptr_gray, rptr_gray;
	reg [LGFIFO-1:0] wptr_bin, rptr_bin;
	reg [LGFIFO:0]  wcnt, rcnt;
	reg full, empty;
	wire wclk, rclk;

	assign wclk = i_wclk;
	assign rclk = i_rclk;

	always @(posedge wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wptr <= 0;
			wcnt <= 0;
			o_wr_full <= 1'b0;
		end else if (i_wr && !full) begin
			if (WRITE_ON_POSEDGE) begin
				mem[wptr] <= i_wr_data;
			end
			wptr <= wptr + 1;
			wcnt <= wcnt + 1;
		end
	end

	always @(posedge wclk) begin
		if (wcnt == (2**LGFIFO)) begin
			o_wr_full <= 1'b1;
		end else begin
			o_wr_full <= 1'b0;
		end
	end

	always @(posedge rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rptr <= 0;
			rcnt <= 0;
			o_rd_empty <= 1'b1;
		end else if (i_rd && !empty) begin
			if (OPT_REGISTER_READS) begin
				o_rd_data <= mem[rptr];
			end
			rptr <= rptr + 1;
			rcnt <= rcnt + 1;
		end
	end

	always @(posedge rclk) begin
		if (rcnt == 0) begin
			o_rd_empty <= 1'b1;
		end else begin
			o_rd_empty <= 1'b0;
		end
	end

	always @(posedge rclk) begin
		if (OPT_REGISTER_READS) begin
			o_rd_data <= mem[rptr];
		end
	end

	always @(posedge wclk) begin
		wptr_gray <= wptr;
		wptr_bin <= wptr;
	end

	always @(posedge rclk) begin
		rptr_gray <= rptr;
		rptr_bin <= rptr;
	end

	always @(posedge wclk) begin
		if (wptr_bin == (2**LGFIFO)) begin
			full <= 1'b1;
		end else begin
			full <= 1'b0;
		end
	end

	always @(posedge rclk) begin
		if (rptr_bin == 0) begin
			empty <= 1'b1;
		end else begin
			empty <= 1'b0;
		end
	end

endmodule
