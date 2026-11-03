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

	// Internal signals
	reg [LGFIFO:0] wr_ptr_gray, rd_ptr_gray;
	reg [LGFIFO:0] wr_ptr_gray_sync, rd_ptr_gray_sync;
	reg wr_full, rd_empty;
	reg [LGFIFO-1:0] wr_ptr_bin, rd_ptr_bin;
	reg [LGFIFO-1:0] wr_ptr_bin_next, rd_ptr_bin_next;
	reg [LGFIFO:0] wr_ptr_gray_next, rd_ptr_gray_next;
	reg wr_en, rd_en;
	reg [WIDTH-1:0] mem [0:(1<<LGFIFO)-1];
	reg [WIDTH-1:0] rd_data;

	// Write side logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr_gray <= 0;
			wr_full <= 0;
		end else begin
			if (wr_en) begin
				wr_ptr_bin <= wr_ptr_bin_next;
				wr_ptr_gray <= wr_ptr_gray_next;
				mem[wr_ptr_bin] <= i_wr_data;
			end
			wr_full <= (wr_ptr_gray_next == {~rd_ptr_gray_sync[LGFIFO], rd_ptr_gray_sync[LGFIFO-1:0]});
		end
	end

	assign wr_ptr_bin_next = wr_ptr_bin + 1;
	assign wr_ptr_gray_next = wr_ptr_bin_next ^ (wr_ptr_bin_next >> 1);

	assign wr_en = i_wr & ~o_wr_full & (WRITE_ON_POSEDGE ? i_wr : ~i_wr);

	// Read side logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr_gray <= 0;
			rd_empty <= 1;
			rd_data <= 0;
		end else begin
			if (rd_en) begin
				rd_ptr_bin <= rd_ptr_bin_next;
				rd_ptr_gray <= rd_ptr_gray_next;
				rd_data <= mem[rd_ptr_bin];
			end
			rd_empty <= (wr_ptr_gray_sync == rd_ptr_gray_next);
		end
	end

	assign rd_ptr_bin_next = rd_ptr_bin + 1;
	assign rd_ptr_gray_next = rd_ptr_bin_next ^ (rd_ptr_bin_next >> 1);

	assign rd_en = i_rd & ~o_rd_empty;

	// Synchronization of pointers and flags
	sync_bit #(.NFF(NFF)) sync_wr_ptr_gray (
		.clk(i_rclk),
		.reset_n(i_rd_reset_n),
		.din(wr_ptr_gray),
		.dout(wr_ptr_gray_sync)
	);

	sync_bit #(.NFF(NFF)) sync_rd_ptr_gray (
		.clk(i_wclk),
		.reset_n(i_wr_reset_n),
		.din(rd_ptr_gray),
		.dout(rd_ptr_gray_sync)
	);

	sync_bit #(.NFF(NFF)) sync_wr_full (
		.clk(i_rclk),
		.reset_n(i_rd_reset_n),
		.din(wr_full),
		.dout(o_wr_full)
	);

	sync_bit #(.NFF(NFF)) sync_rd_empty (
		.clk(i_wclk),
		.reset_n(i_wr_reset_n),
		.din(rd_empty),
		.dout(o_rd_empty)
	);

	// Additional output register if OPT_REGISTER_READS is set
	reg [WIDTH-1:0] rd_data_reg;

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_data_reg <= 0;
		end else if (rd_en) begin
			rd_data_reg <= rd_data;
		end
	end

	assign o_rd_data = (OPT_REGISTER_READS) ? rd_data_reg : rd_data;

endmodule

module sync_bit #(
		parameter	NFF = 2
	) (
		input	wire	clk, reset_n, din,
		output	reg	dout
	);

	reg [NFF-1:0] sync_reg;

	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			sync_reg <= 0;
			dout <= 0;
		end else begin
			sync_reg <= {sync_reg[NFF-2:0], din};
			dout <= sync_reg[NFF-1];
		end
	end

endmodule
