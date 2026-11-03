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
	wire [PTR_W-1:0] wr_ptr_gray = wr_ptr_bin ^ {wr_ptr_bin[PTR_W-1:1], 1'b0};
	wire [PTR_W-1:0] rd_ptr_gray = rd_ptr_bin ^ {rd_ptr_bin[PTR_W-1:1], 1'b0};

	// Synchronizers for write pointer gray into read clock domain
	reg [PTR_W-1:0] wr_ptr_gray_r1, wr_ptr_gray_r2;
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			wr_ptr_gray_r1 <= {PTR_W{1'b0}};
			wr_ptr_gray_r2 <= {PTR_W{1'b0}};
		end else begin
			wr_ptr_gray_r1 <= wr_ptr_gray;
			wr_ptr_gray_r2 <= wr_ptr_gray_r1;
		end
	end

	// Synchronizers for read pointer gray into write clock domain
	reg [PTR_W-1:0] rd_ptr_gray_r1, rd_ptr_gray_r2;
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			rd_ptr_gray_r1 <= {PTR_W{1'b0}};
			rd_ptr_gray_r2 <= {PTR_W{1'b0}};
		end else begin
			rd_ptr_gray_r1 <= rd_ptr_gray;
			rd_ptr_gray_r2 <= rd_ptr_gray_r1;
		end
	end

	// Convert gray to binary
	function [PTR_W-1:0] gray2bin;
		input [PTR_W-1:0] gray;
		reg [PTR_W-1:0] bin;
		integer i;
		begin
			bin[PTR_W-1] = gray[PTR_W-1];
			for (i = PTR_W-2; i >= 0; i = i - 1)
				bin[i] = bin[i+1] ^ gray[i];
			gray2bin = bin;
		end
	endfunction

	// Read pointer binary in write clock domain (for full detection)
	wire [PTR_W-1:0] rd_ptr_bin_wclk = gray2bin(rd_ptr_gray_r2);
	// Write pointer binary in read clock domain (for empty detection)
	wire [PTR_W-1:0] wr_ptr_bin_rclk = gray2bin(wr_ptr_gray_r2);

	// Full condition: write pointer has lapped read pointer by DEPTH
	// Full when upper bits match and lower bits differ by 1 (i.e., wr_ptr_bin == rd_ptr_bin_wclk + DEPTH)
	// Since pointers are PTR_W bits, full when wr_ptr_bin[PTR_W-1:1] == rd_ptr_bin_wclk[PTR_W-1:1]
	// and wr_ptr_bin[0] != rd_ptr_bin_wclk[0]
	wire full_internal;
	assign full_internal = (wr_ptr_bin[PTR_W-1:1] == rd_ptr_bin_wclk[PTR_W-1:1]) &&
	                       (wr_ptr_bin[0] != rd_ptr_bin_wclk[0]);

	// Empty condition: write pointer equals read pointer in read clock domain
	wire empty_internal;
	assign empty_internal = (wr_ptr_bin_rclk == rd_ptr_bin);

	// Write clock domain
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr_bin <= {PTR_W{1'b0}};
			o_wr_full <= 1'b0;
		end else begin
			o_wr_full <= full_internal;
			if (i_wr && !full_internal) begin
				mem[wr_ptr_bin[LGFIFO-1:0]] <= i_wr_data;
				wr_ptr_bin <= wr_ptr_bin + 1'b1;
			end
		end
	end

	// Read clock domain
	reg [WIDTH-1:0] rd_data_reg;
	reg rd_valid;

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr_bin <= {PTR_W{1'b0}};
			o_rd_empty <= 1'b1;
			o_rd_data <= {WIDTH{1'b0}};
			rd_data_reg <= {WIDTH{1'b0}};
			rd_valid <= 1'b0;
		end else begin
			o_rd_empty <= empty_internal;
			if (i_rd && !empty_internal) begin
				rd_data_reg <= mem[rd_ptr_bin[LGFIFO-1:0]];
				rd_valid <= 1'b1;
				rd_ptr_bin <= rd_ptr_bin + 1'b1;
			end else begin
				// Hold rd_valid if not reading
				// rd_valid stays as is
			end
			if (OPT_REGISTER_READS) begin
				if (i_rd && !empty_internal) begin
					o_rd_data <= mem[rd_ptr_bin[LGFIFO-1:0]];
				end
			end else begin
				if (i_rd && !empty_internal) begin
					o_rd_data <= mem[rd_ptr_bin[LGFIFO-1:0]];
				end
			end
		end
	end

endmodule
