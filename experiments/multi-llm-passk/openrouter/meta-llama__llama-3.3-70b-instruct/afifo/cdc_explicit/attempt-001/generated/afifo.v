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
	reg [LGFIFO-1:0] wr_ptr_sync, rd_ptr_sync;
	reg [LGFIFO:0] count;
	reg full, empty;

	wire wr_en;
	wire rd_en;

	assign wr_en = i_wr && !o_wr_full;
	assign rd_en = i_rd && !o_rd_empty;

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			wr_ptr_gray <= 0;
			count <= 0;
			o_wr_full <= 0;
		end else if (wr_en) begin
			wr_ptr <= wr_ptr + 1;
			wr_ptr_gray <= wr_ptr_gray + 1;
			count <= count + 1;
			fifo[wr_ptr] <= i_wr_data;
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
			rd_ptr_gray <= 0;
			count <= 0;
			o_rd_empty <= 1;
		end else if (rd_en) begin
			rd_ptr <= rd_ptr + 1;
			rd_ptr_gray <= rd_ptr_gray + 1;
			count <= count - 1;
			if (OPT_REGISTER_READS) begin
				o_rd_data <= fifo[rd_ptr];
			end
		end
	end

	always @(posedge i_rclk) begin
		if (OPT_REGISTER_READS) begin
			o_rd_empty <= (count == 0);
		end else begin
			o_rd_empty <= (count == 0);
			o_rd_data <= fifo[rd_ptr];
		end
	end

	always @(posedge i_wclk) begin
		o_wr_full <= (count == (2**LGFIFO));
	end

	generate
		for (genvar i = 0; i < NFF; i = i + 1) begin : sync_w
			reg [LGFIFO-1:0] sync_w;
			always @(posedge i_rclk or negedge i_rd_reset_n) begin
				if (!i_rd_reset_n) begin
					sync_w <= 0;
				end else begin
					sync_w <= wr_ptr_gray;
				end
			end
			assign wr_ptr_sync = (i == (NFF-1)) ? sync_w : wr_ptr_sync;
		end
	endgenerate

	generate
		for (genvar i = 0; i < NFF; i = i + 1) begin : sync_r
			reg [LGFIFO-1:0] sync_r;
			always @(posedge i_wclk or negedge i_wr_reset_n) begin
				if (!i_wr_reset_n) begin
					sync_r <= 0;
				end else begin
					sync_r <= rd_ptr_gray;
				end
			end
			assign rd_ptr_sync = (i == (NFF-1)) ? sync_r : rd_ptr_sync;
		end
	endgenerate

	always @(*) begin
		if (count == 0) begin
			empty = 1;
		end else begin
			empty = 0;
		end
		if (count == (2**LGFIFO)) begin
			full = 1;
		end else begin
			full = 0;
		end
	end

endmodule
