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
	reg [LGFIFO:0] wptr, wptr_gray, wptr_gray_sync, wptr_gray_sync_wclk;
	reg [LGFIFO:0] rptr, rptr_gray, rptr_gray_sync, rptr_gray_sync_rclk;
	reg [WIDTH-1:0] mem [0:(1<<LGFIFO)-1];
	reg [WIDTH-1:0] payload_sync_rclk;
	reg wr_full_gray, rd_empty_gray;

	// Gray code conversion functions
	function [LGFIFO:0] bin2gray;
		input [LGFIFO:0] bin;
		bin2gray = bin ^ (bin >> 1);
	endfunction

	function [LGFIFO:0] gray2bin;
		input [LGFIFO:0] gray;
		integer i;
		reg [LGFIFO:0] bin;
		bin = gray;
		for (i = LGFIFO-1; i >= 0; i = i - 1)
			bin[i] = bin[i+1] ^ gray[i];
		gray2bin = bin;
	endfunction

	// Write side logic
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wptr <= 0;
			o_wr_full <= 0;
		end else begin
			if (i_wr && !o_wr_full) begin
				if (WRITE_ON_POSEDGE)
					mem[wptr[LGFIFO-1:0]] <= i_wr_data;
				wptr <= wptr + 1;
			end
			wptr_gray <= bin2gray(wptr);
			o_wr_full <= (wptr_gray == {~wptr_gray_sync_wclk[LGFIFO], wptr_gray_sync_wclk[LGFIFO-1:0]});
		end
	end

	// Read side logic
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rptr <= 0;
			o_rd_empty <= 1;
		end else begin
			if (i_rd && !o_rd_empty) begin
				rptr <= rptr + 1;
			end
			rptr_gray <= bin2gray(rptr);
			o_rd_empty <= (rptr_gray == {~rptr_gray_sync_rclk[LGFIFO], rptr_gray_sync_rclk[LGFIFO-1:0]});
		end
	end

	// Pointer synchronization
	sync_bit #(.NFF(NFF)) wr_sync_rptr (
		.i_clk(i_wclk),
		.i_reset_n(i_wr_reset_n),
		.i_async(rptr_gray),
		.o_sync(rptr_gray_sync_wclk)
	);

	sync_bit #(.NFF(NFF)) rd_sync_wptr (
		.i_clk(i_rclk),
		.i_reset_n(i_rd_reset_n),
		.i_async(wptr_gray),
		.o_sync(wptr_gray_sync_rclk)
	);

	// Payload synchronization
	sync_payload #(.LGFIFO(LGFIFO), .WIDTH(WIDTH), .NFF(NFF)) payload_sync (
		.i_wclk(i_wclk),
		.i_rclk(i_rclk),
		.i_wr_reset_n(i_wr_reset_n),
		.i_rd_reset_n(i_rd_reset_n),
		.i_wptr_gray_sync(wptr_gray_sync_wclk),
		.i_rptr_gray_sync(rptr_gray_sync_rclk),
		.i_wr_data(i_wr_data),
		.o_sync_data(payload_sync_rclk)
	);

	// Output data selection
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			o_rd_data <= 0;
		end else begin
			if (!OPT_REGISTER_READS) begin
				o_rd_data <= payload_sync_rclk;
			end else begin
				if (i_rd && !o_rd_empty) begin
					o_rd_data <= payload_sync_rclk;
				end
			end
		end
	end

endmodule

module sync_bit #(
		parameter	NFF = 2
	) (
		input	wire	i_clk,
		input	wire	i_reset_n,
		input	wire	i_async,
		output	reg	o_sync
	);

	reg [NFF-1:0] sync_reg;

	always @(posedge i_clk or negedge i_reset_n) begin
		if (!i_reset_n)
			sync_reg <= 0;
		else
			sync_reg <= {sync_reg[NFF-2:0], i_async};
	end

	assign o_sync = sync_reg[NFF-1];

endmodule

module sync_payload #(
		parameter	LGFIFO = 3,
		parameter	WIDTH  = 16,
		parameter	NFF    = 2
	) (
		input	wire			i_wclk,
		input	wire			i_rclk,
		input	wire			i_wr_reset_n,
		input	wire			i_rd_reset_n,
		input	wire	[LGFIFO:0]	i_wptr_gray_sync,
		input	wire	[LGFIFO:0]	i_rptr_gray_sync,
		input	wire	[WIDTH-1:0]	i_wr_data,
		output	reg	[WIDTH-1:0]	o_sync_data
	);

	reg [WIDTH-1:0] mem [0:(1<<LGFIFO)-1];
	reg [LGFIFO-1:0] wptr_sync, rptr_sync;
	reg [WIDTH-1:0] payload_reg;

	// Write side
	always @(posedge i_wclk or negedge i_wr_reset_n) begin
		if (!i_wr_reset_n) begin
			wptr_sync <= 0;
		end else begin
			wptr_sync <= i_wptr_gray_sync[LGFIFO-1:0];
		end
	end

	// Read side
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n) begin
			rptr_sync <= 0;
		end else begin
			rptr_sync <= i_rptr_gray_sync[LGFIFO-1:0];
		end
	end

	// Memory write
	always @(posedge i_wclk) begin
		if (i_wr_reset_n)
			mem[wptr_sync] <= i_wr_data;
	end

	// Memory read
	always @(posedge i_rclk) begin
		if (i_rd_reset_n)
			payload_reg <= mem[rptr_sync];
	end

	// Output data with additional register stage if needed
	always @(posedge i_rclk or negedge i_rd_reset_n) begin
		if (!i_rd_reset_n)
			o_sync_data <= 0;
		else
			o_sync_data <= payload_reg;
	end

endmodule
