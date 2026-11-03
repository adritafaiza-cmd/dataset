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

	reg	[AW-1:0]	fifo_addr[(1<<LGFIFO)-1:0];
	reg	[(DW-1):0]	fifo_data[(1<<LGFIFO)-1:0];
	reg	[(DW/8-1):0]	fifo_sel[(1<<LGFIFO)-1:0];
	reg			fifo_we[(1<<LGFIFO)-1:0];
	reg			fifo_valid[(1<<LGFIFO)-1:0];
	reg	[LGFIFO-1:0]	fifo_head;
	reg	[LGFIFO-1:0]	fifo_tail;
	reg	[LGFIFO-1:0]	fifo_count;
	reg			fifo_empty;
	reg			fifo_full;

	always @(posedge i_wb_clk or posedge i_reset) begin
		if (i_reset) begin
			o_wb_stall <= 1'b0;
			o_wb_ack <= 1'b0;
			o_wb_data <= {DW{1'b0}};
			o_wb_err <= 1'b0;
			o_xclk_cyc <= 1'b0;
			o_xclk_stb <= 1'b0;
			o_xclk_we <= 1'b0;
			o_xclk_addr <= {AW{1'b0}};
			o_xclk_data <= {DW{1'b0}};
			o_xclk_sel <= {DW/8{1'b0}};
			fifo_head <= {LGFIFO{1'b0}};
			fifo_tail <= {LGFIFO{1'b0}};
			fifo_count <= {LGFIFO{1'b0}};
			fifo_empty <= 1'b1;
			fifo_full <= 1'b0;
		end else begin
			if (i_wb_cyc && i_wb_stb && !o_wb_stall) begin
				fifo_addr[fifo_head] <= i_wb_addr;
				fifo_data[fifo_head] <= i_wb_data;
				fifo_sel[fifo_head] <= i_wb_sel;
				fifo_we[fifo_head] <= i_wb_we;
				fifo_valid[fifo_head] <= 1'b1;
				if (fifo_head == (1<<LGFIFO)-1) begin
					fifo_head <= {LGFIFO{1'b0}};
				end else begin
					fifo_head <= fifo_head + 1'b1;
				end
				if (fifo_count == (1<<LGFIFO)-1) begin
					fifo_full <= 1'b1;
				end else begin
					fifo_count <= fifo_count + 1'b1;
				end
				fifo_empty <= 1'b0;
			end
			if (i_xclk_ack && !fifo_empty) begin
				o_wb_ack <= 1'b1;
				o_wb_data <= i_xclk_data;
				o_wb_err <= i_xclk_err;
				if (fifo_tail == (1<<LGFIFO)-1) begin
					fifo_tail <= {LGFIFO{1'b0}};
				end else begin
					fifo_tail <= fifo_tail + 1'b1;
				end
				if (fifo_count == 1'b1) begin
					fifo_count <= {LGFIFO{1'b0}};
				end else begin
					fifo_count <= fifo_count - 1'b1;
				end
				if (fifo_count == {LGFIFO{1'b0}}) begin
					fifo_empty <= 1'b1;
				end
			end else begin
				o_wb_ack <= 1'b0;
			end
			if (fifo_full) begin
				o_wb_stall <= 1'b1;
			end else begin
				o_wb_stall <= 1'b0;
			end
			if (!fifo_empty && !i_xclk_stall) begin
				o_xclk_cyc <= 1'b1;
				o_xclk_stb <= 1'b1;
				o_xclk_we <= fifo_we[fifo_tail];
				o_xclk_addr <= fifo_addr[fifo_tail];
				o_xclk_data <= fifo_data[fifo_tail];
				o_xclk_sel <= fifo_sel[fifo_tail];
			end else begin
				o_xclk_cyc <= 1'b0;
				o_xclk_stb <= 1'b0;
				o_xclk_we <= 1'b0;
				o_xclk_addr <= {AW{1'b0}};
				o_xclk_data <= {DW{1'b0}};
				o_xclk_sel <= {DW/8{1'b0}};
			end
		end
	end

	assign fifo_full = (fifo_count == (1<<LGFIFO));
	assign fifo_empty = (fifo_count == {LGFIFO{1'b0}});

endmodule
