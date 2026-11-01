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
	localparam ADDR_W = LGFIFO;
	localparam CNT_W = LGFIFO + 1;

	// Memory
	reg [WIDTH-1:0] mem [0:DEPTH-1];

	// Write pointer
	reg [ADDR_W:0] wptr;
	reg [ADDR_W-1:0] waddr;
	wire [ADDR_W-1:0] waddr_next = wptr[ADDR_W-1:0];

	// Read pointer
	reg [ADDR_W:0] rptr;
	reg [ADDR_W-1:0] raddr;
	wire [ADDR_W-1:0] raddr_next = rptr[ADDR_W-1:0];

	// Gray code pointers
	wire [ADDR_W:0] wptr_gray = wptr ^ {wptr[ADDR_W-1:0], 1'b0} >> 1;
	wire [ADDR_W:0] rptr_gray = rptr ^ {rptr[ADDR_W-1:0], 1'b0} >> 1;

	// Synchronizers for write pointer gray to read domain
	reg [ADDR_W:0] r_wptr_gray_sync [0:NFF-1];
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			r_wptr_gray_sync[0] <= {ADDR_W+1{1'b0}};
			r_wptr_gray_sync[1] <= {ADDR_W+1{1'b0}};
			if (NFF > 2) begin
				integer i;
				for (i = 2; i < NFF; i = i + 1)
					r_wptr_gray_sync[i] <= {ADDR_W+1{1'b0}};
			end
		end else begin
			r_wptr_gray_sync[0] <= wptr_gray;
			r_wptr_gray_sync[1] <= r_wptr_gray_sync[0];
			if (NFF > 2) begin
				integer i;
				for (i = 2; i < NFF; i = i + 1)
					r_wptr_gray_sync[i] <= r_wptr_gray_sync[i-1];
			end
		end
	end
	wire [ADDR_W:0] r_wptr_gray = r_wptr_gray_sync[NFF-1];

	// Synchronizers for read pointer gray to write domain
	reg [ADDR_W:0] w_rptr_gray_sync [0:NFF-1];
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			w_rptr_gray_sync[0] <= {ADDR_W+1{1'b0}};
			w_rptr_gray_sync[1] <= {ADDR_W+1{1'b0}};
			if (NFF > 2) begin
				integer i;
				for (i = 2; i < NFF; i = i + 1)
					w_rptr_gray_sync[i] <= {ADDR_W+1{1'b0}};
			end
		end else begin
			w_rptr_gray_sync[0] <= rptr_gray;
			w_rptr_gray_sync[1] <= w_rptr_gray_sync[0];
			if (NFF > 2) begin
				integer i;
				for (i = 2; i < NFF; i = i + 1)
					w_rptr_gray_sync[i] <= w_rptr_gray_sync[i-1];
			end
		end
	end
	wire [ADDR_W:0] w_rptr_gray = w_rptr_gray_sync[NFF-1];

	// Convert gray to binary
	function [ADDR_W:0] gray2bin;
		input [ADDR_W:0] gray;
		reg [ADDR_W:0] bin;
		begin
			bin[ADDR_W] = gray[ADDR_W];
			if (ADDR_W > 0) begin
				integer i;
				for (i = ADDR_W-1; i >= 0; i = i - 1)
					bin[i] = bin[i+1] ^ gray[i];
			end
			gray2bin = bin;
		end
	endfunction

	wire [ADDR_W:0] r_wptr_bin = gray2bin(r_wptr_gray);
	wire [ADDR_W:0] w_rptr_bin = gray2bin(w_rptr_gray);

	// Full condition: write pointer MSB differs from read pointer MSB, and lower bits equal
	wire full = (wptr[ADDR_W] != w_rptr_bin[ADDR_W]) && (wptr[ADDR_W-1:0] == w_rptr_bin[ADDR_W-1:0]);

	// Empty condition: read pointer equals write pointer
	wire empty = (rptr == r_wptr_bin);

	// Write enable
	wire w_en = i_wr & ~full;

	// Read enable
	wire r_en = i_rd & ~empty;

	// Write clock edge selection
	wire wclk_edge = WRITE_ON_POSEDGE ? i_wclk : ~i_wclk;
	wire wclk_reset = i_wr_reset_n;

	// Write pointer update
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n)
			wptr <= {ADDR_W+1{1'b0}};
		else if (w_en)
			wptr <= wptr + 1'b1;
	end

	// Read pointer update
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n)
			rptr <= {ADDR_W+1{1'b0}};
		else if (r_en)
			rptr <= rptr + 1'b1;
	end

	// Memory write
	always @(posedge i_wclk) begin
		if (w_en)
			mem[waddr_next] <= i_wr_data;
	end

	// Read data
	wire [WIDTH-1:0] mem_rd_data = mem[raddr_next];

	// Output registers
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_data <= {WIDTH{1'b0}};
			o_rd_empty <= 1'b1;
		end else begin
			if (OPT_REGISTER_READS) begin
				o_rd_data <= mem_rd_data;
				o_rd_empty <= empty;
			end else begin
				o_rd_data <= mem_rd_data;
				o_rd_empty <= empty;
			end
		end
	end

	// Full flag output
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n)
			o_wr_full <= 1'b0;
		else
			o_wr_full <= full;
	end

endmodule
