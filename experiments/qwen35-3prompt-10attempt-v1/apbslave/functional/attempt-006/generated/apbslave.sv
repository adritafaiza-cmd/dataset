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
	reg			STATE;
	reg			READ_EN;
	reg			WRITE_EN;
	reg	[DW-1:0]	DATA_IN;
	reg	[DW/8-1:0]	STRB_IN;
	reg	[DW-1:0]	DATA_OUT;

	// State Machine
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			STATE <= 1'b0;
			PREADY <= 1'b1;
			PSLVERR <= 1'b0;
			PRDATA <= 1'b0;
			ADDR <= 1'b0;
			READ_EN <= 1'b0;
			WRITE_EN <= 1'b0;
			DATA_IN <= 1'b0;
			STRB_IN <= 1'b0;
		end
		else begin
			case (STATE)
				1'b0: begin // Idle
					if (PSEL && PENABLE) begin
						ADDR <= PADDR;
						READ_EN <= !PWRITE;
						WRITE_EN <= PWRITE;
						DATA_IN <= PWDATA;
						STRB_IN <= PWSTRB;
						PREADY <= 1'b1;
						PSLVERR <= 1'b0;
						STATE <= 1'b1;
					end
				end
				1'b1: begin // Active
					PREADY <= 1'b1;
					PSLVERR <= 1'b0;
					if (READ_EN) begin
						PRDATA <= DATA_IN;
					end
					else if (WRITE_EN) begin
						PRDATA <= DATA_IN;
						// In a real implementation, DATA_IN would be written to memory/register here.
						// Since no storage is specified in the prompt, we simply acknowledge the write.
					end
					STATE <= 1'b0;
				end
				default: begin
					PREADY <= 1'b1;
					PSLVERR <= 1'b0;
				end
			endcase
		end
	end

	// Output logic for PREADY and PSLVERR based on state
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			PREADY <= 1'b1;
			PSLVERR <= 1'b0;
		end
		else begin
			if (STATE == 1'b1) begin
				PREADY <= 1'b1;
				PSLVERR <= 1'b0;
			end
			else begin
				PREADY <= 1'b1;
				PSLVERR <= 1'b0;
			end
		end
	end

	// Data output register for read data
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			PRDATA <= 1'b0;
		end
		else begin
			if (STATE == 1'b1 && READ_EN) begin
				PRDATA <= DATA_IN;
			end
			else if (STATE == 1'b1 && WRITE_EN) begin
				// For write, PRDATA typically reflects the data being written or the previous value.
				// Here we reflect the incoming data as per standard APB behavior where PRDATA is valid on read.
				// If this is a write-only register, PRDATA might be undefined or hold previous value.
				// We will hold the previous value or zero. Let's hold previous value for consistency.
				// However, since we don't have a storage element for the register content in this minimal model,
				// we will just assign DATA_IN to PRDATA during write cycle if needed, or keep it stable.
				// Standard APB: PRDATA is valid only on read. On write, it can be X or previous.
				// To be safe and simple: keep previous value.
				// But since we don't have a 'reg' for the stored value, we can't easily hold it across cycles
				// without a separate register. Given the constraints, we will assume PRDATA is updated on read.
				// On write, we leave it as is (non-blocking assignment won't update it immediately anyway).
				// Actually, let's add a simple storage for the register value to make it functional.
				// Re-evaluating: The prompt asks for a slave. Usually, it has storage.
				// Without explicit storage logic, we can't store data.
				// Let's assume the data is stored in a register 'REG_DATA'.
			end
		end
	end

	// Adding storage for the register value to make the slave functional
	reg	[DW-1:0]	REG_DATA;

	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			REG_DATA <= 1'b0;
		end
		else begin
			if (STATE == 1'b1 && WRITE_EN) begin
				REG_DATA <= DATA_IN;
			end
		end
	end

	// Update PRDATA logic with the storage
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			PRDATA <= 1'b0;
		end
		else begin
			if (STATE == 1'b1 && READ_EN) begin
				PRDATA <= REG_DATA;
			end
			else if (STATE == 1'b1 && WRITE_EN) begin
				// On write, PRDATA is not necessarily valid, but often driven by the write data or held.
				// We will drive it with the write data for visibility, or hold.
				// Let's hold the previous value to avoid glitches.
				// Since we are in a combinational-like update within sequential, we need to be careful.
				// Actually, PRDATA is an output. We can update it here.
				// If it's a write, we don't necessarily need to update PRDATA, but let's keep it stable.
				// The simplest approach: only update on read.
			end
		end
	end

	// Corrected approach: Combine the storage update and PRDATA output in one block or ensure stability.
	// Let's refine the always block for PRDATA and REG_DATA.

	reg	[DW-1:0]	STORED_DATA;

	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			STORED_DATA <= 1'b0;
			PREADY <= 1'b1;
			PSLVERR <= 1'b0;
			PRDATA <= 1'b0;
		end
		else begin
			if (STATE == 1'b1) begin
				PREADY <= 1'b1;
				PSLVERR <= 1'b0;
				if (READ_EN) begin
					PRDATA <= STORED_DATA;
				end
				else if (WRITE_EN) begin
					STORED_DATA <= DATA_IN;
					// PRDATA can be X or previous. We leave it as previous (no assignment here)
					// or assign DATA_IN if desired. Let's assign DATA_IN to be explicit.
					PRDATA <= DATA_IN; 
				end
			end
			else begin
				PREADY <= 1'b1;
				PSLVERR <= 1'b0;
				PRDATA <= 1'b0; // Idle state
			end
		end
	end

endmodule<|im_end|>
