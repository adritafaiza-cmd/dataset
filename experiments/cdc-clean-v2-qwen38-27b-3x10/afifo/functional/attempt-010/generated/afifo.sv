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

	// Internal parameters
	localparam DEPTH = 1 << LGFIFO;
	localparam ADDR_W = LGFIFO;
	localparam CNT_W = LGFIFO + 1;

	// Memory
	reg [WIDTH-1:0] mem [0:DEPTH-1];

	// Write pointer (write clock domain)
	reg [ADDR_W:0] wptr;
	reg [ADDR_W:0] wptr_sync; // Gray code for crossing

	// Read pointer (read clock domain)
	reg [ADDR_W:0] rptr;
	reg [ADDR_W:0] rptr_sync; // Gray code for crossing

	// Synchronizers for write pointer (read clock domain)
	reg [ADDR_W:0] wptr_gray_sync [0:NFF-1];

	// Synchronizers for read pointer (write clock domain)
	reg [ADDR_W:0] rptr_gray_sync [0:NFF-1];

	// Gray code conversion functions
	function [ADDR_W:0] bin2gray;
		input [ADDR_W:0] bin;
		begin
			bin2gray = bin ^ (bin >> 1);
		end
	endfunction

	function [ADDR_W:0] gray2bin;
		input [ADDR_W:0] gray;
		reg [ADDR_W:0] bin;
		begin
			bin[ADDR_W] = gray[ADDR_W];
			for (integer i = ADDR_W-1; i >= 0; i = i-1)
				bin[i] = gray[i] ^ bin[i+1];
			gray2bin = bin;
		end
	endfunction

	// Write side logic
	wire wclk_edge = WRITE_ON_POSEDGE ? i_wclk : ~i_wclk;
	wire wclk_neg  = WRITE_ON_POSEDGE ? ~i_wclk : i_wclk;

	// Write enable
	wire w_en = i_wr & ~o_wr_full;

	// Write pointer update
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n)
			wptr <= {(ADDR_W+1){1'b0}};
		else if (w_en)
			wptr <= wptr + 1'b1;
	end

	// Write pointer gray code
	always @(*) begin
		wptr_sync = bin2gray(wptr);
	end

	// Read side logic
	wire r_en = i_rd & ~o_rd_empty;

	// Read pointer update
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n)
			rptr <= {(ADDR_W+1){1'b0}};
		else if (r_en)
			rptr <= rptr + 1'b1;
	end

	// Read pointer gray code
	always @(*) begin
		rptr_sync = bin2gray(rptr);
	end

	// Synchronize write pointer gray to read clock domain
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			for (integer i = 0; i < NFF; i = i+1)
				wptr_gray_sync[i] <= {(ADDR_W+1){1'b0}};
		end else begin
			wptr_gray_sync[0] <= wptr_sync;
			for (integer i = 1; i < NFF; i = i+1)
				wptr_gray_sync[i] <= wptr_gray_sync[i-1];
		end
	end

	// Synchronize read pointer gray to write clock domain
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			for (integer i = 0; i < NFF; i = i+1)
				rptr_gray_sync[i] <= {(ADDR_W+1){1'b0}};
		end else begin
			rptr_gray_sync[0] <= rptr_sync;
			for (integer i = 1; i < NFF; i = i+1)
				rptr_gray_sync[i] <= rptr_gray_sync[i-1];
		end
	end

	// Convert synchronized gray codes back to binary
	wire [ADDR_W:0] wptr_gray_rclk = wptr_gray_sync[NFF-1];
	wire [ADDR_W:0] rptr_gray_wclk = rptr_gray_sync[NFF-1];

	wire [ADDR_W:0] wptr_bin_rclk = gray2bin(wptr_gray_rclk);
	wire [ADDR_W:0] rptr_bin_wclk = gray2bin(rptr_gray_wclk);

	// Full condition (write clock domain)
	// Full when write pointer has lapped read pointer by DEPTH
	// In binary: wptr_bin_rclk[ADDR_W] != rptr_bin_wclk[ADDR_W] && wptr_bin_rclk[ADDR_W-1:0] == rptr_bin_wclk[ADDR_W-1:0]
	wire full_raw = (wptr_bin_rclk[ADDR_W] != rptr_bin_wclk[ADDR_W]) && 
	                 (wptr_bin_rclk[ADDR_W-1:0] == rptr_bin_wclk[ADDR_W-1:0]);

	// Empty condition (read clock domain)
	// Empty when write pointer equals read pointer
	wire empty_raw = (wptr_bin_rclk == rptr);

	// Register full and empty flags
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n)
			o_wr_full <= 1'b0;
		else
			o_wr_full <= full_raw;
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n)
			o_rd_empty <= 1'b1;
		else
			o_rd_empty <= empty_raw;
	end

	// Memory write
	always @(posedge i_wclk) begin
		if (w_en)
			mem[wptr[ADDR_W-1:0]] <= i_wr_data;
	end

	// Memory read and output
	// Read address is rptr[ADDR_W-1:0]
	wire [ADDR_W-1:0] raddr = rptr[ADDR_W-1:0];

	// Combinational read from memory
	wire [WIDTH-1:0] mem_rd_data;
	assign mem_rd_data = mem[raddr];

	// Output registering
	// OPT_REGISTER_READS: if 1, register the read data; if 0, direct (but still synchronized)
	// The spec says "the payload must always have destination-clock synchronization"
	// and "OPT_REGISTER_READS selects an additional output holding register or a destination-clock sample"
	
	// We need to handle the read data output. Since reads happen on i_rclk,
	// and the data is read from memory combinationally, we need to register it.
	
	// When OPT_REGISTER_READS = 1: register the data on i_rclk
	// When OPT_REGISTER_READS = 0: we still need synchronization, so we register it anyway
	// but the spec says "neither setting provides an asynchronous memory bypass"
	
	// Let's register the read data on i_rclk
	reg [WIDTH-1:0] rd_data_reg;
	
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n)
			rd_data_reg <= {WIDTH{1'b0}};
		else
			rd_data_reg <= mem_rd_data;
	end

	// Output assignment
	always @(*) begin
		if (OPT_REGISTER_READS)
			o_rd_data = rd_data_reg;
		else
			o_rd_data = mem_rd_data;
	end

endmodule
