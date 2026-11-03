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
	localparam AW = LGFIFO;

	reg [AW:0] wr_ptr, wr_ptr_gray, wr_ptr_gray_sync;
	reg [AW:0] rd_ptr, rd_ptr_gray, rd_ptr_gray_sync;

	// Write side logic
	reg [WIDTH-1:0] mem [DEPTH-1:0];

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			o_wr_full <= 1'b0;
		end else begin
			if (i_wr && !o_wr_full) begin
				mem[wr_ptr[AW-1:0]] <= i_wr_data;
				wr_ptr <= wr_ptr + 1;
			end
			wr_ptr_gray <= {wr_ptr[AW], wr_ptr[AW-1:0] ^ wr_ptr[AW:1]};
		end
	end

	// Synchronize wr_ptr_gray to read clock domain
	generate
		genvar i;
		for (i = 0; i < NFF; i = i + 1) begin : sync_wr_ptr_gray
			reg [AW:0] ff;
			if (i == 0) begin
				always @(posedge i_rclk or negedge i_rd_reset_n) begin
					if (!i_rd_reset_n)
						ff <= 0;
					else
						ff <= wr_ptr_gray;
				end
			end else begin
				always @(posedge i_rclk or negedge i_rd_reset_n) begin
					if (!i_rd_reset_n)
						ff <= 0;
					else
						ff <= sync_wr_ptr_gray[i-1].ff;
				end
			end
			assign sync_wr_ptr_gray[i].ff = ff;
		end
	endgenerate

	assign wr_ptr_gray_sync = sync_wr_ptr_gray[NFF-1].ff;

	// Read side logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
			o_rd_empty <= 1'b1;
		end else begin
			if (i_rd && !o_rd_empty) begin
				rd_ptr <= rd_ptr + 1;
			end
			rd_ptr_gray <= {rd_ptr[AW], rd_ptr[AW-1:0] ^ rd_ptr[AW:1]};
		end
	end

	// Synchronize rd_ptr_gray to write clock domain
	generate
		genvar j;
		for (j = 0; j < NFF; j = j + 1) begin : sync_rd_ptr_gray
			reg [AW:0] ff;
			if (j == 0) begin
				always @(posedge i_wclk or negedge i_wr_reset_n) begin
					if (!i_wr_reset_n)
						ff <= 0;
					else
						ff <= rd_ptr_gray;
				end
			end else begin
				always @(posedge i_wclk or negedge i_wr_reset_n) begin
					if (!i_wr_reset_n)
						ff <= 0;
					else
						ff <= sync_rd_ptr_gray[j-1].ff;
				end
			end
			assign sync_rd_ptr_gray[j].ff = ff;
		end
	endgenerate

	assign rd_ptr_gray_sync = sync_rd_ptr_gray[NFF-1].ff;

	// Gray to binary conversion and full/empty flags
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			o_wr_full <= 1'b0;
		end else begin
			o_wr_full <= (wr_ptr_gray_sync[AW] != wr_ptr_gray[AW]) && (wr_ptr_gray_sync[AW-1:0] == wr_ptr[AW:1]);
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_empty <= 1'b1;
		end else begin
			o_rd_empty <= (rd_ptr_gray_sync[AW] != rd_ptr_gray[AW]) && (rd_ptr_gray_sync[AW-1:0] == rd_ptr[AW:1]);
		end
	end

	// Read data output
	reg [WIDTH-1:0] rd_data_reg;

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_data_reg <= 0;
		end else if (i_rd && !o_rd_empty) begin
			rd_data_reg <= mem[rd_ptr[AW-1:0]];
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_data <= 0;
		end else if (OPT_REGISTER_READS) begin
			o_rd_data <= rd_data_reg;
		end else begin
			o_rd_data <= mem[rd_ptr[AW-1:0]];
		end
	end

endmodule
