```verilog
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

	localparam	NUM_BYTES = DW/8;
	reg	[AW-1:0]	ADDR_REG;
	reg	[DW/8-1:0]	WSTRB_REG;
	reg	[DW-1:0]	DATA_REG;
	reg	STATE; // 0: IDLE, 1: READ, 2: WRITE

	// State Machine Logic
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			ADDR_REG <= 0;
			DATA_REG <= 0;
			WSTRB_REG <= 0;
			PREADY <= 1'b1;
			PRDATA <= 0;
			PSLVERR <= 1'b0;
			STATE <= 0;
		end
		else begin
			if (PSEL && PENABLE) begin
				if (STATE == 0) begin
					// Setup Phase
					ADDR_REG <= PADDR;
					WSTRB_REG <= PWSTRB;
					DATA_REG <= PWDATA;
					PREADY <= 1'b1;
					PSLVERR <= 1'b0;
					if (PWRITE)
						STATE <= 2;
					else
						STATE <= 1;
				end
				else if (STATE == 1) begin
					// Read Response
					PREADY <= 1'b1;
					PRDATA <= DATA_REG;
					STATE <= 0;
				end
				else if (STATE == 2) begin
					// Write Response
					PREADY <= 1'b1;
					PSLVERR <= 1'b0;
					STATE <= 0;
				end
			end
			else begin
				// Idle or No Select
				PREADY <= 1'b1;
				PRDATA <= 0;
				PSLVERR <= 1'b0;
				STATE <= 0;
			end
		end
	end

	// Optional: Logic to handle PSLVERR based on PPROT if specific protection checks are needed.
	// Per requirements: "PSLVERR may stay low for in-range accesses."
	// Assuming default behavior allows all accesses unless specific logic is added.
	// For a generic implementation without specific register map, we keep PSLVERR low.
	// If PPROT indicates a protected region not implemented, PSLVERR could be asserted here.
	// Currently, no specific address decoding is implemented, so all accesses succeed.

endmodule
```<|im_end|>
