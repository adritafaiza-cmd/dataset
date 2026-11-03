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

	reg	[DW-1:0]	data_reg;
	reg				slverr;

	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			PREADY <= 0;
			PRDATA <= 0;
			slverr <= 0;
			data_reg <= 0;
		end else begin
			if (PSEL && PENABLE) begin
				PREADY <= 1;
				if (PWRITE) begin
					// Perform byte-wise write using PWSTRB
					for (integer i = 0; i < DW/8; i = i + 1) begin
						if (PWSTRB[i]) begin
							data_reg[i*8 +: 8] <= PWDATA[i*8 +: 8];
						end
					end
				end else begin
					// Read operation
					PRDATA <= data_reg;
				end
			end else begin
				PREADY <= 0;
			end

			// Always keep PSLVERR low for in-range accesses
			slverr <= 0;
		end
	end

	assign PSLVERR = slverr;

endmodule
