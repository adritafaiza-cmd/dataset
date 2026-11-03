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
	localparam FIFO_WIDTH = AW + DW + DW/8 + 1; // addr + data + sel + we
	localparam ACK_WIDTH  = DW + 1;             // data + err

	// ============================================================
	// Request FIFO: WB side writes, XCLK side reads
	// ============================================================
	reg [FIFO_WIDTH-1:0] req_mem [0:FIFO_DEPTH-1];
	reg [LGFIFO:0]       req_wr_ptr, req_rd_ptr;
	reg                  req_full, req_empty;

	wire req_wr_en = i_wb_cyc && i_wb_stb && !o_wb_stall;
	wire req_rd_en = o_xclk_cyc && !i_xclk_stall && !req_empty;

	// Write side (WB clock)
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_wr_ptr <= {LGFIFO+1{1'b0}};
			req_full   <= 1'b0;
		end else begin
			if (req_wr_en && !req_full) begin
				req_mem[req_wr_ptr[LGFIFO-1:0]] <= {i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};
				req_wr_ptr <= req_wr_ptr + 1'b1;
			end
			if (req_rd_en && !req_empty) begin
				req_full <= 1'b0;
			end
			if (req_wr_en && !req_full && req_rd_en && !req_empty) begin
				// both happen, full stays 0
			end
		end
	end

	// Read side (XCLK clock)
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			req_rd_ptr <= {LGFIFO+1{1'b0}};
			req_empty  <= 1'b0;
		end else begin
			if (req_rd_en && !req_empty) begin
				req_rd_ptr <= req_rd_ptr + 1'b1;
			end
			if (req_wr_en && !req_full) begin
				req_empty <= 1'b0;
			end
			if (req_rd_en && !req_empty && req_wr_en && !req_full) begin
				// both happen, empty stays 0
			end
		end
	end

	// Full/empty flags
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset)
			req_full <= 1'b0;
		else
			req_full <= (req_wr_ptr[LGFIFO] != req_rd_ptr[LGFIFO]) &&
			            (req_wr_ptr[LGFIFO-1:0] == req_rd_ptr[LGFIFO-1:0]);
	end

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset)
			req_empty <= 1'b0;
		else
			req_empty <= (req_wr_ptr == req_rd_ptr);
	end

	// o_wb_stall: backpressure when FIFO is full
	assign o_wb_stall = req_full;

	// ============================================================
	// Response FIFO: XCLK side writes, WB side reads
	// ============================================================
	reg [ACK_WIDTH-1:0] ack_mem [0:FIFO_DEPTH-1];
	reg [LGFIFO:0]       ack_wr_ptr, ack_rd_ptr;
	reg                  ack_full, ack_empty;

	wire ack_wr_en = i_xclk_ack;
	wire ack_rd_en = o_wb_ack;

	// Write side (XCLK clock)
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			ack_wr_ptr <= {LGFIFO+1{1'b0}};
			ack_full   <= 1'b0;
		end else begin
			if (ack_wr_en && !ack_full) begin
				ack_mem[ack_wr_ptr[LGFIFO-1:0]] <= {i_xclk_err, i_xclk_data};
				ack_wr_ptr <= ack_wr_ptr + 1'b1;
			end
			if (ack_rd_en && !ack_empty) begin
				ack_full <= 1'b0;
			end
		end
	end

	// Read side (WB clock)
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			ack_rd_ptr <= {LGFIFO+1{1'b0}};
			ack_empty  <= 1'b0;
		end else begin
			if (ack_rd_en && !ack_empty) begin
				ack_rd_ptr <= ack_rd_ptr + 1'b1;
			end
			if (ack_wr_en && !ack_full) begin
				ack_empty <= 1'b0;
			end
		end
	end

	// Full/empty flags
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset)
			ack_full <= 1'b0;
		else
			ack_full <= (ack_wr_ptr[LGFIFO] != ack_rd_ptr[LGFIFO]) &&
			            (ack_wr_ptr[LGFIFO-1:0] == ack_rd_ptr[LGFIFO-1:0]);
	end

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset)
			ack_empty <= 1'b0;
		else
			ack_empty <= (ack_wr_ptr == ack_rd_ptr);
	end

	// ============================================================
	// XCLK side: drive request from FIFO
	// ============================================================
	reg [FIFO_WIDTH-1:0] req_out;
	reg                  req_valid;

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			req_valid <= 1'b0;
			req_out   <= {FIFO_WIDTH{1'b0}};
		end else begin
			if (req_rd_en && !req_empty) begin
				req_out   <= req_mem[req_rd_ptr[LGFIFO-1:0]];
				req_valid <= 1'b1;
			end else if (req_valid && o_xclk_cyc && i_xclk_ack) begin
				req_valid <= 1'b0;
			end
		end
	end

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc  <= 1'b0;
			o_xclk_stb  <= 1'b0;
			o_xclk_we   <= 1'b0;
			o_xclk_addr <= {AW{1'b0}};
			o_xclk_data <= {DW{1'b0}};
			o_xclk_sel  <= {(DW/8){1'b0}};
		end else begin
			if (req_valid && !req_empty) begin
				o_xclk_cyc  <= 1'b1;
				o_xclk_stb  <= 1'b1;
				o_xclk_we   <= req_out[FIFO_WIDTH-1];
				o_xclk_addr <= req_out[FIFO_WIDTH-2:FIFO_WIDTH-1-AW];
				o_xclk_data <= req_out[FIFO_WIDTH-1-AW:FIFO_WIDTH-1-AW-DW];
				o_xclk_sel  <= req_out[FIFO_WIDTH-1-AW-DW-1:0];
			end else if (o_xclk_cyc && i_xclk_ack) begin
				o_xclk_cyc  <= 1'b0;
				o_xclk_stb  <= 1'b0;
			end
		end
	end

	// ============================================================
	// WB side: drive response from FIFO
	// ============================================================
	reg [ACK_WIDTH-1:0] ack_out;
	reg                  ack_valid;

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			ack_valid <= 1'b0;
			ack_out   <= {ACK_WIDTH{1'b0}};
		end else begin
			if (ack_rd_en && !ack_empty) begin
				ack_out   <= ack_mem[ack_rd_ptr[LGFIFO-1:0]];
				ack_valid <= 1'b1;
			end else if (ack_valid && o_wb_ack) begin
				ack_valid <= 1'b0;
			end
		end
	end

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack   <= 1'b0;
			o_wb_data  <= {DW{1'b0}};
			o_wb_err   <= 1'b0;
		end else begin
			if (ack_valid && !ack_empty) begin
				o_wb_ack  <= 1'b1;
				o_wb_data <= ack_out[ACK_WIDTH-2:0];
				o_wb_err  <= ack_out[ACK_WIDTH-1];
			end else if (o_wb_ack) begin
				o_wb_ack  <= 1'b0;
			end
		end
	end

endmodule
