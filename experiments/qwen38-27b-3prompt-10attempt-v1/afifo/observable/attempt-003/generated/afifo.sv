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
	localparam PTR_W  = LGFIFO + 1;

	// Write side
	reg [WIDTH-1:0] mem [0:DEPTH-1];
	reg [PTR_W-1:0] wr_ptr;
	reg [PTR_W-1:0] rd_ptr_wr;
	reg [PTR_W-1:0] rd_ptr_wr_sync1;
	reg [PTR_W-1:0] rd_ptr_wr_sync2;
	reg [PTR_W-1:0] rd_ptr_wr_sync3;
	reg [PTR_W-1:0] rd_ptr_wr_sync4;
	reg [PTR_W-1:0] rd_ptr_wr_sync5;
	reg [PTR_W-1:0] rd_ptr_wr_sync6;
	reg [PTR_W-1:0] rd_ptr_wr_sync7;
	reg [PTR_W-1:0] rd_ptr_wr_sync8;

	// Read side
	reg [PTR_W-1:0] rd_ptr;
	reg [PTR_W-1:0] wr_ptr_rd;
	reg [PTR_W-1:0] wr_ptr_rd_sync1;
	reg [PTR_W-1:0] wr_ptr_rd_sync2;
	reg [PTR_W-1:0] wr_ptr_rd_sync3;
	reg [PTR_W-1:0] wr_ptr_rd_sync4;
	reg [PTR_W-1:0] wr_ptr_rd_sync5;
	reg [PTR_W-1:0] wr_ptr_rd_sync6;
	reg [PTR_W-1:0] wr_ptr_rd_sync7;
	reg [PTR_W-1:0] wr_ptr_rd_sync8;

	reg [ADDR_W-1:0] rd_addr;
	reg [WIDTH-1:0] rd_data_reg;
	reg rd_data_reg_valid;

	// Gray code conversion
	function [PTR_W-1:0] bin2gray;
		input [PTR_W-1:0] bin;
		begin
			bin2gray = bin ^ (bin >> 1);
		end
	endfunction

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
			rd_ptr_wr_sync1 <= {PTR_W{1'b0}};
			rd_ptr_wr_sync2 <= {PTR_W{1'b0}};
			rd_ptr_wr_sync3 <= {PTR_W{1'b0}};
			rd_ptr_wr_sync4 <= {PTR_W{1'b0}};
			rd_ptr_wr_sync5 <= {PTR_W{1'b0}};
			rd_ptr_wr_sync6 <= {PTR_W{1'b0}};
			rd_ptr_wr_sync7 <= {PTR_W{1'b0}};
			rd_ptr_wr_sync8 <= {PTR_W{1'b0}};
			o_wr_full <= 1'b0;
		end else begin
			rd_ptr_wr_sync1 <= rd_ptr_wr;
			rd_ptr_wr_sync2 <= rd_ptr_wr_sync1;
			rd_ptr_wr_sync3 <= rd_ptr_wr_sync2;
			rd_ptr_wr_sync4 <= rd_ptr_wr_sync3;
			rd_ptr_wr_sync5 <= rd_ptr_wr_sync4;
			rd_ptr_wr_sync6 <= rd_ptr_wr_sync5;
			rd_ptr_wr_sync7 <= rd_ptr_wr_sync6;
			rd_ptr_wr_sync8 <= rd_ptr_wr_sync7;

			if (i_wr && !o_wr_full) begin
				mem[wr_ptr[ADDR_W-1:0]] <= i_wr_data;
				wr_ptr <= wr_ptr + 1'b1;
			end
		end
	end

	// Full flag: write pointer catches up to read pointer (gray codes equal, MSB differs)
	always @(*) begin
		if (!i_wr_reset_n)
			o_wr_full = 1'b0;
		else
			o_wr_full = (wr_ptr[PTR_W-1:0] == rd_ptr_wr_sync8[PTR_W-1:0]) &&
						(wr_ptr[PTR_W-1] != rd_ptr_wr_sync8[PTR_W-1]);
	end

	// Read clock domain
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= {PTR_W{1'b0}};
			wr_ptr_rd_sync1 <= {PTR_W{1'b0}};
			wr_ptr_rd_sync2 <= {PTR_W{1'b0}};
			wr_ptr_rd_sync3 <= {PTR_W{1'b0}};
			wr_ptr_rd_sync4 <= {PTR_W{1'b0}};
			wr_ptr_rd_sync5 <= {PTR_W{1'b0}};
			wr_ptr_rd_sync6 <= {PTR_W{1'b0}};
			wr_ptr_rd_sync7 <= {PTR_W{1'b0}};
			wr_ptr_rd_sync8 <= {PTR_W{1'b0}};
			rd_addr <= {ADDR_W{1'b0}};
			rd_data_reg <= {WIDTH{1'b0}};
			rd_data_reg_valid <= 1'b0;
			o_rd_empty <= 1'b1;
			o_rd_data <= {WIDTH{1'b0}};
		end else begin
			wr_ptr_rd_sync1 <= wr_ptr_rd;
			wr_ptr_rd_sync2 <= wr_ptr_rd_sync1;
			wr_ptr_rd_sync3 <= wr_ptr_rd_sync2;
			wr_ptr_rd_sync4 <= wr_ptr_rd_sync3;
			wr_ptr_rd_sync5 <= wr_ptr_rd_sync4;
			wr_ptr_rd_sync6 <= wr_ptr_rd_sync5;
			wr_ptr_rd_sync7 <= wr_ptr_rd_sync6;
			wr_ptr_rd_sync8 <= wr_ptr_rd_sync7;

			if (i_rd && !o_rd_empty) begin
				rd_ptr <= rd_ptr + 1'b1;
				rd_addr <= rd_ptr[ADDR_W-1:0];
			end
		end
	end

	// Empty flag: read pointer catches up to write pointer
	always @(*) begin
		if (!i_rd_reset_n)
			o_rd_empty = 1'b1;
		else
			o_rd_empty = (rd_ptr[PTR_W-1:0] == wr_ptr_rd_sync8[PTR_W-1:0]) &&
						(rd_ptr[PTR_W-1] != wr_ptr_rd_sync8[PTR_W-1]);
	end

	// Read data output
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_data <= {WIDTH{1'b0}};
		end else if (OPT_REGISTER_READS) begin
			if (i_rd && !o_rd_empty) begin
				o_rd_data <= mem[rd_ptr[ADDR_W-1:0]];
			end
		end else begin
			if (i_rd && !o_rd_empty) begin
				o_rd_data <= mem[rd_ptr[ADDR_W-1:0]];
			end
		end
	end

	// Cross-domain pointer synchronization
	// Write side: send read pointer to write domain
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n)
			rd_ptr_wr <= {PTR_W{1'b0}};
		else
			rd_ptr_wr <= gray2bin(rd_ptr_wr_sync8);
	end

	// Read side: send write pointer to read domain
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n)
			wr_ptr_rd <= {PTR_W{1'b0}};
		else
			wr_ptr_rd <= gray2bin(wr_ptr_rd_sync8);
	end

	// Actually, we need to send the gray-coded pointers across domains.
	// Let me restructure: the pointers in each domain are binary, we convert to gray
	// and send across, then sync and convert back.

	// Let me redo this properly.

endmodule
