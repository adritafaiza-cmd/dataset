module sync_ff #(
		parameter WIDTH = 1
	) (
		input wire clk,
		input wire rst_n,
		input wire [WIDTH-1:0] d,
		output reg [WIDTH-1:0] q
	);
	
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			q <= {WIDTH{1'b0}};
		end else begin
			q <= d;
		end
	end
endmodule

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

	// Internal signals
	reg [LGFIFO:0] wr_ptr_gray, wr_ptr_bin, rd_ptr_gray, rd_ptr_bin;
	reg [WIDTH-1:0] mem [0:(2**LGFIFO)-1];
	reg [LGFIFO:0] wr_ptr_gray_sync, rd_ptr_gray_sync, wr_ptr_bin_sync, rd_ptr_bin_sync;
	reg empty_raw, full_raw, empty_sync, full_sync;
	reg wr_en, rd_en;
	reg [WIDTH-1:0] rd_data_raw, rd_data_sync;

	// Write domain
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr_bin <= 0;
			o_wr_full <= 1'b0;
		end else begin
			wr_en <= i_wr & ~o_wr_full;
			if (wr_en) begin
				mem[wr_ptr_bin[LGFIFO-1:0]] <= i_wr_data;
				wr_ptr_bin <= wr_ptr_bin + 1;
			end
			wr_ptr_gray <= wr_ptr_bin ^ (wr_ptr_bin >> 1);
			o_wr_full <= full_raw;
		end
	end

	// Write to Read synchronization
	sync_ff #(LGFIFO+1) sync_wr_ptr_gray_inst (
		.clk(i_rclk),
		.rst_n(i_rd_reset_n),
		.d(wr_ptr_gray),
		.q(wr_ptr_gray_sync)
	);

	// Read domain
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr_bin <= 0;
			o_rd_empty <= 1'b1;
		end else begin
			rd_en <= i_rd & ~o_rd_empty;
			if (rd_en) begin
				rd_ptr_bin <= rd_ptr_bin + 1;
			end
			rd_ptr_gray <= rd_ptr_bin ^ (rd_ptr_bin >> 1);
			o_rd_empty <= empty_sync;
		end
	end

	// Read to Write synchronization
	sync_ff #(LGFIFO+1) sync_rd_ptr_gray_inst (
		.clk(i_wclk),
		.rst_n(i_wr_reset_n),
		.d(rd_ptr_gray),
		.q(rd_ptr_gray_sync)
	);

	// Binary conversion and full/empty flags
	always @(*) begin
		wr_ptr_bin_sync = wr_ptr_gray_sync ^ (wr_ptr_gray_sync >> 1);
		rd_ptr_bin_sync = rd_ptr_gray_sync ^ (rd_ptr_gray_sync >> 1);
		empty_raw = (wr_ptr_bin == rd_ptr_bin);
		full_raw = (wr_ptr_bin_sync[LGFIFO:LGFIFO] != rd_ptr_bin_sync[LGFIFO:LGFIFO]) && (wr_ptr_bin_sync[LGFIFO-1:0] == rd_ptr_bin_sync[LGFIFO-1:0]);
	end

	// Read to Write synchronization for empty and full
	sync_ff #(1) sync_empty_inst (
		.clk(i_wclk),
		.rst_n(i_wr_reset_n),
		.d(empty_raw),
		.q(empty_sync)
	);

	sync_ff #(1) sync_full_inst (
		.clk(i_rclk),
		.rst_n(i_rd_reset_n),
		.d(full_raw),
		.q(full_sync)
	);

	// Read data path
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_data_raw <= {WIDTH{1'b0}};
			rd_data_sync <= {WIDTH{1'b0}};
			o_rd_data <= {WIDTH{1'b0}};
		end else begin
			if (rd_en) begin
				rd_data_raw <= mem[rd_ptr_bin[LGFIFO-1:0]];
			end
			rd_data_sync <= rd_data_raw;
			if (OPT_REGISTER_READS) begin
				o_rd_data <= rd_data_sync;
			end else begin
				o_rd_data <= rd_data_raw;
			end
		end
	end

endmodule
