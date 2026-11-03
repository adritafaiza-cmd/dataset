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

	localparam DEPTH = 2**LGFIFO;
	localparam ADDR_WIDTH = LGFIFO;

	reg [WIDTH-1:0] mem [0:DEPTH-1];
	reg [ADDR_WIDTH:0] wr_ptr, rd_ptr;
	reg [ADDR_WIDTH:0] wr_ptr_gray, rd_ptr_gray;
	reg [ADDR_WIDTH:0] wr_ptr_gray_sync, rd_ptr_gray_sync;

	// Write side logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			wr_ptr_gray <= 0;
			o_wr_full <= 1'b0;
		end else if (i_wr && !o_wr_full) begin
			mem[wr_ptr[ADDR_WIDTH-1:0]] <= i_wr_data;
			wr_ptr <= wr_ptr + 1;
			wr_ptr_gray <= wr_ptr_gray + 1;
		end
	end

	// Gray code conversion and synchronization
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			wr_ptr_gray_sync <= 0;
		end else begin
			wr_ptr_gray_sync <= wr_ptr_gray;
		end
	end

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			rd_ptr_gray_sync <= 0;
		end else begin
			rd_ptr_gray_sync <= rd_ptr_gray;
		end
	end

	// Read side logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
			rd_ptr_gray <= 0;
			o_rd_empty <= 1'b1;
		end else if (i_rd && !o_rd_empty) begin
			rd_ptr <= rd_ptr + 1;
			rd_ptr_gray <= rd_ptr_gray + 1;
		end
	end

	// Full and empty flags
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			o_wr_full <= 1'b0;
		end else begin
			o_wr_full <= (wr_ptr_gray_sync[ADDR_WIDTH:ADDR_WIDTH-1] != wr_ptr_gray[ADDR_WIDTH:ADDR_WIDTH-1]) &&
				          (wr_ptr_gray_sync[ADDR_WIDTH-1:0] == wr_ptr_gray[ADDR_WIDTH-1:0]);
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_empty <= 1'b1;
		end else begin
			o_rd_empty <= (rd_ptr_gray_sync[ADDR_WIDTH:ADDR_WIDTH-1] != rd_ptr_gray[ADDR_WIDTH:ADDR_WIDTH-1]) &&
				           (rd_ptr_gray_sync[ADDR_WIDTH-1:0] == rd_ptr_gray[ADDR_WIDTH-1:0]);
		end
	end

	// Read data output
	reg [WIDTH-1:0] rd_data_reg;

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_data_reg <= 0;
		end else if (i_rd && !o_rd_empty) begin
			rd_data_reg <= mem[rd_ptr[ADDR_WIDTH-1:0]];
		end
	end

	assign o_rd_data = OPT_REGISTER_READS ? rd_data_reg : mem[rd_ptr[ADDR_WIDTH-1:0]];

endmodule
