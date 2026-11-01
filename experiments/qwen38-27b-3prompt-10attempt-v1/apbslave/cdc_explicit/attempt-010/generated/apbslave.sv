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

	// Single clock domain, single reset domain.
	// No CDC or RDC crossings required.
	// PSLVERR is always low for in-range accesses.

	assign PSLVERR = 1'b0;

	// Register file: simple memory mapped to address space.
	// Address bits [AW-1:APBLSB] index the register.
	localparam NUM_REGS = (1 << (AW - APBLSB));

	reg [DW-1:0] mem [0:NUM_REGS-1];

	// Address decode
	wire [AW-APBLSB-1:0] reg_addr = PADDR[AW-1:APBLSB];

	// Write enable: during access phase (PSEL & PENABLE & PWRITE)
	wire wr_en = PSEL & PENABLE & PWRITE;

	// Read data: combinational read from memory
	always @(*) begin
		if (PSEL && !PWRITE)
			PRDATA = mem[reg_addr];
		else
			PRDATA = {DW{1'b0}};
		end

	// Write data: update memory during access phase
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			// Reset: clear memory (optional, but ensures defined state)
			// For large memories, we can skip full clear; but for correctness:
			// We'll just leave memory uninitialized in reset for simplicity,
			// or clear it. Let's clear it for safety.
			// However, clearing a large memory in reset can be expensive.
			// Since the problem says "After reset the slave must be idle",
			// and doesn't specify memory contents, we can leave memory as-is
			// or clear it. Let's clear it for deterministic behavior.
			// But for large NUM_REGS, this might be slow. 
			// Alternative: don't clear memory, just ensure PREADY is low.
			// The requirement is "idle", which means PREADY=0, no pending transactions.
			// Memory contents are not specified to be cleared.
			// So we'll just reset PREADY and leave memory.
		end else begin
			if (wr_en) begin
				// Byte-lane write using PWSTRB
				for (int i = 0; i < DW/8; i = i + 1) begin
					if (PWSTRB[i]) begin
						mem[reg_addr][i*8 +: 8] <= PWDATA[i*8 +: 8];
					end
				end
			end
		end
	end

	// PREADY: assert during access phase (PSEL & PENABLE)
	// In APB, PREADY should be high during the access phase to complete the transfer.
	// PREADY is typically asserted when the slave is ready to complete the access.
	// For a simple slave, PREADY is high whenever PSEL & PENABLE is high.
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn)
			PREADY <= 1'b0;
		else
			PREADY <= PSEL & PENABLE;
	end

endmodule
