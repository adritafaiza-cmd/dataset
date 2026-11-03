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
	reg [LGFIFO:0]	wr_cnt, rd_cnt;
	reg			wr_full, rd_empty;
	wire			wr_en, rd_en;

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			wr_cnt <= 0;
			wr_full <= 1'b0;
		end else if (i_wr && !wr_full) begin
			ram[wr_ptr] <= i_wr_data;
			wr_ptr <= wr_ptr + 1;
			wr_cnt <= wr_cnt + 1;
			if (wr_cnt == (2**LGFIFO)-1) begin
				wr_full <= 1'b1;
			end
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
			rd_cnt <= 0;
			rd_empty <= 1'b1;
		end else if (i_rd && !rd_empty) begin
			if (OPT_REGISTER_READS) begin
				o_rd_data <= ram[rd_ptr];
			end
			rd_ptr <= rd_ptr + 1;
			rd_cnt <= rd_cnt + 1;
			if (rd_cnt == (2**LGFIFO)-1) begin
				rd_empty <= 1'b1;
			end
		end
	end

	always @(posedge i_rclk) begin
		if (OPT_REGISTER_READS) begin
			o_rd_data <= o_rd_data;
		end
	end

	always @(posedge i_wclk) begin
		wr_ptr_gray <= {wr_ptr[LGFIFO-1], wr_ptr[LGFIFO-2:0]};
	end

	generate
		for (genvar i = 0; i < NFF; i = i + 1) begin : sync
			reg [LGFIFO-1:0] sync_reg;
			always @(posedge i_rclk) begin
				sync_reg <= (i == 0) ? wr_ptr_gray : sync_reg;
			end
			assign wr_ptr_sync = (i == NFF-1) ? sync_reg : sync_reg;
		end
	endgenerate

	always @(posedge i_rclk) begin
		rd_ptr_gray <= {rd_ptr[LGFIFO-1], rd_ptr[LGFIFO-2:0]};
	end

	generate
		for (genvar i = 0; i < NFF; i = i + 1) begin : sync
			reg [LGFIFO-1:0] sync_reg;
			always @(posedge i_wclk) begin
				sync_reg <= (i == 0) ? rd_ptr_gray : sync_reg;
			end
			assign rd_ptr_sync = (i == NFF-1) ? sync_reg : sync_reg;
		end
	endgenerate

	always @(posedge i_wclk) begin
		if (wr_cnt == (2**LGFIFO)) begin
			o_wr_full <= 1'b1;
		end else begin
			o_wr_full <= 1'b0;
		end
	end

	always @(posedge i_rclk) begin
		if (rd_cnt == 0) begin
			o_rd_empty <= 1'b1;
		end else begin
			o_rd_empty <= 1'b0;
		end
	end

endmodule
