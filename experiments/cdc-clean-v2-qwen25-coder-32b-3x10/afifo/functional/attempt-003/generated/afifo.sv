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
	localparam ADDR_WIDTH = LGFIFO;

	reg [WIDTH-1:0] mem [0:DEPTH-1];
	reg [ADDR_WIDTH:0] wr_ptr, rd_ptr;
	reg [ADDR_WIDTH:0] wr_ptr_gray, rd_ptr_gray;
	reg [ADDR_WIDTH:0] wr_ptr_gray_sync, rd_ptr_gray_sync;

	// Gray code conversion functions
	function [ADDR_WIDTH:0] bin_to_gray;
		input [ADDR_WIDTH:0] bin;
		bin_to_gray = bin ^ (bin >> 1);
	endfunction

	function [ADDR_WIDTH:0] gray_to_bin;
		input [ADDR_WIDTH:0] gray;
		integer i;
		reg [ADDR_WIDTH:0] bin;
		bin = gray;
		for (i = ADDR_WIDTH-1; i >= 0; i = i - 1)
			bin[i] = bin[i] ^ bin[i+1];
		gray_to_bin = bin;
	endfunction

	// Write side logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			wr_ptr_gray <= 0;
			o_wr_full <= 0;
		end else begin
			if (i_wr && !o_wr_full) begin
				if (WRITE_ON_POSEDGE)
					mem[wr_ptr[ADDR_WIDTH-1:0]] <= i_wr_data;
				wr_ptr <= wr_ptr + 1;
				wr_ptr_gray <= bin_to_gray(wr_ptr + 1);
			end
			o_wr_full <= (wr_ptr_gray[ADDR_WIDTH:ADDR_WIDTH-1] != rd_ptr_gray_sync[ADDR_WIDTH:ADDR_WIDTH-1]) &&
				          (wr_ptr_gray[ADDR_WIDTH-2:0] == {ADDR_WIDTH-1{1'b1}});
		end
	end

	// Read side logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
			rd_ptr_gray <= 0;
			o_rd_empty <= 1;
		end else begin
			if (i_rd && !o_rd_empty) begin
				rd_ptr <= rd_ptr + 1;
				rd_ptr_gray <= bin_to_gray(rd_ptr + 1);
			end
			o_rd_empty <= (wr_ptr_gray_sync[ADDR_WIDTH:ADDR_WIDTH-1] != rd_ptr_gray[ADDR_WIDTH:ADDR_WIDTH-1]) &&
				           (wr_ptr_gray_sync[ADDR_WIDTH-2:0] == rd_ptr_gray[ADDR_WIDTH-2:0]);
		end
	end

	// Gray code synchronization
	generate
		genvar i;
		for (i = 0; i < NFF; i = i + 1) begin : sync_wr_ptr_gray
			always @(posedge i_rclk or negedge i_rd_reset_n) begin
				if (!i_rd_reset_n)
					wr_ptr_gray_sync[i] <= 0;
				else
					wr_ptr_gray_sync[i] <= (i == 0) ? wr_ptr_gray[0] : wr_ptr_gray_sync[i-1];
			end
		end
		for (i = 0; i < NFF; i = i + 1) begin : sync_rd_ptr_gray
			always @(posedge i_wclk or negedge i_wr_reset_n) begin
				if (!i_wr_reset_n)
					rd_ptr_gray_sync[i] <= 0;
				else
					rd_ptr_gray_sync[i] <= (i == 0) ? rd_ptr_gray[0] : rd_ptr_gray_sync[i-1];
			end
		end
	endgenerate

	// Data output
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n)
			o_rd_data <= 0;
		else if (i_rd && !o_rd_empty) begin
			if (OPT_REGISTER_READS)
				o_rd_data <= mem[rd_ptr[ADDR_WIDTH-1:0]];
			else
				o_rd_data <= mem[gray_to_bin(rd_ptr_gray_sync)[ADDR_WIDTH-1:0]];
		end
	end

endmodule
