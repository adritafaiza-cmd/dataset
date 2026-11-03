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
	reg [LGFIFO:0] wr_ptr_gray, wr_ptr_gray_sync;
	reg [LGFIFO:0] rd_ptr_gray, rd_ptr_gray_sync;
	reg wr_ptr_inc, rd_ptr_inc;
	reg mem_wr_en, mem_rd_en;
	reg [LGFIFO-1:0] mem_wr_addr, mem_rd_addr;
	reg [WIDTH-1:0] mem_wr_data, mem_rd_data, mem_rd_data_sync;

	// Write side logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr_gray <= 0;
			o_wr_full <= 0;
		end else begin
			wr_ptr_inc = i_wr && !o_wr_full;
			if (wr_ptr_inc && WRITE_ON_POSEDGE) begin
				wr_ptr_gray <= wr_ptr_gray + 1;
			end
			// Detect full condition
			o_wr_full <= (wr_ptr_gray[LGFIFO:LGFIFO-1] != rd_ptr_gray_sync[LGFIFO:LGFIFO-1]) && (wr_ptr_gray[LGFIFO-1:0] == rd_ptr_gray_sync[LGFIFO-1:0]);
		end
	end

	// Read side logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr_gray <= 0;
			o_rd_empty <= 1;
		end else begin
			rd_ptr_inc = i_rd && !o_rd_empty;
			if (rd_ptr_inc) begin
				rd_ptr_gray <= rd_ptr_gray + 1;
			end
			// Detect empty condition
			o_rd_empty <= (wr_ptr_gray_sync[LGFIFO:LGFIFO-1] == rd_ptr_gray[LGFIFO:LGFIFO-1]) && (wr_ptr_gray_sync[LGFIFO-1:0] == rd_ptr_gray[LGFIFO-1:0]);
		end
	end

	// Memory write address and enable
	assign mem_wr_addr = wr_ptr_gray[LGFIFO-1:0];
	assign mem_wr_en = wr_ptr_inc;

	// Memory read address and enable
	assign mem_rd_addr = rd_ptr_gray[LGFIFO-1:0];
	assign mem_rd_en = rd_ptr_inc;

	// Memory
	reg [WIDTH-1:0] mem [0:(1<<LGFIFO)-1];
	always @(posedge i_wclk) begin
		if (mem_wr_en) begin
			mem[mem_wr_addr] <= i_wr_data;
		end
	end

	// Memory read
	always @(posedge i_rclk) begin
		if (mem_rd_en) begin
			mem_rd_data <= mem[mem_rd_addr];
		end
	end

	// Synchronize write pointer to read clock domain
	async_fifo_sync #(.NFF(NFF)) sync_wr_ptr (
		.clk(i_rclk),
		.reset_n(i_rd_reset_n),
		.data_in(wr_ptr_gray),
		.data_out(wr_ptr_gray_sync)
	);

	// Synchronize read pointer to write clock domain
	async_fifo_sync #(.NFF(NFF)) sync_rd_ptr (
		.clk(i_wclk),
		.reset_n(i_wr_reset_n),
		.data_in(rd_ptr_gray),
		.data_out(rd_ptr_gray_sync)
	);

	// Gray code counter for write pointer
	gray_counter gray_counter_wr (
		.clk(i_wclk),
		.reset_n(i_wr_reset_n),
		.inc(wr_ptr_inc),
		.gray(wr_ptr_gray)
	);

	// Gray code counter for read pointer
	gray_counter gray_counter_rd (
		.clk(i_rclk),
		.reset_n(i_rd_reset_n),
		.inc(rd_ptr_inc),
		.gray(rd_ptr_gray)
	);

	// Synchronize memory read data to read clock domain
	async_fifo_sync #(.NFF(NFF)) sync_mem_data (
		.clk(i_rclk),
		.reset_n(i_rd_reset_n),
		.data_in(mem_rd_data),
		.data_out(mem_rd_data_sync)
	);

	// Additional output register if OPT_REGISTER_READS is set
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_data <= 0;
		end else if (OPT_REGISTER_READS && mem_rd_en) begin
			o_rd_data <= mem_rd_data_sync;
		end else if (!OPT_REGISTER_READS) begin
			o_rd_data <= mem_rd_data_sync;
		end
	end

endmodule

module async_fifo_sync #(
		parameter	NFF = 2
	) (
		input	wire			clk,
		input	wire			reset_n,
		input	wire	[LGFIFO:0]	data_in,
		output	reg	[LGFIFO:0]	data_out
	);

	reg [LGFIFO:0] sync_reg [0:NFF-1];

	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			data_out <= 0;
			for (integer i = 0; i < NFF; i = i + 1) begin
				sync_reg[i] <= 0;
			end
		end else begin
			sync_reg[0] <= data_in;
			for (integer i = 1; i < NFF; i = i + 1) begin
				sync_reg[i] <= sync_reg[i-1];
			end
			data_out <= sync_reg[NFF-1];
		end
	end

endmodule

module gray_counter (
		input	wire			clk,
		input	wire			reset_n,
		input	wire			inc,
		output	reg	[LGFIFO:0]	gray
	);

	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			gray <= 0;
		end else if (inc) begin
			gray <= gray + 1;
		end
	end

endmodule
