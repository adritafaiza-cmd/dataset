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

	// Write pointer (write clock domain)
	reg [PTR_W-1:0] wr_ptr;
	// Read pointer (read clock domain)
	reg [PTR_W-1:0] rd_ptr;

	// Gray code pointers for CDC
	reg [PTR_W-1:0] wr_ptr_gray;
	reg [PTR_W-1:0] rd_ptr_gray;

	// Synchronized gray pointers
	reg [PTR_W-1:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;
	reg [PTR_W-1:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;

	// Full/Empty flags
	reg wr_full;
	reg rd_empty;

	// Read data path
	reg [WIDTH-1:0] rd_data_reg;
	reg rd_valid;

	// Helper: binary to gray
	function [PTR_W-1:0] bin2gray;
		input [PTR_W-1:0] bin;
		begin
			bin2gray = bin ^ (bin >> 1);
		end
	endfunction

	// Helper: gray to binary
	function [PTR_W-1:0] gray2bin;
		input [PTR_W-1:0] gray;
		reg [PTR_W-1:0] bin;
		integer i;
		begin
			bin[PTR_W-1] = gray[PTR_W-1];
			for (i = PTR_W-2; i >= 0; i = i - 1)
				bin[i] = gray[i] ^ bin[i+1];
			gray2bin = bin;
		end
	endfunction

	// Write clock domain
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= {PTR_W{1'b0}};
			wr_ptr_gray <= {PTR_W{1'b0}};
			wr_full <= 1'b0;
		end else begin
			wr_ptr_gray <= bin2gray(wr_ptr);
			if (i_wr && !wr_full) begin
				mem[wr_ptr[LGFIFO-1:0]] <= i_wr_data;
				wr_ptr <= wr_ptr + 1'b1;
			end
		end
	end

	// Full flag: write pointer gray equals read pointer gray with MSB different
	// Full when wr_ptr_gray == {~rd_ptr_gray[PTR_W-1], rd_ptr_gray[PTR_W-2:0]}
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n)
			wr_full <= 1'b0;
		else
			wr_full <= (wr_ptr_gray == {~rd_ptr_gray_sync2[PTR_W-1], rd_ptr_gray_sync2[PTR_W-2:0]});
	end

	// Synchronize write gray pointer to read clock domain
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			wr_ptr_gray_sync1 <= {PTR_W{1'b0}};
			wr_ptr_gray_sync2 <= {PTR_W{1'b0}};
		end else begin
			wr_ptr_gray_sync1 <= wr_ptr_gray;
			wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
		end
	end

	// Read clock domain
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= {PTR_W{1'b0}};
			rd_ptr_gray <= {PTR_W{1'b0}};
			rd_empty <= 1'b1;
			rd_data_reg <= {WIDTH{1'b0}};
			rd_valid <= 1'b0;
		end else begin
			rd_ptr_gray <= bin2gray(rd_ptr);
			if (i_rd && !rd_empty) begin
				rd_ptr <= rd_ptr + 1'b1;
			end
		end
	end

	// Empty flag: read pointer gray equals write pointer gray
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n)
			rd_empty <= 1'b1;
		else
			rd_empty <= (rd_ptr_gray == wr_ptr_gray_sync2);
	end

	// Synchronize read gray pointer to write clock domain
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			rd_ptr_gray_sync1 <= {PTR_W{1'b0}};
			rd_ptr_gray_sync2 <= {PTR_W{1'b0}};
		end else begin
			rd_ptr_gray_sync1 <= rd_ptr_gray;
			rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
		end
	end

	// Read data path
	// When OPT_REGISTER_READS is 1, use an additional output register
	// When OPT_REGISTER_READS is 0, sample directly from memory
	// Both settings use destination-clock sampling

	// The read address is the current rd_ptr (before increment)
	// We need to present data one beat after the read is accepted

	// For OPT_REGISTER_READS = 1:
	//   rd_data_reg holds the data, o_rd_data is registered from rd_data_reg
	// For OPT_REGISTER_READS = 0:
	//   o_rd_data is sampled directly from memory at rd_ptr

	// Let's use a unified approach:
	// On a valid read (i_rd && !rd_empty), capture mem[rd_ptr] into rd_data_reg
	// Then o_rd_data is either rd_data_reg (if OPT_REGISTER_READS=1, with one more register)
	// or directly from memory (if OPT_REGISTER_READS=0)

	// Actually, let's think about this more carefully.
	// The read pointer points to the next word to be read.
	// When i_rd && !rd_empty, we read mem[rd_ptr] and increment rd_ptr.
	// The data should be available on o_rd_data.

	// For OPT_REGISTER_READS = 0: o_rd_data = mem[rd_ptr] sampled on read clock
	// For OPT_REGISTER_READS = 1: o_rd_data is an additional register

	// Let's implement it as:
	// - On read, capture the data into an internal register
	// - If OPT_REGISTER_READS, add one more register stage

	reg [WIDTH-1:0] rd_data_internal;

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_data_internal <= {WIDTH{1'b0}};
		end else if (i_rd && !rd_empty) begin
			rd_data_internal <= mem[rd_ptr[LGFIFO-1:0]];
		end
	end

	// Output data
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_data <= {WIDTH{1'b0}};
		end else if (OPT_REGISTER_READS) begin
			o_rd_data <= rd_data_internal;
		end else begin
			o_rd_data <= rd_data_internal;
		end
	end

	// Output flags
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n)
			o_wr_full <= 1'b0;
		else
			o_wr_full <= wr_full;
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n)
			o_rd_empty <= 1'b1;
		else
			o_rd_empty <= rd_empty;
	end

endmodule
