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

	// Request FIFO (Wishbone side to XCLK side)
	reg [DW-1:0] req_fifo_data [0:FIFO_DEPTH-1];
	reg [AW-1:0] req_fifo_addr [0:FIFO_DEPTH-1];
	reg [DW/8-1:0] req_fifo_sel [0:FIFO_DEPTH-1];
	reg req_fifo_we [0:FIFO_DEPTH-1];
	reg [FIFO_PTR_W-1:0] req_wr_ptr, req_rd_ptr;
	reg [FIFO_PTR_W:0] req_count;

	// Response FIFO (XCLK side to Wishbone side)
	reg [DW-1:0] rsp_fifo_data [0:FIFO_DEPTH-1];
	reg rsp_fifo_err [0:FIFO_DEPTH-1];
	reg [FIFO_PTR_W-1:0] rsp_wr_ptr, rsp_rd_ptr;
	reg [FIFO_PTR_W:0] rsp_count;

	// Handshake signals
	reg req_valid;
	reg rsp_valid;
	reg req_ready;
	reg rsp_ready;

	// Synchronization signals
	reg [1:0] req_valid_sync;
	reg [1:0] rsp_valid_sync;
	reg [1:0] req_ready_sync;
	reg [1:0] rsp_ready_sync;

	// Wishbone side logic
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			req_wr_ptr <= {FIFO_PTR_W{1'b0}};
			rsp_rd_ptr <= {FIFO_PTR_W{1'b0}};
			req_count <= {(FIFO_PTR_W+1){1'b0}};
			rsp_count <= {(FIFO_PTR_W+1){1'b0}};
			o_wb_ack <= 1'b0;
			o_wb_data <= {DW{1'b0}};
			o_wb_err <= 1'b0;
			req_valid <= 1'b0;
			rsp_valid <= 1'b0;
			req_valid_sync <= 2'b00;
			rsp_ready_sync <= 2'b00;
		end else begin
			// Synchronize req_ready from xclk domain
			req_ready_sync <= {req_ready_sync[0], req_ready};
			req_ready <= req_ready_sync[1];

			// Synchronize rsp_valid from xclk domain
			rsp_valid_sync <= {rsp_valid_sync[0], rsp_valid};
			rsp_valid <= rsp_valid_sync[1];

			// Write to request FIFO
			if (i_wb_cyc && i_wb_stb && !req_ready) begin
				req_fifo_data[req_wr_ptr] <= i_wb_data;
				req_fifo_addr[req_wr_ptr] <= i_wb_addr;
				req_fifo_sel[req_wr_ptr] <= i_wb_sel;
				req_fifo_we[req_wr_ptr] <= i_wb_we;
				req_wr_ptr <= req_wr_ptr + 1'b1;
				req_count <= req_count + 1'b1;
			end

			// Read from response FIFO
			if (rsp_valid && rsp_ready) begin
				o_wb_ack <= 1'b1;
				o_wb_data <= rsp_fifo_data[rsp_rd_ptr];
				o_wb_err <= rsp_fifo_err[rsp_rd_ptr];
				rsp_rd_ptr <= rsp_rd_ptr + 1'b1;
				rsp_count <= rsp_count - 1'b1;
			end else begin
				o_wb_ack <= 1'b0;
			end

			// Update rsp_ready
			rsp_ready <= (rsp_count < FIFO_DEPTH);
		end
	end

	// XCLK side logic
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			req_rd_ptr <= {FIFO_PTR_W{1'b0}};
			rsp_wr_ptr <= {FIFO_PTR_W{1'b0}};
			req_count <= {(FIFO_PTR_W+1){1'b0}};
			rsp_count <= {(FIFO_PTR_W+1){1'b0}};
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= {AW{1'b0}};
			o_xclk_data <= {DW{1'b0}};
			o_xclk_sel <= {(DW/8){1'b0}};
			req_valid <= 1'b0;
			rsp_valid <= 1'b0;
			rsp_valid_sync <= 2'b00;
			req_ready_sync <= 2'b00;
		end else begin
			// Synchronize req_valid from wb domain
			req_valid_sync <= {req_valid_sync[0], req_valid};
			req_valid <= req_valid_sync[1];

			// Synchronize rsp_ready from wb domain
			rsp_ready_sync <= {rsp_ready_sync[0], rsp_ready};
			rsp_ready <= rsp_ready_sync[1];

			// Read from request FIFO and drive xclk bus
			if (req_valid && !i_xclk_stall) begin
				o_xclk_cyc <= 1'b1;
				o_xclk_stb <= 1'b1;
				o_xclk_we <= req_fifo_we[req_rd_ptr];
				o_xclk_addr <= req_fifo_addr[req_rd_ptr];
				o_xclk_data <= req_fifo_data[req_rd_ptr];
				o_xclk_sel <= req_fifo_sel[req_rd_ptr];
				req_rd_ptr <= req_rd_ptr + 1'b1;
				req_count <= req_count - 1'b1;
			end else begin
				o_xclk_cyc <= 1'b0;
				o_xclk_stb <= 1'b0;
			end

			// Write to response FIFO
			if (i_xclk_ack) begin
				rsp_fifo_data[rsp_wr_ptr] <= i_xclk_data;
				rsp_fifo_err[rsp_wr_ptr] <= i_xclk_err;
				rsp_wr_ptr <= rsp_wr_ptr + 1'b1;
				rsp_count <= rsp_count + 1'b1;
			end

			// Update req_ready
			req_ready <= (req_count < FIFO_DEPTH);
		end
	end

	// o_wb_stall is high when the request FIFO is full
	assign o_wb_stall = (req_count == FIFO_DEPTH);

endmodule
