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
	wire [LGFIFO-1:0] write_address_gray, read_address_gray;
	wire [LGFIFO-1:0] write_address_bin, read_address_bin;
	wire fifo_full, fifo_empty;

	// Write domain
	gray_counter write_gray_counter (
		.clk      (i_wclk),
		.reset_n  (i_wr_reset_n),
		.enable   (i_wr),
		.gray_out (write_address_gray)
	);

	binary_to_gray write_bin_to_gray (
		.bin_in   (write_address_bin),
		.gray_out (write_address_gray)
	);

	gray_to_binary write_gray_to_bin (
		.gray_in  (write_address_gray),
		.bin_out  (write_address_bin)
	);

	// Read domain
	gray_counter read_gray_counter (
		.clk      (i_rclk),
		.reset_n  (i_rd_reset_n),
		.enable   (i_rd),
		.gray_out (read_address_gray)
	);

	binary_to_gray read_bin_to_gray (
		.bin_in   (read_address_bin),
		.gray_out (read_address_gray)
	);

	gray_to_binary read_gray_to_bin (
		.gray_in  (read_address_gray),
		.bin_out  (read_address_bin)
	);

	// FIFO memory
	fifo_memory fifo_mem (
		.write_clk       (i_wclk),
		.write_reset_n   (i_wr_reset_n),
		.write_address   (write_address_bin),
		.write_data      (i_wr_data),
		.write_enable    (i_wr),
		.read_clk        (i_rclk),
		.read_reset_n    (i_rd_reset_n),
		.read_address    (read_address_bin),
		.read_data       (o_rd_data)
	);

	// Full and empty flags
	assign fifo_full  = (write_address_bin == (read_address_bin + 1));
	assign fifo_empty = (write_address_bin == read_address_bin);

	// Synchronize full and empty flags
	sync_register wr_full_sync_reg (
		.clk      (i_rclk),
		.reset_n  (i_rd_reset_n),
		.d        (fifo_full),
		.q        (o_wr_full)
	);

	sync_register rd_empty_sync_reg (
		.clk      (i_wclk),
		.reset_n  (i_wr_reset_n),
		.d        (fifo_empty),
		.q        (o_rd_empty)
	);

	// Additional output register if OPT_REGISTER_READS is set
	reg [WIDTH-1:0] rd_data_reg;
	reg rd_empty_reg;

	generate
		if (OPT_REGISTER_READS == 1'b1) begin
			always @(posedge i_rclk or negedge i_rd_reset_n) begin
				if (!i_rd_reset_n) begin
					rd_data_reg  <= {WIDTH{1'b0}};
					rd_empty_reg <= 1'b1;
				end else begin
					if (i_rd && !fifo_empty) begin
						rd_data_reg  <= o_rd_data;
						rd_empty_reg <= 1'b0;
					end else if (i_rd && !rd_empty_reg) begin
						rd_empty_reg <= 1'b1;
					end
				end
			end
			assign o_rd_data = rd_data_reg;
			assign o_rd_empty = rd_empty_reg;
		end
	endgenerate

endmodule

module gray_counter (
		input	wire			clk, reset_n, enable,
		output	reg	[LGFIFO-1:0]	gray_out
	);

	// Internal signals
	reg [LGFIFO-1:0] count_bin, count_gray;

	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			count_bin  <= {LGFIFO{1'b0}};
			count_gray <= {LGFIFO{1'b0}};
		end else if (enable) begin
			count_bin <= count_bin + 1;
		end
	end

	assign count_gray = (count_bin ^ (count_bin >> 1));
	assign gray_out = count_gray;

endmodule

module binary_to_gray (
		input	wire	[LGFIFO-1:0]	bin_in,
		output	reg	[LGFIFO-1:0]	gray_out
	);

	assign gray_out = (bin_in ^ (bin_in >> 1));

endmodule

module gray_to_binary (
		input	wire	[LGFIFO-1:0]	gray_in,
		output	reg	[LGFIFO-1:0]	bin_out
	);

	integer i;
	always @(*) begin
		bin_out[0] = gray_in[0];
		for (i = 1; i < LGFIFO; i = i + 1) begin
			bin_out[i] = bin_out[i-1] ^ gray_in[i];
		end
	end

endmodule

module fifo_memory #(
		parameter LGFIFO = 3,
		parameter WIDTH  = 16
	) (
		input	wire			write_clk, write_reset_n,
		input	wire	[LGFIFO-1:0]	write_address,
		input	wire	[WIDTH-1:0]	write_data,
		input	wire			write_enable,
		input	wire			read_clk, read_reset_n,
		input	wire	[LGFIFO-1:0]	read_address,
		output	reg	[WIDTH-1:0]	read_data
	);

	// Internal memory
	reg [WIDTH-1:0] memory [0:(2**LGFIFO)-1];

	// Write operation
	always @(posedge write_clk or negedge write_reset_n) begin
		if (!write_reset_n) begin
			// Reset memory if needed
		end else if (write_enable) begin
			memory[write_address] <= write_data;
		end
	end

	// Read operation
	always @(posedge read_clk or negedge read_reset_n) begin
		if (!read_reset_n) begin
			read_data <= {WIDTH{1'b0}};
		end else begin
			read_data <= memory[read_address];
		end
	end

endmodule

module sync_register (
		input	wire			clk, reset_n,
		input	wire			d,
		output	reg			q
	);

	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			q <= 1'b0;
		end else begin
			q <= d;
		end
	end

endmodule
