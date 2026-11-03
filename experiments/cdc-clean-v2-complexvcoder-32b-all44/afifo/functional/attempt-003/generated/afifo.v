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

	// Instantiate the core FIFO logic
	async_fifo_core #(
		.LGFIFO(LGFIFO),
		.WIDTH(WIDTH),
		.NFF(NFF),
		.WRITE_ON_POSEDGE(WRITE_ON_POSEDGE),
		.OPT_REGISTER_READS(OPT_REGISTER_READS)
	) fifo_core (
		.i_wclk(i_wclk),
		.i_wr_reset_n(i_wr_reset_n),
		.i_wr(i_wr),
		.i_wr_data(i_wr_data),
		.o_wr_full(o_wr_full),
		.i_rclk(i_rclk),
		.i_rd_reset_n(i_rd_reset_n),
		.i_rd(i_rd),
		.o_rd_data(o_rd_data),
		.o_rd_empty(o_rd_empty)
	);

endmodule

module async_fifo_core #(
		parameter	LGFIFO = 3,
		parameter	WIDTH  = 16,
		parameter	NFF    = 2,
		parameter [0:0]	WRITE_ON_POSEDGE = 1'b1,
		parameter [0:0]	OPT_REGISTER_READS = 1'b1
	) (
		input	wire			i_wclk,
		input	wire			i_wr_reset_n,
		input	wire			i_wr,
		input	wire	[WIDTH-1:0]	i_wr_data,
		output	reg			o_wr_full,
		input	wire			i_rclk,
		input	wire			i_rd_reset_n,
		input	wire			i_rd,
		output	reg	[WIDTH-1:0]	o_rd_data,
		output	reg			o_rd_empty
	);

	wire [LGFIFO:0] wr_gray;
	wire [LGFIFO:0] rd_gray;
	wire [LGFIFO:0] wr_bin;
	wire [LGFIFO:0] rd_bin;
	wire [LGFIFO:0] wr_sync_gray;
	wire [LGFIFO:0] rd_sync_gray;
	wire [LGFIFO:0] rd_sync_gray2;

	// Write gray counter
	gray_counter #(
		.LGFIFO(LGFIFO)
	) wr_gray_counter (
		.i_clk(i_wclk),
		.i_reset_n(i_wr_reset_n),
		.i_en(i_wr & ~o_wr_full),
		.o_gray(wr_gray)
	);

	// Read gray counter
	gray_counter #(
		.LGFIFO(LGFIFO)
	) rd_gray_counter (
		.i_clk(i_rclk),
		.i_reset_n(i_rd_reset_n),
		.i_en(i_rd & ~o_rd_empty),
		.o_gray(rd_gray)
	);

	// Convert gray to binary for write address
	gray_to_bin #(
		.LGFIFO(LGFIFO)
	) wr_gray_to_bin (
		.i_gray(wr_gray),
		.o_bin(wr_bin)
	);

	// Convert gray to binary for read address
	gray_to_bin #(
		.LGFIFO(LGFIFO)
	) rd_gray_to_bin (
		.i_gray(rd_gray),
		.o_bin(rd_bin)
	);

	// Dual-port RAM for FIFO storage
	dual_port_ram #(
		.WIDTH(WIDTH)
	) fifo_memory (
		.i_wr_clk(i_wclk),
		.i_wr_reset_n(i_wr_reset_n),
		.i_wr_addr(wr_bin),
		.i_wr_data(i_wr_data),
		.i_wr_en(i_wr & ~o_wr_full),
		.i_rd_clk(i_rclk),
		.i_rd_reset_n(i_rd_reset_n),
		.i_rd_addr(rd_sync_gray2),
		.o_rd_data(o_rd_data)
	);

	// Write side synchronizer
	sync_register #(
		.NFF(NFF),
		.LGFIFO(LGFIFO)
	) wr_sync_reg (
		.i_clk(i_rclk),
		.i_reset_n(i_rd_reset_n),
		.i_data(wr_gray),
		.o_data(wr_sync_gray)
	);

	// Read side synchronizer
	sync_register #(
		.NFF(NFF),
		.LGFIFO(LGFIFO)
	) rd_sync_reg (
		.i_clk(i_wclk),
		.i_reset_n(i_wr_reset_n),
		.i_data(rd_gray),
		.o_data(rd_sync_gray)
	);

	// Second read side synchronizer
	sync_register #(
		.NFF(NFF),
		.LGFIFO(LGFIFO)
	) rd_sync_reg2 (
		.i_clk(i_wclk),
		.i_reset_n(i_wr_reset_n),
		.i_data(rd_sync_gray),
		.o_data(rd_sync_gray2)
	);

	// Generate o_wr_full signal
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			o_wr_full <= 1'b0;
		end else begin
			if (WRITE_ON_POSEDGE) begin
				if (i_wr && ~o_wr_full) begin
					o_wr_full <= (wr_sync_gray == (rd_bin + 1));
				end
			end else begin
				if (i_wr && ~o_wr_full) begin
					o_wr_full <= (wr_sync_gray == (rd_bin + 1));
				end
			end
		end
	end

	// Generate o_rd_empty signal
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_empty <= 1'b1;
		end else begin
			o_rd_empty <= (wr_sync_gray2 == rd_bin);
		end
	end

