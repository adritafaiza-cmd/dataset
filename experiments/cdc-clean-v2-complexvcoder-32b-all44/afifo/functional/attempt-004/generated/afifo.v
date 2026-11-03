module afifo #(
		parameter	LGFIFO = 3,
		parameter	WIDTH  = 16,
		parameter	NFF    = 2,
		parameter [0:0]	WRITE_ON_POSEDGE = 1'b1,
		parameter [0:0]	OPT_REGISTER_READS = 1'b1
	) (
		input	wire			i_wclk, i_wr_reset_n, i_wr,
		input	wire	[WIDTH-1:0]	i_wr_data,
		output	reg			o_wr_full,
		input	wire			i_rclk, i_rd_reset_n, i_rd,
		output	reg	[WIDTH-1:0]	o_rd_data,
		output	reg			o_rd_empty
	);

wire [WIDTH-1:0] rd_data;
wire rd_empty;

async_fifo_core #(
	.LGFIFO(LGFIFO),
	.WIDTH(WIDTH),
	.NFF(NFF),
	.WRITE_ON_POSEDGE(WRITE_ON_POSEDGE),
	.OPT_REGISTER_READS(OPT_REGISTER_READS)
) fifo_core (
	.i_wclk(i_wclk),
	.i_wr_reset_n(i_wr_reset_n),
	.i_wr(i_wr),
	.i_wr_data(i_wr_data),
	.o_wr_full(o_wr_full),
	.i_rclk(i_rclk),
	.i_rd_reset_n(i_rd_reset_n),
	.i_rd(i_rd),
	.o_rd_data(rd_data),
	.o_rd_empty(rd_empty)
);

always @(posedge i_rclk or negedge i_rd_reset_n) begin
	if (!i_rd_reset_n) begin
		o_rd_empty <= 1'b1;
		o_rd_data <= {WIDTH{1'b0}};
	end else begin
		o_rd_empty <= rd_empty;
		if (OPT_REGISTER_READS && !rd_empty && i_rd) begin
			o_rd_data <= rd_data;
		end else if (!OPT_REGISTER_READS) begin
			o_rd_data <= rd_data;
		end
	end
end

endmodule

module async_fifo_core #(
		parameter	LGFIFO = 3,
		parameter	WIDTH  = 16,
		parameter	NFF    = 2,
		parameter [0:0]	WRITE_ON_POSEDGE = 1'b1,
		parameter [0:0]	OPT_REGISTER_READS = 1'b1
	) (
		input	wire			i_wclk, i_wr_reset_n, i_wr,
		input	wire	[WIDTH-1:0]	i_wr_data,
		output	reg			o_wr_full,
		input	wire			i_rclk, i_rd_reset_n, i_rd,
		output	wire	[WIDTH-1:0]	o_rd_data,
		output	wire			o_rd_empty
	);

reg [LGFIFO:0] wr_cnt_gray, rd_cnt_gray;
reg [LGFIFO:0] wr_cnt_gray_sync, rd_cnt_gray_sync;
reg [LGFIFO-1:0] wr_ptr, rd_ptr, wr_ptr_next, rd_ptr_next;
reg [WIDTH-1:0] mem [0:(1<<LGFIFO)-1];
reg full, empty;
reg [LGFIFO:0] wr_gray_next, rd_gray_next;
reg [LGFIFO-1:0] gray2bin_wr, gray2bin_rd, gray2bin_wr_sync, gray2bin_rd_sync;
reg [LGFIFO:0] bin2gray_wr, bin2gray_rd;
reg [WIDTH-1:0] rd_data_raw, rd_data_reg;

sync_counter #(
	.LGFIFO(LGFIFO)
) wr_counter_sync (
	.clk(i_rclk),
	.reset_n(i_rd_reset_n),
	.din(wr_cnt_gray),
	.dout(rd_cnt_gray_sync)
);

