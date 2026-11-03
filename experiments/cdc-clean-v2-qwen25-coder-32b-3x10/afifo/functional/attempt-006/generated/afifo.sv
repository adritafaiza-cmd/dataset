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

	reg [WIDTH-1:0] mem [0:DEPTH-1];
	reg [ADDR_WIDTH:0] wr_ptr, rd_ptr;
	reg [ADDR_WIDTH:0] wr_ptr_gray, rd_ptr_gray;
	reg [ADDR_WIDTH:0] wr_ptr_gray_sync, rd_ptr_gray_sync;

	// Write Pointer Logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			wr_ptr_gray <= 0;
		end else if (i_wr && !o_wr_full) begin
			if (WRITE_ON_POSEDGE) begin
				mem[wr_ptr[ADDR_WIDTH-1:0]] <= i_wr_data;
				wr_ptr <= wr_ptr + 1;
				wr_ptr_gray <= (wr_ptr + 1) ^ ((wr_ptr + 1) >> 1);
			end else begin
				mem[wr_ptr[ADDR_WIDTH-1:0]] <= i_wr_data;
				wr_ptr_gray <= (wr_ptr + 1) ^ ((wr_ptr + 1) >> 1);
				wr_ptr <= wr_ptr + 1;
			end
		end
	end

	// Read Pointer Logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
			rd_ptr_gray <= 0;
		end else if (i_rd && !o_rd_empty) begin
			rd_ptr <= rd_ptr + 1;
			rd_ptr_gray <= (rd_ptr + 1) ^ ((rd_ptr + 1) >> 1);
		end
	end

	// Gray Code Synchronization
	generate
		genvar i;
		for (i = 0; i < NFF; i = i + 1) begin : sync_wr_ptr_gray
			reg [ADDR_WIDTH:0] wr_ptr_gray_sync_stage;
			if (i == 0) begin
				always @(posedge i_rclk or negedge i_rd_reset_n) begin
					if (!i_rd_reset_n)
						wr_ptr_gray_sync_stage <= 0;
					else
						wr_ptr_gray_sync_stage <= wr_ptr_gray;
				end
			end else begin
				always @(posedge i_rclk or negedge i_rd_reset_n) begin
					if (!i_rd_reset_n)
						wr_ptr_gray_sync_stage <= 0;
					else
						wr_ptr_gray_sync_stage <= wr_ptr_gray_sync[i-1];
				end
			end
			assign wr_ptr_gray_sync[i] = wr_ptr_gray_sync_stage;
		end
	endgenerate

	generate
		genvar j;
		for (j = 0; j < NFF; j = j + 1) begin : sync_rd_ptr_gray
			reg [ADDR_WIDTH:0] rd_ptr_gray_sync_stage;
			if (j == 0) begin
				always @(posedge i_wclk or negedge i_wr_reset_n) begin
					if (!i_wr_reset_n)
						rd_ptr_gray_sync_stage <= 0;
					else
						rd_ptr_gray_sync_stage <= rd_ptr_gray;
				end
			end else begin
				always @(posedge i_wclk or negedge i_wr_reset_n) begin
					if (!i_wr_reset_n)
						rd_ptr_gray_sync_stage <= 0;
					else
						rd_ptr_gray_sync_stage <= rd_ptr_gray_sync[j-1];
				end
			end
			assign rd_ptr_gray_sync[j] = rd_ptr_gray_sync_stage;
		end
	endgenerate

	assign wr_ptr_gray_sync = wr_ptr_gray_sync[NFF-1];
	assign rd_ptr_gray_sync = rd_ptr_gray_sync[NFF-1];

	// Full and Empty Flags
	assign o_wr_full = (wr_ptr_gray_sync[ADDR_WIDTH:0] == {~rd_ptr_gray_sync[ADDR_WIDTH], rd_ptr_gray_sync[ADDR_WIDTH-1:0]});
	assign o_rd_empty = (wr_ptr_gray_sync[ADDR_WIDTH:0] == rd_ptr_gray_sync[ADDR_WIDTH:0]);

	// Read Data Output
	reg [WIDTH-1:0] rd_data_reg;

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n)
			rd_data_reg <= 0;
		else if (i_rd && !o_rd_empty)
			rd_data_reg <= mem[rd_ptr[ADDR_WIDTH-1:0]];
	end

	assign o_rd_data = OPT_REGISTER_READS ? rd_data_reg : mem[rd_ptr[ADDR_WIDTH-1:0]];

endmodule
