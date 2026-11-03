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

	localparam FIFO_DEPTH = 1 << LGFIFO;
	localparam FIFO_WIDTH = AW + DW + 2; // addr + data + we + sel? No, sel is DW/8. Let's pack: addr, data, we, sel
	// Actually, let's define a struct-like packing.
	// Fields: addr (AW), data (DW), we (1), sel (DW/8)
	// Total width = AW + DW + 1 + DW/8

	localparam SEL_W = DW/8;
	localparam REQ_W = AW + DW + 1 + SEL_W;
	localparam RSP_W = DW + 1; // data + err

	// Request FIFO
	wire [REQ_W-1:0] req_fifo_din;
	wire             req_fifo_wr_en;
	wire             req_fifo_rd_en;
	wire [REQ_W-1:0] req_fifo_dout;
	wire             req_fifo_full;
	wire             req_fifo_empty;
	wire [LGFIFO:0]  req_fifo_count;

	// Response FIFO
	wire [RSP_W-1:0] rsp_fifo_din;
	wire             rsp_fifo_wr_en;
	wire             rsp_fifo_rd_en;
	wire [RSP_W-1:0] rsp_fifo_dout;
	wire             rsp_fifo_full;
	wire             rsp_fifo_empty;
	wire [LGFIFO:0]  rsp_fifo_count;

	// Request FIFO instance
	fifo_sync #(.WIDTH(REQ_W), .DEPTH(FIFO_DEPTH)) u_req_fifo (
		.clk_w   (i_wb_clk),
		.rst_w   (i_reset),
		.wr_en   (req_fifo_wr_en),
		.din     (req_fifo_din),
		.full    (req_fifo_full),
		.clk_r   (i_xclk_clk),
		.rst_r   (i_reset),
		.rd_en   (req_fifo_rd_en),
		.dout    (req_fifo_dout),
		.empty   (req_fifo_empty),
		.count   (req_fifo_count)
	);

	// Response FIFO instance
	fifo_sync #(.WIDTH(RSP_W), .DEPTH(FIFO_DEPTH)) u_rsp_fifo (
		.clk_w   (i_xclk_clk),
		.rst_w   (i_reset),
		.wr_en   (rsp_fifo_wr_en),
		.din     (rsp_fifo_din),
		.full    (rsp_fifo_full),
		.clk_r   (i_wb_clk),
		.rst_r   (i_reset),
		.rd_en   (rsp_fifo_rd_en),
		.dout    (rsp_fifo_dout),
		.empty   (rsp_fifo_empty),
		.count   (rsp_fifo_count)
	);

	// Wishbone side logic
	// Accept request if not stalled
	wire wb_accept = i_wb_cyc && i_wb_stb && !o_wb_stall;

	// Pack request
	assign req_fifo_din = {i_wb_addr, i_wb_data, i_wb_we, i_wb_sel};
	assign req_fifo_wr_en = wb_accept;

	// o_wb_stall is high when request FIFO is full
	assign o_wb_stall = req_fifo_full;

	// Response side: read from response FIFO
	// We need to present the response when the FIFO is not empty
	// The response is valid when rsp_fifo_empty is low
	// We read from the FIFO when we present the response
	// The response is presented for one cycle when the FIFO is not empty
	// But we need to ensure we only read when we are actually presenting
	// Let's use a simple approach: if not empty, present and read

	wire rsp_valid = !rsp_fifo_empty;

	// Unpack response
	wire [DW-1:0] rsp_data = rsp_fifo_dout[RSP_W-1:0];
	wire           rsp_err  = rsp_fifo_dout[RSP_W];

	// Present response on Wishbone side
	// The response is valid for one cycle
	// We read from the FIFO when we present the response
	// But we need to be careful: if we read, the FIFO becomes empty on the next cycle
	// So we present the response when rsp_valid is high, and read from the FIFO
	// The response is held for one cycle

	// We need to register the response to present it
	// Actually, the FIFO output is combinational, so we can present it directly
	// But we need to read from the FIFO to advance it
	// Let's read from the FIFO when we present the response

	// The response is presented when rsp_valid is high
	// We read from the FIFO when we present the response
	// But we need to ensure that the response is stable for one cycle
	// Since the FIFO output is stable as long as we don't read, we can present it
	// and read from the FIFO in the same cycle

	// However, if we read from the FIFO, the output changes on the next cycle
	// So we need to register the response to present it for one cycle

	// Let's use a register to hold the response
	reg [DW-1:0] wb_rsp_data_reg;
	reg           wb_rsp_err_reg;
	reg           wb_rsp_valid_reg;

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wb_rsp_data_reg <= {DW{1'b0}};
			wb_rsp_err_reg  <= 1'b0;
			wb_rsp_valid_reg <= 1'b0;
		end else begin
			if (rsp_valid) begin
				wb_rsp_data_reg  <= rsp_data;
				wb_rsp_err_reg   <= rsp_err;
				wb_rsp_valid_reg <= 1'b1;
			end else begin
				wb_rsp_valid_reg <= 1'b0;
			end
		end
		end

	// Read from response FIFO when we present the response
	// We read from the FIFO when wb_rsp_valid_reg is high
	// But we need to ensure that we only read when the FIFO is not empty
	// Since wb_rsp_valid_reg is set when rsp_valid is high, and rsp_valid is !rsp_fifo_empty
	// We can read from the FIFO when wb_rsp_valid_reg is high

	assign rsp_fifo_rd_en = wb_rsp_valid_reg;

	// Present response on Wishbone side
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack  <= 1'b0;
			o_wb_data <= {DW{1'b0}};
			o_wb_err  <= 1'b0;
		end else begin
			if (wb_rsp_valid_reg) begin
				o_wb_ack  <= 1'b1;
				o_wb_data <= wb_rsp_data_reg;
				o_wb_err  <= wb_rsp_err_reg;
			end else begin
				o_wb_ack  <= 1'b0;
				o_wb_data <= {DW{1'b0}};
				o_wb_err  <= 1'b0;
			end
		end
	end

	// XCLK side logic
	// Present request from request FIFO
	// The request is valid when req_fifo_empty is low
	// We present the request when req_fifo_empty is low and not stalled
	// We read from the FIFO when we present the request and it is accepted

	wire req_valid = !req_fifo_empty;

	// Unpack request
	wire [AW-1:0]  req_addr = req_fifo_dout[REQ_W-1:AW];
	wire [DW-1:0]  req_data = req_fifo_dout[AW+DW-1:DW];
	wire            req_we   = req_fifo_dout[DW];
	wire [SEL_W-1:0] req_sel = req_fifo_dout[DW-1:0];

	// Present request on XCLK side
	// The request is presented when req_valid is high and not stalled
	// We read from the FIFO when the request is accepted

	wire xclk_accept = req_valid && !i_xclk_stall;

	// Read from request FIFO when the request is accepted
	assign req_fifo_rd_en = xclk_accept;

	// Present request on XCLK side
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc  <= 1'b0;
			o_xclk_stb  <= 1'b0;
			o_xclk_we   <= 1'b0;
			o_xclk_addr <= {AW{1'b0}};
			o_xclk_data <= {DW{1'b0}};
			o_xclk_sel  <= {SEL_W{1'b0}};
		end else begin
			if (req_valid) begin
				o_xclk_cyc  <= 1'b1;
				o_xclk_stb  <= 1'b1;
				o_xclk_we   <= req_we;
				o_xclk_addr <= req_addr;
				o_xclk_data <= req_data;
				o_xclk_sel  <= req_sel;
			end else begin
				o_xclk_cyc  <= 1'b0;
				o_xclk_stb  <= 1'b0;
				o_xclk_we   <= 1'b0;
				o_xclk_addr <= {AW{1'b0}};
				o_xclk_data <= {DW{1'b0}};
				o_xclk_sel  <= {SEL_W{1'b0}};
			end
		end
	end

	// Response side: write to response FIFO
	// The response is valid when i_xclk_ack is high
	// We write to the FIFO when i_xclk_ack is high and the FIFO is not full
	// But we need to ensure that we don't lose responses
	// If the FIFO is full, we need to stall the XCLK side
	// But the XCLK side is already stalled by i_xclk_stall
	// So we can write to the FIFO when i_xclk_ack is high

	// Pack response
	assign rsp_fifo_din = {i_xclk_err, i_xclk_data};
	assign rsp_fifo_wr_en = i_xclk_ack;

endmodule

// Synchronous FIFO module
module fifo_sync #(
	parameter WIDTH = 32,
	parameter DEPTH = 16
) (
	input  wire             clk_w,
	input  wire             rst_w,
	input  wire             wr_en,
	input  wire [WIDTH-1:0] din,
	output wire             full,
	input  wire             clk_r,
	input  wire             rst_r,
	input  wire             rd_en,
	output wire [WIDTH-1:0] dout,
	output wire             empty,
	output wire [5:0]       count
);

	localparam ADDR_W = $clog2(DEPTH);

	reg [WIDTH-1:0] mem [0:DEPTH-1];
	reg [ADDR_W-1:0] wr_ptr, rd_ptr;
	reg [ADDR_W:0]   wr_count, rd_count;

	// Write side
	always @(posedge clk_w or posedge rst_w) begin
		if (rst_w) begin
			wr_ptr   <= {ADDR_W{1'b0}};
			wr_count <= {(ADDR_W+1){1'b0}};
		end else if (wr_en && !full) begin
			mem[wr_ptr] <= din;
			wr_ptr   <= wr_ptr + 1'b1;
			wr_count <= wr_count + 1'b1;
		end
	end

	// Read side
	always @(posedge clk_r or posedge rst_r) begin
		if (rst_r) begin
			rd_ptr   <= {ADDR_W{1'b0}};
			rd_count <= {(ADDR_W+1){1'b0}};
		end else if (rd_en && !empty) begin
			rd_ptr   <= rd_ptr + 1'b1;
			rd_count <= rd_count + 1'b1;
		end
	end

	// Synchronize write pointer to read clock domain
	reg [ADDR_W:0] wr_ptr_sync [0:2];
	always @(posedge clk_r or posedge rst_r) begin
		if (rst_r) begin
			wr_ptr_sync[0] <= {(ADDR_W+1){1'b0}};
			wr_ptr_sync[1] <= {(ADDR_W+1){1'b0}};
			wr_ptr_sync[2] <= {(ADDR_W+1){1'b0}};
		end else begin
			wr_ptr_sync[0] <= wr_count;
			wr_ptr_sync[1] <= wr_ptr_sync[0];
			wr_ptr_sync[2] <= wr_ptr_sync[1];
		end
	end

	// Synchronize read pointer to write clock domain
	reg [ADDR_W:0] rd_ptr_sync [0:2];
	always @(posedge clk_w or posedge rst_w) begin
		if (rst_w) begin
			rd_ptr_sync[0] <= {(ADDR_W+1){1'b0}};
			rd_ptr_sync[1] <= {(ADDR_W+1){1'b0}};
			rd_ptr_sync[2] <= {(ADDR_W+1){1'b0}};
		end else begin
			rd_ptr_sync[0] <= rd_count;
			rd_ptr_sync[1] <= rd_ptr_sync[0];
			rd_ptr_sync[2] <= rd_ptr_sync[1];
		end
	end

	// Calculate count in read clock domain
	wire [ADDR_W:0] wr_count_sync = wr_ptr_sync[2];
	wire [ADDR_W:0] count_r = wr_count_sync - rd_count;

	// Calculate count in write clock domain
	wire [ADDR_W:0] rd_count_sync = rd_ptr_sync[2];
	wire [ADDR_W:0] count_w = wr_count - rd_count_sync;

	// Full and empty flags
	assign full  = (count_w == DEPTH);
	assign empty = (count_r == 0);

	// Output
	assign dout  = mem[rd_ptr];
	assign count = count_r;

endmodule
