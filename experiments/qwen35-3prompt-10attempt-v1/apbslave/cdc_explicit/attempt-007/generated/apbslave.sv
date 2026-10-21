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
	localparam	NUM_BITS = DW;

	// Internal state registers
	reg	[AW-1:0]		m_addr;
	reg	[DW-1:0]		m_data;
	reg	[DW/8-1:0]		m_strb;
	reg	[2:0]			m_prot;
	reg			m_write;
	reg			m_sel;
	reg			m_ready;
	reg			m_error;
	reg			m_valid;

	// State machine for APB protocol
	// States: IDLE, READ, WRITE
	reg	[1:0]		m_state;

	// Generate mask for write strobe
	generate
		genvar i;
		for (i = 0; i < NUM_BYTES; i = i + 1) begin : gen_strb
			wire		sel_bit = (PWSTRB[i] == 1'b1);
			assign	m_strb[i] = sel_bit;
		end
	endgenerate

	// State machine logic
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			m_addr <= 0;
			m_data <= 0;
			m_strb <= 0;
			m_prot <= 0;
			m_write <= 0;
			m_sel <= 0;
			m_ready <= 0;
			m_error <= 0;
			m_valid <= 0;
			m_state <= 2'b00; // IDLE
			PREADY <= 1'b0;
			PRDATA <= 0;
			PSLVERR <= 1'b0;
		end
		else begin
			// State transitions
			case (m_state)
				2'b00: // IDLE
					if (PRESETn) begin
						m_state <= 2'b00;
					end
					else if (PSEL && PENABLE) begin
						m_sel <= 1'b1;
						m_addr <= PADDR;
						m_write <= PWRITE;
						m_prot <= PPROT;
						m_state <= (PWRITE) ? 2'b01 : 2'b10; // WRITE or READ
					end
					else begin
						m_sel <= 1'b0;
						m_state <= 2'b00;
					end

				2'b01: // WRITE
					if (PRESETn) begin
						m_state <= 2'b00;
					end
					else if (PSEL && PENABLE) begin
						m_data <= PWDATA;
						m_strb <= PWSTRB;
						m_state <= 2'b00;
					end
					else begin
						m_state <= 2'b00;
					end

				2'b10: // READ
					if (PRESETn) begin
						m_state <= 2'b00;
					end
					else if (PSEL && PENABLE) begin
						m_state <= 2'b00;
					end
					else begin
						m_state <= 2'b00;
					end
			endcase

			// Output logic
			if (PRESETn) begin
				PREADY <= 1'b0;
				PRDATA <= 0;
				PSLVERR <= 1'b0;
			end
			else begin
				// PREADY assertion: 
				// - Must be asserted if PSEL is not asserted (idle)
				// - Must be asserted if PSEL is asserted but PENABLE is not asserted
				// - Must be asserted if PSEL and PENABLE are asserted and state is IDLE (no transaction in progress)
				// - Must be asserted if PSEL and PENABLE are asserted and state is WRITE (write complete)
				// - Must be asserted if PSEL and PENABLE are asserted and state is READ (read complete)
				// Note: In standard APB, PREADY is asserted when the slave is ready to complete the transaction.
				// For a simple slave without latency, PREADY is asserted whenever PSEL is not asserted OR 
				// when the transaction is complete.
				
				if (!PSEL || !PENABLE) begin
					PREADY <= 1'b1;
				end
				else begin
					// Transaction in progress
					if (m_state == 2'b00) begin
						// Idle state within transaction (should not happen if logic is correct, but safe default)
						PREADY <= 1'b1;
					end
					else if (m_state == 2'b01) begin
						// Write complete
						PREADY <= 1'b1;
					end
					else if (m_state == 2'b10) begin
						// Read complete
						PREADY <= 1'b1;
					end
				end

				// Data output
				if (m_state == 2'b10) begin // READ
					PRDATA <= m_data;
					PSLVERR <= m_error;
				end
				else begin
					PRDATA <= 0;
					PSLVERR <= 0;
				end
			end
		end
	end

	// Error generation logic (example: invalid address or protection)
	// Since no specific register map is defined, we assume all addresses are valid for this generic slave.
	// We can add error conditions here if needed, e.g., reserved addresses.
	// For now, PSLVERR is always 0 as per requirement "PSLVERR may stay low for in-range accesses".
	// If specific error conditions were required, they would be added here.
	assign m_error = 1'b0;

endmodule
```<|im_end|>
