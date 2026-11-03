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
	reg [LGFIFO:0]	wr_ptr_bin, wr_ptr_bin_sync, wr_ptr_gray, wr_ptr_gray_sync;
	reg [LGFIFO:0]	rd_ptr_bin, rd_ptr_bin_sync, rd_ptr_gray, rd_ptr_gray_sync;

	// Write Pointer Logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr_bin <= 0;
			wr_ptr_gray <= 0;
		end else if (i_wr & !o_wr_full) begin
			if (WRITE_ON_POSEDGE)
				wr_ptr_bin <= wr_ptr_bin + 1;
			else
				wr_ptr_bin <= wr_ptr_bin + 1;
		end
	end

	assign wr_ptr_gray = wr_ptr_bin ^ (wr_ptr_bin >> 1);

	// Read Pointer Logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr_bin <= 0;
			rd_ptr_gray <= 0;
		end else if (i_rd & !o_rd_empty) begin
			rd_ptr_bin <= rd_ptr_bin + 1;
		end
	end

	assign rd_ptr_gray = rd_ptr_bin ^ (rd_ptr_bin >> 1);

	// Write Pointer Synchronization
	sync_ff #(.NFF(NFF)) wr_ptr_sync (
		.clk(i_rclk),
		.reset_n(i_rd_reset_n),
		.d(wr_ptr_gray),
		.q(wr_ptr_gray_sync)
	);

	// Read Pointer Synchronization
	sync_ff #(.NFF(NFF)) rd_ptr_sync (
		.clk(i_wclk),
		.reset_n(i_wr_reset_n),
		.d(rd_ptr_gray),
		.q(rd_ptr_gray_sync)
	);

	// Gray to Binary Conversion for Write Pointer
	gray_to_bin wr_ptr_gray_to_bin (
		.gray(wr_ptr_gray_sync),
		.bin(wr_ptr_bin_sync)
	);

	// Gray to Binary Conversion for Read Pointer
	gray_to_bin rd_ptr_gray_to_bin (
		.gray(rd_ptr_gray),
		.bin(rd_ptr_bin)
	);

	// FIFO Memory
	fifo_memory #(.LGFIFO(LGFIFO), .WIDTH(WIDTH)) fifo_mem (
		.wclk(i_wclk),
		.waddr(wr_ptr_bin_sync[LGFIFO-1:0]),
		.din(i_wr_data),
		.rclk(i_rclk),
		.raddr(rd_ptr_bin[LGFIFO-1:0]),
		.dout(o_rd_data)
	);

	// Full and Empty Flags
	assign o_wr_full = (wr_ptr_gray_sync == {1'b1, rd_ptr_gray_sync[LGFIFO-1:0]});
	assign o_rd_empty = (wr_ptr_gray == rd_ptr_gray);

	// Additional output register if OPT_REGISTER_READS is set
	reg [WIDTH-1:0] rd_data_reg;

	generate
		if (OPT_REGISTER_READS) begin : gen_opt_reg
			always @(posedge i_rclk or negedge i_rd_reset_n) begin
				if (!i_rd_reset_n)
					rd_data_reg <= 0;
				else
					rd_data_reg <= o_rd_data;
			end
			assign o_rd_data = rd_data_reg;
		end
	endgenerate

endmodule

// Synchronization Flip-Flops
module sync_ff #(
		parameter	NFF = 2
	) (
		input	wire			clk,
		input	wire			reset_n,
		input	wire	[NFF-1:0]	d,
		output	reg	[NFF-1:0]	q
	);

	always @(posedge clk or negedge reset_n) begin
		if (!reset_n)
			q <= {NFF{1'b0}};
		else
			q <= {d[NFF-2:0], d[NFF-1]};
	end

endmodule

// Gray to Binary Conversion
module gray_to_bin #(
		parameter	LGFIFO = 3
	) (
		input	wire	[LGFIFO:0]	gray,
		output	reg	[LGFIFO:0]	bin
	);

	always @(*) begin
		bin[0] = gray[0];
		for (int i = 1; i <= LGFIFO; i = i + 1) begin
			bin[i] = gray[i] ^ gray[i-1];
		end
	end

endmodule

// FIFO Memory Array
module fifo_memory #(
		parameter	LGFIFO = 3,
		parameter	WIDTH  = 16
	) (
		input	wire			wclk,
		input	wire	[LGFIFO-1:0]	waddr,
		input	wire	[WIDTH-1:0]	din,
		input	wire			rclk,
		input	wire	[LGFIFO-1:0]	raddr,
		output	reg	[WIDTH-1:0]	dout
	);

	reg [WIDTH-1:0] memory [0:(2**LGFIFO)-1];

	always @(posedge wclk) begin
		if (wclk)
			memory[waddr] <= din;
	end

	always @(posedge rclk) begin
		dout <= memory[raddr];
	end

endmodule
