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

	reg [ADDR_WIDTH-1:0] wr_ptr, wr_ptr_gray, wr_ptr_gray_sync;
	reg [ADDR_WIDTH-1:0] rd_ptr, rd_ptr_gray, rd_ptr_gray_sync;
	reg [WIDTH-1:0] mem [DEPTH-1:0];

	// Write Pointer Logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			wr_ptr_gray <= 0;
		end else if (i_wr && !o_wr_full) begin
			if (WRITE_ON_POSEDGE) begin
				wr_ptr <= wr_ptr + 1;
				wr_ptr_gray <= (wr_ptr + 1) ^ ((wr_ptr + 1) >> 1);
			end else begin
				wr_ptr <= wr_ptr;
				wr_ptr_gray <= wr_ptr_gray;
			end
		end else if (!WRITE_ON_POSEDGE) begin
			wr_ptr <= wr_ptr + 1;
			wr_ptr_gray <= (wr_ptr + 1) ^ ((wr_ptr + 1) >> 1);
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

	// Write Data to Memory
	always @(posedge i_wclk) begin
		if (i_wr && !o_wr_full) begin
			mem[wr_ptr] <= i_wr_data;
		end
	end

	// Gray Code Synchronization
	generate
		genvar i;
		for (i = 0; i < NFF; i = i + 1) begin : sync_wr_ptr_gray
			reg [ADDR_WIDTH-1:0] wr_ptr_gray_sync_stage;
			if (i == 0) begin
				always @(posedge i_rclk or negedge i_rd_reset_n) begin
					if (!i_rd_reset_n) begin
						wr_ptr_gray_sync_stage <= 0;
					end else begin
						wr_ptr_gray_sync_stage <= wr_ptr_gray;
					end
				end
			end else begin
				always @(posedge i_rclk or negedge i_rd_reset_n) begin
					if (!i_rd_reset_n) begin
						wr_ptr_gray_sync_stage <= 0;
					end else begin
						wr_ptr_gray_sync_stage <= wr_ptr_gray_sync_stage;
					end
				end
			end
			if (i == NFF - 1) begin
				assign wr_ptr_gray_sync = wr_ptr_gray_sync_stage;
			end
		end
	endgenerate

	generate
		genvar j;
		for (j = 0; j < NFF; j = j + 1) begin : sync_rd_ptr_gray
			reg [ADDR_WIDTH-1:0] rd_ptr_gray_sync_stage;
			if (j == 0) begin
				always @(posedge i_wclk or negedge i_wr_reset_n) begin
					if (!i_wr_reset_n) begin
						rd_ptr_gray_sync_stage <= 0;
					end else begin
						rd_ptr_gray_sync_stage <= rd_ptr_gray;
					end
				end
			end else begin
				always @(posedge i_wclk or negedge i_wr_reset_n) begin
					if (!i_wr_reset_n) begin
						rd_ptr_gray_sync_stage <= 0;
					end else begin
						rd_ptr_gray_sync_stage <= rd_ptr_gray_sync_stage;
					end
				end
			end
			if (j == NFF - 1) begin
				assign rd_ptr_gray_sync = rd_ptr_gray_sync_stage;
			end
		end
	endgenerate

	// Full and Empty Flags
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			o_wr_full <= 0;
		end else begin
			o_wr_full <= (wr_ptr_gray_sync == (rd_ptr_gray + 1) ^ ((rd_ptr_gray + 1) >> 1));
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_empty <= 1;
		end else begin
			o_rd_empty <= (wr_ptr_gray_sync == rd_ptr_gray);
		end
	end

	// Read Data from Memory
	reg [WIDTH-1:0] rd_data_sync;
	always @(posedge i_rclk) begin
		if (i_rd && !o_rd_empty) begin
			rd_data_sync <= mem[rd_ptr];
		end
	end

	// Output Data
	generate
		if (OPT_REGISTER_READS) begin
			reg [WIDTH-1:0] rd_data_reg;
			always @(posedge i_rclk or negedge i_rd_reset_n) begin
				if (!i_rd_reset_n) begin
					rd_data_reg <= 0;
				end else if (i_rd && !o_rd_empty) begin
					rd_data_reg <= rd_data_sync;
				end
			end
			assign o_rd_data = rd_data_reg;
		end else begin
			assign o_rd_data = rd_data_sync;
		end
	endgenerate

endmodule
