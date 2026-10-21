module apbslave #(
	parameter	C_APB_ADDR_WIDTH = 12,
	parameter	C_APB_DATA_WIDTH = 32,
	localparam	AW = C_APB_ADDR_WIDTH,
	localparam	DW = C_APB_DATA_WIDTH,
	localparam	APBLSB = $clog2(C_APB_DATA_WIDTH)-3
) (
	input	wire			PCLK, PRESETn,
	input	wire			PSEL,
	input	wire			PENABLE,
	output	reg			PREADY,
	input	wire	[AW-1:0]	PADDR,
	input	wire			PWRITE,
	input	wire	[DW-1:0]	PWDATA,
	input	wire	[DW/8-1:0]	PWSTRB,
	input	wire	[2:0]		PPROT,
	output	reg	[DW-1:0]	PRDATA,
	output	wire			PSLVERR
);

	reg	[AW-1:0]	ADDR;
	reg	[DW-1:0]	DATA;
	reg	[DW/8-1:0]	WSTRB;
	reg	STATE;
	reg	[2:0]	PROT;
	reg	[DW-1:0]	OLD_DATA;

	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			ADDR <= 0;
			DATA <= 0;
			WSTRB <= 0;
			STATE <= 0;
			PROT <= 0;
			OLD_DATA <= 0;
			PREADY <= 0;
			PRDATA <= 0;
			PSLVERR <= 0;
		end
		else begin
			if (PSEL && PENABLE && !PREADY) begin
				ADDR <= PADDR;
				DATA <= PWDATA;
				WSTRB <= PWSTRB;
				PROT <= PPROT;
				OLD_DATA <= PRDATA;
				if (PWRITE) begin
					STATE <= 1;
				end
				else begin
					STATE <= 2;
				end
			end
			else begin
				PREADY <= 1;
				if (STATE == 1) begin
					PRDATA <= DATA;
					STATE <= 0;
				end
				else if (STATE == 2) begin
					PRDATA <= OLD_DATA;
					STATE <= 0;
				end
			end
		end
	end

	assign PSLVERR = 0;

endmodule<|im_end|>
