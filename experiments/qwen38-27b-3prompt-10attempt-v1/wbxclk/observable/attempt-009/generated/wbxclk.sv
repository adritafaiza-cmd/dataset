module	wbxclk #(
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

	localparam REQ_W = AW + DW + (DW/8) + 1;
	localparam RSP_W = DW + 1;
	localparam CNT_W = LGFIFO + 1;

	// Request FIFO (Wishbone side -> xclk side)
	reg [REQ_W-1:0] req_mem [0:(1<<LGFIFO)-1];
	reg [LGFIFO-1:0] req_wr_ptr, req_rd_ptr;
	reg req_wr_en, req_rd_en;

	// Response FIFO (xclk side -> Wishbone side)
	reg [RSP_W-1:0] rsp_mem [0:(1<<LGFIFO)-1];
	reg [LGFIFO-1:0] rsp_wr_ptr, rsp_rd_ptr;
	reg rsp_wr_en, rsp_rd_en;

	// Outstanding request counter
	reg [CNT_W-1:0] outstanding_cnt;

	// Request FIFO full/empty
	wire req_full = (req_wr_ptr == req_rd_ptr) && (req_wr_ptr[LGFIFO-1] != req_rd_ptr[LGFIFO-1]);
	wire req_empty = (req_wr_ptr == req_rd_ptr);

	// Response FIFO full/empty
	wire rsp_full = (rsp_wr_ptr == rsp_rd_ptr) && (rsp_wr_ptr[LGFIFO-1] != rsp_rd_ptr[LGFIFO-1]);
	wire rsp_empty = (rsp_wr_ptr == rsp_rd_ptr);

	// Request FIFO write (Wishbone clock domain)
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_wr_ptr <= {LGFIFO{1'b0}};
			req_wr_en  <= 1'b0;
		end else begin
			req_wr_en <= i_wb_cyc && i_wb_stb && !req_full;
			if (i_wb_cyc && i_wb_stb && !req_full) begin
				req_mem[req_wr_ptr] <= {i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};
				req_wr_ptr <= req_wr_ptr + 1'b1;
			end
		end
	end

	// Request FIFO read (xclk clock domain)
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			req_rd_ptr <= {LGFIFO{1'b0}};
			req_rd_en  <= 1'b0;
		end else begin
			req_rd_en <= !req_empty && !i_xclk_stall;
			if (!req_empty && !i_xclk_stall) begin
				req_rd_ptr <= req_rd_ptr + 1'b1;
			end
		end
	end

	// Response FIFO write (xclk clock domain)
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			rsp_wr_ptr <= {LGFIFO{1'b0}};
			rsp_wr_en  <= 1'b0;
		end else begin
			rsp_wr_en <= i_xclk_ack && !rsp_full;
			if (i_xclk_ack && !rsp_full) begin
				rsp_mem[rsp_wr_ptr] <= {i_xclk_err, i_xclk_data};
				rsp_wr_ptr <= rsp_wr_ptr + 1'b1;
			end
		end
	end

	// Response FIFO read (Wishbone clock domain)
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			rsp_rd_ptr <= {LGFIFO{1'b0}};
			rsp_rd_en  <= 1'b0;
		end else begin
			rsp_rd_en <= !rsp_empty;
			if (!rsp_empty) begin
				rsp_rd_ptr <= rsp_rd_ptr + 1'b1;
			end
		end
	end

	// Outstanding counter (Wishbone clock domain)
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			outstanding_cnt <= {CNT_W{1'b0}};
		end else begin
			case ({i_wb_cyc && i_wb_stb && !req_full, rsp_rd_en})
				2'b10: outstanding_cnt <= outstanding_cnt + 1'b1;
				2'b01: outstanding_cnt <= outstanding_cnt - 1'b1;
				default: outstanding_cnt <= outstanding_cnt;
			endcase
		end
	end

	assign o_wb_stall = |outstanding_cnt;

	// Wishbone response outputs
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack   <= 1'b0;
			o_wb_data  <= {DW{1'b0}};
			o_wb_err   <= 1'b0;
		end else begin
			if (!rsp_empty) begin
				o_wb_ack  <= 1'b1;
				o_wb_data <= rsp_mem[rsp_rd_ptr][RSP_W-1:1];
				o_wb_err  <= rsp_mem[rsp_rd_ptr][0];
			end else begin
				o_wb_ack  <= 1'b0;
			end
		end
	end

	// xclk request outputs
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_cyc   <= 1'b0;
			o_xclk_stb   <= 1'b0;
			o_xclk_we    <= 1'b0;
			o_xclk_addr  <= {AW{1'b0}};
			o_xclk_data  <= {DW{1'b0}};
			o_xclk_sel   <= {(DW/8){1'b0}};
		end else begin
			if (!req_empty && !i_xclk_stall) begin
				o_xclk_cyc  <= 1'b1;
				o_xclk_stb  <= 1'b1;
				o_xclk_we   <= req_mem[req_rd_ptr][REQ_W-1];
				o_xclk_addr <= req_mem[req_rd_ptr][REQ_W-2:REQ_W-1-AW];
				o_xclk_data <= req_mem[req_rd_ptr][REQ_W-2-AW:REQ_W-2-AW-DW+1];
				o_xclk_sel  <= req_mem[req_rd_ptr][REQ_W-2-AW-DW:0];
			end else begin
				o_xclk_cyc <= 1'b0;
				o_xclk_stb <= 1'b0;
			end
		end
	end

endmodule
