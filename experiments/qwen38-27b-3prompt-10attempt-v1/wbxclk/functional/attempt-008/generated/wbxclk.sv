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
	localparam PTR_WIDTH = LGFIFO;

	// Request FIFO (wb -> xclk)
	reg [FIFO_WIDTH-1:0] req_fifo [0:FIFO_DEPTH-1];
	reg [PTR_WIDTH-1:0] req_wr_ptr, req_rd_ptr;
	reg [PTR_WIDTH:0] req_count;

	// Response FIFO (xclk -> wb)
	reg [DW+1:0] resp_fifo [0:FIFO_DEPTH-1]; // data + err
	reg [PTR_WIDTH-1:0] resp_wr_ptr, resp_rd_ptr;
	reg [PTR_WIDTH:0] resp_count;

	// Synchronizers for request FIFO pointers
	reg [PTR_WIDTH:0] req_count_sync1, req_count_sync2;
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			req_count_sync1 <= {(PTR_WIDTH+1){1'b0}};
			req_count_sync2 <= {(PTR_WIDTH+1){1'b0}};
		end else begin
			req_count_sync1 <= req_count;
			req_count_sync2 <= req_count_sync1;
		end
	end

	// Synchronizers for response FIFO pointers
	reg [PTR_WIDTH:0] resp_count_sync1, resp_count_sync2;
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			resp_count_sync1 <= {(PTR_WIDTH+1){1'b0}};
			resp_count_sync2 <= {(PTR_WIDTH+1){1'b0}};
		end else begin
			resp_count_sync1 <= resp_count;
			resp_count_sync2 <= resp_count_sync1;
		end
	end

	// Stall signals
	assign o_wb_stall = (req_count_sync2 == FIFO_DEPTH);

	// Request FIFO write (wb clock domain)
	wire req_wr_en = i_wb_cyc & i_wb_stb & ~o_wb_stall;
	wire [FIFO_WIDTH-1:0] req_wr_data = {i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_wr_ptr <= {PTR_WIDTH{1'b0}};
			req_count <= {(PTR_WIDTH+1){1'b0}};
		end else begin
			if (req_wr_en) begin
				req_fifo[req_wr_ptr] <= req_wr_data;
				req_wr_ptr <= req_wr_ptr + 1'b1;
			end
			if (req_wr_en && req_rd_ptr != req_wr_ptr) begin
				req_count <= req_count + 1'b1;
			end else if (req_wr_en && req_rd_ptr == req_wr_ptr) begin
				// This case shouldn't happen if we check stall properly, but handle it
				req_count <= req_count;
			end else if (!req_wr_en && req_rd_ptr != req_wr_ptr) begin
				req_count <= req_count;
			end
		end
	end

	// Request FIFO read (xclk clock domain)
	wire req_rd_en = (req_count_sync2 > 0) & ~i_xclk_stall;
	wire [FIFO_WIDTH-1:0] req_rd_data = req_fifo[req_rd_ptr];

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			req_rd_ptr <= {PTR_WIDTH{1'b0}};
			req_count <= {(PTR_WIDTH+1){1'b0}};
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= {(AW){1'b0}};
			o_xclk_data <= {(DW){1'b0}};
			o_xclk_sel <= {(DW/8){1'b0}};
		end else begin
			if (req_rd_en) begin
				o_xclk_cyc <= 1'b1;
				o_xclk_stb <= 1'b1;
				o_xclk_we <= req_rd_data[FIFO_WIDTH-1];
				o_xclk_addr <= req_rd_data[FIFO_WIDTH-2:FIFO_WIDTH-1-AW];
				o_xclk_data <= req_rd_data[FIFO_WIDTH-1-AW:FIFO_WIDTH-1-AW-DW];
				o_xclk_sel <= req_rd_data[FIFO_WIDTH-1-AW-DW:FIFO_WIDTH-1-AW-DW-(DW/8)];
				req_rd_ptr <= req_rd_ptr + 1'b1;
				req_count <= req_count - 1'b1;
			end else begin
				o_xclk_cyc <= 1'b0;
				o_xclk_stb <= 1'b0;
			end
		end
	end

	// Response FIFO write (xclk clock domain)
	wire resp_wr_en = i_xclk_ack;
	wire [DW+1:0] resp_wr_data = {i_xclk_err, i_xclk_data};

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			resp_wr_ptr <= {PTR_WIDTH{1'b0}};
			resp_count <= {(PTR_WIDTH+1){1'b0}};
		end else begin
			if (resp_wr_en) begin
				resp_fifo[resp_wr_ptr] <= resp_wr_data;
				resp_wr_ptr <= resp_wr_ptr + 1'b1;
			end
			if (resp_wr_en && resp_rd_ptr != resp_wr_ptr) begin
				resp_count <= resp_count + 1'b1;
			end else if (resp_wr_en && resp_rd_ptr == resp_wr_ptr) begin
				resp_count <= resp_count;
			end else if (!resp_wr_en && resp_rd_ptr != resp_wr_ptr) begin
				resp_count <= resp_count;
			end
		end
	end

	// Response FIFO read (wb clock domain)
	wire resp_rd_en = (resp_count_sync2 > 0);
	wire [DW+1:0] resp_rd_data = resp_fifo[resp_rd_ptr];

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			resp_rd_ptr <= {PTR_WIDTH{1'b0}};
			resp_count <= {(PTR_WIDTH+1){1'b0}};
			o_wb_ack <= 1'b0;
			o_wb_data <= {(DW){1'b0}};
			o_wb_err <= 1'b0;
		end else begin
			if (resp_rd_en) begin
				o_wb_ack <= 1'b1;
				o_wb_data <= resp_rd_data[DW-1:0];
				o_wb_err <= resp_rd_data[DW];
				resp_rd_ptr <= resp_rd_ptr + 1'b1;
				resp_count <= resp_count - 1'b1;
			end else begin
				o_wb_ack <= 1'b0;
			end
		end
	end

endmodule
