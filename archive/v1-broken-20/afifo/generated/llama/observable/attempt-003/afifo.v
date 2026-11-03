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

	reg [WIDTH-1:0]		mem [2**LGFIFO-1:0];
	reg [LGFIFO-1:0]	wr_ptr, rd_ptr;
	reg [LGFIFO:0]		wr_cnt, rd_cnt;
	wire			wr_en;
	wire			rd_en;

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			wr_cnt <= 0;
			o_wr_full <= 1'b0;
		end else if (i_wr && (WRITE_ON_POSEDGE || !i_wr)) begin
			if (wr_cnt != 2**LGFIFO) begin
				mem[wr_ptr] <= i_wr_data;
				wr_ptr <= wr_ptr + 1;
				wr_cnt <= wr_cnt + 1;
			end
			if (wr_cnt == 2**LGFIFO - 1) begin
				o_wr_full <= 1'b1;
			end
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
			rd_cnt <= 0;
			o_rd_empty <= 1'b1;
		end else if (i_rd) begin
			if (rd_cnt != 0) begin
				if (OPT_REGISTER_READS) begin
					o_rd_data <= mem[rd_ptr];
				end else begin
					o_rd_data = mem[rd_ptr];
				end
				rd_ptr <= rd_ptr + 1;
				rd_cnt <= rd_cnt - 1;
			end
			if (rd_cnt == 1) begin
				o_rd_empty <= 1'b1;
			end
		end
	end

	always @(posedge i_rclk) begin
		if (wr_cnt > rd_cnt) begin
			o_rd_empty <= 1'b0;
		end
	end

endmodule
