module apbxclk #(
		parameter	C_APB_ADDR_WIDTH = 12,
		parameter	C_APB_DATA_WIDTH = 32,
		parameter [0:0]	OPT_REGISTERED = 1'b0,
		localparam	AW = C_APB_ADDR_WIDTH,
		localparam	DW = C_APB_DATA_WIDTH
	) (
		input	wire			S_APB_PCLK, S_PRESETn,
		input	wire			S_APB_PSEL,
		input	wire			S_APB_PENABLE,
		output	reg			S_APB_PREADY,
		input	wire	[AW-1:0]	S_APB_PADDR,
		input	wire			S_APB_PWRITE,
		input	wire	[DW-1:0]	S_APB_PWDATA,
		input	wire	[DW/8-1:0]	S_APB_PWSTRB,
		input	wire	[2:0]		S_APB_PPROT,
		output	wire	[DW-1:0]	S_APB_PRDATA,
		output	wire			S_APB_PSLVERR,
		input	wire			M_APB_PCLK,
		output	reg			M_PRESETn,
		output	reg			M_APB_PSEL,
		output	reg			M_APB_PENABLE,
		input	wire			M_APB_PREADY,
		output	wire	[AW-1:0]	M_APB_PADDR,
		output	wire			M_APB_PWRITE,
		output	wire	[DW-1:0]	M_APB_PWDATA,
		output	wire	[DW/8-1:0]	M_APB_PWSTRB,
		output	wire	[2:0]		M_APB_PPROT,
		input	wire	[DW-1:0]	M_APB_PRDATA,
		input	wire			M_APB_PSLVERR
	);

	reg			src_ready;
	reg			dst_ready;
	reg	[AW-1:0]	src_addr;
	reg			src_write;
	reg	[DW-1:0]	src_wdata;
	reg	[DW/8-1:0]	src_wstrb;
	reg	[2:0]		src_prott;
	wire	[DW-1:0]	dst_rdata;
	wire			dst_serr;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			src_ready <= 1'b1;
			dst_ready <= 1'b1;
			src_addr <= 0;
			src_write <= 1'b0;
			src_wdata <= 0;
			src_wstrb <= 0;
			src_prott <= 0;
		end else begin
			if (S_APB_PSEL && S_APB_PENABLE) begin
				src_ready <= 1'b0;
				dst_ready <= 1'b0;
				if (S_APB_PWRITE) begin
					src_addr <= S_APB_PADDR;
					src_write <= 1'b1;
					src_wdata <= S_APB_PWDATA;
					src_wstrb <= S_APB_PWSTRB;
					src_prott <= S_APB_PPROT;
				end else begin
					src_addr <= S_APB_PADDR;
					src_write <= 1'b0;
					src_wdata <= 0;
					src_wstrb <= 0;
					src_prott <= 0;
				end
			end else begin
				src_ready <= 1'b1;
				dst_ready <= 1'b1;
			end
			if (M_APB_PREADY) begin
				S_APB_PREADY <= 1'b1;
				M_APB_PSEL <= 1'b0;
				M_APB_PENABLE <= 1'b0;
				M_APB_PADDR <= 0;
				M_APB_PWRITE <= 1'b0;
				M_APB_PWDATA <= 0;
				M_APB_PWSTRB <= 0;
				M_APB_PPROT <= 0;
			end else begin
				S_APB_PREADY <= 1'b0;
				M_APB_PSEL <= S_APB_PSEL;
				M_APB_PENABLE <= S_APB_PENABLE;
				M_APB_PADDR <= src_addr;
				M_APB_PWRITE <= src_write;
				M_APB_PWDATA <= src_wdata;
				M_APB_PWSTRB <= src_wstrb;
				M_APB_PPROT <= src_prott;
			end
		end
	end

	always @(posedge M_APB_PCLK) begin
		if (!M_PRESETn) begin
			M_PRESETn <= 1'b1;
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			M_APB_PADDR <= 0;
			M_APB_PWRITE <= 1'b0;
			M_APB_PWDATA <= 0;
			M_APB_PWSTRB <= 0;
			M_APB_PPROT <= 0;
		end else begin
			if (M_APB_PSEL && M_APB_PENABLE) begin
				dst_ready <= 1'b0;
				if (src_write) begin
					dst_rdata <= src_wdata;
					dst_serr <= 1'b0;
				end else begin
					dst_rdata <= M_APB_PRDATA;
					dst_serr <= M_APB_PSLVERR;
				end
			end else begin
				dst_ready <= 1'b1;
			end
		end
	end

	assign S_APB_PRDATA = dst_rdata;
	assign S_APB_PSLVERR = dst_serr;

endmodule
