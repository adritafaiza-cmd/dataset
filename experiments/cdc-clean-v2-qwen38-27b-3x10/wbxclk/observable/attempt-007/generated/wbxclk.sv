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
	output	reg	[(DW-1):0]	o_xclk_data,
	output	reg	[(DW/8-1):0]	o_xclk_sel,
	input	wire			i_xclk_stall,
	input	wire			i_xclk_ack,
	input	wire	[(DW-1):0]	i_xclk_data,
	input	wire			i_xclk_err
);

	localparam FIFO_DEPTH = 1 << LGFIFO;
	localparam FIFO_WIDTH = AW + DW + DW/8 + 1; // addr + data + sel + we
	localparam ACK_WIDTH  = DW + 1;             // data + err

	// Request FIFO (wb -> xclk)
	reg [FIFO_WIDTH-1:0] req_mem [0:FIFO_DEPTH-1];
	reg [LGFIFO:0]       req_wr_ptr, req_rd_ptr;
	reg                  req_wr_en, req_rd_en;
	wire                 req_full, req_empty;

	// Response FIFO (xclk -> wb)
	reg [ACK_WIDTH-1:0]  ack_mem [0:FIFO_DEPTH-1];
	reg [LGFIFO:0]       ack_wr_ptr, ack_rd_ptr;
	reg                  ack_wr_en, ack_rd_en;
	wire                 ack_full, ack_empty;

	// Request FIFO full/empty
	assign req_full  = (req_wr_ptr[LGFIFO] != req_rd_ptr[LGFIFO]) &&
	                   (req_wr_ptr[LGFIFO-1:0] == req_rd_ptr[LGFIFO-1:0]);
	assign req_empty = (req_wr_ptr == req_rd_ptr);

	// Response FIFO full/empty
	assign ack_full  = (ack_wr_ptr[LGFIFO] != ack_rd_ptr[LGFIFO]) &&
	                   (ack_wr_ptr[LGFIFO-1:0] == ack_rd_ptr[LGFIFO-1:0]);
	assign ack_empty = (ack_wr_ptr == ack_rd_ptr);

	// WB side: accept request when not full
	assign o_wb_stall = req_full;

	// WB clock domain: write to request FIFO
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_wr_ptr <= {LGFIFO+1{1'b0}};
			req_wr_en  <= 1'b0;
		end else begin
			req_wr_en <= i_wb_cyc && !req_full;
			if (i_wb_cyc && !req_full) begin
				req_mem[req_wr_ptr[LGFIFO-1:0]] <= {i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};
				req_wr_ptr <= req_wr_ptr + 1'b1;
			end
		end
	end

	// XCLK clock domain: read from request FIFO, drive xclk outputs
	reg [FIFO_WIDTH-1:0] req_data;
	reg                  req_valid;

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			req_rd_ptr  <= {LGFIFO+1{1'b0}};
			req_rd_en   <= 1'b0;
			req_valid   <= 1'b0;
			o_xclk_cyc  <= 1'b0;
			o_xclk_stb  <= 1'b0;
			o_xclk_we   <= 1'b0;
			o_xclk_addr <= {AW{1'b0}};
			o_xclk_data <= {DW{1'b0}};
			o_xclk_sel  <= {(DW/8){1'b0}};
		end else begin
			req_rd_en <= req_valid && !i_xclk_stall;
			if (req_valid && !i_xclk_stall) begin
				req_mem[req_rd_ptr[LGFIFO-1:0]] <= req_data; // dummy, actual read below
				req_rd_ptr <= req_rd_ptr + 1'b1;
			end

			if (!req_empty) begin
				req_data  <= req_mem[req_rd_ptr[LGFIFO-1:0]];
				req_valid <= 1'b1;
			end else begin
				req_valid <= 1'b0;
			end

			if (req_valid && !i_xclk_stall) begin
				o_xclk_cyc  <= 1'b1;
				o_xclk_stb  <= 1'b1;
				o_xclk_we   <= req_data[FIFO_WIDTH-1];
				o_xclk_addr <= req_data[FIFO_WIDTH-2:FIFO_WIDTH-1-AW];
				o_xclk_data <= req_data[FIFO_WIDTH-1-AW:FIFO_WIDTH-1-AW-DW];
				o_xclk_sel  <= req_data[FIFO_WIDTH-1-AW-DW-1:0];
			end else begin
				o_xclk_cyc  <= 1'b0;
				o_xclk_stb  <= 1'b0;
			end
		end
	end

	// XCLK clock domain: write to response FIFO on ack
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			ack_wr_ptr <= {LGFIFO+1{1'b0}};
			ack_wr_en  <= 1'b0;
		end else begin
			ack_wr_en <= i_xclk_ack && !ack_full;
			if (i_xclk_ack && !ack_full) begin
				ack_mem[ack_wr_ptr[LGFIFO-1:0]] <= {i_xclk_err, i_xclk_data};
				ack_wr_ptr <= ack_wr_ptr + 1'b1;
			end
		end
	end

	// WB clock domain: read from response FIFO, drive wb outputs
	reg [ACK_WIDTH-1:0] ack_data;
	reg                  ack_valid;

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			ack_rd_ptr <= {LGFIFO+1{1'b0}};
			ack_rd_en  <= 1'b0;
			ack_valid  <= 1'b0;
			o_wb_ack   <= 1'b0;
			o_wb_data  <= {DW{1'b0}};
			o_wb_err   <= 1'b0;
		end else begin
			ack_rd_en <= ack_valid;
			if (ack_valid) begin
				ack_rd_ptr <= ack_rd_ptr + 1'b1;
			end

			if (!ack_empty) begin
				ack_data  <= ack_mem[ack_rd_ptr[LGFIFO-1:0]];
				ack_valid <= 1'b1;
			end else begin
				ack_valid <= 1'b0;
			end

			if (ack_valid) begin
				o_wb_ack  <= 1'b1;
				o_wb_data <= ack_data[ACK_WIDTH-2:0];
				o_wb_err  <= ack_data[ACK_WIDTH-1];
			end else begin
				o_wb_ack  <= 1'b0;
			end
		end
	end

endmodule
