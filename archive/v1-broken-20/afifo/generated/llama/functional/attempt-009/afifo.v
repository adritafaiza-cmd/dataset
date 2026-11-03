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

	reg [WIDTH-1:0] fifo [2**LGFIFO-1:0];
	reg [LGFIFO-1:0] wr_ptr, rd_ptr;
	reg [LGFIFO-1:0] wr_ptr_gray, rd_ptr_gray;
	reg [LGFIFO-1:0] wr_ptr_gray_sync [NFF-1:0];
	reg [LGFIFO-1:0] rd_ptr_gray_sync [NFF-1:0];
	reg [LGFIFO:0] count;
	reg [LGFIFO:0] count_sync [NFF-1:0];

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			wr_ptr_gray <= 0;
			count <= 0;
		end else if (i_wr && !o_wr_full) begin
			if (WRITE_ON_POSEDGE) begin
				fifo[wr_ptr] <= i_wr_data;
				wr_ptr <= wr_ptr + 1;
				wr_ptr_gray <= wr_ptr_gray + 1;
				count <= count + 1;
			end
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
			rd_ptr_gray <= 0;
			count <= 0;
			o_rd_empty <= 1;
		end else if (i_rd && !o_rd_empty) begin
			if (OPT_REGISTER_READS) begin
				o_rd_data <= fifo[rd_ptr];
				rd_ptr <= rd_ptr + 1;
				rd_ptr_gray <= rd_ptr_gray + 1;
				count <= count - 1;
			end else begin
				o_rd_data <= fifo[rd_ptr];
				rd_ptr <= rd_ptr + 1;
				rd_ptr_gray <= rd_ptr_gray + 1;
				count <= count - 1;
			end
		end
	end

	always @(posedge i_wclk) begin
		wr_ptr_gray_sync[0] <= wr_ptr_gray;
		for (int i = 1; i < NFF; i++) begin
			wr_ptr_gray_sync[i] <= wr_ptr_gray_sync[i-1];
		end
	end

	always @(posedge i_rclk) begin
		rd_ptr_gray_sync[0] <= rd_ptr_gray;
		for (int i = 1; i < NFF; i++) begin
			rd_ptr_gray_sync[i] <= rd_ptr_gray_sync[i-1];
		end
	end

	always @(posedge i_wclk) begin
		count_sync[0] <= count;
		for (int i = 1; i < NFF; i++) begin
			count_sync[i] <= count_sync[i-1];
		end
	end

	always @(posedge i_rclk) begin
		if (OPT_REGISTER_READS) begin
			o_rd_empty <= (count_sync[NFF-1] == 0);
		end else begin
			o_rd_empty <= (count == 0);
		end
	end

	always @(posedge i_wclk) begin
		o_wr_full <= (count == (2**LGFIFO));
	end

endmodule
