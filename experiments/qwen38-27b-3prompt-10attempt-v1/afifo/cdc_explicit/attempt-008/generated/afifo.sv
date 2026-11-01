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
	localparam PTR_W = LGFIFO + 1;

	// Write domain
	reg [WIDTH-1:0] mem [0:DEPTH-1];
	reg [PTR_W-1:0] wptr;
	reg [PTR_W-1:0] rptr_w;
	reg [PTR_W-1:0] rptr_w_sync [0:NFF-1];
	reg [PTR_W-1:0] rptr_w_sync_next;
	reg wfull;

	// Read domain
	reg [PTR_W-1:0] rptr;
	reg [PTR_W-1:0] wptr_r;
	reg [PTR_W-1:0] wptr_r_sync [0:NFF-1];
	reg [PTR_W-1:0] wptr_r_sync_next;
	reg rempty;
	reg [WIDTH-1:0] rd_data_reg;

	// Write clock edge selection
	wire wclk_edge = WRITE_ON_POSEDGE ? i_wclk : ~i_wclk;
	wire wclk_neg  = WRITE_ON_POSEDGE ? ~i_wclk : i_wclk;

	// Read clock edge selection (always posedge for reads)
	wire rclk_edge = i_rclk;

	// Write domain logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wptr <= {PTR_W{1'b0}};
			wfull <= 1'b0;
		end else begin
			if (i_wr && !wfull) begin
				mem[wptr[LGFIFO-1:0]] <= i_wr_data;
				wptr <= wptr + 1'b1;
			end
			wfull <= (wptr[PTR_W-1] != rptr_w_sync[NFF-1][PTR_W-1]) &&
					 (wptr[LGFIFO-1:0] == rptr_w_sync[NFF-1][LGFIFO-1:0]);
		end
	end

	// Synchronize read pointer to write domain
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			rptr_w_sync[0] <= {PTR_W{1'b0}};
			rptr_w_sync[1] <= {PTR_W{1'b0}};
			if (NFF > 2) begin
				rptr_w_sync[2] <= {PTR_W{1'b0}};
				if (NFF > 3) begin
					rptr_w_sync[3] <= {PTR_W{1'b0}};
					if (NFF > 4) begin
						rptr_w_sync[4] <= {PTR_W{1'b0}};
						if (NFF > 5) begin
							rptr_w_sync[5] <= {PTR_W{1'b0}};
							if (NFF > 6) begin
								rptr_w_sync[6] <= {PTR_W{1'b0}};
								if (NFF > 7) begin
									rptr_w_sync[7] <= {PTR_W{1'b0}};
								end
							end
						end
					end
				end
			end
		end else begin
			rptr_w_sync[0] <= rptr_w;
			rptr_w_sync[1] <= rptr_w_sync[0];
			if (NFF > 2) begin
				rptr_w_sync[2] <= rptr_w_sync[1];
				if (NFF > 3) begin
					rptr_w_sync[3] <= rptr_w_sync[2];
					if (NFF > 4) begin
						rptr_w_sync[4] <= rptr_w_sync[3];
						if (NFF > 5) begin
							rptr_w_sync[5] <= rptr_w_sync[4];
							if (NFF > 6) begin
								rptr_w_sync[6] <= rptr_w_sync[5];
								if (NFF > 7) begin
									rptr_w_sync[7] <= rptr_w_sync[6];
								end
							end
						end
					end
				end
			end
		end
	end

	// Read domain logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rptr <= {PTR_W{1'b0}};
			rempty <= 1'b1;
			rd_data_reg <= {WIDTH{1'b0}};
		end else begin
			if (i_rd && !rempty) begin
				rptr <= rptr + 1'b1;
				if (OPT_REGISTER_READS) begin
					rd_data_reg <= mem[rptr[LGFIFO-1:0]];
				end
			end
			rempty <= (rptr[PTR_W-1] == wptr_r_sync[NFF-1][PTR_W-1]) &&
					  (rptr[LGFIFO-1:0] == wptr_r_sync[NFF-1][LGFIFO-1:0]);
		end
	end

	// Synchronize write pointer to read domain
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			wptr_r_sync[0] <= {PTR_W{1'b0}};
			wptr_r_sync[1] <= {PTR_W{1'b0}};
			if (NFF > 2) begin
				wptr_r_sync[2] <= {PTR_W{1'b0}};
				if (NFF > 3) begin
					wptr_r_sync[3] <= {PTR_W{1'b0}};
					if (NFF > 4) begin
						wptr_r_sync[4] <= {PTR_W{1'b0}};
						if (NFF > 5) begin
							wptr_r_sync[5] <= {PTR_W{1'b0}};
							if (NFF > 6) begin
								wptr_r_sync[6] <= {PTR_W{1'b0}};
								if (NFF > 7) begin
									wptr_r_sync[7] <= {PTR_W{1'b0}};
								end
							end
						end
					end
				end
			end
		end else begin
			wptr_r_sync[0] <= wptr_r;
			wptr_r_sync[1] <= wptr_r_sync[0];
			if (NFF > 2) begin
				wptr_r_sync[2] <= wptr_r_sync[1];
				if (NFF > 3) begin
					wptr_r_sync[3] <= wptr_r_sync[2];
					if (NFF > 4) begin
						wptr_r_sync[4] <= wptr_r_sync[3];
						if (NFF > 5) begin
							wptr_r_sync[5] <= wptr_r_sync[4];
							if (NFF > 6) begin
								wptr_r_sync[6] <= wptr_r_sync[5];
								if (NFF > 7) begin
									wptr_r_sync[7] <= wptr_r_sync[6];
								end
							end
						end
					end
				end
			end
		end
	end

	// Output assignments
	always @(*) begin
		o_wr_full = wfull;
		if (OPT_REGISTER_READS) begin
			o_rd_data = rd_data_reg;
		end else begin
			o_rd_data = mem[rptr[LGFIFO-1:0]];
		end
		o_rd_empty = rempty;
	end

endmodule
