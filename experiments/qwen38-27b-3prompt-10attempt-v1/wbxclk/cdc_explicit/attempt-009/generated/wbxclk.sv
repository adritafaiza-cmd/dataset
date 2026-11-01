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
	localparam FIFO_ADDR_WIDTH = LGFIFO;
	localparam DATA_WIDTH = AW + DW + (DW/8) + 1; // addr + data + sel + we

	// Request FIFO (wb -> xclk)
	reg [DATA_WIDTH-1:0] req_fifo_mem [0:FIFO_DEPTH-1];
	reg [FIFO_ADDR_WIDTH-1:0] req_wr_ptr, req_rd_ptr;
	reg [FIFO_ADDR_WIDTH:0] req_count;

	// Response FIFO (xclk -> wb)
	reg [DW+1-1:0] rsp_fifo_mem [0:FIFO_DEPTH-1]; // data + err
	reg [FIFO_ADDR_WIDTH-1:0] rsp_wr_ptr, rsp_rd_ptr;
	reg [FIFO_ADDR_WIDTH:0] rsp_count;

	// Request FIFO write logic (wb domain)
	wire req_full = (req_count == FIFO_DEPTH);
	wire req_empty = (req_count == 0);
	wire req_wr_en = i_wb_cyc && i_wb_stb && !req_full;

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_wr_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
			req_count <= {(FIFO_ADDR_WIDTH+1){1'b0}};
		end else begin
			if (req_wr_en) begin
				req_fifo_mem[req_wr_ptr] <= {i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};
				req_wr_ptr <= req_wr_ptr + 1'b1;
			end
			if (req_wr_en && !req_empty) begin
				req_count <= req_count; // no change
			end else if (req_wr_en) begin
				req_count <= req_count + 1'b1;
			end else if (!req_empty) begin
				req_count <= req_count - 1'b1;
			end
		end
	end

	// Request FIFO read logic (xclk domain)
	wire req_rd_en = !req_empty && !i_xclk_stall;

	always @(posedge i_xclk_clk) begin
		if (req_rd_en) begin
			req_rd_ptr <= req_rd_ptr + 1'b1;
		end
	end

	// Request FIFO read data
	wire [DATA_WIDTH-1:0] req_rd_data = req_fifo_mem[req_rd_ptr];
	wire req_we = req_rd_data[DATA_WIDTH-1];
	wire [AW-1:0] req_addr = req_rd_data[DATA_WIDTH-2:DW+(DW/8)];
	wire [DW-1:0] req_data = req_rd_data[DW+(DW/8)-1:DW/8];
	wire [DW/8-1:0] req_sel = req_rd_data[DW/8-1:0];

	// Output to xclk bus
	always @(posedge i_xclk_clk) begin
		if (req_rd_en) begin
			o_xclk_cyc <= 1'b1;
			o_xclk_stb <= 1'b1;
			o_xclk_we <= req_we;
			o_xclk_addr <= req_addr;
			o_xclk_data <= req_data;
			o_xclk_sel <= req_sel;
		end else begin
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
		end
	end

	// Response FIFO write logic (xclk domain)
	wire rsp_full = (rsp_count == FIFO_DEPTH);
	wire rsp_empty = (rsp_count == 0);
	wire rsp_wr_en = i_xclk_ack && !rsp_full;

	always @(posedge i_xclk_clk) begin
		if (rsp_wr_en) begin
			rsp_fifo_mem[rsp_wr_ptr] <= {i_xclk_err, i_xclk_data};
			rsp_wr_ptr <= rsp_wr_ptr + 1'b1;
		end
		if (rsp_wr_en && !rsp_empty) begin
			rsp_count <= rsp_count;
		end else if (rsp_wr_en) begin
			rsp_count <= rsp_count + 1'b1;
		end else if (!rsp_empty) begin
			rsp_count <= rsp_count - 1'b1;
		end
	end

	// Response FIFO read logic (wb domain)
	wire rsp_rd_en = !rsp_empty;

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			rsp_rd_ptr <= {FIFO_ADDR_WIDTH{1'b0}};
		end else begin
			if (rsp_rd_en) begin
				rsp_rd_ptr <= rsp_rd_ptr + 1'b1;
			end
		end
	end

	// Response FIFO read data
	wire [DW+1-1:0] rsp_rd_data = rsp_fifo_mem[rsp_rd_ptr];
	wire rsp_err = rsp_rd_data[DW];
	wire [DW-1:0] rsp_data = rsp_rd_data[DW-1:0];

	// Output to wb bus
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 1'b0;
			o_wb_data <= {DW{1'b0}};
			o_wb_err <= 1'b0;
		end else begin
			if (rsp_rd_en) begin
				o_wb_ack <= 1'b1;
				o_wb_data <= rsp_data;
				o_wb_err <= rsp_err;
			end else begin
				o_wb_ack <= 1'b0;
			end
		end
	end

	// Stall output
	assign o_wb_stall = req_full;

endmodule
