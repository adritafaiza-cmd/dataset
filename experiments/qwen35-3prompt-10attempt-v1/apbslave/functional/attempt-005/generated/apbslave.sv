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
	reg			WRITE;
	reg			READY;
	reg			VALID;

	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			ADDR <= 0;
			DATA <= 0;
			WRITE <= 0;
			READY <= 0;
			VALID <= 0;
			PREADY <= 0;
			PRDATA <= 0;
			PSLVERR <= 0;
		end
		else begin
			// State Machine Logic
			if (!PSEL || !PENABLE) begin
				// Idle state
				PREADY <= 0;
				PSLVERR <= 0;
				READY <= 0;
				VALID <= 0;
			end
			else if (READY) begin
				// Transfer complete, release VALID
				READY <= 0;
				PREADY <= 1;
				VALID <= 0;
			end
			else if (VALID) begin
				// Transfer in progress, keep VALID
				PREADY <= 0;
				PSLVERR <= 0;
			end
			else begin
				// Initial handshake request
				PREADY <= 1;
				PSLVERR <= 0;
				READY <= 1;
				VALID <= 1;
				ADDR <= PADDR;
				DATA <= PWDATA;
				WRITE <= PWRITE;
			end
		end
	end

	// Data Output Logic
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn)
			PRDATA <= 0;
		else if (VALID)
			PRDATA <= DATA;
		else
			PRDATA <= 0;
	end

	// Error Logic (PSLVERR)
	// Per requirement: PSLVERR may stay low for in-range accesses.
	// This implementation assumes all accesses are valid unless specific
	// protection checks are added. Since no specific register map or
	// protection logic was provided in the prompt, PSLVERR remains low.
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn)
			PSLVERR <= 0;
		else if (VALID)
			PSLVERR <= 0; // Keep low for valid accesses
		else
			PSLVERR <= 0;
	end

endmodule<|im_end|>
