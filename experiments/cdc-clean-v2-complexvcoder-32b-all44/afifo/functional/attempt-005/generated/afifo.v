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

	wire [LGFIFO:0] wr_ptr_gray, rd_ptr_gray;
	wire [LGFIFO:0] wr_ptr_gray_synced, rd_ptr_gray_synced;
	wire [LGFIFO:0] wr_ptr_bin, rd_ptr_bin;
	wire [LGFIFO:0] next_wr_ptr_gray, next_rd_ptr_gray;
	wire full_flag, empty_flag;
	reg [WIDTH-1:0] mem [2**LGFIFO-1:0];
	reg [WIDTH-1:0] rd_data_reg;

	// Write domain logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr_gray <= 0;
			o_wr_full <= 0;
		end else if (i_wr && !o_wr_full) begin
			if (WRITE_ON_POSEDGE) begin
				mem[wr_ptr_bin] <= i_wr_data;
				wr_ptr_gray <= next_wr_ptr_gray;
			end
		end
	end

	// Read domain logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr_gray <= 0;
			o_rd_empty <= 1;
			o_rd_data <= 0;
		end else if (i_rd && !o_rd_empty) begin
			if (OPT_REGISTER_READS) begin
				o_rd_data <= rd_data_reg;
			end else begin
				o_rd_data <= mem[rd_ptr_bin];
			end
			rd_ptr_gray <= next_rd_ptr_gray;
		end
	end

	// Gray code to binary conversion for write pointer
	always @(*) begin
		wr_ptr_bin = wr_ptr_gray ^ (wr_ptr_gray >> 1);
	end

	// Gray code to binary conversion for read pointer
	always @(*) begin
		rd_ptr_bin = rd_ptr_gray ^ (rd_ptr_gray >> 1);
	end

	// Next write pointer gray code
	always @(*) begin
		next_wr_ptr_gray = wr_ptr_gray + 1;
	end

	// Next read pointer gray code
	always @(*) begin
		next_rd_ptr_gray = rd_ptr_gray + 1;
	end

	// Full flag generation
	always @(*) begin
		full_flag = (wr_ptr_gray_synced == {~rd_ptr_gray[LGFIFO], rd_ptr_gray[LGFIFO-1:0]});
	end

	// Empty flag generation
	always @(*) begin
		empty_flag = (wr_ptr_gray == rd_ptr_gray_synced);
	end

	// Assign full and empty flags
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			o_wr_full <= 0;
		end else begin
			o_wr_full <= full_flag;
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_empty <= 1;
		end else begin
			o_rd_empty <= empty_flag;
		end
	end

	// Register read data if OPT_REGISTER_READS is set
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_data_reg <= 0;
		end else if (i_rd && !o_rd_empty) begin
			rd_data_reg <= mem[rd_ptr_bin];
		end
	end

	// Synchronizers
	sync_register #(
		.LGFIFO(LGFIFO)
	) wr_ptr_gray_sync (
		.clk(i_rclk),
		.reset_n(i_rd_reset_n),
		.data_in(wr_ptr_gray),
		.data_out(wr_ptr_gray_synced)
	);

	sync_register #(
		.LGFIFO(LGFIFO)
	) rd_ptr_gray_sync (
		.clk(i_wclk),
		.reset_n(i_wr_reset_n),
		.data_in(rd_ptr_gray),
		.data_out(rd_ptr_gray_synced)
	);

endmodule

module sync_register #(
		parameter	LGFIFO = 3
	) (
		input	wire			clk, reset_n,
		input	wire	[LGFIFO:0]	data_in,
		output	reg	[LGFIFO:0]	data_out
	);

	reg [LGFIFO:0] sync_reg [NFF-1:0];

	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			for (integer i = 0; i < NFF; i = i + 1) begin
				sync_reg[i] <= 0;
			end
		end else begin
			sync_reg[0] <= data_in;
			for (integer i = 1; i < NFF; i = i + 1) begin
				sync_reg[i] <= sync_reg[i-1];
			end
		end
	end

	assign data_out = sync_reg[NFF-1];

endmodule
