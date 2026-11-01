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

	localparam FIFO_DEPTH = 1 << LGFIFO;
	localparam FIFO_PTR_W = LGFIFO;
	localparam FIFO_FULL_THRESH = FIFO_DEPTH - 1;

	// Request FIFO (wb -> xclk)
	reg [DW-1:0] req_fifo_data [0:FIFO_DEPTH-1];
	reg [AW-1:0] req_fifo_addr [0:FIFO_DEPTH-1];
	reg [DW/8-1:0] req_fifo_sel [0:FIFO_DEPTH-1];
	reg req_fifo_we [0:FIFO_DEPTH-1];
	reg [FIFO_PTR_W-1:0] req_wr_ptr, req_rd_ptr;
	reg req_wr_en, req_rd_en;
	wire req_full, req_empty;

	// Response FIFO (xclk -> wb)
	reg [DW-1:0] rsp_fifo_data [0:FIFO_DEPTH-1];
	reg rsp_fifo_err [0:FIFO_DEPTH-1];
	reg [FIFO_PTR_W-1:0] rsp_wr_ptr, rsp_rd_ptr;
	reg rsp_wr_en, rsp_rd_en;
	wire rsp_full, rsp_empty;

	// Synchronizers for request FIFO pointers
	reg [FIFO_PTR_W-1:0] req_wr_ptr_sync1, req_wr_ptr_sync2;
	reg [FIFO_PTR_W-1:0] req_rd_ptr_sync1, req_rd_ptr_sync2;

	// Synchronizers for response FIFO pointers
	reg [FIFO_PTR_W-1:0] rsp_wr_ptr_sync1, rsp_wr_ptr_sync2;
	reg [FIFO_PTR_W-1:0] rsp_rd_ptr_sync1, rsp_rd_ptr_sync2;

	// Synchronizers for xclk stall
	reg i_xclk_stall_sync1, i_xclk_stall_sync2;

	// Synchronizers for xclk ack
	reg i_xclk_ack_sync1, i_xclk_ack_sync2;

	// Synchronizers for xclk data and err
	reg [DW-1:0] i_xclk_data_sync1, i_xclk_data_sync2;
	reg i_xclk_err_sync1, i_xclk_err_sync2;

	// WB side logic
	wire wb_can_accept = !req_full && !i_xclk_stall_sync2;
	assign o_wb_stall = !wb_can_accept;

	wire wb_accept = i_wb_cyc && i_wb_stb && wb_can_accept;

	// XCLK side logic
	wire xclk_can_read = !req_empty && !i_xclk_stall_sync2;
	wire xclk_read = xclk_can_read;

	// Response FIFO write from xclk side
	wire xclk_rsp_write = i_xclk_ack_sync2;

	// Response FIFO read from wb side
	wire wb_rsp_read = !rsp_empty;

	// Synchronizer for req_wr_ptr to xclk domain
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			req_wr_ptr_sync1 <= {FIFO_PTR_W{1'b0}};
			req_wr_ptr_sync2 <= {FIFO_PTR_W{1'b0}};
		end else begin
			req_wr_ptr_sync1 <= req_wr_ptr;
			req_wr_ptr_sync2 <= req_wr_ptr_sync1;
		end
	end

	// Synchronizer for req_rd_ptr to wb domain
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_rd_ptr_sync1 <= {FIFO_PTR_W{1'b0}};
			req_rd_ptr_sync2 <= {FIFO_PTR_W{1'b0}};
		end else begin
			req_rd_ptr_sync1 <= req_rd_ptr;
			req_rd_ptr_sync2 <= req_rd_ptr_sync1;
		end
	end

	// Synchronizer for rsp_wr_ptr to wb domain
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			rsp_wr_ptr_sync1 <= {FIFO_PTR_W{1'b0}};
			rsp_wr_ptr_sync2 <= {FIFO_PTR_W{1'b0}};
		end else begin
			rsp_wr_ptr_sync1 <= rsp_wr_ptr;
			rsp_wr_ptr_sync2 <= rsp_wr_ptr_sync1;
		end
	end

	// Synchronizer for rsp_rd_ptr to xclk domain
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			rsp_rd_ptr_sync1 <= {FIFO_PTR_W{1'b0}};
			rsp_rd_ptr_sync2 <= {FIFO_PTR_W{1'b0}};
		end else begin
			rsp_rd_ptr_sync1 <= rsp_rd_ptr;
			rsp_rd_ptr_sync2 <= rsp_rd_ptr_sync1;
		end
	end

	// Synchronizer for i_xclk_stall to wb domain
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			i_xclk_stall_sync1 <= 1'b0;
			i_xclk_stall_sync2 <= 1'b0;
		end else begin
			i_xclk_stall_sync1 <= i_xclk_stall;
			i_xclk_stall_sync2 <= i_xclk_stall_sync1;
		end
	end

	// Synchronizer for i_xclk_ack to wb domain
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			i_xclk_ack_sync1 <= 1'b0;
			i_xclk_ack_sync2 <= 1'b0;
		end else begin
			i_xclk_ack_sync1 <= i_xclk_ack;
			i_xclk_ack_sync2 <= i_xclk_ack_sync1;
		end
	end

	// Synchronizer for i_xclk_data to wb domain
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			i_xclk_data_sync1 <= {DW{1'b0}};
			i_xclk_data_sync2 <= {DW{1'b0}};
		end else begin
			i_xclk_data_sync1 <= i_xclk_data;
			i_xclk_data_sync2 <= i_xclk_data_sync1;
		end
	end

	// Synchronizer for i_xclk_err to wb domain
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			i_xclk_err_sync1 <= 1'b0;
			i_xclk_err_sync2 <= 1'b0;
		end else begin
			i_xclk_err_sync1 <= i_xclk_err;
			i_xclk_err_sync2 <= i_xclk_err_sync1;
		end
	end

	// Request FIFO full/empty
	wire [FIFO_PTR_W:0] req_wr_ptr_ext = {1'b0, req_wr_ptr};
	wire [FIFO_PTR_W:0] req_rd_ptr_ext = {1'b0, req_rd_ptr};
	wire [FIFO_PTR_W:0] req_wr_ptr_sync2_ext = {1'b0, req_wr_ptr_sync2};
	wire [FIFO_PTR_W:0] req_rd_ptr_sync2_ext = {1'b0, req_rd_ptr_sync2};

	// In wb domain: req_full when wr_ptr - rd_ptr_sync2 == FIFO_DEPTH
	wire [FIFO_PTR_W:0] req_diff_wb = req_wr_ptr_ext - req_rd_ptr_sync2_ext;
	assign req_full = (req_diff_wb == FIFO_DEPTH);

	// In xclk domain: req_empty when rd_ptr == wr_ptr_sync2
	assign req_empty = (req_rd_ptr == req_wr_ptr_sync2);

	// Response FIFO full/empty
	wire [FIFO_PTR_W:0] rsp_wr_ptr_ext = {1'b0, rsp_wr_ptr};
	wire [FIFO_PTR_W:0] rsp_rd_ptr_ext = {1'b0, rsp_rd_ptr};
	wire [FIFO_PTR_W:0] rsp_wr_ptr_sync2_ext = {1'b0, rsp_wr_ptr_sync2};
	wire [FIFO_PTR_W:0] rsp_rd_ptr_sync2_ext = {1'b0, rsp_rd_ptr_sync2};

	// In wb domain: rsp_empty when rd_ptr == wr_ptr_sync2
	assign rsp_empty = (rsp_rd_ptr == rsp_wr_ptr_sync2);

	// In xclk domain: rsp_full when wr_ptr - rd_ptr_sync2 == FIFO_DEPTH
	wire [FIFO_PTR_W:0] rsp_diff_xclk = rsp_wr_ptr_ext - rsp_rd_ptr_sync2_ext;
	wire rsp_full_xclk = (rsp_diff_xclk == FIFO_DEPTH);

	// WB domain: write to request FIFO
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_wr_ptr <= {FIFO_PTR_W{1'b0}};
		end else if (wb_accept) begin
			req_fifo_data[req_wr_ptr] <= i_wb_data;
			req_fifo_addr[req_wr_ptr] <= i_wb_addr;
			req_fifo_sel[req_wr_ptr] <= i_wb_sel;
			req_fifo_we[req_wr_ptr] <= i_wb_we;
			req_wr_ptr <= req_wr_ptr + 1'b1;
		end
	end

	// WB domain: read from response FIFO
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			rsp_rd_ptr <= {FIFO_PTR_W{1'b0}};
			o_wb_ack <= 1'b0;
			o_wb_data <= {DW{1'b0}};
			o_wb_err <= 1'b0;
		end else if (wb_rsp_read) begin
			o_wb_ack <= 1'b1;
			o_wb_data <= rsp_fifo_data[rsp_rd_ptr];
			o_wb_err <= rsp_fifo_err[rsp_rd_ptr];
			rsp_rd_ptr <= rsp_rd_ptr + 1'b1;
		end else begin
			o_wb_ack <= 1'b0;
		end
	end

	// XCLK domain: read from request FIFO
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			req_rd_ptr <= {FIFO_PTR_W{1'b0}};
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= {AW{1'b0}};
			o_xclk_data <= {DW{1'b0}};
			o_xclk_sel <= {(DW/8){1'b0}};
		end else if (xclk_read) begin
			o_xclk_cyc <= 1'b1;
			o_xclk_stb <= 1'b1;
			o_xclk_we <= req_fifo_we[req_rd_ptr];
			o_xclk_addr <= req_fifo_addr[req_rd_ptr];
			o_xclk_data <= req_fifo_data[req_rd_ptr];
			o_xclk_sel <= req_fifo_sel[req_rd_ptr];
			req_rd_ptr <= req_rd_ptr + 1'b1;
		end else begin
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
		end
	end

	// XCLK domain: write to response FIFO
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			rsp_wr_ptr <= {FIFO_PTR_W{1'b0}};
		end else if (xclk_rsp_write && !rsp_full_xclk) begin
			rsp_fifo_data[rsp_wr_ptr] <= i_xclk_data;
			rsp_fifo_err[rsp_wr_ptr] <= i_xclk_err;
			rsp_wr_ptr <= rsp_wr_ptr + 1'b1;
		end
	end

endmodule
