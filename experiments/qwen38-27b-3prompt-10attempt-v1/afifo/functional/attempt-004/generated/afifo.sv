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

	// Write pointer
	reg [ADDR_W-1:0] wptr;
	reg [CNT_W-1:0] wcnt;

	// Read pointer
	reg [ADDR_W-1:0] rptr;
	reg [CNT_W-1:0] rcnt;

	// Memory
	reg [WIDTH-1:0] mem [0:DEPTH-1];

	// Gray code pointers
	wire [ADDR_W-1:0] wptr_gray = wptr ^ {wptr[ADDR_W-1:0], {wptr[ADDR_W-1:0], 1'b0}};
	wire [ADDR_W-1:0] rptr_gray = rptr ^ {rptr[ADDR_W-1:0], {rptr[ADDR_W-1:0], 1'b0}};

	// Synchronizers for write pointer gray to read clock domain
	reg [ADDR_W-1:0] wptr_gray_sync [0:NFF-1];
	// Synchronizers for read pointer gray to write clock domain
	reg [ADDR_W-1:0] rptr_gray_sync [0:NFF-1];

	// Convert gray to binary
	function [ADDR_W-1:0] gray2bin;
		input [ADDR_W-1:0] gray;
		reg [ADDR_W-1:0] bin;
		begin
			bin[ADDR_W-1] = gray[ADDR_W-1];
			for (i = ADDR_W-2; i >= 0; i = i - 1)
				bin[i] = bin[i+1] ^ gray[i];
		end
	endfunction

	// Synchronizer logic
	integer i;
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			for (i = 0; i < NFF; i = i + 1)
				wptr_gray_sync[i] <= {ADDR_W{1'b0}};
		end else begin
			wptr_gray_sync[0] <= wptr_gray;
			for (i = 1; i < NFF; i = i + 1)
				wptr_gray_sync[i] <= wptr_gray_sync[i-1];
		end
	end

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			for (i = 0; i < NFF; i = i + 1)
				rptr_gray_sync[i] <= {ADDR_W{1'b0}};
		end else begin
			rptr_gray_sync[0] <= rptr_gray;
			for (i = 1; i < NFF; i = i + 1)
				rptr_gray_sync[i] <= rptr_gray_sync[i-1];
		end
	end

	// Write domain logic
	wire wclk_edge = WRITE_ON_POSEDGE ? i_wclk : ~i_wclk;
	wire wclk_edge_neg = WRITE_ON_POSEDGE ? ~i_wclk : i_wclk;

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wptr <= {ADDR_W{1'b0}};
			wcnt <= {CNT_W{1'b0}};
			o_wr_full <= 1'b0;
		end else begin
			if (i_wr && !o_wr_full) begin
				mem[wptr] <= i_wr_data;
				wptr <= wptr + 1'b1;
				wcnt <= wcnt + 1'b1;
			end
			// Update full flag based on synchronized read pointer
			begin
				wire [ADDR_W-1:0] rptr_bin_sync = gray2bin(rptr_gray_sync[NFF-1]);
				wire [CNT_W-1:0] diff = wcnt - {1'b0, rptr_bin_sync};
				o_wr_full <= (diff == DEPTH);
			end
		end
	end

	// Read domain logic
	wire rclk_edge = i_rclk;
	wire rclk_edge_neg = ~i_rclk;

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rptr <= {ADDR_W{1'b0}};
			rcnt <= {CNT_W{1'b0}};
			o_rd_empty <= 1'b1;
			o_rd_data <= {WIDTH{1'b0}};
		end else begin
			if (i_rd && !o_rd_empty) begin
				rptr <= rptr + 1'b1;
				rcnt <= rcnt + 1'b1;
			end
			// Update empty flag based on synchronized write pointer
			begin
				wire [ADDR_W-1:0] wptr_bin_sync = gray2bin(wptr_gray_sync[NFF-1]);
				wire [CNT_W-1:0] diff = wcnt - {1'b0, rptr_bin_sync};
				o_rd_empty <= (diff == 0);
			end
			// Read data
			if (OPT_REGISTER_READS) begin
				if (i_rd && !o_rd_empty)
					o_rd_data <= mem[rptr];
			end else begin
				if (i_rd && !o_rd_empty)
					o_rd_data <= mem[rptr];
			end
		end
	end

endmodule
