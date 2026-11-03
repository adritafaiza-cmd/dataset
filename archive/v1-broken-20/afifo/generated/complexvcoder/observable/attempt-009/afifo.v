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

	// Internal signals
	localparam FIFO_SIZE = 2**LGFIFO;
	localparam ADDR_WIDTH = LGFIFO;
	localparam COUNTER_WIDTH = LGFIFO + 1;

	reg [ADDR_WIDTH-1:0] wr_addr, rd_addr;
	reg [COUNTER_WIDTH-1:0] wr_counter, rd_counter;
	reg [WIDTH-1:0] mem [0:FIFO_SIZE-1];
	reg full_flag, empty_flag;

	// Write logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_addr <= 0;
			wr_counter <= 0;
			full_flag <= 0;
		end else if (i_wr && !full_flag) begin
			mem[wr_addr] <= i_wr_data;
			wr_addr <= wr_addr + 1;
			wr_counter <= wr_counter + 1;
			full_flag <= (wr_counter == FIFO_SIZE);
		end
	end

	// Read logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_addr <= 0;
			rd_counter <= 0;
			empty_flag <= 1;
		end else if (i_rd && !empty_flag) begin
			o_rd_data <= mem[rd_addr];
			rd_addr <= rd_addr + 1;
			rd_counter <= rd_counter + 1;
			empty_flag <= (rd_counter == FIFO_SIZE);
		end
	end

	// Full and empty flags
	assign o_wr_full = full_flag;
	assign o_rd_empty = empty_flag;

endmodule
