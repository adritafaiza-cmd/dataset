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

	reg [WIDTH-1:0] mem [2**LGFIFO-1:0];
	reg [LGFIFO-1:0] wr_ptr, rd_ptr;
	reg [LGFIFO-1:0] wr_ptr_gray, rd_ptr_gray;
	reg [LGFIFO-1:0] wr_ptr_sync, rd_ptr_sync;
	reg [WIDTH-1:0] data_sync [NFF-1:0];
	reg [WIDTH-1:0] data_out;
	reg full, empty;

	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= 0;
			wr_ptr_gray <= 0;
			full <= 0;
		end else if (i_wr && !full) begin
			if (WRITE_ON_POSEDGE) begin
				mem[wr_ptr] <= i_wr_data;
				wr_ptr <= wr_ptr + 1;
				wr_ptr_gray <= wr_ptr_gray + 1;
			end
		end
	end

	always @(posedge i_wclk) begin
		wr_ptr_gray <= wr_ptr_gray + (wr_ptr - wr_ptr_gray);
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= 0;
			rd_ptr_gray <= 0;
			empty <= 1;
		end else if (i_rd && !empty) begin
			rd_ptr <= rd_ptr + 1;
			rd_ptr_gray <= rd_ptr_gray + 1;
		end
	end

	always @(posedge i_rclk) begin
		rd_ptr_gray <= rd_ptr_gray + (rd_ptr - rd_ptr_gray);
	end

	always @(posedge i_wclk) begin
		wr_ptr_sync <= wr_ptr_gray;
	end

	always @(posedge i_rclk) begin
		rd_ptr_sync <= rd_ptr_gray;
	end

	always @(posedge i_wclk) begin
		data_sync[0] <= i_wr_data;
	end

	generate
		for (genvar i = 1; i < NFF; i++) begin
			always @(posedge i_wclk) begin
				data_sync[i] <= data_sync[i-1];
			end
		end
	endgenerate

	always @(posedge i_rclk) begin
		if (OPT_REGISTER_READS) begin
			o_rd_data <= data_out;
			o_rd_empty <= empty;
		end
	end

	assign full = (wr_ptr == rd_ptr + (2**LGFIFO));
	assign empty = (wr_ptr == rd_ptr);
	assign o_wr_full = full;

	always @(*) begin
		if (empty) begin
			data_out = {WIDTH{1'bx}};
		end else begin
			data_out = mem[rd_ptr];
		end
	end

endmodule
