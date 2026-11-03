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
		for (i = ADDR_WIDTH-1; i > 0; i = i - 1) begin
			bin[i-1] = bin[i] ^ bin[i-1];
		end
		gray_to_bin = bin;
	endfunction

	// Write side logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			o_wr_full <= 0;
		end else begin
			if (i_wr && !o_wr_full) begin
				if (WRITE_ON_POSEDGE) begin
					mem[wr_ptr[ADDR_WIDTH-1:0]] <= i_wr_data;
					wr_ptr <= wr_ptr + 1;
				end else begin
					mem[wr_ptr[ADDR_WIDTH-1:0]] <= i_wr_data;
					wr_ptr <= wr_ptr + 1;
				end
			end
			wr_ptr_gray <= bin_to_gray(wr_ptr);
		end
	end

	// Synchronize write pointer to read clock domain
	generate
		genvar i;
		for (i = 0; i < NFF; i = i + 1) begin : sync_wr_ptr_gray
			always @(posedge i_rclk or negedge i_rd_reset_n) begin
				if (!i_rd_reset_n) begin
					wr_ptr_gray_sync[i] <= 0;
				end else begin
					wr_ptr_gray_sync[i] <= (i == 0) ? wr_ptr_gray : wr_ptr_gray_sync[i-1];
				end
			end
		end
	endgenerate

	// Read side logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
			o_rd_empty <= 1;
		end else begin
			if (i_rd && !o_rd_empty) begin
				rd_ptr <= rd_ptr + 1;
			end
			rd_ptr_gray <= bin_to_gray(rd_ptr);
		end
	end

	// Synchronize read pointer to write clock domain
	generate
		genvar j;
		for (j = 0; j < NFF; j = j + 1) begin : sync_rd_ptr_gray
			always @(posedge i_wclk or negedge i_wr_reset_n) begin
				if (!i_wr_reset_n) begin
					rd_ptr_gray_sync[j] <= 0;
				end else begin
					rd_ptr_gray_sync[j] <= (j == 0) ? rd_ptr_gray : rd_ptr_gray_sync[j-1];
				end
			end
		end
	endgenerate

	// Calculate full and empty flags
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			o_wr_full <= 0;
		end else begin
			o_wr_full <= (wr_ptr_gray_sync[NFF-1] == {~rd_ptr_gray[ADDR_WIDTH], rd_ptr_gray[ADDR_WIDTH-1:0]});
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_empty <= 1;
		end else begin
			o_rd_empty <= (rd_ptr_gray_sync[NFF-1] == wr_ptr_gray);
		end
	end

	// Read data output
	reg [WIDTH-1:0] rd_data_reg;

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_data_reg <= 0;
		end else if (i_rd && !o_rd_empty) begin
			rd_data_reg <= mem[rd_ptr[ADDR_WIDTH-1:0]];
		end
	end

	assign o_rd_data = (OPT_REGISTER_READS) ? rd_data_reg : mem[rd_ptr[ADDR_WIDTH-1:0]];

endmodule