endmodule

module gray_counter #(
		parameter	LGFIFO = 3
	) (
		input	wire			i_clk,
		input	wire			i_reset_n,
		input	wire			i_en,
		output	reg	[LGFIFO:0]	o_gray
	);

	always @(posedge i_clk or negedge i_reset_n) begin
		if (!i_reset_n) begin
			o_gray <= {LGFIFO+1{1'b0}};
		end else if (i_en) begin
			o_gray <= o_gray ^ ({LGFIFO+1{1'b0}} << (LGFIFO+1-1));
		end
	end

endmodule

module gray_to_bin #(
		parameter	LGFIFO = 3
	) (
		input	wire	[LGFIFO:0]	i_gray,
		output	reg	[LGFIFO:0]	o_bin
	);

	integer i;

	always @(*) begin
		o_bin = i_gray[LGFIFO];
		for (i = LGFIFO-1; i >= 0; i = i - 1) begin
			o_bin[i] = o_bin[i+1] ^ i_gray[i];
		end
	end

endmodule

module dual_port_ram #(
		parameter	WIDTH = 16
	) (
		input	wire			i_wr_clk,
		input	wire			i_wr_reset_n,
		input	wire	[LGFIFO:0]	i_wr_addr,
		input	wire	[WIDTH-1:0]	i_wr_data,
		input	wire			i_wr_en,
		input	wire			i_rd_clk,
		input	wire			i_rd_reset_n,
		input	wire	[LGFIFO:0]	i_rd_addr,
		output	reg	[WIDTH-1:0]	o_rd_data
	);

	localparam DEPTH = 2**(LGFIFO+1);
	reg [WIDTH-1:0] mem [0:DEPTH-1];

	always @(posedge i_wr_clk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			for (integer i = 0; i < DEPTH; i = i + 1) begin
				mem[i] <= {WIDTH{1'b0}};
			end
		end else if (i_wr_en) begin
			mem[i_wr_addr] <= i_wr_data;
		end
	end

	always @(posedge i_rd_clk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_data <= {WIDTH{1'b0}};
		end else begin
			o_rd_data <= mem[i_rd_addr];
		end
	end

endmodule

module sync_register #(
		parameter	NFF = 2,
		parameter	LGFIFO = 3
	) (
		input	wire			i_clk,
		input	wire			i_reset_n,
		input	wire	[LGFIFO:0]	i_data,
		output	reg	[LGFIFO:0]	o_data
	);

	reg [LGFIFO:0] sync_stage [0:NFF-1];

	always @(posedge i_clk or negedge i_reset_n) begin
		if (!i_reset_n) begin
			for (integer i = 0; i < NFF; i = i + 1) begin
				sync_stage[i] <= {LGFIFO+1{1'b0}};
			end
		end else begin
			sync_stage[0] <= i_data;
			for (integer i = 1; i < NFF; i = i + 1) begin
				sync_stage[i] <= sync_stage[i-1];
			end
		end
	end

	assign o_data = sync_stage[NFF-1];

endmodule
