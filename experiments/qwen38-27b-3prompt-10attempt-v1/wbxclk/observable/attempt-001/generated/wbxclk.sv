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
	output	reg	[(DW/8-1):0]	o_wb_data,
	output	reg			o_wb_err,
	input	wire			i_xclk_clk,
	output	reg			o_xclk_cyc,
	output	reg			o_xclk_stb,
	output	reg			o_xclk_we,
	output	reg	[(AW-1):0]	o_xclk_addr,
	output	reg	[(DW/8-1):0]	o_xclk_data,
	output	reg	[(DW/8-1):0]	o_xclk_sel,
	input	wire			i_xclk_stall,
	input	wire			i_xclk_ack,
	input	wire	[(DW/8-1):0]	i_xclk_data,
	input	wire			i_xclk_err
);

	localparam REQ_W = AW + DW + DW/8 + 1;
	localparam RSP_W = DW + 1;
	localparam DEPTH = 1 << LGFIFO;
	localparam PTR_W = LGFIFO;

	// Request FIFO (Wishbone -> XCLK)
	reg [REQ_W-1:0] req_mem [0:DEPTH-1];
	reg [PTR_W-1:0] req_wr_ptr, req_rd_ptr;
	reg [PTR_W:0]   req_count;

	// Response FIFO (XCLK -> Wishbone)
	reg [RSP_W-1:0] rsp_mem [0:DEPTH-1];
	reg [PTR_W-1:0] rsp_wr_ptr, rsp_rd_ptr;
	reg [PTR_W:0]   rsp_count;

	// Request FIFO write (Wishbone clock domain)
	wire req_full = (req_count == DEPTH);
	wire req_wr_en = i_wb_cyc && i_wb_stb && !req_full;

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_wr_ptr <= {PTR_W{1'b0}};
			req_count  <= {(PTR_W+1){1'b0}};
		end else begin
			if (req_wr_en) begin
				req_mem[req_wr_ptr] <= {i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};
				req_wr_ptr <= req_wr_ptr + 1'b1;
			end
			if (req_wr_en && req_rd_ptr != req_wr_ptr)
				req_count <= req_count + 1'b1;
			else if (req_wr_en && req_rd_ptr == req_wr_ptr)
				req_count <= req_count + 1'b1;
			else if (!req_wr_en && req_rd_ptr != req_wr_ptr)
				req_count <= req_count - 1'b1;
		end
	end

	// Request FIFO read (XCLK clock domain)
	wire req_empty = (req_count == 0);
	wire req_rd_en = !req_empty && !i_xclk_stall;

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			req_rd_ptr <= {PTR_W{1'b0}};
		end else begin
			if (req_rd_en)
				req_rd_ptr <= req_rd_ptr + 1'b1;
		end
	end

	// Request FIFO count update from read side (XCLK clock domain)
	// We need a separate count that tracks reads. Actually, let's use a simpler approach:
	// Use a single count in each domain is tricky. Let's use two counters with async reset.
	// Better approach: use a standard async FIFO with gray code pointers.
	// But the problem says "Each FIFO keeps its own order" and "A beat is one registered sample and empty falls on a later read clock."
	// Let's use a simpler approach: separate write and read pointers, and compute full/empty locally.

	// Let me redo this with a cleaner async FIFO structure.

	// Request FIFO - write side (Wishbone clock)
	reg [PTR_W-1:0] req_wr_ptr_wb;
	reg [PTR_W-1:0] req_rd_ptr_wb; // gray code read pointer synchronized to WB domain

	// Request FIFO - read side (XCLK clock)
	reg [PTR_W-1:0] req_rd_ptr_xclk;
	reg [PTR_W-1:0] req_wr_ptr_xclk; // gray code write pointer synchronized to XCLK domain

	// Response FIFO - write side (XCLK clock)
	reg [PTR_W-1:0] rsp_wr_ptr_xclk;
	reg [PTR_W-1:0] rsp_rd_ptr_xclk; // gray code read pointer synchronized to XCLK domain

	// Response FIFO - read side (Wishbone clock)
	reg [PTR_W-1:0] rsp_rd_ptr_wb;
	reg [PTR_W-1:0] rsp_wr_ptr_wb; // gray code write pointer synchronized to WB domain

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
			for (i = PTR_W-2; i >= 0; i = i - 1)
				bin[i] = gray[i] ^ bin[i+1];
			gray2bin = bin;
		end
	endfunction

	// Request FIFO write (Wishbone clock)
	wire req_full_wb = (req_wr_ptr_wb == req_rd_ptr_wb) && (req_wr_ptr_wb[PTR_W-1] != req_rd_ptr_wb[PTR_W-1]);
	wire req_wr_en_wb = i_wb_cyc && i_wb_stb && !req_full_wb;

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset)
			req_wr_ptr_wb <= {PTR_W{1'b0}};
		else if (req_wr_en_wb) begin
			req_mem[req_wr_ptr_wb] <= {i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};
			req_wr_ptr_wb <= req_wr_ptr_wb + 1'b1;
		end
	end

	// Synchronize request write pointer to XCLK domain
	reg [PTR_W-1:0] req_wr_ptr_gray_wb;
	reg [PTR_W-1:0] req_wr_ptr_gray_xclk_1, req_wr_ptr_gray_xclk_2;

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset)
			req_wr_ptr_gray_wb <= {PTR_W{1'b0}};
		else
			req_wr_ptr_gray_wb <= bin2gray(req_wr_ptr_wb);
	end

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			req_wr_ptr_gray_xclk_1 <= {PTR_W{1'b0}};
			req_wr_ptr_gray_xclk_2 <= {PTR_W{1'b0}};
		end else begin
			req_wr_ptr_gray_xclk_1 <= req_wr_ptr_gray_wb;
			req_wr_ptr_gray_xclk_2 <= req_wr_ptr_gray_xclk_1;
		end
	end

	assign req_wr_ptr_xclk = gray2bin(req_wr_ptr_gray_xclk_2);

	// Request FIFO read (XCLK clock)
	wire req_empty_xclk = (req_rd_ptr_xclk == req_wr_ptr_xclk);
	wire req_rd_en_xclk = !req_empty_xclk && !i_xclk_stall;

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset)
			req_rd_ptr_xclk <= {PTR_W{1'b0}};
		else if (req_rd_en_xclk)
			req_rd_ptr_xclk <= req_rd_ptr_xclk + 1'b1;
	end

	// Synchronize request read pointer to WB domain
	reg [PTR_W-1:0] req_rd_ptr_gray_xclk;
	reg [PTR_W-1:0] req_rd_ptr_gray_wb_1, req_rd_ptr_gray_wb_2;

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset)
			req_rd_ptr_gray_xclk <= {PTR_W{1'b0}};
		else
			req_rd_ptr_gray_xclk <= bin2gray(req_rd_ptr_xclk);
	end

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_rd_ptr_gray_wb_1 <= {PTR_W{1'b0}};
			req_rd_ptr_gray_wb_2 <= {PTR_W{1'b0}};
		end else begin
			req_rd_ptr_gray_wb_1 <= req_rd_ptr_gray_xclk;
			req_rd_ptr_gray_wb_2 <= req_rd_ptr_gray_wb_1;
		end
	end

	assign req_rd_ptr_wb = gray2bin(req_rd_ptr_gray_wb_2);

	// Response FIFO write (XCLK clock)
	wire rsp_full_xclk = (rsp_wr_ptr_xclk == rsp_rd_ptr_xclk) && (rsp_wr_ptr_xclk[PTR_W-1] != rsp_rd_ptr_xclk[PTR_W-1]);
	wire rsp_wr_en_xclk = i_xclk_ack && !rsp_full_xclk;

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset)
			rsp_wr_ptr_xclk <= {PTR_W{1'b0}};
		else if (rsp_wr_en_xclk) begin
			rsp_mem[rsp_wr_ptr_xclk] <= {i_xclk_err, i_xclk_data};
			rsp_wr_ptr_xclk <= rsp_wr_ptr_xclk + 1'b1;
		end
	end

	// Synchronize response write pointer to WB domain
	reg [PTR_W-1:0] rsp_wr_ptr_gray_xclk;
	reg [PTR_W-1:0] rsp_wr_ptr_gray_wb_1, rsp_wr_ptr_gray_wb_2;

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset)
			rsp_wr_ptr_gray_xclk <= {PTR_W{1'b0}};
		else
			rsp_wr_ptr_gray_xclk <= bin2gray(rsp_wr_ptr_xclk);
	end

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			rsp_wr_ptr_gray_wb_1 <= {PTR_W{1'b0}};
			rsp_wr_ptr_gray_wb_2 <= {PTR_W{1'b0}};
		end else begin
			rsp_wr_ptr_gray_wb_1 <= rsp_wr_ptr_gray_xclk;
			rsp_wr_ptr_gray_wb_2 <= rsp_wr_ptr_gray_wb_1;
		end
	end

	assign rsp_wr_ptr_wb = gray2bin(rsp_wr_ptr_gray_wb_2);

	// Response FIFO read (Wishbone clock)
	wire rsp_empty_wb = (rsp_rd_ptr_wb == rsp_wr_ptr_wb);
	wire rsp_rd_en_wb = !rsp_empty_wb;

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset)
			rsp_rd_ptr_wb <= {PTR_W{1'b0}};
		else if (rsp_rd_en_wb)
			rsp_rd_ptr_wb <= rsp_rd_ptr_wb + 1'b1;
	end

	// Synchronize response read pointer to XCLK domain
	reg [PTR_W-1:0] rsp_rd_ptr_gray_wb;
	reg [PTR_W-1:0] rsp_rd_ptr_gray_xclk_1, rsp_rd_ptr_gray_xclk_2;

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset)
			rsp_rd_ptr_gray_wb <= {PTR_W{1'b0}};
		else
			rsp_rd_ptr_gray_wb <= bin2gray(rsp_rd_ptr_wb);
	end

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			rsp_rd_ptr_gray_xclk_1 <= {PTR_W{1'b0}};
			rsp_rd_ptr_gray_xclk_2 <= {PTR_W{1'b0}};
		end else begin
			rsp_rd_ptr_gray_xclk_1 <= rsp_rd_ptr_gray_wb;
			rsp_rd_ptr_gray_xclk_2 <= rsp_rd_ptr_gray_xclk_1;
		end
	end

	assign rsp_rd_ptr_xclk = gray2bin(rsp_rd_ptr_gray_xclk_2);

	// XCLK side outputs
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc  <= 1'b0;
			o_xclk_stb  <= 1'b0;
			o_xclk_we   <= 1'b0;
			o_xclk_addr <= {AW{1'b0}};
			o_xclk_data <= {DW{1'b0}};
			o_xclk_sel  <= {(DW/8){1'b0}};
		end else begin
			if (req_rd_en_xclk) begin
				o_xclk_cyc  <= req_mem[req_rd_ptr_xclk][REQ_W-1];
				o_xclk_addr <= req_mem[req_rd_ptr_xclk][REQ_W-2:REQ_W-1-AW];
				o_xclk_data <= req_mem[req_rd_ptr_xclk][REQ_W-1-AW:REQ_W-1-AW-DW];
				o_xclk_sel  <= req_mem[req_rd_ptr_xclk][REQ_W-1-AW-DW:0];
				o_xclk_stb  <= 1'b1;
			end else begin
				o_xclk_stb <= 1'b0;
			end
		end
	end

	// Wishbone side outputs
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack   <= 1'b0;
			o_wb_data  <= {DW{1'b0}};
			o_wb_err   <= 1'b0;
		end else begin
			if (rsp_rd_en_wb) begin
				o_wb_ack  <= 1'b1;
				o_wb_data <= rsp_mem[rsp_rd_ptr_wb][RSP_W-1:0];
				o_wb_err  <= rsp_mem[rsp_rd_ptr_wb][RSP_W-1];
			end else begin
				o_wb_ack <= 1'b0;
			end
		end
	end

	// o_wb_stall = outstanding request count
	// Count = number of requests in the request FIFO
	// We can compute this from the pointers in the WB domain
	wire [PTR_W:0] req_count_wb = req_wr_ptr_wb - req_rd_ptr_wb;
	assign o_wb_stall = (req_count_wb != 0);

endmodule