sync_counter #(
	.LGFIFO(LGFIFO)
) rd_counter_sync (
	.clk(i_wclk),
	.reset_n(i_wr_reset_n),
	.din(rd_cnt_gray),
	.dout(wr_cnt_gray_sync)
);

always @(posedge i_wclk or negedge i_wr_reset_n) begin
	if (!i_wr_reset_n) begin
		wr_ptr <= {LGFIFO{1'b0}};
		wr_ptr_next <= {LGFIFO{1'b0}};
		wr_gray_next <= {LGFIFO+1{1'b0}};
		wr_cnt_gray <= {LGFIFO+1{1'b0}};
	end else begin
		wr_ptr_next <= wr_ptr + 1;
		wr_gray_next <= (wr_ptr_next ^ (wr_ptr_next >> 1));
		if (WRITE_ON_POSEDGE && i_wr && !full) begin
			wr_ptr <= wr_ptr_next;
			wr_cnt_gray <= wr_gray_next;
			mem[wr_ptr_next] <= i_wr_data;
		end
	end
end

always @(posedge i_rclk or negedge i_rd_reset_n) begin
	if (!i_rd_reset_n) begin
		rd_ptr <= {LGFIFO{1'b0}};
		rd_ptr_next <= {LGFIFO{1'b0}};
		rd_gray_next <= {LGFIFO+1{1'b0}};
		rd_cnt_gray <= {LGFIFO+1{1'b0}};
	end else begin
		rd_ptr_next <= rd_ptr + 1;
		rd_gray_next <= (rd_ptr_next ^ (rd_ptr_next >> 1));
		if (i_rd && !empty) begin
			rd_ptr <= rd_ptr_next;
			rd_cnt_gray <= rd_gray_next;
		end
	end
end

assign gray2bin_wr = wr_cnt_gray_sync ^ (wr_cnt_gray_sync >> 1);
assign gray2bin_rd = rd_cnt_gray_sync ^ (rd_cnt_gray_sync >> 1);
assign gray2bin_wr_sync = wr_cnt_gray ^ (wr_cnt_gray >> 1);
assign gray2bin_rd_sync = rd_cnt_gray ^ (rd_cnt_gray >> 1);

assign bin2gray_wr = wr_ptr_next ^ (wr_ptr_next >> 1);
assign bin2gray_rd = rd_ptr_next ^ (rd_ptr_next >> 1);

assign full = (wr_gray_next == {1'b1, rd_cnt_gray_sync[LGFIFO-1:0]});
assign empty = (wr_cnt_gray_sync == {1'b0, rd_ptr_next[LGFIFO-1:0]});

assign o_wr_full = full;

always @(posedge i_rclk or negedge i_rd_reset_n) begin
	if (!i_rd_reset_n) begin
		rd_data_raw <= {WIDTH{1'b0}};
		o_rd_data <= {WIDTH{1'b0}};
	end else begin
		rd_data_raw <= mem[rd_ptr];
		if (OPT_REGISTER_READS) begin
			o_rd_data <= rd_data_raw;
		end
	end
end

assign o_rd_empty = empty;
assign o_rd_data = OPT_REGISTER_READS ? rd_data_reg : rd_data_raw;

endmodule

module sync_counter #(
		parameter	LGFIFO = 3
	) (
		input	wire			clk,
		input	wire			reset_n,
		input	wire	[LGFIFO:0]	din,
		output	reg	[LGFIFO:0]	dout
	);

reg [LGFIFO:0] sync_stage [0:NFF-1];

always @(posedge clk or negedge reset_n) begin
	if (!reset_n) begin
		dout <= {LGFIFO+1{1'b0}};
		for (int i = 0; i < NFF; i = i + 1) begin
			sync_stage[i] <= {LGFIFO+1{1'b0}};
		end
	end else begin
		sync_stage[0] <= din;
		for (int i = 1; i < NFF; i = i + 1) begin
			sync_stage[i] <= sync_stage[i-1];
		end
		dout <= sync_stage[NFF-1];
	end
end

endmodule
