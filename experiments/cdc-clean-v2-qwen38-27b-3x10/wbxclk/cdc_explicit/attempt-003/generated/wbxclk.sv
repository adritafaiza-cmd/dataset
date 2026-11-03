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

	// Write side (WB clock)
	wire wb_wr_en = i_wb_cyc & i_wb_stb & ~o_wb_stall;
	wire wb_full = (wr_ptr[FIFO_PTR_W] != rd_ptr[FIFO_PTR_W]) &&
	               (wr_ptr[FIFO_PTR_W-1:0] == rd_ptr[FIFO_PTR_W-1:0]);
	wire wb_almost_full = (wr_ptr[FIFO_PTR_W-1:0] == rd_ptr[FIFO_PTR_W-1:0]) &&
	                      (wr_ptr[FIFO_PTR_W] != rd_ptr[FIFO_PTR_W]) &&
	                      (FIFO_DEPTH - (wr_ptr[FIFO_PTR_W-1:0] - rd_ptr[FIFO_PTR_W-1:0]) <= 1);

	assign o_wb_stall = wb_full;

	always @(posedge i_wb_clk or posedge wb_rst) begin
		if (wb_rst) begin
			wr_ptr <= {(FIFO_PTR_W+1){1'b0}};
			o_wb_ack <= 1'b0;
			o_wb_data <= {(DW){1'b0}};
			o_wb_err <= 1'b0;
		end else begin
			if (wb_wr_en) begin
				fifo_data[wr_ptr[FIFO_PTR_W-1:0]] <= i_wb_data;
				fifo_addr[wr_ptr[FIFO_PTR_W-1:0]] <= i_wb_addr;
				fifo_sel[wr_ptr[FIFO_PTR_W-1:0]] <= i_wb_sel;
				fifo_we[wr_ptr[FIFO_PTR_W-1:0]] <= i_wb_we;
				wr_ptr <= wr_ptr + 1'b1;
			end
		end
	end

	// Read side (XCLK clock)
	// Synchronize wr_ptr to xclk domain
	reg [FIFO_PTR_W:0] wr_ptr_sync;
	reg [FIFO_PTR_W:0] wr_ptr_sync1;
	reg [FIFO_PTR_W:0] wr_ptr_sync2;

	always @(posedge i_xclk_clk or posedge xclk_rst) begin
		if (xclk_rst) begin
			wr_ptr_sync <= {(FIFO_PTR_W+1){1'b0}};
			wr_ptr_sync1 <= {(FIFO_PTR_W+1){1'b0}};
			wr_ptr_sync2 <= {(FIFO_PTR_W+1){1'b0}};
		end else begin
			wr_ptr_sync <= wr_ptr;
			wr_ptr_sync1 <= wr_ptr_sync;
			wr_ptr_sync2 <= wr_ptr_sync1;
		end
	end

	wire xclk_empty = (rd_ptr == wr_ptr_sync2);
	wire xclk_rd_en = ~xclk_empty & ~i_xclk_stall;

	// Two-stage pipeline for payload
	reg [DW-1:0] pipe_data1, pipe_data2;
	reg [AW-1:0] pipe_addr1, pipe_addr2;
	reg [DW/8-1:0] pipe_sel1, pipe_sel2;
	reg pipe_we1, pipe_we2;
	reg pipe_valid1, pipe_valid2;

	always @(posedge i_xclk_clk or posedge xclk_rst) begin
		if (xclk_rst) begin
			rd_ptr <= {(FIFO_PTR_W+1){1'b0}};
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= {(AW){1'b0}};
			o_xclk_data <= {(DW){1'b0}};
			o_xclk_sel <= {(DW/8){1'b0}};
			pipe_data1 <= {(DW){1'b0}};
			pipe_data2 <= {(DW){1'b0}};
			pipe_addr1 <= {(AW){1'b0}};
			pipe_addr2 <= {(AW){1'b0}};
			pipe_sel1 <= {(DW/8){1'b0}};
			pipe_sel2 <= {(DW/8){1'b0}};
			pipe_we1 <= 1'b0;
			pipe_we2 <= 1'b0;
			pipe_valid1 <= 1'b0;
			pipe_valid2 <= 1'b0;
		end else begin
			// Stage 1: read from FIFO
			if (xclk_rd_en) begin
				pipe_data1 <= fifo_data[rd_ptr[FIFO_PTR_W-1:0]];
				pipe_addr1 <= fifo_addr[rd_ptr[FIFO_PTR_W-1:0]];
				pipe_sel1 <= fifo_sel[rd_ptr[FIFO_PTR_W-1:0]];
				pipe_we1 <= fifo_we[rd_ptr[FIFO_PTR_W-1:0]];
				pipe_valid1 <= 1'b1;
				rd_ptr <= rd_ptr + 1'b1;
			end else begin
				pipe_valid1 <= 1'b0;
			end

			// Stage 2: output
			if (pipe_valid1) begin
				pipe_data2 <= pipe_data1;
				pipe_addr2 <= pipe_addr1;
				pipe_sel2 <= pipe_sel1;
				pipe_we2 <= pipe_we1;
				pipe_valid2 <= 1'b1;
			end else begin
				pipe_valid2 <= 1'b0;
			end

			// Drive outputs from stage 2
			if (pipe_valid2) begin
				o_xclk_cyc <= 1'b1;
				o_xclk_stb <= 1'b1;
				o_xclk_we <= pipe_we2;
				o_xclk_addr <= pipe_addr2;
				o_xclk_data <= pipe_data2;
				o_xclk_sel <= pipe_sel2;
			end else begin
				o_xclk_cyc <= 1'b0;
				o_xclk_stb <= 1'b0;
				o_xclk_we <= 1'b0;
			end
		end
	end

	// WB response: when xclk_ack is received, return data/err
	// We need to track which WB transaction the xclk_ack corresponds to.
	// Since we forward in order, we can use a simple counter or just
	// respond on the next WB clock after xclk_ack is synchronized.

	// Synchronize xclk_ack to WB domain
	reg xclk_ack_sync1, xclk_ack_sync2;
	reg xclk_err_sync1, xclk_err_sync2;
	reg [DW-1:0] xclk_data_sync1, xclk_data_sync2;

	always @(posedge i_wb_clk or posedge wb_rst) begin
		if (wb_rst) begin
			xclk_ack_sync1 <= 1'b0;
			xclk_ack_sync2 <= 1'b0;
			xclk_err_sync1 <= 1'b0;
			xclk_err_sync2 <= 1'b0;
			xclk_data_sync1 <= {(DW){1'b0}};
			xclk_data_sync2 <= {(DW){1'b0}};
		end else begin
			xclk_ack_sync1 <= i_xclk_ack;
			xclk_ack_sync2 <= xclk_ack_sync1;
			xclk_err_sync1 <= i_xclk_err;
			xclk_err_sync2 <= xclk_err_sync1;
			xclk_data_sync1 <= i_xclk_data;
			xclk_data_sync2 <= xclk_data_sync1;
		end
	end

	// Respond on WB clock when ack is synchronized
	always @(posedge i_wb_clk or posedge wb_rst) begin
		if (wb_rst) begin
			o_wb_ack <= 1'b0;
			o_wb_data <= {(DW){1'b0}};
			o_wb_err <= 1'b0;
		end else begin
			if (xclk_ack_sync2) begin
				o_wb_ack <= 1'b1;
				o_wb_data <= xclk_data_sync2;
				o_wb_err <= xclk_err_sync2;
			end else begin
				o_wb_ack <= 1'b0;
			end
		end
	end

endmodule
