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
	wire [LGFIFO:0] wr_ptr_gray, rd_ptr_gray;
	wire [LGFIFO:0] wr_ptr_bin, rd_ptr_bin;
	wire [LGFIFO-1:0] mem_wr_addr, mem_rd_addr;
	wire [WIDTH-1:0] mem_wr_data, mem_rd_data;
	wire [LGFIFO:0] wr_ptr_next, rd_ptr_next;
	wire wr_full_raw, rd_empty_raw;
	wire wr_full_sync, rd_empty_sync;

	// Memory array
	reg [WIDTH-1:0] mem [0:(1<<LGFIFO)-1];

	// Write side synchronization
	fifo_sync #(LGFIFO+1, NFF) wr_sync (
		.i_clk(i_wclk),
		.i_reset_n(i_wr_reset_n),
		.i_async(wr_ptr_bin),
		.o_sync(wr_ptr_gray)
	);

	// Read side synchronization
	fifo_sync #(LGFIFO+1, NFF) rd_sync (
		.i_clk(i_rclk),
		.i_reset_n(i_rd_reset_n),
		.i_async(rd_ptr_bin),
		.o_sync(rd_ptr_gray)
	);

	// Gray to binary conversion for write pointer
	always @(*) begin
		wr_ptr_bin = 0;
		for (integer j = 0; j <= LGFIFO; j = j + 1) begin
			wr_ptr_bin[j] = wr_ptr_gray[j] ^ wr_ptr_gray[j+1];
		end
	end

	// Gray to binary conversion for read pointer
	always @(*) begin
		rd_ptr_bin = 0;
		for (integer j = 0; j <= LGFIFO; j = j + 1) begin
			rd_ptr_bin[j] = rd_ptr_gray[j] ^ rd_ptr_bin[j+1];
		end
	end

	// Write address and data assignment
	assign mem_wr_addr = wr_ptr_bin[LGFIFO-1:0];
	assign mem_wr_data = i_wr_data;

	// Memory write logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			o_wr_full <= 0;
		end else if (i_wr && !o_wr_full) begin
			mem[mem_wr_addr] <= mem_wr_data;
		end
	end

	// Write pointer increment logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr_next <= 0;
		end else if (i_wr && !o_wr_full) begin
			wr_ptr_next <= wr_ptr_bin + 1;
		end
	end

	// Write full raw flag
	assign wr_full_raw = (wr_ptr_next == {~rd_ptr_gray[LGFIFO], rd_ptr_gray[LGFIFO-1:0]});

	// Write full synchronized flag
	fifo_sync #(1, NFF) wr_full_sync_inst (
		.i_clk(i_wclk),
		.i_reset_n(i_wr_reset_n),
		.i_async(wr_full_raw),
		.o_sync(o_wr_full)
	);

	// Read address assignment
	assign mem_rd_addr = rd_ptr_bin[LGFIFO-1:0];

	// Memory read logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_data <= 0;
			mem_rd_data <= 0;
		end else if (i_rd && !o_rd_empty) begin
			mem_rd_data <= mem[mem_rd_addr];
		end
	end

	// Read pointer increment logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr_next <= 0;
		end else if (i_rd && !o_rd_empty) begin
			rd_ptr_next <= rd_ptr_bin + 1;
		end
	end

	// Read empty raw flag
	assign rd_empty_raw = (wr_ptr_gray == rd_ptr_bin);

	// Read empty synchronized flag
	fifo_sync #(1, NFF) rd_empty_sync_inst (
		.i_clk(i_rclk),
		.i_reset_n(i_rd_reset_n),
		.i_async(rd_empty_raw),
		.o_sync(o_rd_empty)
	);

	// Additional output register if OPT_REGISTER_READS is set
	generate
		if (OPT_REGISTER_READS) begin : gen_opt_reg
			reg [WIDTH-1:0] rd_data_reg;
			always @(posedge i_rclk or negedge i_rd_reset_n) begin
				if (!i_rd_reset_n) begin
					rd_data_reg <= 0;
				end else if (i_rd && !o_rd_empty) begin
					rd_data_reg <= mem_rd_data;
				end
			end
			assign o_rd_data = rd_data_reg;
		end else begin : gen_no_opt_reg
			assign o_rd_data = mem_rd_data;
		end
	endgenerate

endmodule

module fifo_sync #(
		parameter WIDTH = 4,
		parameter NFF = 2
	) (
		input wire i_clk,
		input wire i_reset_n,
		input wire [WIDTH-1:0] i_async,
		output reg [WIDTH-1:0] o_sync
	);

	// Synchronizer registers
	reg [WIDTH-1:0] sync_reg [0:NFF-1];

	// Synchronization logic
	always @(posedge i_clk or negedge i_reset_n) begin
		if (!i_reset_n) begin
			for (integer j = 0; j < NFF; j = j + 1) begin
				sync_reg[j] <= 0;
			end
		end else begin
			sync_reg[0] <= i_async;
			for (integer j = 1; j < NFF; j = j + 1) begin
				sync_reg[j] <= sync_reg[j-1];
			end
		end
	end

	assign o_sync = sync_reg[NFF-1];

endmodule
