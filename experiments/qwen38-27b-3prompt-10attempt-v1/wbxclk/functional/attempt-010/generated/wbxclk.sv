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

	localparam FIFO_DEPTH = 1 << LGFIFO;
	localparam FIFO_WIDTH = AW + DW + (DW/8) + 1; // addr + data + sel + we

	// Request FIFO (wb_clk domain)
	reg [FIFO_WIDTH-1:0] req_fifo [0:FIFO_DEPTH-1];
	reg [LGFIFO:0] req_wr_ptr, req_rd_ptr;
	reg req_full, req_empty;

	// Response FIFO (xclk_clk domain)
	reg [DW+1:0] rsp_fifo [0:FIFO_DEPTH-1]; // data + err
	reg [LGFIFO:0] rsp_wr_ptr, rsp_rd_ptr;
	reg rsp_full, rsp_empty;

	// Synchronization signals
	reg [1:0] req_full_sync, rsp_empty_sync;
	reg [1:0] rsp_full_sync, req_empty_sync;

	// Request FIFO write logic (wb_clk domain)
	wire req_wr_en = i_wb_cyc & i_wb_stb & ~req_full;
	wire req_wr_data = {i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_wr_ptr <= 0;
			req_full <= 0;
		end else if (req_wr_en) begin
			req_fifo[req_wr_ptr[LGFIFO-1:0]] <= req_wr_data;
			req_wr_ptr <= req_wr_ptr + 1;
			req_full <= (req_wr_ptr[LGFIFO] != req_rd_ptr[LGFIFO]);
		end
	end

	// Request FIFO read logic (xclk_clk domain)
	wire req_rd_en = ~req_empty & ~i_xclk_stall;
	wire [FIFO_WIDTH-1:0] req_rd_data = req_fifo[req_rd_ptr[LGFIFO-1:0]];

	always @(posedge i_xclk_clk) begin
		if (req_rd_en) begin
			req_rd_ptr <= req_rd_ptr + 1;
			req_empty <= (req_rd_ptr[LGFIFO] != req_wr_ptr[LGFIFO]);
		end
	end

	// Response FIFO write logic (xclk_clk domain)
	wire rsp_wr_en = i_xclk_ack;
	wire [DW+1:0] rsp_wr_data = {i_xclk_err, i_xclk_data};

	always @(posedge i_xclk_clk) begin
		if (rsp_wr_en) begin
			rsp_fifo[rsp_wr_ptr[LGFIFO-1:0]] <= rsp_wr_data;
			rsp_wr_ptr <= rsp_wr_ptr + 1;
			rsp_full <= (rsp_wr_ptr[LGFIFO] != rsp_rd_ptr[LGFIFO]);
		end
	end

	// Response FIFO read logic (wb_clk domain)
	wire rsp_rd_en = ~rsp_empty;
	wire [DW+1:0] rsp_rd_data = rsp_fifo[rsp_rd_ptr[LGFIFO-1:0]];

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			rsp_rd_ptr <= 0;
			rsp_empty <= 1;
		end else if (rsp_rd_en) begin
			rsp_rd_ptr <= rsp_rd_ptr + 1;
			rsp_empty <= (rsp_rd_ptr[LGFIFO] != rsp_wr_ptr[LGFIFO]);
		end
	end

	// Synchronize req_full to xclk_clk domain
	always @(posedge i_xclk_clk) begin
		req_full_sync <= {req_full_sync[0], req_full};
	end

	// Synchronize rsp_empty to wb_clk domain
	always @(posedge i_wb_clk) begin
		rsp_empty_sync <= {rsp_empty_sync[0], rsp_empty};
	end

	// Synchronize rsp_full to wb_clk domain
	always @(posedge i_wb_clk) begin
		rsp_full_sync <= {rsp_full_sync[0], rsp_full};
	end

	// Synchronize req_empty to xclk_clk domain
	always @(posedge i_xclk_clk) begin
		req_empty_sync <= {req_empty_sync[0], req_empty};
	end

	// Output logic
	assign o_wb_stall = req_full_sync[1] | rsp_full_sync[1];

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 0;
			o_wb_data <= 0;
			o_wb_err <= 0;
		end else if (rsp_rd_en) begin
			o_wb_ack <= 1;
			o_wb_data <= rsp_rd_data[DW-1:0];
			o_wb_err <= rsp_rd_data[DW];
		end else begin
			o_wb_ack <= 0;
		end
	end

	always @(posedge i_xclk_clk) begin
		if (req_rd_en) begin
			o_xclk_cyc <= 1;
			o_xclk_stb <= 1;
			o_xclk_we <= req_rd_data[FIFO_WIDTH-1];
			o_xclk_addr <= req_rd_data[FIFO_WIDTH-2:FIFO_WIDTH-1-AW];
			o_xclk_data <= req_rd_data[FIFO_WIDTH-1-AW:FIFO_WIDTH-1-AW-DW];
			o_xclk_sel <= req_rd_data[FIFO_WIDTH-1-AW-DW-1:0];
		end else begin
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
		end
	end

endmodule
