```verilog
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

	localparam ADDR_WIDTH = LGFIFO;
	localparam FULL_THRESH = (1 << LGFIFO) - 1;
	localparam EMPTY_THRESH = 0;

	// Write side
	reg [ADDR_WIDTH-1:0] wr_ptr, wr_gray;
	reg [ADDR_WIDTH-1:0] rd_ptr, rd_gray;
	reg [WIDTH-1:0] mem [0: (1<<LGFIFO)-1];
	reg [ADDR_WIDTH-1:0] next_rd_ptr;

	// Write pointer logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			o_wr_full <= 0;
		end else if (i_wr && !o_wr_full) begin
			if (WRITE_ON_POSEDGE) begin
				wr_ptr <= wr_ptr + 1'b1;
			end else begin
				// Level sensitive write for compatibility if posedge is disabled
				wr_ptr <= wr_ptr + 1'b1;
			end
		end
	end

	// Write pointer Gray code generation
	always @(*) begin
		wr_gray = wr_ptr;
		wr_gray[ADDR_WIDTH-1] = wr_gray[ADDR_WIDTH-1] ^ wr_gray[ADDR_WIDTH-2];
		if (ADDR_WIDTH > 2)
			wr_gray[ADDR_WIDTH-2] = wr_gray[ADDR_WIDTH-2] ^ wr_gray[ADDR_WIDTH-3];
		// For simplicity in synthesis, standard recursive XOR or manual expansion
		// A robust way for any width:
		wr_gray = wr_ptr;
		for (integer i = ADDR_WIDTH-1; i > 0; i = i - 1) begin
			wr_gray[i-1] = wr_gray[i-1] ^ wr_gray[i];
		end
	end

	// Read pointer logic (Gray code generation)
	always @(*) begin
		rd_gray = rd_ptr;
		for (integer i = ADDR_WIDTH-1; i > 0; i = i - 1) begin
			rd_gray[i-1] = rd_gray[i-1] ^ rd_gray[i];
		end
	end

	// Read pointer update logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
			o_rd_empty <= 1;
		end else if (i_rd && !o_rd_empty) begin
			rd_ptr <= rd_ptr + 1'b1;
		end
	end

	// Full flag logic
	always @(*) begin
		o_wr_full = 0;
		if (wr_gray == rd_gray) begin
			o_wr_full = (wr_ptr >= rd_ptr);
		end
	end

	// Empty flag logic
	always @(*) begin
		o_rd_empty = 0;
		if (wr_gray == rd_gray) begin
			o_rd_empty = (wr_ptr <= rd_ptr);
		end
	end

	// Memory write
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			// Memory content doesn't strictly matter on reset if full is low,
			// but good practice to clear or leave as is.
		end else if (i_wr && !o_wr_full) begin
			mem[wr_ptr] <= i_wr_data;
		end
	end

	// Memory read
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_data <= 0;
		end else if (i_rd && !o_rd_empty) begin
			if (OPT_REGISTER_READS) begin
				// Register the read data for stability
				o_rd_data <= mem[rd_ptr];
			end else begin
				// Combinational read (less stable across clock domains)
				o_rd_data <= mem[rd_ptr];
			end
		end
	end

endmodule
```<|im_end|>
