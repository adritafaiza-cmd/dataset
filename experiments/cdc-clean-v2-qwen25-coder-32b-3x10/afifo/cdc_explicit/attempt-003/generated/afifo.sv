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
	reg [ADDR_WIDTH-1:0] wptr, rptr;
	reg [ADDR_WIDTH:0] wptr_gray, rptr_gray;
	reg [ADDR_WIDTH:0] wptr_gray_sync, rptr_gray_sync;

	// Write Pointer Logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wptr <= 0;
			wptr_gray <= 0;
			o_wr_full <= 0;
		end else begin
			if (i_wr && !o_wr_full) begin
				if (WRITE_ON_POSEDGE) begin
					mem[wptr] <= i_wr_data;
					wptr <= wptr + 1;
				end else begin
					mem[wptr + 1] <= i_wr_data;
					wptr <= wptr + 1;
				end
			end
			wptr_gray <= {wptr[ADDR_WIDTH-1:0] ^ (wptr[ADDR_WIDTH-1:0] >> 1), 1'b0};
			o_wr_full <= (wptr_gray[ADDR_WIDTH:ADDR_WIDTH-ADDR_WIDTH] == rptr_gray_sync[ADDR_WIDTH:ADDR_WIDTH-ADDR_WIDTH]) && (wptr_gray[ADDR_WIDTH-1:0] != rptr_gray_sync[ADDR_WIDTH-1:0]);
		end
	end

	// Read Pointer Logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rptr <= 0;
			rptr_gray <= 0;
			o_rd_empty <= 1;
		end else begin
			if (i_rd && !o_rd_empty) begin
				rptr <= rptr + 1;
			end
			rptr_gray <= {rptr[ADDR_WIDTH-1:0] ^ (rptr[ADDR_WIDTH-1:0] >> 1), 1'b0};
			o_rd_empty <= (wptr_gray_sync[ADDR_WIDTH:ADDR_WIDTH-ADDR_WIDTH] == rptr_gray[ADDR_WIDTH:ADDR_WIDTH-ADDR_WIDTH]) && (wptr_gray_sync[ADDR_WIDTH-1:0] == rptr_gray[ADDR_WIDTH-1:0]);
		end
	end

	// Gray Code Synchronization
	generate
		genvar i;
		for (i = 0; i < NFF; i = i + 1) begin : sync_wptr_gray
			reg [ADDR_WIDTH:0] wptr_gray_sync_stage;
			always @(posedge i_rclk or negedge i_rd_reset_n) begin
				if (!i_rd_reset_n) begin
					wptr_gray_sync_stage <= 0;
				end else begin
					wptr_gray_sync_stage <= (i == 0) ? wptr_gray : wptr_gray_sync_stage;
				end
			end
			assign wptr_gray_sync = (i == NFF - 1) ? wptr_gray_sync_stage : wptr_gray_sync;
		end
	endgenerate

	generate
		genvar j;
		for (j = 0; j < NFF; j = j + 1) begin : sync_rptr_gray
			reg [ADDR_WIDTH:0] rptr_gray_sync_stage;
			always @(posedge i_wclk or negedge i_wr_reset_n) begin
				if (!i_wr_reset_n) begin
					rptr_gray_sync_stage <= 0;
				end else begin
					rptr_gray_sync_stage <= (j == 0) ? rptr_gray : rptr_gray_sync_stage;
				end
			end
			assign rptr_gray_sync = (j == NFF - 1) ? rptr_gray_sync_stage : rptr_gray_sync;
		end
	endgenerate

	// Read Data Output
	reg [WIDTH-1:0] rd_data_sync;
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_data_sync <= 0;
		end else if (i_rd && !o_rd_empty) begin
			rd_data_sync <= mem[rptr];
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_data <= 0;
		end else if (OPT_REGISTER_READS) begin
			o_rd_data <= rd_data_sync;
		end else begin
			o_rd_data <= mem[rptr];
		end
	end

endmodule
