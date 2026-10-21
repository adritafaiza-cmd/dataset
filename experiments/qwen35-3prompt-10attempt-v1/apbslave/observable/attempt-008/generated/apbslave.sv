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
	input	wire		[AW-1:0]	PADDR,
	input	wire			PWRITE,
	input	wire		[DW-1:0]	PWDATA,
	input	wire		[DW/8-1:0]	PWSTRB,
	input	wire		[2:0]		PPROT,
	output	reg		[DW-1:0]	PRDATA,
	output	wire			PSLVERR
);

	localparam	NUM_BYTES = DW/8;
	localparam	NUM_BYTES_LOG = $clog2(NUM_BYTES);

	reg	[AW-1:0]	ADDR_REG;
	reg	[DW-1:0]	DATA_REG;
	reg			WRITE_ENABLE;
	reg			STATE; // 0: IDLE, 1: ACCESS
	reg			VALID;
	reg			STRB_VALID;
	reg	[APBLSB:0]	STRB_MASK;
	reg			PSLVERR_INT;

	// State Machine
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			ADDR_REG <= 0;
			DATA_REG <= 0;
			WRITE_ENABLE <= 0;
			STATE <= 0;
			PREADY <= 1'b0;
			PRDATA <= 0;
			PSLVERR <= 1'b0;
			VALID <= 1'b0;
			STRB_VALID <= 1'b0;
			STRB_MASK <= 0;
			PSLVERR_INT <= 1'b0;
		end
		else begin
			if (PSEL && PENABLE) begin
				// Setup Phase
				if (!PREADY) begin
					// Slave not ready, keep PREADY low
				end
				else begin
					// Slave ready, capture address and control
					ADDR_REG <= PADDR;
					WRITE_ENABLE <= PWRITE;
					
					// Check for strobe validity
					if (PWRITE) begin
						// Write strobe must be valid
						if (PWSTRB == 0) begin
							PSLVERR_INT <= 1'b1;
						end
						else begin
							STRB_VALID <= 1'b1;
							STRB_MASK <= PWSTRB;
						end
					end
					else begin
						// Read operation, no strobe needed
						STRB_VALID <= 1'b0;
						STRB_MASK <= 0;
					end

					// Transition to Access Phase
					STATE <= 1;
					PREADY <= 1'b1;
					VALID <= 1'b1;
				end
			end
			else begin
				// No select or no enable
				PREADY <= 1'b1;
				VALID <= 1'b0;
				STRB_VALID <= 1'b0;
				PSLVERR_INT <= 1'b0;
			end
		end
	end

	// Data Output Logic
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			PRDATA <= 0;
		end
		else if (STATE == 1 && PENABLE && PREADY) begin
			if (WRITE_ENABLE) begin
				// Write operation
				if (STRB_VALID) begin
					// Apply byte mask
					DATA_REG <= DATA_REG & (~STRB_MASK) | (PWDATA & STRB_MASK);
				end
				else begin
					// Invalid write strobe
					PSLVERR_INT <= 1'b1;
				end
			end
			else begin
				// Read operation
				PRDATA <= DATA_REG;
			end
		end
	end

	// Error Output
	assign PSLVERR = PSEL && PENABLE && PREADY && PSLVERR_INT;

endmodule
```<|im_end|>
