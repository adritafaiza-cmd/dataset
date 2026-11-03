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

	// Storage
	reg [WIDTH-1:0] mem [0:DEPTH-1];

	// Write pointer (write clock domain)
	reg [PTR_W-1:0] wr_ptr;
	// Read pointer (read clock domain)
	reg [PTR_W-1:0] rd_ptr;

	// Gray code pointers for CDC
	reg [PTR_W-1:0] wr_ptr_gray;
	reg [PTR_W-1:0] rd_ptr_gray;

	// Synchronized read pointer in write domain
	reg [PTR_W-1:0] rd_ptr_gray_sync1;
	reg [PTR_W-1:0] rd_ptr_gray_sync2;

	// Synchronized write pointer in read domain
	reg [PTR_W-1:0] wr_ptr_gray_sync1;
	reg [PTR_W-1:0] wr_ptr_gray_sync2;

	// Full/Empty flags
	reg wr_full;
	reg rd_empty;

	// Binary to Gray conversion
	function [PTR_W-1:0] bin2gray;
		input [PTR_W-1:0] bin;
		begin
			bin2gray = bin ^ (bin >> 1);
		end
	endfunction

	// Gray to Binary conversion
	function [PTR_W-1:0] gray2bin;
		input [PTR_W-1:0] gray;
		reg [PTR_W-1:0] bin;
		begin
			bin[PTR_W-1] = gray[PTR_W-1];
			for (integer i = PTR_W-2; i >= 0; i = i - 1)
				bin[i] = gray[i] ^ bin[i+1];
			gray2bin = bin;
		end
	endfunction

	// Write clock domain
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= {PTR_W{1'b0}};
			wr_ptr_gray <= {PTR_W{1'b0}};
			rd_ptr_gray_sync1 <= {PTR_W{1'b0}};
			rd_ptr_gray_sync2 <= {PTR_W{1'b0}};
			wr_full <= 1'b0;
		end else begin
			rd_ptr_gray_sync1 <= rd_ptr_gray;
			rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;

			if (i_wr && !wr_full) begin
				mem[wr_ptr[LGFIFO-1:0]] <= i_wr_data;
				wr_ptr <= wr_ptr + 1'b1;
				wr_ptr_gray <= bin2gray(wr_ptr + 1'b1);
			end

			// Full condition: write pointer has lapped read pointer
			// In gray code, full when MSB differs and rest are same
			wr_full <= (wr_ptr_gray[PTR_W-1] != rd_ptr_gray_sync2[PTR_W-1]) &&
					   (wr_ptr_gray[PTR_W-2:0] == rd_ptr_gray_sync2[PTR_W-2:0]);
		end
	end

	// Read clock domain
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= {PTR_W{1'b0}};
			rd_ptr_gray <= {PTR_W{1'b0}};
			wr_ptr_gray_sync1 <= {PTR_W{1'b0}};
			wr_ptr_gray_sync2 <= {PTR_W{1'b0}};
			rd_empty <= 1'b1;
			o_rd_data <= {WIDTH{1'b0}};
			o_rd_empty <= 1'b1;
		end else begin
			wr_ptr_gray_sync1 <= wr_ptr_gray;
			wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;

			// Empty condition: read pointer equals write pointer
			rd_empty <= (rd_ptr_gray == wr_ptr_gray_sync2);

			if (i_rd && !rd_empty) begin
				rd_ptr <= rd_ptr + 1'b1;
				rd_ptr_gray <= bin2gray(rd_ptr + 1'b1);
			end
		end
	end

	// Output logic
	// OPT_REGISTER_READS: if 1, register the read data in read clock domain
	// if 0, still sample in read clock domain (no async bypass)
	// The spec says "neither setting bypasses destination-clock sampling"
	// and "neither setting provides an asynchronous memory bypass"
	// So we always read from memory in the read clock domain.

	// We need to present data. Let's use a simple approach:
	// When not empty, the data at rd_ptr is valid.
	// We register it for stable output.

	reg [WIDTH-1:0] rd_data_reg;
	reg rd_data_valid;

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_data_reg <= {WIDTH{1'b0}};
			rd_data_valid <= 1'b0;
		end else begin
			if (!rd_empty) begin
				rd_data_reg <= mem[rd_ptr[LGFIFO-1:0]];
				rd_data_valid <= 1'b1;
			end else begin
				rd_data_valid <= 1'b0;
			end
		end
	end

	// Output assignment
	always @(*) begin
		if (OPT_REGISTER_READS) begin
			o_rd_data = rd_data_reg;
			o_rd_empty = !rd_data_valid;
		end else begin
			// Even without extra register, we sample in read clock
			// Use the same registered data but with different empty logic
			o_rd_data = rd_data_reg;
			o_rd_empty = rd_empty;
		end
	end

	// Assign full flag
	assign o_wr_full = wr_full;

endmodule
