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
	localparam FIFO_MASK  = FIFO_DEPTH - 1;
	localparam DATA_WIDTH = AW + DW + (DW/8) + 2; // addr + data + sel + we + cyc

	// Request FIFO (wb_clk domain)
	reg [DATA_WIDTH-1:0] req_fifo [0:FIFO_DEPTH-1];
	reg [LGFIFO:0] req_wr_ptr, req_rd_ptr;
	reg [LGFIFO:0] req_count;

	// Response FIFO (xclk_clk domain)
	reg [DW+1:0] rsp_fifo [0:FIFO_DEPTH-1]; // data + err
	reg [LGFIFO:0] rsp_wr_ptr, rsp_rd_ptr;
	reg [LGFIFO:0] rsp_count;

	// Synchronization signals
	reg [1:0] req_full_sync;
	reg [1:0] rsp_empty_sync;

	// Reset synchronization
	reg [1:0] reset_sync_wb;
	reg [1:0] reset_sync_xclk;

	// Reset sync for wb domain
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset)
			reset_sync_wb <= 2'b00;
		else
			reset_sync_wb <= {reset_sync_wb[0], 1'b1};
	end

	// Reset sync for xclk domain
	always @(posedge i_xclk_clk) begin
		reset_sync_xclk <= {reset_sync_xclk[0], reset_sync_wb[1]};
	end

	wire xclk_reset = ~reset_sync_xclk[1];

	// Request FIFO write (wb_clk domain)
	wire req_valid = i_wb_cyc & i_wb_stb & ~o_wb_stall;
	wire req_full = (req_count == FIFO_DEPTH);
	assign o_wb_stall = req_full;

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_wr_ptr <= 0;
			req_rd_ptr <= 0;
			req_count  <= 0;
		end else begin
			if (req_valid && !req_full) begin
				req_fifo[req_wr_ptr[LGFIFO-1:0]] <= {i_wb_cyc, i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};
				req_wr_ptr <= req_wr_ptr + 1;
				req_count  <= req_count + 1;
			end
			if (req_rd_ptr != req_wr_ptr && req_count > 0) begin
				req_rd_ptr <= req_rd_ptr + 1;
				req_count  <= req_count - 1;
			end
		end
	end

	// Synchronize req_full to xclk domain
	always @(posedge i_xclk_clk) begin
		req_full_sync <= {req_full_sync[0], req_full};
	end

	// Response FIFO read (wb_clk domain)
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			rsp_rd_ptr <= 0;
			rsp_count  <= 0;
			o_wb_ack   <= 1'b0;
			o_wb_data  <= 0;
			o_wb_err   <= 1'b0;
		end else begin
			if (rsp_count > 0) begin
				{ o_wb_data, o_wb_err } <= rsp_fifo[rsp_rd_ptr[LGFIFO-1:0]];
				o_wb_ack <= 1'b1;
				rsp_rd_ptr <= rsp_rd_ptr + 1;
				rsp_count  <= rsp_count - 1;
			end else begin
				o_wb_ack <= 1'b0;
			end
		end
	end

	// Synchronize rsp_empty to wb domain
	always @(posedge i_wb_clk) begin
		rsp_empty_sync <= {rsp_empty_sync[0], (rsp_count == 0)};
	end

	// Request FIFO read (xclk_clk domain)
	reg [DATA_WIDTH-1:0] req_data_xclk;
	reg [1:0] req_valid_xclk;
	reg [1:0] req_valid_sync;

	always @(posedge i_xclk_clk) begin
		if (xclk_reset) begin
			req_rd_ptr <= 0;
			req_count  <= 0;
			req_valid_xclk <= 1'b0;
			req_valid_sync <= 2'b00;
		end else begin
			// Synchronize req_valid (req_count > 0)
			req_valid_sync <= {req_valid_sync[0], (req_count > 0)};
			
			if (req_valid_sync[1] && !req_valid_xclk) begin
				req_data_xclk <= req_fifo[req_rd_ptr[LGFIFO-1:0]];
				req_valid_xclk <= 1'b1;
			end
		end
	end

	// Drive xclk bus outputs
	always @(posedge i_xclk_clk) begin
		if (xclk_reset) begin
			o_xclk_cyc  <= 1'b0;
			o_xclk_stb  <= 1'b0;
			o_xclk_we   <= 1'b0;
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel  <= 0;
		end else if (req_valid_xclk && !i_xclk_stall) begin
			{ o_xclk_cyc, o_xclk_we, o_xclk_addr, o_xclk_data, o_xclk_sel } <= req_data_xclk;
			o_xclk_stb <= 1'b1;
			req_valid_xclk <= 1'b0;
			req_rd_ptr <= req_rd_ptr + 1;
			req_count  <= req_count - 1;
		end else begin
			o_xclk_stb <= 1'b0;
		end
	end

	// Response FIFO write (xclk_clk domain)
	always @(posedge i_xclk_clk) begin
		if (xclk_reset) begin
			rsp_wr_ptr <= 0;
			rsp_count  <= 0;
		end else if (i_xclk_ack) begin
			rsp_fifo[rsp_wr_ptr[LGFIFO-1:0]] <= {i_xclk_data, i_xclk_err};
			rsp_wr_ptr <= rsp_wr_ptr + 1;
			rsp_count  <= rsp_count + 1;
		end
	end

endmodule
