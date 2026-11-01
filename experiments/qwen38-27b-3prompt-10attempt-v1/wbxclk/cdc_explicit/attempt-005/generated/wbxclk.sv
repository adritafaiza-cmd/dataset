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
	localparam FIFO_WIDTH = AW + DW + (DW/8) + 1; // addr + data + sel + we

	// Request FIFO (wb -> xclk)
	reg [FIFO_WIDTH-1:0] req_fifo [0:FIFO_DEPTH-1];
	reg [LGFIFO:0] req_wr_ptr;
	reg [LGFIFO:0] req_rd_ptr;
	reg [LGFIFO:0] req_rd_ptr_sync1;
	reg [LGFIFO:0] req_rd_ptr_sync2;
	reg [LGFIFO:0] req_wr_ptr_sync1;
	reg [LGFIFO:0] req_wr_ptr_sync2;

	// Response FIFO (xclk -> wb)
	reg [DW+1:0] resp_fifo [0:FIFO_DEPTH-1]; // data + err
	reg [LGFIFO:0] resp_wr_ptr;
	reg [LGFIFO:0] resp_rd_ptr;
	reg [LGFIFO:0] resp_rd_ptr_sync1;
	reg [LGFIFO:0] resp_rd_ptr_sync2;
	reg [LGFIFO:0] resp_wr_ptr_sync1;
	reg [LGFIFO:0] resp_wr_ptr_sync2;

	// Reset synchronizers
	reg [1:0] rst_sync_wb;
	reg [1:0] rst_sync_xclk;

	// WB domain: reset synchronizer
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset)
			rst_sync_wb <= 2'b00;
		else
			rst_sync_wb <= {rst_sync_wb[0], 1'b1};
	end

	// XCLK domain: reset synchronizer
	always @(posedge i_xclk_clk) begin
		rst_sync_xclk <= {rst_sync_xclk[0], rst_sync_wb[1]};
	end

	// WB domain: request FIFO write
	wire req_full = (req_wr_ptr - req_rd_ptr_sync2) == FIFO_DEPTH;
	wire req_valid = i_wb_cyc & i_wb_stb & ~req_full;

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset)
			req_wr_ptr <= {(LGFIFO+1){1'b0}};
		else if (req_valid)
			req_wr_ptr <= req_wr_ptr + 1'b1;
	end

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (req_valid)
			req_fifo[req_wr_ptr[LGFIFO-1:0]] <= {i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};
	end

	// WB domain: sync request read pointer
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_rd_ptr_sync1 <= {(LGFIFO+1){1'b0}};
			req_rd_ptr_sync2 <= {(LGFIFO+1){1'b0}};
		end
		else begin
			req_rd_ptr_sync1 <= req_rd_ptr;
			req_rd_ptr_sync2 <= req_rd_ptr_sync1;
		end
	end

	// XCLK domain: sync request write pointer
	always @(posedge i_xclk_clk) begin
		req_wr_ptr_sync1 <= req_wr_ptr;
		req_wr_ptr_sync2 <= req_wr_ptr_sync1;
	end

	// XCLK domain: request FIFO read
	wire req_empty = (req_rd_ptr == req_wr_ptr_sync2);
	wire xclk_ready = ~i_xclk_stall;
	wire req_read = ~req_empty & xclk_ready;

	always @(posedge i_xclk_clk) begin
		if (rst_sync_xclk[1])
			req_rd_ptr <= {(LGFIFO+1){1'b0}};
		else if (req_read)
			req_rd_ptr <= req_rd_ptr + 1'b1;
	end

	// XCLK domain: drive xclk outputs
	always @(posedge i_xclk_clk) begin
		if (rst_sync_xclk[1]) begin
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= {(AW){1'b0}};
			o_xclk_data <= {(DW){1'b0}};
			o_xclk_sel <= {(DW/8){1'b0}};
		end
		else if (req_read) begin
			o_xclk_cyc <= 1'b1;
			o_xclk_stb <= 1'b1;
			o_xclk_we <= req_fifo[req_rd_ptr[LGFIFO-1:0]][FIFO_WIDTH-1];
			o_xclk_addr <= req_fifo[req_rd_ptr[LGFIFO-1:0]][FIFO_WIDTH-2:FIFO_WIDTH-1-AW];
			o_xclk_data <= req_fifo[req_rd_ptr[LGFIFO-1:0]][FIFO_WIDTH-2-AW:FIFO_WIDTH-2-AW-DW];
			o_xclk_sel <= req_fifo[req_rd_ptr[LGFIFO-1:0]][FIFO_WIDTH-2-AW-DW:FIFO_WIDTH-2-AW-DW-(DW/8)];
		end
		else if (i_xclk_ack) begin
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
		end
	end

	// XCLK domain: response FIFO write
	wire resp_full = (resp_wr_ptr - resp_rd_ptr_sync2) == FIFO_DEPTH;
	wire resp_valid = i_xclk_ack & ~resp_full;

	always @(posedge i_xclk_clk) begin
		if (rst_sync_xclk[1])
			resp_wr_ptr <= {(LGFIFO+1){1'b0}};
		else if (resp_valid)
			resp_wr_ptr <= resp_wr_ptr + 1'b1;
	end

	always @(posedge i_xclk_clk) begin
		if (resp_valid)
			resp_fifo[resp_wr_ptr[LGFIFO-1:0]] <= {i_xclk_err, i_xclk_data};
	end

	// XCLK domain: sync response read pointer
	always @(posedge i_xclk_clk) begin
		resp_rd_ptr_sync1 <= resp_rd_ptr;
		resp_rd_ptr_sync2 <= resp_rd_ptr_sync1;
	end

	// WB domain: sync response write pointer
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			resp_wr_ptr_sync1 <= {(LGFIFO+1){1'b0}};
			resp_wr_ptr_sync2 <= {(LGFIFO+1){1'b0}};
		end
		else begin
			resp_wr_ptr_sync1 <= resp_wr_ptr;
			resp_wr_ptr_sync2 <= resp_wr_ptr_sync1;
		end
	end

	// WB domain: response FIFO read
	wire resp_empty = (resp_rd_ptr == resp_wr_ptr_sync2);
	wire resp_read = ~resp_empty;

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset)
			resp_rd_ptr <= {(LGFIFO+1){1'b0}};
		else if (resp_read)
			resp_rd_ptr <= resp_rd_ptr + 1'b1;
	end

	// WB domain: drive wb outputs
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 1'b0;
			o_wb_data <= {(DW){1'b0}};
			o_wb_err <= 1'b0;
		end
		else if (resp_read) begin
			o_wb_ack <= 1'b1;
			o_wb_data <= resp_fifo[resp_rd_ptr[LGFIFO-1:0]][DW-1:0];
			o_wb_err <= resp_fifo[resp_rd_ptr[LGFIFO-1:0]][DW];
		end
		else begin
			o_wb_ack <= 1'b0;
		end
	end

	// WB domain: stall output
	assign o_wb_stall = req_full;

endmodule
