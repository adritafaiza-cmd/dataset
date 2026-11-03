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
	reg [LGFIFO-1:0] wr_ptr, rd_ptr;
	reg [LGFIFO-1:0] wr_ptr_gray, rd_ptr_gray;
	reg [LGFIFO-1:0] wr_ptr_sync, rd_ptr_sync;
	reg [LGFIFO-1:0] wr_ptr_sync_gray, rd_ptr_sync_gray;
	reg [LGFIFO:0] count;
	reg [NFF-1:0] wr_sync;
	reg [NFF-1:0] rd_sync;
	reg full, empty;

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			wr_ptr_gray <= 0;
			count <= 0;
			o_wr_full <= 0;
			wr_sync <= 0;
		end else if (i_wr &&!o_wr_full) begin
			if (WRITE_ON_POSEDGE) begin
				mem[wr_ptr] <= i_wr_data;
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
			o_rd_empty <= 1;
			rd_sync <= 0;
		end else if (i_rd &&!o_rd_empty) begin
			rd_ptr <= rd_ptr + 1;
			rd_ptr_gray <= rd_ptr_gray + 1;
			count <= count - 1;
		end
	end

	always @(posedge i_wclk) begin
		wr_ptr_sync <= wr_ptr;
		wr_ptr_sync_gray <= wr_ptr_gray;
	end

	always @(posedge i_rclk) begin
		rd_ptr_sync <= rd_ptr;
		rd_ptr_sync_gray <= rd_ptr_gray;
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
		if (wr_sync[NFF-1] &&!o_wr_full) begin
			o_wr_full <= (count == 2**LGFIFO);
		end
	end

	always @(posedge i_rclk) begin
		if (OPT_REGISTER_READS) begin
			o_rd_data <= mem[rd_ptr_sync];
			o_rd_empty <= (count == 0);
		end else begin
			o_rd_data <= mem[rd_ptr];
			o_rd_empty <= (count == 0);
		end
	end

endmodule
