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

	// Internal signals
	reg [DW-1:0] memory [0:(1<<AW)-1];
	reg [2:0] state;

	// State definitions
	localparam IDLE = 3'b000;
	localparam SETUP = 3'b001;
	localparam ACCESS = 3'b010;
	localparam DONE = 3'b011;

	// State machine
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			state <= IDLE;
			PREADY <= 0;
			PRDATA <= 0;
			PSLVERR <= 0;
		end else begin
			case (state)
				IDLE: begin
					if (PSEL && PENABLE) begin
						state <= SETUP;
						PREADY <= 0;
					end
				end
				SETUP: begin
					if (PSEL && PENABLE) begin
						if (PWRITE) begin
							// Write operation
							integer i;
							for (i = 0; i < DW/8; i = i + 1) begin
								if (PWSTRB[i]) begin
									memory[PADDR][i*8 +: 8] <= PWDATA[i*8 +: 8];
								end
							end
						end else begin
							// Read operation
							PRDATA <= memory[PADDR];
						end
						state <= ACCESS;
					end else begin
						state <= IDLE;
					end
				end
				ACCESS: begin
					PREADY <= 1;
					if (!PSEL || !PENABLE) begin
						state <= IDLE;
					end
				end
				default: state <= IDLE;
			endcase
		end
	end

endmodule
