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

	// Gray Code Synchronization
	generate
		genvar i;
		for (i = 0; i < NFF; i = i + 1) begin : sync_gray
			if (i == 0) begin
				always @(posedge i_rclk or negedge i_rd_reset_n) begin
					if (!i_rd_reset_n) begin
						wr_ptr_gray_sync[0] <= 0;
					end else begin
						wr_ptr_gray_sync[0] <= wr_ptr_gray[0];
					end
				end
				always @(posedge i_wclk or negedge i_wr_reset_n) begin
					if (!i_wr_reset_n) begin
						rd_ptr_gray_sync[0] <= 0;
					end else begin
						rd_ptr_gray_sync[0] <= rd_ptr_gray[0];
					end
				end
			end else begin
				always @(posedge i_rclk or negedge i_rd_reset_n) begin
					if (!i_rd_reset_n) begin
						wr_ptr_gray_sync[i] <= 0;
					end else begin
						wr_ptr_gray_sync[i] <= wr_ptr_gray_sync[i-1];
					end
				end
				always @(posedge i_wclk or negedge i_wr_reset_n) begin
					if (!i_wr_reset_n) begin
						rd_ptr_gray_sync[i] <= 0;
					end else begin
						rd_ptr_gray_sync[i] <= rd_ptr_gray_sync[i-1];
					end
				end
			end
		end
	endgenerate

	// Full and Empty Flags
	wire [ADDR_WIDTH-1:0] wr_ptr_gray_sync_final = wr_ptr_gray_sync[NFF-1];
	wire [ADDR_WIDTH-1:0] rd_ptr_gray_sync_final = rd_ptr_gray_sync[NFF-1];

	assign o_wr_full = (wr_ptr_gray_sync_final ^ wr_ptr_gray) == {ADDR_WIDTH{1'b1}};
	assign o_rd_empty = (rd_ptr_gray_sync_final ^ rd_ptr_gray) == {ADDR_WIDTH{1'b0}};

	// Memory Write Logic
	always @(posedge i_wclk) begin
		if (i_wr && !o_wr_full) begin
			mem[wr_ptr] <= i_wr_data;
		end
	end

	// Memory Read Logic
	reg [WIDTH-1:0] rd_data_sync;
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_data_sync <= 0;
		end else if (i_rd && !o_rd_empty) begin
			rd_data_sync <= mem[rd_ptr];
		end
	end

	// Output Data Registering
	generate
		if (OPT_REGISTER_READS) begin
			always @(posedge i_rclk or negedge i_rd_reset_n) begin
				if (!i_rd_reset_n) begin
					o_rd_data <= 0;
				end else begin
					o_rd_data <= rd_data_sync;
				end
			end
		end else begin
			assign o_rd_data = rd_data_sync;
		end
	endgenerate

endmodule
