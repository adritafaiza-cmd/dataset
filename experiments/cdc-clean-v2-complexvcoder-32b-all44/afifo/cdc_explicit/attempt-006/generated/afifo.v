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
	reg [LGFIFO:0] wr_ptr, rd_ptr, wr_ptr_sync, rd_ptr_sync;
	reg [WIDTH-1:0] mem [0:(2**LGFIFO)-1];
	reg wr_full_raw, rd_empty_raw;
	reg [LGFIFO:0] next_wr_ptr, next_rd_ptr;
	reg [WIDTH-1:0] read_data;
	reg write_en, read_en;
	reg [WIDTH-1:0] read_data_reg;

	// Write domain logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			o_wr_full <= 0;
		end else begin
			write_en <= (WRITE_ON_POSEDGE) ? (i_wr && !o_wr_full) : (i_wr && !o_wr_full);
			if (write_en) begin
				mem[wr_ptr[LGFIFO-1:0]] <= i_wr_data;
				next_wr_ptr <= wr_ptr + 1;
				if (next_wr_ptr == rd_ptr_sync)
					wr_full_raw <= 1;
				else
					wr_full_raw <= 0;
			end
			o_wr_full <= wr_full_raw;
			wr_ptr <= next_wr_ptr;
		end
	end

	// Read domain logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
			o_rd_empty <= 1;
			read_data_reg <= 0;
		end else begin
			read_en <= i_rd && !o_rd_empty;
			if (read_en) begin
				next_rd_ptr <= rd_ptr + 1;
				if (next_rd_ptr == wr_ptr_sync)
					rd_empty_raw <= 1;
				else
					rd_empty_raw <= 0;
			end
			o_rd_empty <= rd_empty_raw;
			rd_ptr <= next_rd_ptr;
			if (read_en)
				read_data <= mem[rd_ptr[LGFIFO-1:0]];
			if (OPT_REGISTER_READS)
				read_data_reg <= read_data;
			else
				read_data_reg <= read_data;
		end
	end

	// Synchronize write pointer to read clock domain
	sync_register #(.LGFIFO(LGFIFO), .NFF(NFF))
	wr_sync_reg (
		.data_in(wr_ptr),
		.clk_src(i_wclk),
		.reset_n_src(i_wr_reset_n),
		.clk_dst(i_rclk),
		.reset_n_dst(i_rd_reset_n),
		.data_out(wr_ptr_sync)
	);

	// Synchronize read pointer to write clock domain
	sync_register #(.LGFIFO(LGFIFO), .NFF(NFF))
	rd_sync_reg (
		.data_in(rd_ptr),
		.clk_src(i_rclk),
		.reset_n_src(i_rd_reset_n),
		.clk_dst(i_wclk),
		.reset_n_dst(i_wr_reset_n),
		.data_out(rd_ptr_sync)
	);

	// Assign output data
	assign o_rd_data = read_data_reg;

endmodule

module sync_register #(
		parameter	LGFIFO = 3,
		parameter	NFF = 2
	) (
		input	wire	[LGFIFO:0]	data_in,
		input	wire			clk_src, reset_n_src,
		input	wire			clk_dst, reset_n_dst,
		output	reg	[LGFIFO:0]	data_out
	);

	reg [LGFIFO:0] sync_stage [0:NFF-1];

	// Source clock domain
	always @(posedge clk_src or negedge reset_n_src) begin
		if (!reset_n_src) begin
			for (int i = 0; i < NFF; i = i + 1)
				sync_stage[i] <= 0;
		end else begin
			sync_stage[0] <= data_in;
			for (int i = 1; i < NFF; i = i + 1)
				sync_stage[i] <= sync_stage[i-1];
		end
	end

	// Destination clock domain
	always @(posedge clk_dst or negedge reset_n_dst) begin
		if (!reset_n_dst) begin
			data_out <= 0;
		end else begin
			data_out <= sync_stage[NFF-1];
		end
	end

endmodule
