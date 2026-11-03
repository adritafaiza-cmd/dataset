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
	reg [LGFIFO:0] count;
	wire wr_en, rd_en;

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			count <= 0;
			o_wr_full <= 1'b0;
		end else if (wr_en) begin
			fifo[wr_ptr] <= i_wr_data;
			wr_ptr <= wr_ptr + 1;
			count <= count + 1;
			if (count == 2**LGFIFO) begin
				o_wr_full <= 1'b1;
			end
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
			count <= 0;
			o_rd_empty <= 1'b1;
		end else if (rd_en) begin
			if (OPT_REGISTER_READS) begin
				o_rd_data <= fifo[rd_ptr];
			end
			rd_ptr <= rd_ptr + 1;
			count <= count - 1;
			if (count == 0) begin
				o_rd_empty <= 1'b1;
			end
		end
	end

	assign wr_en = (i_wr && !o_wr_full) && (WRITE_ON_POSEDGE ? i_wclk : !i_wclk);
	assign rd_en = (i_rd && !o_rd_empty);

	always @(posedge i_rclk) begin
		if (!OPT_REGISTER_READS) begin
			o_rd_data <= fifo[rd_ptr];
		end
	end

	reg [NFF-1:0] wr_sync;
	always @(posedge i_rclk) begin
		wr_sync[0] <= i_wclk;
		for (int i = 1; i < NFF; i++) begin
			wr_sync[i] <= wr_sync[i-1];
		end
	end

	reg [NFF-1:0] rd_sync;
	always @(posedge i_wclk) begin
		rd_sync[0] <= i_rclk;
		for (int i = 1; i < NFF; i++) begin
			rd_sync[i] <= rd_sync[i-1];
		end
	end

	assign o_rd_empty = (count == 0) || (rd_ptr == wr_ptr && rd_sync[NFF-1] != wr_sync[NFF-1]);

endmodule
