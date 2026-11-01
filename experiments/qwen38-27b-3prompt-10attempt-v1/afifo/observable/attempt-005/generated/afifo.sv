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
	localparam PTR_WIDTH = LGFIFO + 1;

	// Write side
	reg [WIDTH-1:0] mem [0:DEPTH-1];
	reg [PTR_WIDTH-1:0] wr_ptr;
	reg [PTR_WIDTH-1:0] wr_ptr_gray;
	reg [PTR_WIDTH-1:0] rd_ptr_gray_wr;
	reg [PTR_WIDTH-1:0] rd_ptr_gray_wr_sync1;
	reg [PTR_WIDTH-1:0] rd_ptr_gray_wr_sync2;
	reg [PTR_WIDTH-1:0] rd_ptr_gray_wr_sync3;
	reg [PTR_WIDTH-1:0] rd_ptr_gray_wr_sync4;
	reg [PTR_WIDTH-1:0] rd_ptr_gray_wr_sync5;
	reg [PTR_WIDTH-1:0] rd_ptr_gray_wr_sync6;
	reg [PTR_WIDTH-1:0] rd_ptr_gray_wr_sync7;
	reg [PTR_WIDTH-1:0] rd_ptr_gray_wr_sync8;

	// Read side
	reg [PTR_WIDTH-1:0] rd_ptr;
	reg [PTR_WIDTH-1:0] rd_ptr_gray;
	reg [PTR_WIDTH-1:0] wr_ptr_gray_rd;
	reg [PTR_WIDTH-1:0] wr_ptr_gray_rd_sync1;
	reg [PTR_WIDTH-1:0] wr_ptr_gray_rd_sync2;
	reg [PTR_WIDTH-1:0] wr_ptr_gray_rd_sync3;
	reg [PTR_WIDTH-1:0] wr_ptr_gray_rd_sync4;
	reg [PTR_WIDTH-1:0] wr_ptr_gray_rd_sync5;
	reg [PTR_WIDTH-1:0] wr_ptr_gray_rd_sync6;
	reg [PTR_WIDTH-1:0] wr_ptr_gray_rd_sync7;
	reg [PTR_WIDTH-1:0] wr_ptr_gray_rd_sync8;

	// Gray code conversion
	function [PTR_WIDTH-1:0] bin2gray;
		input [PTR_WIDTH-1:0] bin;
		begin
			bin2gray = bin ^ (bin >> 1);
		end
	endfunction

	function [PTR_WIDTH-1:0] gray2bin;
		input [PTR_WIDTH-1:0] gray;
		reg [PTR_WIDTH-1:0] bin;
		begin
			bin[PTR_WIDTH-1] = gray[PTR_WIDTH-1];
			for (integer i = PTR_WIDTH-2; i >= 0; i = i - 1)
				bin[i] = gray[i] ^ bin[i+1];
			gray2bin = bin;
		end
	endfunction

	// Write clock domain
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= {PTR_WIDTH{1'b0}};
			wr_ptr_gray <= {PTR_WIDTH{1'b0}};
		end else begin
			if (i_wr && !o_wr_full) begin
				mem[wr_ptr[ADDR_WIDTH-1:0]] <= i_wr_data;
				wr_ptr <= wr_ptr + 1'b1;
				wr_ptr_gray <= bin2gray(wr_ptr + 1'b1);
			end
		end
	end

	// Synchronize read pointer gray code to write domain
	always @(posedge i_wclk) begin
		rd_ptr_gray_wr_sync1 <= rd_ptr_gray;
		rd_ptr_gray_wr_sync2 <= rd_ptr_gray_wr_sync1;
		rd_ptr_gray_wr_sync3 <= rd_ptr_gray_wr_sync2;
		rd_ptr_gray_wr_sync4 <= rd_ptr_gray_wr_sync3;
		rd_ptr_gray_wr_sync5 <= rd_ptr_gray_wr_sync4;
		rd_ptr_gray_wr_sync6 <= rd_ptr_gray_wr_sync5;
		rd_ptr_gray_wr_sync7 <= rd_ptr_gray_wr_sync6;
		rd_ptr_gray_wr_sync8 <= rd_ptr_gray_wr_sync7;
	end

	// Full flag in write domain
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			o_wr_full <= 1'b0;
		end else begin
			// Full when write pointer gray equals read pointer gray with MSB different
			// Actually, full when wr_ptr_gray == rd_ptr_gray_wr_sync8 and the next bit differs
			// Standard: full when wr_ptr_gray == rd_ptr_gray_wr_sync8 ^ (1 << (PTR_WIDTH-1))
			// Wait, let me reconsider. Full condition:
			// wr_ptr_gray == rd_ptr_gray_wr_sync8 with the MSB inverted
			// i.e., wr_ptr_gray == {~rd_ptr_gray_wr_sync8[PTR_WIDTH-1], rd_ptr_gray_wr_sync8[PTR_WIDTH-2:0]}
			o_wr_full <= (wr_ptr_gray == {~rd_ptr_gray_wr_sync8[PTR_WIDTH-1], rd_ptr_gray_wr_sync8[PTR_WIDTH-2:0]});
		end
	end

	// Read clock domain
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= {PTR_WIDTH{1'b0}};
			rd_ptr_gray <= {PTR_WIDTH{1'b0}};
		end else begin
			if (i_rd && !o_rd_empty) begin
				rd_ptr <= rd_ptr + 1'b1;
				rd_ptr_gray <= bin2gray(rd_ptr + 1'b1);
			end
		end
	end

	// Synchronize write pointer gray code to read domain
	always @(posedge i_rclk) begin
		wr_ptr_gray_rd_sync1 <= wr_ptr_gray;
		wr_ptr_gray_rd_sync2 <= wr_ptr_gray_rd_sync1;
		wr_ptr_gray_rd_sync3 <= wr_ptr_gray_rd_sync2;
		wr_ptr_gray_rd_sync4 <= wr_ptr_gray_rd_sync3;
		wr_ptr_gray_rd_sync5 <= wr_ptr_gray_rd_sync4;
		wr_ptr_gray_rd_sync6 <= wr_ptr_gray_rd_sync5;
		wr_ptr_gray_rd_sync7 <= wr_ptr_gray_rd_sync6;
		wr_ptr_gray_rd_sync8 <= wr_ptr_gray_rd_sync7;
	end

	// Empty flag in read domain
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_empty <= 1'b1;
		end else begin
			// Empty when rd_ptr_gray == wr_ptr_gray_rd_sync8
			o_rd_empty <= (rd_ptr_gray == wr_ptr_gray_rd_sync8);
		end
	end

	// Read data output
	// If OPT_REGISTER_READS is 1, register the read data
	// If OPT_REGISTER_READS is 0, combinational read

	// The read address is rd_ptr[ADDR_WIDTH-1:0]
	// But we need to handle the timing carefully.

	// For registered reads, we output the data from the previous read
	// For non-registered reads, we output the data combinationally

	// Let's think about this more carefully.
	// When i_rd is asserted and !o_rd_empty, we read from mem[rd_ptr[ADDR_WIDTH-1:0]]
	// and increment rd_ptr.

	// If OPT_REGISTER_READS = 1:
	//   o_rd_data is registered, so it shows the data from the last read
	//   The read happens on the clock edge, and o_rd_data updates on the next clock edge
	//   Actually, in a typical registered read FIFO, the data is available one cycle after the read request

	// If OPT_REGISTER_READS = 0:
	//   o_rd_data is combinational, showing mem[rd_ptr[ADDR_WIDTH-1:0]]

	// Let me implement both cases.

	// For the read data, we need to be careful about when the data is valid.
	// The data at mem[rd_ptr[ADDR_WIDTH-1:0]] is valid when !o_rd_empty.

	// Let's use a register for the read data when OPT_REGISTER_READS is 1.

	reg [WIDTH-1:0] rd_data_reg;

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_data_reg <= {WIDTH{1'b0}};
		end else begin
			if (i_rd && !o_rd_empty) begin
				rd_data_reg <= mem[rd_ptr[ADDR_WIDTH-1:0]];
			end
		end
	end

	// Assign o_rd_data based on OPT_REGISTER_READS
	// We need to handle this carefully since o_rd_data is a reg output

	// For OPT_REGISTER_READS = 1: o_rd_data = rd_data_reg
	// For OPT_REGISTER_READS = 0: o_rd_data = mem[rd_ptr[ADDR_WIDTH-1:0]]

	// But we can't have a continuous assignment to a reg output in a simple way.
	// Let's use an always block.

	always @(*) begin
		if (OPT_REGISTER_READS) begin
			o_rd_data = rd_data_reg;
		end else begin
			o_rd_data = mem[rd_ptr[ADDR_WIDTH-1:0]];
		end
	end

endmodule
