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

	reg	[AW-1:0]	ADDR;
	reg			STATE;
	reg			VALID;
	reg			READ;
	reg			[DW-1:0]	DATA;
	reg			[DW/8-1:0]	WSTRB;

	// State Machine
	// IDLE: Waiting for PSEL and PENABLE
	// READ: Processing read transaction
	// WRITE: Processing write transaction

	initial begin
		ADDR = 0;
		STATE = IDLE;
		VALID = 0;
		READ = 0;
		DATA = 0;
		WSTRB = 0;
	end

	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			ADDR <= 0;
			STATE <= IDLE;
			VALID <= 0;
			READ <= 0;
			DATA <= 0;
			WSTRB <= 0;
			PREADY <= 1'b0;
			PRDATA <= 0;
			PSLVERR <= 1'b0;
		end
		else begin
			// State Logic
			case (STATE)
				IDLE: begin
					if (!PSEL || !PENABLE) begin
						PREADY <= 1'b1;
					end
					else begin
						PREADY <= 1'b0;
						ADDR <= PADDR;
						READ <= ~PWRITE;
						DATA <= 0;
						WSTRB <= PWSTRB;
						STATE <= (READ) ? READ : WRITE;
					end
				end

				READ: begin
					// Simulate read data generation (e.g., address mapping)
					DATA <= {AW{1'b0}} | PADDR; // Placeholder for actual logic
					PREADY <= 1'b1;
					PRDATA <= DATA;
					PSLVERR <= 1'b0;
					STATE <= IDLE;
				end

				WRITE: begin
					// Simulate write data storage (e.g., register update)
					DATA <= PWDATA;
					PREADY <= 1'b1;
					PRDATA <= DATA;
					PSLVERR <= 1'b0;
					STATE <= IDLE;
				end
			endcase
		end
	end

	// Output assignments
	PREADY <= (STATE == IDLE) ? 1'b1 : 1'b0;
	PRDATA <= DATA;
	PSLVERR <= 1'b0; // Always low for in-range accesses as per requirement

endmodule
```<|im_end|>
