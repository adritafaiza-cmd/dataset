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

	reg [DW-1:0] mem [0:2**AW-1];
	reg [DW-1:0] rdata_reg;
	reg [DW/8-1:0] wstrb_reg;
	reg [AW-1:0] waddr_reg;
	reg rwrite_reg;

	assign PSLVERR = 1'b0;

	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			PREADY <= 1'b1;
			PRDATA <= {DW{1'b0}};
			rdata_reg <= {DW{1'b0}};
			wstrb_reg <= {(DW/8){1'b0}};
			waddr_reg <= {AW{1'b0}};
			rwrite_reg <= 1'b0;
		end else begin
			if (PSEL && !PENABLE) begin
				PREADY <= 1'b1;
				if (PWRITE) begin
					wstrb_reg <= PWSTRB;
					waddr_reg <= PADDR[AW-1:APBLSB];
					rwrite_reg <= 1'b1;
				end else begin
					rdata_reg <= mem[PADDR[AW-1:APBLSB]];
					rwrite_reg <= 1'b0;
				end
			end else if (PSEL && PENABLE) begin
				PREADY <= 1'b1;
				if (rwrite_reg) begin
					if (PWRITE) begin
						for (integer i = 0; i < DW/8; i = i + 1) begin
							if (wstrb_reg[i]) begin
								mem[waddr_reg][i*8 +: 8] <= PWDATA[i*8 +: 8];
							end
						end
					end
				end else begin
					PRDATA <= rdata_reg;
				end
			end
		end
	end

endmodule
