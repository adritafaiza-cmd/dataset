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
	localparam	NUM_BITS  = DW;

	// Internal state registers
	reg	[AW-1:0]		i_addr;
	reg	[2:0]			i_prot;
	reg	[DW-1:0]		i_data;
	reg	[DW/8-1:0]		i_strb;
	reg			i_write;
	reg			i_sel;
	reg			i_enable;
	reg			i_ready;
	reg			i_err;

	// State machine
	localparam	IDLE = 0;
	localparam	ACCESS = 1;

	reg	[1:0]		state;

	// ------------------------------------------------------------------
	// Sequential Logic (Single Clock Domain)
	// ------------------------------------------------------------------
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			state <= IDLE;
			i_sel <= 1'b0;
			i_enable <= 1'b0;
			i_write <= 1'b0;
			i_addr <= 12'd0;
			i_prot <= 3'd0;
			i_data <= {DW{1'b0}};
			i_strb <= {NUM_BYTES{1'b0}};
			i_ready <= 1'b0;
			i_err <= 1'b0;
			PREADY <= 1'b0;
			PRDATA <= {DW{1'b0}};
			PSLVERR <= 1'b0;
		end
		else begin
			// State Machine
			case (state)
				IDLE: begin
					if (i_sel && i_enable) begin
						state <= ACCESS;
						i_addr <= PADDR;
						i_prot <= PPROT;
						i_write <= PWRITE;
						i_data <= PWDATA;
						i_strb <= PWSTRB;
						i_ready <= 1'b1; // Ready to accept data
						i_err <= 1'b0;
					end
					else begin
						state <= IDLE;
						i_ready <= 1'b0;
					end
				end

				ACCESS: begin
					// If slave is ready, complete the transaction
					if (i_ready) begin
						state <= IDLE;
						i_ready <= 1'b0;
						PREADY <= 1'b1;
						PSLVERR <= i_err;
						// Drive output data based on read/write
						if (!i_write) begin
							PRDATA <= i_data;
						end
						else begin
							// For write, PRDATA is typically don't care, but we drive 0
							PRDATA <= {DW{1'b0}};
						end
					end
					else begin
						// Slave not ready, keep state
						PREADY <= 1'b0;
						PSLVERR <= i_err;
						PRDATA <= (i_write) ? {DW{1'b0}} : i_data;
					end
				end
			endcase
		end
	end

	// ------------------------------------------------------------------
	// Combinational Logic for Error Detection and Data Handling
	// ------------------------------------------------------------------
	// Note: In a real implementation, 'i_data' and 'i_strb' are captured
	// on the clock edge in the sequential block above. This block is
	// technically redundant for the state update logic but serves to
	// demonstrate where error logic would reside if it depended on
	// current cycle inputs rather than registered state.
	//
	// However, to strictly adhere to the "safe for CDC" requirement and
	// avoid any combinational path from slave inputs to outputs that
	// could cause metastability or timing violations, all state updates
	// and output drives must be synchronous.
	//
	// The error logic (PSLVERR) is driven by the registered state 'i_err'.
	// In this simple implementation, we assume no error conditions are met
	// for in-range accesses as per the prompt ("PSLVERR may stay low").
	// If specific error conditions were required (e.g., invalid address),
	// they would be evaluated here and latched into 'i_err' in the
	// sequential block.

	// ------------------------------------------------------------------
	// Output Assignments (Synchronous)
	// ------------------------------------------------------------------
	// PREADY is driven in the sequential block based on state.
	// PRDATA is driven in the sequential block based on state and i_write.
	// PSLVERR is driven in the sequential block based on i_err.

	// Default assignments to ensure synthesis tools don't infer latches
	// for outputs that are only updated in specific conditions.
	assign PREADY = i_ready ? 1'b1 : 1'b0;
	assign PSLVERR = i_err;

	// Data output assignment handled inside the sequential block to ensure
	// it is synchronous with the clock.
	// We use a non-blocking assignment for PRDATA inside the always block
	// to ensure it updates correctly on the clock edge.

endmodule
```<|im_end|>
