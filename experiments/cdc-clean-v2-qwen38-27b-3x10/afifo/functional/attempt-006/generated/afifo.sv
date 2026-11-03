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
	localparam GRAY_W = LGFIFO + 1;

	// Write side
	reg [WIDTH-1:0] mem [0:DEPTH-1];
	reg [ADDR_W-1:0] wr_ptr;
	reg [ADDR_W-1:0] wr_ptr_gray;
	reg [CNT_W-1:0] wr_count;

	// Read side
	reg [ADDR_W-1:0] rd_ptr;
	reg [ADDR_W-1:0] rd_ptr_gray;
	reg [CNT_W-1:0] rd_count;

	// Synchronizers
	reg [GRAY_W-1:0] wr_gray_sync [0:NFF-1];
	reg [GRAY_W-1:0] rd_gray_sync [0:NFF-1];

	// Write clock domain
	wire wr_clk_edge = WRITE_ON_POSEDGE ? i_wclk : ~i_wclk;
	wire wr_clk_neg  = WRITE_ON_POSEDGE ? ~i_wclk : i_wclk;

	// Write pointer and count
	reg [ADDR_W-1:0] wr_ptr_next;
	reg [ADDR_W-1:0] wr_ptr_gray_next;
	reg [CNT_W-1:0] wr_count_next;

	// Read pointer and count
	reg [ADDR_W-1:0] rd_ptr_next;
	reg [ADDR_W-1:0] rd_ptr_gray_next;
	reg [CNT_W-1:0] rd_count_next;

	// Gray code conversion functions
	function [GRAY_W-1:0] bin2gray;
		input [CNT_W-1:0] bin;
		begin
			bin2gray = bin ^ (bin >> 1);
		end
	endfunction

	function [CNT_W-1:0] gray2bin;
		input [GRAY_W-1:0] gray;
		reg [CNT_W-1:0] bin;
		begin
			bin[GRAY_W-1] = gray[GRAY_W-1];
			for (integer i = GRAY_W-2; i >= 0; i = i - 1)
				bin[i] = bin[i+1] ^ gray[i];
			gray2bin = bin;
		end
	endfunction

	// Write side logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= {ADDR_W{1'b0}};
			wr_ptr_gray <= {GRAY_W{1'b0}};
			wr_count <= {CNT_W{1'b0}};
		end else begin
			wr_ptr <= wr_ptr_next;
			wr_ptr_gray <= wr_ptr_gray_next;
			wr_count <= wr_count_next;
		end
	end

	// Write memory
	always @(posedge i_wclk) begin
		if (i_wr && !o_wr_full) begin
			mem[wr_ptr] <= i_wr_data;
		end
	end

	// Read side logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= {ADDR_W{1'b0}};
			rd_ptr_gray <= {GRAY_W{1'b0}};
			rd_count <= {CNT_W{1'b0}};
		end else begin
			rd_ptr <= rd_ptr_next;
			rd_ptr_gray <= rd_ptr_gray_next;
			rd_count <= rd_count_next;
		end
	end

	// Synchronizers
	always @(posedge i_rclk) begin
		wr_gray_sync[0] <= wr_ptr_gray;
		for (integer i = 1; i < NFF; i = i + 1)
			wr_gray_sync[i] <= wr_gray_sync[i-1];
	end

	always @(posedge i_wclk) begin
		rd_gray_sync[0] <= rd_ptr_gray;
		for (integer i = 1; i < NFF; i = i + 1)
			rd_gray_sync[i] <= rd_gray_sync[i-1];
	end

	// Compute next states
	// Write side: convert synchronized read gray to binary
	wire [CNT_W-1:0] rd_count_sync = gray2bin(rd_gray_sync[NFF-1]);
	wire [CNT_W-1:0] wr_count_sync = gray2bin(wr_gray_sync[NFF-1]);

	// Write side next state
	assign wr_ptr_next = (i_wr && !o_wr_full) ? (wr_ptr + 1'b1) : wr_ptr;
	assign wr_ptr_gray_next = bin2gray(wr_ptr_next);
	assign wr_count_next = (i_wr && !o_wr_full) ? (wr_count + 1'b1) : wr_count;

	// Read side next state
	assign rd_ptr_next = (i_rd && !o_rd_empty) ? (rd_ptr + 1'b1) : rd_ptr;
	assign rd_ptr_gray_next = bin2gray(rd_ptr_next);
	assign rd_count_next = (i_rd && !o_rd_empty) ? (rd_count + 1'b1) : rd_count;

	// Full and empty flags
	// Full: write count == DEPTH
	assign o_wr_full = (wr_count == DEPTH);

	// Empty: read count == 0
	assign o_rd_empty = (rd_count == 0);

	// Read data
	wire [WIDTH-1:0] mem_rd_data = mem[rd_ptr];

	// Output registering
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_data <= {WIDTH{1'b0}};
			o_rd_empty <= 1'b1;
		end else begin
			if (OPT_REGISTER_READS) begin
				// Register the read data and empty flag
				o_rd_data <= mem_rd_data;
				o_rd_empty <= (rd_count == 0);
			end else begin
				// Direct sample (still synchronized to read clock)
				o_rd_data <= mem_rd_data;
				o_rd_empty <= (rd_count == 0);
			end
		end
	end

endmodule
