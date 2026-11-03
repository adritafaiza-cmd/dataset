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

	reg [LGFIFO:0] wr_ptr_bin, wr_ptr_bin_next;
	reg [LGFIFO:0] rd_ptr_bin, rd_ptr_bin_next;
	reg [LGFIFO:0] wr_ptr_gray, wr_ptr_gray_sync;
	reg [LGFIFO:0] rd_ptr_gray, rd_ptr_gray_sync;
	reg [WIDTH-1:0] mem [0:(1<<LGFIFO)-1];
	reg wr_ack, rd_ack;
	reg [WIDTH-1:0] rd_data_raw, rd_data_reg;

	// Binary to Gray conversion
	assign wr_ptr_gray = wr_ptr_bin ^ (wr_ptr_bin >> 1);
	assign rd_ptr_gray = rd_ptr_bin ^ (rd_ptr_bin >> 1);

	// Write acknowledge signal
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ack <= 1'b0;
		end else if (WRITE_ON_POSEDGE) begin
			wr_ack <= i_wr & ~o_wr_full;
		end else begin
			wr_ack <= i_wr & ~o_wr_full;
		end
	end

	// Read acknowledge signal
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ack <= 1'b0;
		end else begin
			rd_ack <= i_rd & ~o_rd_empty;
		end
	end

	// Write pointer increment
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr_bin <= {LGFIFO+1{1'b0}};
		end else if (wr_ack) begin
			wr_ptr_bin <= wr_ptr_bin + 1;
		end
	end

	// Read pointer increment
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr_bin <= {LGFIFO+1{1'b0}};
		end else if (rd_ack) begin
			rd_ptr_bin <= rd_ptr_bin + 1;
		end
	end

	// Memory write operation
	always @(posedge i_wclk) begin
		if (wr_ack) begin
			mem[wr_ptr_bin] <= i_wr_data;
		end
	end

	// Memory read operation
	always @(posedge i_rclk) begin
		if (rd_ack) begin
			rd_data_raw <= mem[rd_ptr_bin];
		end
	end

	// Register read data if OPT_REGISTER_READS is high
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_data_reg <= {WIDTH{1'b0}};
		end else if (rd_ack && OPT_REGISTER_READS) begin
			rd_data_reg <= rd_data_raw;
		end
	end

	// Output read data
	assign o_rd_data = OPT_REGISTER_READS ? rd_data_reg : rd_data_raw;

	// Write full flag
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			o_wr_full <= 1'b0;
		end else if (wr_ack) begin
			o_wr_full <= (wr_ptr_gray_sync + 1) == rd_ptr_gray;
		end
	end

	// Read empty flag
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_empty <= 1'b1;
		end else if (rd_ack) begin
			o_rd_empty <= wr_ptr_gray == rd_ptr_gray_sync;
		end
	end

	// Synchronize write pointer to read clock domain
	sync_bit #(.NFF(NFF)) sync_wr_to_rd (
		.i_clk(i_rclk),
		.i_reset_n(i_rd_reset_n),
		.i_d(wr_ptr_gray),
		.o_q(wr_ptr_gray_sync)
	);

	// Synchronize read pointer to write clock domain
	sync_bit #(.NFF(NFF)) sync_rd_to_wr (
		.i_clk(i_wclk),
		.i_reset_n(i_wr_reset_n),
		.i_d(rd_ptr_gray),
		.o_q(rd_ptr_gray_sync)
	);

endmodule

module sync_bit #(
		parameter	NFF = 2
	) (
		input	wire	i_clk, i_reset_n, i_d,
		output	reg	o_q
	);

	reg [NFF-1:0] sreg;

	always @(posedge i_clk) begin
		if (!i_reset_n) begin
			sreg <= {NFF{1'b0}};
		end else begin
			sreg[0] <= i_d;
			for (integer i = 1; i < NFF; i = i + 1) begin
				sreg[i] <= sreg[i-1];
			end
		end
	end

	assign o_q = sreg[NFF-1];

endmodule
