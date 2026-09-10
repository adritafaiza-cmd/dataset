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

	reg [WIDTH-1:0] fifo [2**LGFIFO-1:0];
	reg [LGFIFO-1:0] wr_ptr, rd_ptr;
	reg [LGFIFO:0] count;
	reg [NFF-1:0] wr_sync, rd_sync;
	reg wr_synced, rd_synced;

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			count <= 0;
			wr_synced <= 0;
			wr_sync <= 0;
		end else if (i_wr && !o_wr_full) begin
			fifo[wr_ptr] <= i_wr_data;
			wr_ptr <= wr_ptr + 1;
			count <= count + 1;
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
			rd_synced <= 0;
			rd_sync <= 0;
		end else if (i_rd && !o_rd_empty) begin
			if (OPT_REGISTER_READS) begin
				o_rd_data <= fifo[rd_ptr];
			end
			rd_ptr <= rd_ptr + 1;
			count <= count - 1;
		end
	end

	always @(posedge i_wclk) begin
		if (WRITE_ON_POSEDGE) begin
			wr_sync <= {wr_sync[1], i_rclk};
		end else begin
			wr_sync <= {wr_sync[1], ~i_rclk};
		end
		if (wr_sync == {NFF{1'b1}} || wr_sync == {NFF{1'b0}}) begin
			wr_synced <= 1'b1;
		end else begin
			wr_synced <= 1'b0;
		end
	end

	always @(posedge i_rclk) begin
		if (WRITE_ON_POSEDGE) begin
			rd_sync <= {rd_sync[1], i_wclk};
		end else begin
			rd_sync <= {rd_sync[1], ~i_wclk};
		end
		if (rd_sync == {NFF{1'b1}} || rd_sync == {NFF{1'b0}}) begin
			rd_synced <= 1'b1;
		end else begin
			rd_synced <= 1'b0;
		end
	end

	always @(*) begin
		o_wr_full = (count == 2**LGFIFO);
		o_rd_empty = (count == 0);
		if (!OPT_REGISTER_READS) begin
			o_rd_data = fifo[rd_ptr];
		end
	end

endmodule
