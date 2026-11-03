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
	localparam FIFO_FULL_THRESH = FIFO_DEPTH - 1;

	// Reset synchronizers
	reg [1:0] rst_sync_wb;
	reg [1:0] rst_sync_xclk;

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset)
			rst_sync_wb <= 2'b00;
		else
			rst_sync_wb <= {rst_sync_wb[0], 1'b1};
	end

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset)
			rst_sync_xclk <= 2'b00;
		else
			rst_sync_xclk <= {rst_sync_xclk[0], 1'b1};
	end

	wire wb_rst = ~rst_sync_wb[1];
	wire xclk_rst = ~rst_sync_xclk[1];

	// FIFO storage
	reg [DW-1:0] fifo_data [0:FIFO_DEPTH-1];
	reg [AW-1:0] fifo_addr [0:FIFO_DEPTH-1];
	reg [DW/8-1:0] fifo_sel [0:FIFO_DEPTH-1];
	reg fifo_we [0:FIFO_DEPTH-1];

	// Pointers
	reg [FIFO_PTR_W:0] wr_ptr;
	reg [FIFO_PTR_W:0] rd_ptr;

	// Write enable from WB side
	wire wb_write_en = i_wb_cyc & i_wb_stb & ~o_wb_stall;

	// Read enable from XCLK side
	wire xclk_read_en = o_xclk_cyc & o_xclk_stb & ~i_xclk_stall;

	// FIFO full/empty logic
	wire [FIFO_PTR_W:0] wr_ptr_sync;
	wire [FIFO_PTR_W:0] rd_ptr_sync;

	// Synchronize write pointer to XCLK domain
	reg [FIFO_PTR_W:0] wr_ptr_sync_reg [0:1];
	always @(posedge i_xclk_clk or posedge xclk_rst) begin
		if (xclk_rst) begin
			wr_ptr_sync_reg[0] <= {(FIFO_PTR_W+1){1'b0}};
			wr_ptr_sync_reg[1] <= {(FIFO_PTR_W+1){1'b0}};
		end else begin
			wr_ptr_sync_reg[0] <= wr_ptr;
			wr_ptr_sync_reg[1] <= wr_ptr_sync_reg[0];
		end
	end
	assign wr_ptr_sync = wr_ptr_sync_reg[1];

	// Synchronize read pointer to WB domain
	reg [FIFO_PTR_W:0] rd_ptr_sync_reg [0:1];
	always @(posedge i_wb_clk or posedge wb_rst) begin
		if (wb_rst) begin
			rd_ptr_sync_reg[0] <= {(FIFO_PTR_W+1){1'b0}};
			rd_ptr_sync_reg[1] <= {(FIFO_PTR_W+1){1'b0}};
		end else begin
			rd_ptr_sync_reg[0] <= rd_ptr;
			rd_ptr_sync_reg[1] <= rd_ptr_sync_reg[0];
		end
	end
	assign rd_ptr_sync = rd_ptr_sync_reg[1];

	// Stall logic: stall when FIFO is nearly full
	wire [FIFO_PTR_W:0] fifo_count = wr_ptr - rd_ptr_sync;
	assign o_wb_stall = (fifo_count >= FIFO_FULL_THRESH);

	// Write to FIFO on WB clock
	always @(posedge i_wb_clk or posedge wb_rst) begin
		if (wb_rst) begin
			wr_ptr <= {(FIFO_PTR_W+1){1'b0}};
		end else if (wb_write_en) begin
			fifo_data[wr_ptr[FIFO_PTR_W-1:0]] <= i_wb_data;
			fifo_addr[wr_ptr[FIFO_PTR_W-1:0]] <= i_wb_addr;
			fifo_sel[wr_ptr[FIFO_PTR_W-1:0]] <= i_wb_sel;
			fifo_we[wr_ptr[FIFO_PTR_W-1:0]] <= i_wb_we;
			wr_ptr <= wr_ptr + 1'b1;
		end
	end

	// Read from FIFO on XCLK clock
	// Two-stage pipeline for data coherence
	reg [DW-1:0] pipe_data_1, pipe_data_2;
	reg [AW-1:0] pipe_addr_1, pipe_addr_2;
	reg [DW/8-1:0] pipe_sel_1, pipe_sel_2;
	reg pipe_we_1, pipe_we_2;
	reg pipe_valid_1, pipe_valid_2;

	always @(posedge i_xclk_clk or posedge xclk_rst) begin
		if (xclk_rst) begin
			rd_ptr <= {(FIFO_PTR_W+1){1'b0}};
			pipe_data_1 <= {(DW){1'b0}};
			pipe_addr_1 <= {(AW){1'b0}};
			pipe_sel_1 <= {(DW/8){1'b0}};
			pipe_we_1 <= 1'b0;
			pipe_valid_1 <= 1'b0;
			pipe_data_2 <= {(DW){1'b0}};
			pipe_addr_2 <= {(AW){1'b0}};
			pipe_sel_2 <= {(DW/8){1'b0}};
			pipe_we_2 <= 1'b0;
			pipe_valid_2 <= 1'b0;
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= {(AW){1'b0}};
			o_xclk_data <= {(DW){1'b0}};
			o_xclk_sel <= {(DW/8){1'b0}};
		end else begin
			// Stage 1: read from FIFO
			if (xclk_read_en) begin
				pipe_data_1 <= fifo_data[rd_ptr[FIFO_PTR_W-1:0]];
				pipe_addr_1 <= fifo_addr[rd_ptr[FIFO_PTR_W-1:0]];
				pipe_sel_1 <= fifo_sel[rd_ptr[FIFO_PTR_W-1:0]];
				pipe_we_1 <= fifo_we[rd_ptr[FIFO_PTR_W-1:0]];
				pipe_valid_1 <= 1'b1;
				rd_ptr <= rd_ptr + 1'b1;
			end else begin
				pipe_valid_1 <= 1'b0;
			end

			// Stage 2: pipeline to output
			pipe_data_2 <= pipe_data_1;
			pipe_addr_2 <= pipe_addr_1;
			pipe_sel_2 <= pipe_sel_1;
			pipe_we_2 <= pipe_we_1;
			pipe_valid_2 <= pipe_valid_1;

			// Drive XCLK bus
			if (pipe_valid_2) begin
				o_xclk_cyc <= 1'b1;
				o_xclk_stb <= 1'b1;
				o_xclk_we <= pipe_we_2;
				o_xclk_addr <= pipe_addr_2;
				o_xclk_data <= pipe_data_2;
				o_xclk_sel <= pipe_sel_2;
			end else begin
				o_xclk_cyc <= 1'b0;
				o_xclk_stb <= 1'b0;
			end
		end
	end

	// WB side: acknowledge when XCLK side accepts
	// We need to track which FIFO entries have been acknowledged
	// Use a simple approach: when xclk_read_en occurs, we know an entry was consumed
	// We need to send ack back to WB domain

	// Synchronize ack signal to WB domain
	reg [1:0] ack_sync;
	reg ack_pending;

	always @(posedge i_xclk_clk or posedge xclk_rst) begin
		if (xclk_rst) begin
			ack_sync <= 2'b00;
			ack_pending <= 1'b0;
		end else begin
			ack_sync <= {ack_sync[0], xclk_read_en};
			ack_pending <= ack_sync[1];
		end
	end

	// Synchronize ack_pending to WB domain
	reg [1:0] ack_pending_sync;
	always @(posedge i_wb_clk or posedge wb_rst) begin
		if (wb_rst)
			ack_pending_sync <= 2'b00;
		else
			ack_pending_sync <= {ack_pending_sync[0], ack_pending};
	end

	// We need to track outstanding requests to generate proper ack
	// Simplified: generate ack when a request is accepted and later acknowledged
	// For pipelined Wishbone, we can use a simple counter

	reg [FIFO_PTR_W:0] outstanding_count;
	reg [DW-1:0] ack_data_reg;
	reg ack_err_reg;

	always @(posedge i_wb_clk or posedge wb_rst) begin
		if (wb_rst) begin
			outstanding_count <= {(FIFO_PTR_W+1){1'b0}};
			o_wb_ack <= 1'b0;
			o_wb_data <= {(DW){1'b0}};
			o_wb_err <= 1'b0;
			ack_data_reg <= {(DW){1'b0}};
			ack_err_reg <= 1'b0;
		end else begin
			// Increment when new request accepted
			if (wb_write_en)
				outstanding_count <= outstanding_count + 1'b1;

			// Decrement when ack received from XCLK side
			if (ack_pending_sync[1])
				outstanding_count <= outstanding_count - 1'b1;

			// Generate ack when outstanding count decreases
			if (ack_pending_sync[1] && outstanding_count > 0) begin
				o_wb_ack <= 1'b1;
				o_wb_data <= i_xclk_data;
				o_wb_err <= i_xclk_err;
			end else begin
				o_wb_ack <= 1'b0;
			end
		end
	end

endmodule
