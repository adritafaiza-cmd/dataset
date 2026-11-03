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

	reg [AW-1:0] addr_reg;
	reg write_reg;
	reg [DW-1:0] data_reg;
	reg [DW/8-1:0] strb_reg;
	reg [2:0] prot_reg;
	reg [DW-1:0] rdata_reg;
	reg slerr_reg;
	reg sel_reg;
	reg enable_reg;
	reg presetn_reg;
	reg pready_reg;

	wire [AW-1:0] addr;
	wire write;
	wire [DW-1:0] data;
	wire [DW/8-1:0] strb;
	wire [2:0] prot;
	wire [DW-1:0] rdata;
	wire slerr;
	wire sel;
	wire enable;
	wire presetn;

	assign addr = OPT_REGISTERED? addr_reg : S_APB_PADDR;
	assign write = OPT_REGISTERED? write_reg : S_APB_PWRITE;
	assign data = OPT_REGISTERED? data_reg : S_APB_PWDATA;
	assign strb = OPT_REGISTERED? strb_reg : S_APB_PWSTRB;
	assign prot = OPT_REGISTERED? prot_reg : S_APB_PPROT;
	assign rdata = OPT_REGISTERED? rdata_reg : M_APB_PRDATA;
	assign slerr = OPT_REGISTERED? slerr_reg : M_APB_PSLVERR;
	assign sel = OPT_REGISTERED? sel_reg : S_APB_PSEL;
	assign enable = OPT_REGISTERED? enable_reg : S_APB_PENABLE;
	assign presetn = OPT_REGISTERED? presetn_reg : S_PRESETn;

	assign M_PRESETn = presetn;
	assign M_APB_PSEL = sel;
	assign M_APB_PENABLE = enable;
	assign M_APB_PADDR = addr;
	assign M_APB_PWRITE = write;
	assign M_APB_PWDATA = data;
	assign M_APB_PWSTRB = strb;
	assign M_APB_PPROT = prot;
	assign S_APB_PRDATA = rdata;
	assign S_APB_PSLVERR = slerr;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			sel_reg <= 1'b0;
			enable_reg <= 1'b0;
			presetn_reg <= 1'b1;
			pready_reg <= 1'b0;
		end else if (S_APB_PSEL &&!S_APB_PENABLE) begin
			sel_reg <= 1'b1;
			enable_reg <= 1'b0;
			presetn_reg <= 1'b1;
			pready_reg <= 1'b0;
			if (OPT_REGISTERED) begin
				addr_reg <= S_APB_PADDR;
				write_reg <= S_APB_PWRITE;
				data_reg <= S_APB_PWDATA;
				strb_reg <= S_APB_PWSTRB;
				prot_reg <= S_APB_PPROT;
			end
		end else if (S_APB_PSEL && S_APB_PENABLE) begin
			enable_reg <= 1'b1;
		end else if (!S_APB_PSEL) begin
			sel_reg <= 1'b0;
			enable_reg <= 1'b0;
		end
	end

	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			presetn_reg <= 1'b1;
			pready_reg <= 1'b0;
		end else if (M_APB_PREADY) begin
			presetn_reg <= 1'b1;
			pready_reg <= 1'b1;
			if (OPT_REGISTERED) begin
				rdata_reg <= M_APB_PRDATA;
				slerr_reg <= M_APB_PSLVERR;
			end
		end else if (!M_APB_PREADY) begin
			pready_reg <= 1'b0;
		end
	end

	assign S_APB_PREADY = pready_reg;

endmodule
