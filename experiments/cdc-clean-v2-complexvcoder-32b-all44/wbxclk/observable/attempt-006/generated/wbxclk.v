module wbxclk #(
		parameter	AW=32,
				DW=32,
				LGFIFO = 5
	) (
		input	wire			i_wb_clk, i_reset,
		input	wire			i_wb_cyc, i_wb_stb, i_wb_we,
		input	wire	[(AW-1):0]	i_wb_addr,
		input	wire	[(DW-1):0]	i_wb_data,
		input	wire	[(DW/8-1):0]	i_wb_sel,
		output	wire			o_wb_stall,
		output	reg			o_wb_ack,
		output	reg	[(DW-1):0]	o_wb_data,
		output	reg			o_wb_err,
		input	wire			i_xclk_clk,
		output	reg			o_xclk_cyc,
		output	reg			o_xclk_stb,
		output	reg			o_xclk_we,
		output	reg	[(AW-1):0]	o_xclk_addr,
		output	reg	[(DW-1):0]	o_xclk_data,
		output	reg	[(DW/8-1):0]	o_xclk_sel,
		input	wire			i_xclk_stall,
		input	wire			i_xclk_ack,
		input	wire	[(DW-1):0]	i_xclk_data,
		input	wire			i_xclk_err
	);

	reg [(DW+AW+DW/8+2):0] wb_to_xclk_fifo_data_in;
	wire [(DW+AW+DW/8+2):0] wb_to_xclk_fifo_data_out;
	wire wb_to_xclk_fifo_full, wb_to_xclk_fifo_empty;
	
	reg [(DW):0] xclk_to_wb_fifo_data_in;
	wire [(DW):0] xclk_to_wb_fifo_data_out;
	wire xclk_to_wb_fifo_full, xclk_to_wb_fifo_empty;

	// Instantiate FIFOs
	async_fifo #(
		.WIDTH(DW+AW+DW/8+3),
		.DEPTH(2**LGFIFO)
	) wb_to_xclk_fifo (
		.wr_clk(i_wb_clk),
		.rd_clk(i_xclk_clk),
		.reset(i_reset),
		.data_in(wb_to_xclk_fifo_data_in),
		.data_out(wb_to_xclk_fifo_data_out),
		.full(wb_to_xclk_fifo_full),
		.empty(wb_to_xclk_fifo_empty),
		.wr_en(wb_req_valid),
		.rd_en(xclk_req_valid)
	);

	async_fifo #(
		.WIDTH(DW+1),
		.DEPTH(2**LGFIFO)
	) xclk_to_wb_fifo (
		.wr_clk(i_xclk_clk),
		.rd_clk(i_wb_clk),
		.reset(i_reset),
		.data_in(xclk_to_wb_fifo_data_in),
		.data_out(xclk_to_wb_fifo_data_out),
		.full(xclk_to_wb_fifo_full),
		.empty(xclk_to_wb_fifo_empty),
		.wr_en(xclk_resp_valid),
		.rd_en(wb_resp_valid)
	);

	// WB to XCLK FIFO input data packing
	always @(*) begin
		wb_to_xclk_fifo_data_in = {i_wb_cyc, i_wb_stb, i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};
	end

	// XCLK to WB FIFO input data packing
	always @(*) begin
		xclk_to_wb_fifo_data_in = {i_xclk_err, i_xclk_data};
	end

	// WB side control logic
	reg wb_req;
	reg wb_req_valid;

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_req <= 0;
			wb_req_valid <= 0;
			o_wb_ack <= 0;
			o_wb_data <= 0;
			o_wb_err <= 0;
		end else begin
			// Enqueue requests to wb_to_xclk_fifo
			if (i_wb_stb && !wb_to_xclk_fifo_full) begin
				wb_req <= 1;
				wb_req_valid <= 1;
			end else if (wb_to_xclk_fifo_empty) begin
				wb_req <= 0;
				wb_req_valid <= 0;
			end

			// Dequeue responses from xclk_to_wb_fifo
			if (!xclk_to_wb_fifo_empty) begin
				o_wb_data <= xclk_to_wb_fifo_data_out[DW-1:0];
				o_wb_err <= xclk_to_wb_fifo_data_out[DW];
				o_wb_ack <= 1;
				wb_resp_valid <= 1;
			end else begin
				o_wb_ack <= 0;
				wb_resp_valid <= 0;
			end
		end
	end

	// XCLK side control logic
	reg xclk_req_valid;

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
			o_xclk_we <= 0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
			xclk_req_valid <= 0;
			xclk_resp_valid <= 0;
		end else begin
			// Dequeue requests from wb_to_xclk_fifo
			if (!wb_to_xclk_fifo_empty && !i_xclk_stall) begin
				o_xclk_cyc <= wb_to_xclk_fifo_data_out[DW+AW+DW/8+2];
				o_xclk_stb <= wb_to_xclk_fifo_data_out[DW+AW+DW/8+1];
				o_xclk_we <= wb_to_xclk_fifo_data_out[DW+AW+DW/8];
				o_xclk_addr <= wb_to_xclk_fifo_data_out[DW+AW+DW/8-1:DW];
				o_xclk_data <= wb_to_xclk_fifo_data_out[DW-1:0];
				o_xclk_sel <= wb_to_xclk_fifo_data_out[DW/8-1:0];
				xclk_req_valid <= 1;
			end else begin
				xclk_req_valid <= 0;
			end

			// Enqueue responses to xclk_to_wb_fifo
			if (i_xclk_ack && !xclk_to_wb_fifo_full) begin
				xclk_resp_valid <= 1;
			end else begin
				xclk_resp_valid <= 0;
			end
		end
	end

	// Backpressure stall signal
	assign o_wb_stall = wb_to_xclk_fifo_full;

