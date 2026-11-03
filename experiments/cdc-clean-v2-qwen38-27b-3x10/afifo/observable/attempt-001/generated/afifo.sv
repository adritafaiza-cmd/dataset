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

	// Memory
	reg [WIDTH-1:0] mem [0:DEPTH-1];

	// Write pointer (write clock domain)
	reg [PTR_W-1:0] wr_ptr;
	// Read pointer (read clock domain)
	reg [PTR_W-1:0] rd_ptr;

	// Gray code pointers for CDC
	reg [PTR_W-1:0] wr_ptr_gray;
	reg [PTR_W-1:0] rd_ptr_gray;

	// Synchronized read pointer in write domain
	reg [PTR_W-1:0] rd_ptr_gray_sync;
	reg [PTR_W-1:0] rd_ptr_gray_sync2;

	// Synchronized write pointer in read domain
	reg [PTR_W-1:0] wr_ptr_gray_sync;
	reg [PTR_W-1:0] wr_ptr_gray_sync2;

	// Full and empty flags
	wire wr_full;
	wire rd_empty;

	// Write side
	wire wr_en;
	wire [PTR_W-1:0] wr_ptr_next;
	wire [PTR_W-1:0] wr_ptr_gray_next;

	// Read side
	wire rd_en;
	wire [PTR_W-1:0] rd_ptr_next;
	wire [PTR_W-1:0] rd_ptr_gray_next;

	// Binary to Gray conversion
	function [PTR_W-1:0] bin2gray;
		input [PTR_W-1:0] bin;
		begin
			bin2gray = bin ^ (bin >> 1);
		end
	endfunction

	// Gray to Binary conversion
	function [PTR_W-1:0] gray2bin;
		input [PTR_W-1:0] gray;
		reg [PTR_W-1:0] bin;
		begin
			bin[PTR_W-1] = gray[PTR_W-1];
			for (integer i = PTR_W-2; i >= 0; i = i - 1)
				bin[i] = bin[i+1] ^ gray[i];
			gray2bin = bin;
		end
	endfunction

	// Write clock domain
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= {PTR_W{1'b0}};
			wr_ptr_gray <= {PTR_W{1'b0}};
			rd_ptr_gray_sync <= {PTR_W{1'b0}};
			rd_ptr_gray_sync2 <= {PTR_W{1'b0}};
		end else begin
			wr_ptr <= wr_ptr_next;
			wr_ptr_gray <= wr_ptr_gray_next;
			rd_ptr_gray_sync <= rd_ptr_gray;
			rd_ptr_gray_sync2 <= rd_ptr_gray_sync;
		end
	end

	// Read clock domain
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= {PTR_W{1'b0}};
			rd_ptr_gray <= {PTR_W{1'b0}};
			wr_ptr_gray_sync <= {PTR_W{1'b0}};
			wr_ptr_gray_sync2 <= {PTR_W{1'b0}};
		end else begin
			rd_ptr <= rd_ptr_next;
			rd_ptr_gray <= rd_ptr_gray_next;
			wr_ptr_gray_sync <= wr_ptr_gray;
			wr_ptr_gray_sync2 <= wr_ptr_gray_sync;
		end
	end

	// Write enable: honor WRITE_ON_POSEDGE
	// When WRITE_ON_POSEDGE=1, write on posedge i_wclk
	// When WRITE_ON_POSEDGE=0, write on negedge i_wclk
	// We handle this by using the appropriate clock edge for the write operation.
	// Since we're using always @(posedge i_wclk), we need to adjust.
	// Actually, let's restructure: use a separate always block for the write data capture
	// and pointer update based on the selected edge.

	// For simplicity and correctness, let's use the posedge for the main logic
	// and handle the edge selection by gating the write enable appropriately.
	// If WRITE_ON_POSEDGE=0, we need to capture on negedge. Let's use a different approach.

	// Let's use two separate always blocks for write and read pointer updates
	// based on the selected clock edge.

	// Write pointer update
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= {PTR_W{1'b0}};
			wr_ptr_gray <= {PTR_W{1'b0}};
		end else if (WRITE_ON_POSEDGE) begin
			if (i_wr && !wr_full) begin
				wr_ptr <= wr_ptr + 1'b1;
				wr_ptr_gray <= bin2gray(wr_ptr + 1'b1);
			end
		end
	end

	// If WRITE_ON_POSEDGE=0, handle on negedge
	always @(negedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wr_ptr <= {PTR_W{1'b0}};
			wr_ptr_gray <= {PTR_W{1'b0}};
		end else if (!WRITE_ON_POSEDGE) begin
			if (i_wr && !wr_full) begin
				wr_ptr <= wr_ptr + 1'b1;
				wr_ptr_gray <= bin2gray(wr_ptr + 1'b1);
			end
		end
	end

	// Memory write
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			// No write
		end else if (WRITE_ON_POSEDGE) begin
			if (i_wr && !wr_full) begin
				mem[wr_ptr[LGFIFO-1:0]] <= i_wr_data;
			end
		end
	end

	always @(negedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			// No write
		end else if (!WRITE_ON_POSEDGE) begin
			if (i_wr && !wr_full) begin
				mem[wr_ptr[LGFIFO-1:0]] <= i_wr_data;
			end
		end
	end

	// Read pointer update
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rd_ptr <= {PTR_W-1:0};
			rd_ptr_gray <= {PTR_W{1'b0}};
		end else begin
			if (i_rd && !rd_empty) begin
				rd_ptr <= rd_ptr + 1'b1;
				rd_ptr_gray <= bin2gray(rd_ptr + 1'b1);
			end
		end
	end

	// Full flag: write pointer has lapped read pointer
	// Full when wr_ptr_gray == {~rd_ptr_gray_sync2[LGFIFO], rd_ptr_gray_sync2[LGFIFO-1:0]}
	wire [PTR_W-1:0] rd_ptr_gray_sync2_bin = gray2bin(rd_ptr_gray_sync2);
	wire [PTR_W-1:0] wr_ptr_gray_full_check = {~rd_ptr_gray_sync2[LGFIFO], rd_ptr_gray_sync2[LGFIFO-1:0]};
	assign wr_full = (wr_ptr_gray == wr_ptr_gray_full_check);

	// Empty flag: read pointer equals write pointer
	wire [PTR_W-1:0] wr_ptr_gray_sync2_bin = gray2bin(wr_ptr_gray_sync2);
	assign rd_empty = (rd_ptr_gray == wr_ptr_gray_sync2);

	// Output registers
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_data <= {WIDTH{1'b0}};
			o_rd_empty <= 1'b1;
		end else begin
			o_rd_empty <= rd_empty;
			if (i_rd && !rd_empty) begin
				if (OPT_REGISTER_READS) begin
					o_rd_data <= mem[rd_ptr[LGFIFO-1:0]];
				end else begin
					o_rd_data <= mem[rd_ptr[LGFIFO-1:0]];
				end
			end
		end
	end

	// o_wr_full output
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			o_wr_full <= 1'b0;
		end else begin
			o_wr_full <= wr_full;
		end
	end

endmodule
