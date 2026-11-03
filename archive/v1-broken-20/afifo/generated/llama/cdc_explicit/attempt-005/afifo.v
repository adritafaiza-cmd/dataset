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

	reg [WIDTH-1:0]	ram[2**LGFIFO-1:0];
	reg [LGFIFO-1:0]	wr_ptr, rd_ptr;
	reg [LGFIFO-1:0]	wr_ptr_gray, rd_ptr_gray;
	reg [LGFIFO-1:0]	wr_ptr_sync, rd_ptr_sync;
	reg			wr_full, rd_empty;
	reg			wr_sync, rd_sync;

	wire			wr_en;
	wire			rd_en;

	assign wr_en = i_wr && !o_wr_full;
	assign rd_en = i_rd && !o_rd_empty;

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			wr_full <= 0;
		end else if (wr_en) begin
			if (WRITE_ON_POSEDGE) begin
				ram[wr_ptr] <= i_wr_data;
				wr_ptr <= wr_ptr + 1;
			end else begin
				if (i_wclk == 1'b0) begin
					ram[wr_ptr] <= i_wr_data;
					wr_ptr <= wr_ptr + 1;
				end
			end
			if (wr_ptr == (2**LGFIFO - 1)) begin
				wr_full <= 1;
			end
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
			rd_empty <= 1;
		end else if (rd_en) begin
			if (OPT_REGISTER_READS) begin
				o_rd_data <= ram[rd_ptr];
				rd_ptr <= rd_ptr + 1;
				if (rd_ptr == (2**LGFIFO - 1)) begin
					rd_empty <= 1;
				end
			end else begin
				if (i_rclk == 1'b1) begin
					o_rd_data <= ram[rd_ptr];
					rd_ptr <= rd_ptr + 1;
					if (rd_ptr == (2**LGFIFO - 1)) begin
						rd_empty <= 1;
					end
				end
			end
		end
	end

	always @(posedge i_wclk) begin
		wr_ptr_gray <= wr_ptr;
	end

	always @(posedge i_rclk) begin
		rd_ptr_gray <= rd_ptr;
	end

	// Synchronize wr_ptr_gray to i_rclk
	reg [NFF-1:0][LGFIFO-1:0] wr_ptr_sync_reg;
	always @(posedge i_rclk) begin
		wr_ptr_sync_reg[0] <= wr_ptr_gray;
		for (int i = 1; i < NFF; i++) begin
			wr_ptr_sync_reg[i] <= wr_ptr_sync_reg[i-1];
		end
	end
	assign wr_ptr_sync = wr_ptr_sync_reg[NFF-1];

	// Synchronize rd_ptr_gray to i_wclk
	reg [NFF-1:0][LGFIFO-1:0] rd_ptr_sync_reg;
	always @(posedge i_wclk) begin
		rd_ptr_sync_reg[0] <= rd_ptr_gray;
		for (int i = 1; i < NFF; i++) begin
			rd_ptr_sync_reg[i] <= rd_ptr_sync_reg[i-1];
		end
	end
	assign rd_ptr_sync = rd_ptr_sync_reg[NFF-1];

	always @(posedge i_rclk) begin
		o_rd_empty <= (rd_ptr_sync == wr_ptr_sync) ? 1'b1 : 1'b0;
	end

	always @(posedge i_wclk) begin
		o_wr_full <= (wr_ptr_sync == rd_ptr_sync) ? 1'b1 : 1'b0;
	end

endmodule
