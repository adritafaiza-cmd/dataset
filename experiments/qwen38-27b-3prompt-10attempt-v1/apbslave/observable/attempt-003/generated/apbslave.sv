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

	// Internal register file: 256 bytes (32 words)
	reg [DW-1:0] mem [0:2**APBLSB-1];

	// State machine
	localparam S_IDLE = 1'b0;
	localparam S_SETUP = 1'b1;
	localparam S_ACCESS = 1'b1; // APB uses PSEL & PENABLE to distinguish setup/access

	// We use a simple state variable
	reg state;

	// PSLVERR is always 0 for this simple slave
	assign PSLVERR = 1'b0;

	// Main clocked logic
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			state <= S_IDLE;
			PREADY <= 1'b0;
			PRDATA <= {DW{1'b0}};
		end else begin
			case (state)
				S_IDLE: begin
					PREADY <= 1'b1;
					if (PSEL) begin
						state <= S_SETUP;
					end
				end
				S_SETUP: begin
					PREADY <= 1'b1;
					if (PENABLE) begin
						// Access phase
						if (PWRITE) begin
							// Byte-strobed write
							for (integer i = 0; i < DW/8; i = i + 1) begin
								if (PWSTRB[i]) begin
									mem[PADDR[AW-1:APBLSB]][i*8 +: 8] <= PWDATA[i*8 +: 8];
								end
							end
						end else begin
							// Read
							PRDATA <= mem[PADDR[AW-1:APBLSB]];
						end
						state <= S_IDLE;
					end
				end
				default: begin
					state <= S_IDLE;
					PREADY <= 1'b1;
				end
			endcase
		end
	end

endmodule
