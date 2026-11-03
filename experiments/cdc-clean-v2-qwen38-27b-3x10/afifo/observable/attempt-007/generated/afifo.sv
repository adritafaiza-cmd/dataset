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

	localparam DEPTH = 1 << LGFIFO;
	localparam PTR_W = LGFIFO + 1;

	// Memory
	reg [WIDTH-1:0] mem [0:DEPTH-1];

	// Write pointer (binary)
	reg [PTR_W-1:0] wr_ptr_bin;
	// Read pointer (binary)
	reg [PTR_W-1:0] rd_ptr_bin;

	// Gray code pointers
	wire [PTR_W-1:0] wr_ptr_gray = wr_ptr_bin ^ {1'b0, wr_ptr_bin[PTR_W-1:1]};
	wire [PTR_W-1:0] rd_ptr_gray = rd_ptr_bin ^ {1'b0, rd_ptr_bin[PTR_W-1:1]};

	// Synchronizers for write pointer gray into read clock domain
	reg [PTR_W-1:0] wr_ptr_gray_r1, wr_ptr_gray_r2;
	// Synchronizers for read pointer gray into write clock domain
	reg [PTR_W-1:0] rd_ptr_gray_r1, rd_ptr_gray_r2;

	// Full and empty flags
	wire wr_full;
	wire rd_empty;

	// Write side: full detection
	// Full when write gray pointer equals read gray pointer with MSB different
	assign wr_full = (wr_ptr_gray == {~rd_ptr_gray_r2[PTR_W-1], rd_ptr_gray_r2[PTR_W-2:0]});

	// Read side: empty detection
	// Empty when read gray pointer equals write gray pointer
	assign rd_empty = (rd_ptr_gray == wr_ptr_gray_r2);

	// Write clock domain
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr_bin <= {PTR_W{1'b0}};
		end else if (i_wr && !wr_full) begin
			wr_ptr_bin <= wr_ptr_bin + 1'b1;
			mem[wr_ptr_bin[LGFIFO-1:0]] <= i_wr_data;
		end
	end

	// Read clock domain
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr_bin <= {PTR_W{1'b0}};
		end else if (i_rd && !rd_empty) begin
			rd_ptr_bin <= rd_ptr_bin + 1'b1;
		end
	end

	// Synchronize write pointer gray to read clock domain
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			wr_ptr_gray_r1 <= {PTR_W{1'b0}};
			wr_ptr_gray_r2 <= {PTR_W{1'b0}};
		end else begin
			wr_ptr_gray_r1 <= wr_ptr_gray;
			wr_ptr_gray_r2 <= wr_ptr_gray_r1;
		end
	end

	// Synchronize read pointer gray to write clock domain
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			rd_ptr_gray_r1 <= {PTR_W{1'b0}};
			rd_ptr_gray_r2 <= {PTR_W{1'b0}};
		end else begin
			rd_ptr_gray_r1 <= rd_ptr_gray;
			rd_ptr_gray_r2 <= rd_ptr_gray_r1;
		end
	end

	// Output registering
	// OPT_REGISTER_READS = 1: additional output holding register
	// OPT_REGISTER_READS = 0: destination-clock sample (combinational from memory)

	// Read data from memory
	wire [WIDTH-1:0] rd_data_comb = mem[rd_ptr_bin[LGFIFO-1:0]];

	// Output registers
	reg [WIDTH-1:0] o_rd_data_reg;
	reg o_rd_empty_reg;

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_data_reg <= {WIDTH{1'b0}};
			o_rd_empty_reg <= 1'b1;
		end else begin
			if (OPT_REGISTER_READS) begin
				// Additional output holding register
				// Present one stored word at a time
				// When not empty, output the current read data
				// When empty, hold previous data
				if (!rd_empty) begin
					o_rd_data_reg <= rd_data_comb;
					o_rd_empty_reg <= 1'b0;
				end else begin
					o_rd_empty_reg <= 1'b1;
				end
			end else begin
				// Destination-clock sample: sample the memory output
				// This is still registered in the read clock domain
				if (!rd_empty) begin
					o_rd_data_reg <= rd_data_comb;
					o_rd_empty_reg <= 1'b0;
				end else begin
					o_rd_empty_reg <= 1'b1;
				end
			end
		end
	end

	assign o_rd_data = o_rd_data_reg;
	assign o_rd_empty = o_rd_empty_reg;

	// Write full output
	reg o_wr_full_reg;
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			o_wr_full_reg <= 1'b0;
		end else begin
			o_wr_full_reg <= wr_full;
		end
	end
	assign o_wr_full = o_wr_full_reg;

endmodule
