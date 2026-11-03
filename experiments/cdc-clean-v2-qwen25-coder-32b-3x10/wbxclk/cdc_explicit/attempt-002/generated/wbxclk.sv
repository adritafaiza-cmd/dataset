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

	// FIFO for Wishbone to XCLK domain
	reg [AW-1:0]	fifo_addr [0:(1<<LGFIFO)-1];
	reg [DW-1:0]	fifo_data [0:(1<<LGFIFO)-1];
	reg [(DW/8-1):0] fifo_sel [0:(1<<LGFIFO)-1];
	reg [DW-1:0]	fifo_wb_data [0:(1<<LGFIFO)-1];
	reg		fifo_we [0:(1<<LGFIFO)-1];
	reg		fifo_cyc [0:(1<<LGFIFO)-1];
	reg		fifo_stb [0:(1<<LGFIFO)-1];
	reg		fifo_we_xclk [0:(1<<LGFIFO)-1];
	reg		fifo_cyc_xclk [0:(1<<LGFIFO)-1];
	reg		fifo_stb_xclk [0:(1<<LGFIFO)-1];
	reg [LGFIFO:0]	wr_ptr, rd_ptr, wr_ptr_gray, rd_ptr_gray, wr_ptr_gray_xclk, rd_ptr_gray_xclk;
	reg [LGFIFO:0]	wr_ptr_gray_sync, rd_ptr_gray_sync;
	reg		fifo_full, fifo_empty;

	// Gray code conversion
	function [LGFIFO:0] bin2gray;
		input [LGFIFO:0] bin;
		bin2gray = bin ^ (bin >> 1);
	endfunction

	// WB to XCLK FIFO write logic
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			wr_ptr <= 0;
			wr_ptr_gray <= 0;
			fifo_full <= 0;
		end else if (i_wb_cyc && i_wb_stb && !fifo_full) begin
			fifo_addr[wr_ptr] <= i_wb_addr;
			fifo_data[wr_ptr] <= i_wb_data;
			fifo_sel[wr_ptr] <= i_wb_sel;
			fifo_we[wr_ptr] <= i_wb_we;
			fifo_cyc[wr_ptr] <= i_wb_cyc;
			fifo_stb[wr_ptr] <= i_wb_stb;
			wr_ptr <= wr_ptr + 1;
			wr_ptr_gray <= bin2gray(wr_ptr + 1);
		end
	end

	// Sync write pointer to XCLK domain
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			wr_ptr_gray_sync <= 0;
		end else begin
			wr_ptr_gray_sync <= wr_ptr_gray;
		end
	end

	// XCLK FIFO read logic
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			rd_ptr <= 0;
			rd_ptr_gray <= 0;
			fifo_empty <= 1;
		end else if (o_xclk_stb && !i_xclk_stall && !fifo_empty) begin
			rd_ptr <= rd_ptr + 1;
			rd_ptr_gray <= bin2gray(rd_ptr + 1);
		end
	end

	// Sync read pointer to WB domain
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			rd_ptr_gray_sync <= 0;
		end else begin
			rd_ptr_gray_sync <= rd_ptr_gray;
		end
	end

	// FIFO flags
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			fifo_full <= 0;
		end else begin
			fifo_full <= (wr_ptr_gray_sync[LGFIFO:1] == {~rd_ptr_gray[LGFIFO:1], rd_ptr_gray[0]});
		end
	end

	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			fifo_empty <= 1;
		end else begin
			fifo_empty <= (wr_ptr_gray_sync == rd_ptr_gray_sync);
		end
	end

	// FIFO read data
	always @(posedge i_xclk_clk or posedge i_reset) begin
		if (i_reset) begin
			o_xclk_addr <= 0;
			o_xclk_data <= 0;
			o_xclk_sel <= 0;
			o_xclk_we <= 0;
			o_xclk_cyc <= 0;
			o_xclk_stb <= 0;
		end else if (o_xclk_stb && !i_xclk_stall && !fifo_empty) begin
			o_xclk_addr <= fifo_addr[rd_ptr];
			o_xclk_data <= fifo_data[rd_ptr];
			o_xclk_sel <= fifo_sel[rd_ptr];
			o_xclk_we <= fifo_we[rd_ptr];
			o_xclk_cyc <= fifo_cyc[rd_ptr];
			o_xclk_stb <= fifo_stb[rd_ptr];
		end
	end

	// XCLK to WB response handling
	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_ack <= 0;
			o_wb_err <= 0;
			o_wb_data <= 0;
			o_wb_stall <= 0;
		end else begin
			if (i_xclk_ack) begin
				o_wb_ack <= 1;
				o_wb_err <= i_xclk_err;
				o_wb_data <= i_xclk_data;
			end else if (i_xclk_err) begin
				o_wb_ack <= 0;
				o_wb_err <= 1;
				o_wb_data <= i_xclk_data;
			end else begin
				o_wb_ack <= 0;
				o_wb_err <= 0;
			end

			if (fifo_full) begin
				o_wb_stall <= 1;
			end else begin
				o_wb_stall <= 0;
			end
		end
	end

endmodule
