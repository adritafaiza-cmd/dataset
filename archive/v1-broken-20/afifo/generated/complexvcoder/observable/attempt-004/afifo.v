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

	parameter FIFO_SIZE = 2**LGFIFO;
	parameter ADDR_WIDTH = $clog2(FIFO_SIZE);

	localparam [ADDR_WIDTH-1:0] ADDR_ALL_ONES = FIFO_SIZE-1;

	wire [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
	wire [ADDR_WIDTH-1:0] wr_next, rd_next;
	wire full, empty;
	wire [WIDTH-1:0] mem [0:FIFO_SIZE-1];

	// Write pointer logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
		end else if (i_wr && !full) begin
			wr_ptr <= wr_next;
		end
	end

	// Read pointer logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
		end else if (i_rd && !empty) begin
			rd_ptr <= rd_next;
		end
	end

	// Next write pointer logic
	always @(*) begin
		if (WRITE_ON_POSEDGE && i_wr && !full) begin
			wr_next = wr_ptr + 1;
		end else begin
			wr_next = wr_ptr;
		end
	end

	// Next read pointer logic
	always @(*) begin
		if (i_rd && !empty) begin
			rd_next = rd_ptr + 1;
		end else begin
			rd_next = rd_ptr;
		end
	end

	// Full and empty flags
	assign full = wr_next == rd_ptr;
	assign empty = wr_ptr == rd_ptr;

	// FIFO memory
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			for (integer i = 0; i < FIFO_SIZE; i = i + 1) begin
				mem[i] <= 0;
			end
		end else if (i_wr && !full) begin
			mem[wr_ptr] <= i_wr_data;
		end
	end

	// Read data output
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_data <= 0;
		end else if (i_rd && !empty) begin
			o_rd_data <= mem[rd_ptr];
		end
	end

	// Registered read data output
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_data <= 0;
		end else if (i_rd && !empty) begin
			o_rd_data <= mem[rd_ptr];
		end
	end

	// Empty flag output
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_empty <= 1;
		end else begin
			o_rd_empty <= empty;
		end
	end

endmodule
