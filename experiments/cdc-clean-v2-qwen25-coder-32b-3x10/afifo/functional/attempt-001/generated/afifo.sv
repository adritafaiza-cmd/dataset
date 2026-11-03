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
	localparam AW = LGFIFO;

	reg [AW:0] wptr_gray, wptr_gray_nxt, wptr_gray_sync;
	reg [AW:0] rptr_gray, rptr_gray_nxt, rptr_gray_sync;
	reg [AW:0] wptr_bin, rptr_bin;

	// Gray code to binary conversion
	function [AW:0] gray2bin;
		input [AW:0] gray;
		integer i;
		reg [AW:0] bin;
		begin
			bin = gray[AW];
			for (i = AW-1; i >= 0; i = i - 1) begin
				bin[i] = bin[i+1] ^ gray[i];
			end
			gray2bin = bin;
		end
	endfunction

	// Binary to gray code conversion
	function [AW:0] bin2gray;
		input [AW:0] bin;
		begin
			bin2gray = bin ^ (bin >> 1);
		end
	endfunction

	// Write pointer logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wptr_gray <= 0;
			o_wr_full <= 0;
		end else begin
			wptr_gray <= wptr_gray_nxt;
			o_wr_full <= (wptr_gray_nxt == {~rptr_gray_sync[AW], rptr_gray_sync[AW-1:0]});
		end
	end

	always @(*) begin
		if (WRITE_ON_POSEDGE)
			wptr_gray_nxt = i_wr & ~o_wr_full ? bin2gray(wptr_bin + 1) : wptr_gray;
		else
			wptr_gray_nxt = bin2gray(wptr_bin);
	end

	always @(posedge i_wclk) begin
		if (i_wr & ~o_wr_full)
			wptr_bin <= wptr_bin + 1;
	end

	// Read pointer logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rptr_gray <= 0;
			o_rd_empty <= 1;
		end else begin
			rptr_gray <= rptr_gray_nxt;
			o_rd_empty <= (rptr_gray_nxt == wptr_gray_sync);
		end
	end

	always @(*) begin
		rptr_gray_nxt = i_rd & ~o_rd_empty ? bin2gray(rptr_bin + 1) : rptr_gray;
	end

	always @(posedge i_rclk) begin
		if (i_rd & ~o_rd_empty)
			rptr_bin <= rptr_bin + 1;
	end

	// Synchronize pointers
	generate
		genvar i;
		for (i = 0; i < NFF; i = i + 1) begin : sync_wptr
			if (i == 0) begin
				always @(posedge i_rclk or negedge i_rd_reset_n) begin
					if (!i_rd_reset_n)
						wptr_gray_sync <= 0;
					else
						wptr_gray_sync <= wptr_gray;
				end
			end else begin
				always @(posedge i_rclk or negedge i_rd_reset_n) begin
					if (!i_rd_reset_n)
						wptr_gray_sync <= 0;
					else
						wptr_gray_sync <= wptr_gray_sync;
				end
			end
		end
		for (i = 0; i < NFF; i = i + 1) begin : sync_rptr
			if (i == 0) begin
				always @(posedge i_wclk or negedge i_wr_reset_n) begin
					if (!i_wr_reset_n)
						rptr_gray_sync <= 0;
					else
						rptr_gray_sync <= rptr_gray;
				end
			end else begin
				always @(posedge i_wclk or negedge i_wr_reset_n) begin
					if (!i_wr_reset_n)
						rptr_gray_sync <= 0;
					else
						rptr_gray_sync <= rptr_gray_sync;
				end
			end
		end
	endgenerate

	// Memory
	reg [WIDTH-1:0] mem [0:DEPTH-1];

	always @(posedge i_wclk) begin
		if (i_wr & ~o_wr_full)
			mem[wptr_bin[AW-1:0]] <= i_wr_data;
	end

	// Read data
	reg [WIDTH-1:0] rd_data;

	always @(posedge i_rclk) begin
		if (i_rd & ~o_rd_empty)
			rd_data <= mem[rptr_bin[AW-1:0]];
	end

	// Output register
	generate
		if (OPT_REGISTER_READS) begin
			always @(posedge i_rclk or negedge i_rd_reset_n) begin
				if (!i_rd_reset_n)
					o_rd_data <= 0;
				else
					o_rd_data <= rd_data;
			end
		end else begin
			assign o_rd_data = rd_data;
		end
	endgenerate

endmodule
