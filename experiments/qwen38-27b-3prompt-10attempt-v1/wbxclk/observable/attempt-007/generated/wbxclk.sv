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
	output	reg	[(DW/1):0]	o_wb_data,
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

	localparam REQ_W = AW + DW + DW/8 + 1;
	localparam RSP_W = DW + 1;
	localparam DEPTH = 1 << LGFIFO;
	localparam PTR_W = LGFIFO;

	// Request FIFO (Wishbone -> xclk)
	reg [REQ_W-1:0] req_mem [0:DEPTH-1];
	reg [PTR_W-1:0] req_wr_ptr, req_rd_ptr;
	reg [PTR_W:0]   req_count;

	// Response FIFO (xclk -> Wishbone)
	reg [RSP_W-1:0] rsp_mem [0:DEPTH-1];
	reg [PTR_W-1:0] rsp_wr_ptr, rsp_rd_ptr;
	reg [PTR_W:0]   rsp_count;

	// Request FIFO write (Wishbone clock domain)
	wire req_wr_en = i_wb_cyc && i_wb_stb && (req_count < DEPTH);
	wire [REQ_W-1:0] req_wr_data = {i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_wr_ptr <= {PTR_W{1'b0}};
			req_count  <= {(PTR_W+1){1'b0}};
		end else begin
			if (req_wr_en) begin
				req_mem[req_wr_ptr] <= req_wr_data;
				req_wr_ptr <= req_wr_ptr + 1'b1;
			end
			if (req_wr_en && (req_count == DEPTH - 1))
				req_count <= req_count;
			else if (req_wr_en)
				req_count <= req_count + 1'b1;
		end
	end

	// Request FIFO read (xclk clock domain)
	wire req_rd_en = (req_count > 0) && !i_xclk_stall;
	wire [REQ_W-1:0] req_rd_data = req_mem[req_rd_ptr];

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			req_rd_ptr <= {PTR_W{1'b0}};
			req_count  <= {(PTR_W+1){1'b0}};
		end else begin
			if (req_rd_en) begin
				req_rd_ptr <= req_rd_ptr + 1'b1;
			end
			if (req_rd_en && (req_count == 1))
				req_count <= req_count;
			else if (req_rd_en)
				req_count <= req_count - 1'b1;
		end
	end

	// xclk side outputs
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc  <= 1'b0;
			o_xclk_stb  <= 1'b0;
			o_xclk_we   <= 1'b0;
			o_xclk_addr <= {AW{1'b0}};
			o_xclk_data <= {DW{1'b0}};
			o_xclk_sel  <= {(DW/8){1'b0}};
		end else begin
			if (req_rd_en) begin
				o_xclk_cyc  <= req_rd_data[REQ_W-1];
				o_xclk_addr <= req_rd_data[REQ_W-2:REQ_W-1-AW];
				o_xclk_data <= req_rd_data[REQ_W-1-AW:REQ_W-1-AW-DW];
				o_xclk_sel  <= req_rd_data[REQ_W-1-AW-DW:0];
				o_xclk_stb  <= 1'b1;
			end else begin
				o_xclk_stb <= 1'b0;
			end
		end
	end

	// Response FIFO write (xclk clock domain)
	wire rsp_wr_en = i_xclk_ack;
	wire [RSP_W-1:0] rsp_wr_data = {i_xclk_err, i_xclk_data};

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			rsp_wr_ptr <= {PTR_W{1'b0}};
			rsp_count  <= {(PTR_W+1){1'b0}};
		end else begin
			if (rsp_wr_en) begin
				rsp_mem[rsp_wr_ptr] <= rsp_wr_data;
				rsp_wr_ptr <= rsp_wr_ptr + 1'b1;
			end
			if (rsp_wr_en && (rsp_count == DEPTH - 1))
				rsp_count <= rsp_count;
			else if (rsp_wr_en)
				rsp_count <= rsp_count + 1'b1;
		end
	end

	// Response FIFO read (Wishbone clock domain)
	wire rsp_rd_en = (rsp_count > 0);
	wire [RSP_W-1:0] rsp_rd_data = rsp_mem[rsp_rd_ptr];

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			rsp_rd_ptr <= {PTR_W{1'b0}};
			rsp_count  <= {(PTR_W+1){1'b0}};
		end else begin
			if (rsp_rd_en) begin
				rsp_rd_ptr <= rsp_rd_ptr + 1'b1;
			end
			if (rsp_rd_en && (rsp_count == 1))
				rsp_count <= rsp_count;
			else if (rsp_rd_en)
				rsp_count <= rsp_count - 1'b1;
		end
	end

	// Wishbone side outputs
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack   <= 1'b0;
			o_wb_data  <= {DW{1'b0}};
			o_wb_err   <= 1'b0;
		end else begin
			if (rsp_rd_en) begin
				o_wb_ack  <= 1'b1;
				o_wb_data <= rsp_rd_data[RSP_W-1:1];
				o_wb_err  <= rsp_rd_data[0];
			end else begin
				o_wb_ack <= 1'b0;
			end
		end
	end

	// o_wb_stall is the outstanding request count
	assign o_wb_stall = (req_count > 0);

endmodule
