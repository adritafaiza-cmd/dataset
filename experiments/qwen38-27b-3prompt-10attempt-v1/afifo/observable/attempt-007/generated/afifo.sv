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
	localparam ADDR_W = LGFIFO;
	localparam PTR_W = LGFIFO + 1;

	// Write side
	reg [WIDTH-1:0] mem [0:DEPTH-1];
	reg [PTR_W-1:0] wr_ptr;
	reg [PTR_W-1:0] wr_ptr_gray;
	reg [PTR_W-1:0] rd_ptr_gray_wr;

	// Read side
	reg [PTR_W-1:0] rd_ptr;
	reg [PTR_W-1:0] rd_ptr_gray;
	reg [PTR_W-1:0] wr_ptr_gray_rd;

	// Synchronizers
	reg [PTR_W-1:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;
	reg [PTR_W-1:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;

	// Binary to Gray
	function [PTR_W-1:0] bin2gray;
		input [PTR_W-1:0] bin;
		begin
			bin2gray = bin ^ (bin >> 1);
		end
	endfunction

	// Gray to Binary
	function [PTR_W-1:0] gray2bin;
		input [PTR_W-1:0] gray;
		reg [PTR_W-1:0] bin;
		begin
			bin[PTR_W-1] = gray[PTR_W-1];
			for (integer i = PTR_W-2; i >= 0; i = i - 1)
				bin[i] = gray[i] ^ bin[i+1];
			gray2bin = bin;
		end
	endfunction

	// Write clock domain
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= {PTR_W{1'b0}};
			wr_ptr_gray <= {PTR_W{1'b0}};
		end else begin
			if (i_wr && !o_wr_full) begin
				mem[wr_ptr[ADDR_W-1:0]] <= i_wr_data;
				wr_ptr <= wr_ptr + 1'b1;
				wr_ptr_gray <= bin2gray(wr_ptr + 1'b1);
			end
		end
	end

	// Write full flag
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n)
			o_wr_full <= 1'b0;
		else
			o_wr_full <= (wr_ptr_gray[PTR_W-1:0] == {rd_ptr_gray_wr[PTR_W-2:0], ~rd_ptr_gray_wr[PTR_W-1], rd_ptr_gray_wr[PTR_W-1]}) &&
			             (wr_ptr_gray[PTR_W-1:0] != rd_ptr_gray_wr[PTR_W-1:0]);
	end

	// Synchronize rd_ptr_gray to write domain
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			rd_ptr_gray_wr <= {PTR_W{1'b0}};
		end else begin
			rd_ptr_gray_wr <= rd_ptr_gray;
		end
	end

	// Read clock domain
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= {PTR_W{1'b0}};
			rd_ptr_gray <= {PTR_W{1'b0}};
		end else begin
			if (i_rd && !o_rd_empty) begin
				rd_ptr <= rd_ptr + 1'b1;
				rd_ptr_gray <= bin2gray(rd_ptr + 1'b1);
			end
		end
	end

	// Read empty flag
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n)
			o_rd_empty <= 1'b1;
		else
			o_rd_empty <= (rd_ptr_gray[PTR_W-1:0] == wr_ptr_gray_rd[PTR_W-1:0]);
	end

	// Synchronize wr_ptr_gray to read domain
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			wr_ptr_gray_rd <= {PTR_W{1'b0}};
		end else begin
			wr_ptr_gray_rd <= wr_ptr_gray;
		end
	end

	// Read data output
	// If OPT_REGISTER_READS is 1, register the read data
	// If OPT_REGISTER_READS is 0, combinational read
	reg [WIDTH-1:0] rd_data_reg;
	reg [ADDR_W-1:0] rd_addr;

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_data_reg <= {WIDTH{1'b0}};
			rd_addr <= {ADDR_W{1'b0}};
		end else begin
			if (i_rd && !o_rd_empty) begin
				rd_addr <= rd_ptr[ADDR_W-1:0];
			end
		end
	end

	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n)
			o_rd_data <= {WIDTH{1'b0}};
		else if (OPT_REGISTER_READS)
			o_rd_data <= mem[rd_addr];
		else
			o_rd_data <= mem[rd_ptr[ADDR_W-1:0]];
	end

endmodule
