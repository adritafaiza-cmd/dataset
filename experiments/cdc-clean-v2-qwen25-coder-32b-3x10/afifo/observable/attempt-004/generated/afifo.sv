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

	reg [WIDTH-1:0] mem [0:DEPTH-1];
	reg [AW:0] wr_ptr, wr_ptr_gray, wr_ptr_gray_sync;
	reg [AW:0] rd_ptr, rd_ptr_gray, rd_ptr_gray_sync;

	// Write side logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			wr_ptr_gray <= 0;
			o_wr_full <= 0;
		end else begin
			if (i_wr && !o_wr_full) begin
				mem[wr_ptr[AW-1:0]] <= i_wr_data;
				wr_ptr <= wr_ptr + 1;
				wr_ptr_gray <= wr_ptr ^ (wr_ptr >> 1);
			end
			// Detect full condition
			if (wr_ptr_gray_sync[AW] != wr_ptr_gray[AW] && wr_ptr_gray_sync[AW-1:0] == wr_ptr_gray[AW-1:0])
				o_wr_full <= 1;
			else
				o_wr_full <= 0;
		end
	end

	// Gray code synchronization for wr_ptr_gray to read domain
	generate
		genvar i;
		for (i = 0; i <= AW; i = i + 1) begin : sync_wr_ptr_gray
			reg [NFF-1:0] sync_reg;
			always @(posedge i_rclk or negedge i_rd_reset_n) begin
				if (!i_rd_reset_n)
					sync_reg <= 0;
				else
					sync_reg <= {sync_reg[NFF-2:0], wr_ptr_gray[i]};
			end
			assign wr_ptr_gray_sync[i] = sync_reg[NFF-1];
		end
	endgenerate

	// Read side logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
			rd_ptr_gray <= 0;
			o_rd_empty <= 1;
		end else begin
			if (i_rd && !o_rd_empty) begin
				rd_ptr <= rd_ptr + 1;
				rd_ptr_gray <= rd_ptr ^ (rd_ptr >> 1);
			end
			// Detect empty condition
			if (rd_ptr_gray_sync[AW] == rd_ptr_gray[AW] && rd_ptr_gray_sync[AW-1:0] == rd_ptr_gray[AW-1:0])
				o_rd_empty <= 1;
			else
				o_rd_empty <= 0;
		end
	end

	// Gray code synchronization for rd_ptr_gray to write domain
	generate
		genvar j;
		for (j = 0; j <= AW; j = j + 1) begin : sync_rd_ptr_gray
			reg [NFF-1:0] sync_reg;
			always @(posedge i_wclk or negedge i_wr_reset_n) begin
				if (!i_wr_reset_n)
					sync_reg <= 0;
				else
					sync_reg <= {sync_reg[NFF-2:0], rd_ptr_gray[j]};
			end
			assign rd_ptr_gray_sync[j] = sync_reg[NFF-1];
		end
	endgenerate

	// Read data output
	wire [WIDTH-1:0] rd_data;
	assign rd_data = mem[rd_ptr[AW-1:0]];

	// Output register for read data
	generate
		if (OPT_REGISTER_READS) begin : reg_read_data
			always @(posedge i_rclk or negedge i_rd_reset_n) begin
				if (!i_rd_reset_n)
					o_rd_data <= 0;
				else if (i_rd && !o_rd_empty)
					o_rd_data <= rd_data;
			end
		end else begin : no_reg_read_data
			assign o_rd_data = rd_data;
		end
	endgenerate

endmodule