endmodule

module async_fifo #(
		parameter WIDTH = 32,
				DEPTH = 32
	) (
		input	wire			wr_clk, rd_clk, reset,
		input	wire	[WIDTH-1:0]	data_in,
		output	wire	[WIDTH-1:0]	data_out,
		output	wire			full,
		output	wire			empty,
		input	wire			wr_en,
		input	wire			rd_en
	);

	reg [$clog2(DEPTH):0] wr_ptr, rd_ptr;
	reg [$clog2(DEPTH):0] wr_ptr_gray, rd_ptr_gray;
	reg [$clog2(DEPTH):0] wr_ptr_gray_sync, rd_ptr_gray_sync;

	reg [WIDTH-1:0] mem [0:DEPTH-1];

	// Write pointer logic
	always @(posedge wr_clk or posedge reset) begin
		if (reset) begin
			wr_ptr <= 0;
		end else if (wr_en && !full) begin
			wr_ptr <= wr_ptr + 1;
			mem[wr_ptr] <= data_in;
		end
	end

	// Read pointer logic
	always @(posedge rd_clk or posedge reset) begin
		if (reset) begin
			rd_ptr <= 0;
		end else if (rd_en && !empty) begin
			rd_ptr <= rd_ptr + 1;
		end
	end

	// Binary to Gray conversion for write pointer
	always @(*) begin
		wr_ptr_gray = (wr_ptr >> 1) ^ wr_ptr;
	end

	// Gray to binary conversion for read pointer
	always @(*) begin
		rd_ptr_gray = (rd_ptr >> 1) ^ rd_ptr;
	end

	// Gray code synchronization for cross-domain communication
	always @(posedge wr_clk or posedge reset) begin
		if (reset) begin
			rd_ptr_gray_sync <= 0;
		end else begin
			rd_ptr_gray_sync <= rd_ptr_gray;
		end
	end

	always @(posedge rd_clk or posedge reset) begin
		if (reset) begin
			wr_ptr_gray_sync <= 0;
		end else begin
			wr_ptr_gray_sync <= wr_ptr_gray;
		end
	end

	// Full and empty flags
	assign full = (wr_ptr_gray[$clog2(DEPTH)] != wr_ptr_gray_sync[$clog2(DEPTH)]) && (wr_ptr_gray[$clog2(DEPTH)-1:0] == wr_ptr_gray_sync[$clog2(DEPTH)-1:0]);
	assign empty = (wr_ptr_gray[$clog2(DEPTH)-1:0] == rd_ptr_gray[$clog2(DEPTH)-1:0]) && (wr_ptr_gray[$clog2(DEPTH)] == rd_ptr_gray[$clog2(DEPTH)]);

	// Data output
	always @(posedge rd_clk or posedge reset) begin
		if (reset) begin
			data_out <= 0;
		end else if (rd_en && !empty) begin
			data_out <= mem[rd_ptr];
		end
	end

endmodule
