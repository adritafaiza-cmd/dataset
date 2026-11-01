module wbxclk #(
	parameter AW=32,
	parameter DW=32,
	parameter LGFIFO = 5
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

	// Local parameters
	localparam FIFO_DEPTH = 1 << LGFIFO;
	localparam FIFO_PTR_W = LGFIFO;
	localparam FIFO_FULL_THRESH = FIFO_DEPTH - 1;

	// Reset synchronization for xclk domain
	reg [1:0] xclk_rst_sync;
	wire xclk_rst;

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset)
			xclk_rst_sync <= 2'b11;
		else
			xclk_rst_sync <= {xclk_rst_sync[0], 1'b0};
	end
	assign xclk_rst = xclk_rst_sync[1];

	// Request FIFO (wb_clk domain)
	reg [DW+AW+DW/8+1:0] req_fifo [0:FIFO_DEPTH-1];
	reg [FIFO_PTR_W:0] req_wr_ptr;
	reg [FIFO_PTR_W:0] req_rd_ptr_wb;
	reg [FIFO_PTR_W:0] req_rd_ptr_xclk;
	reg [FIFO_PTR_W:0] req_rd_ptr_xclk_sync;

	// Response FIFO (xclk domain)
	reg [DW+1:0] resp_fifo [0:FIFO_DEPTH-1];
	reg [FIFO_PTR_W:0] resp_wr_ptr;
	reg [FIFO_PTR_W:0] resp_rd_ptr_xclk;
	reg [FIFO_PTR_W:0] resp_rd_ptr_wb;
	reg [FIFO_PTR_W:0] resp_rd_ptr_wb_sync;

	// Synchronizers for read pointers
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset)
			req_rd_ptr_xclk_sync <= {(FIFO_PTR_W+1){1'b0}};
		else
			req_rd_ptr_xclk_sync <= req_rd_ptr_xclk;
	end

	always @(posedge i_xclk_clk or posedge xclk_rst) begin
		if (xclk_rst)
			resp_rd_ptr_wb_sync <= {(FIFO_PTR_W+1){1'b0}};
		else
			resp_rd_ptr_wb_sync <= resp_rd_ptr_wb;
	end

	// Calculate FIFO levels
	wire [FIFO_PTR_W:0] req_level = req_wr_ptr - req_rd_ptr_xclk_sync;
	wire [FIFO_PTR_W:0] resp_level = resp_wr_ptr - resp_rd_ptr_wb_sync;

	// Stall logic
	assign o_wb_stall = (req_level >= FIFO_FULL_THRESH) || (resp_level >= FIFO_FULL_THRESH);

	// Request FIFO write (wb_clk domain)
	wire req_wr_en = i_wb_cyc & i_wb_stb & ~o_wb_stall;

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_wr_ptr <= {(FIFO_PTR_W+1){1'b0}};
		end else if (req_wr_en) begin
			req_fifo[req_wr_ptr[FIFO_PTR_W-1:0]] <= {i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};
			req_wr_ptr <= req_wr_ptr + 1'b1;
		end
	end

	// Request FIFO read (xclk domain)
	wire req_rd_en = ~xclk_rst & (req_rd_ptr_xclk != req_wr_ptr) & ~i_xclk_stall;

	always @(posedge i_xclk_clk or posedge xclk_rst) begin
		if (xclk_rst) begin
			req_rd_ptr_xclk <= {(FIFO_PTR_W+1){1'b0}};
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= {(AW){1'b0}};
			o_xclk_data <= {(DW){1'b0}};
			o_xclk_sel <= {(DW/8){1'b0}};
		end else if (req_rd_en) begin
			req_rd_ptr_xclk <= req_rd_ptr_xclk + 1'b1;
			o_xclk_cyc <= 1'b1;
			o_xclk_stb <= 1'b1;
			o_xclk_we <= req_fifo[req_rd_ptr_xclk[FIFO_PTR_W-1:0]][DW+AW+DW/8];
			o_xclk_addr <= req_fifo[req_rd_ptr_xclk[FIFO_PTR_W-1:0]][DW+AW+DW/8-1:DW+DW/8];
			o_xclk_data <= req_fifo[req_rd_ptr_xclk[FIFO_PTR_W-1:0]][DW+DW/8-1:DW/8];
			o_xclk_sel <= req_fifo[req_rd_ptr_xclk[FIFO_PTR_W-1:0]][DW/8-1:0];
		end else begin
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
		end
	end

	// Response FIFO write (xclk domain)
	wire resp_wr_en = i_xclk_ack;

	always @(posedge i_xclk_clk or posedge xclk_rst) begin
		if (xclk_rst) begin
			resp_wr_ptr <= {(FIFO_PTR_W+1){1'b0}};
		end else if (resp_wr_en) begin
			resp_fifo[resp_wr_ptr[FIFO_PTR_W-1:0]] <= {i_xclk_err, i_xclk_data};
			resp_wr_ptr <= resp_wr_ptr + 1'b1;
		end
	end

	// Response FIFO read (wb_clk domain)
	wire resp_rd_en = ~i_reset & (resp_rd_ptr_wb != resp_wr_ptr);

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			resp_rd_ptr_wb <= {(FIFO_PTR_W+1){1'b0}};
			o_wb_ack <= 1'b0;
			o_wb_data <= {(DW){1'b0}};
			o_wb_err <= 1'b0;
		end else if (resp_rd_en) begin
			resp_rd_ptr_wb <= resp_rd_ptr_wb + 1'b1;
			o_wb_ack <= 1'b1;
			o_wb_data <= resp_fifo[resp_rd_ptr_wb[FIFO_PTR_W-1:0]][DW:0];
			o_wb_err <= resp_fifo[resp_rd_ptr_wb[FIFO_PTR_W-1:0]][DW];
		end else begin
			o_wb_ack <= 1'b0;
		end
	end

endmodule
