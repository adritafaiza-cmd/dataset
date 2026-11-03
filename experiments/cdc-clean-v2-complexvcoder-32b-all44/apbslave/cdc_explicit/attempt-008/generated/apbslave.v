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

	// Internal registers
	reg [1:0] state;
	reg [1:0] next_state;
	reg [DW-1:0] reg_prdata;
	reg reg_pslverr;

	// State definitions
	localparam IDLE = 2'b00;
	localparam SETUP = 2'b01;
	localparam ACCESS = 2'b10;

	// Memory model for simplicity (1-word memory)
	reg [DW-1:0] memory;

	// State transition logic
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			state <= IDLE;
		end else begin
			state <= next_state;
		end
	end

	// Next state logic
	always @(*) begin
		next_state = state;
		case (state)
			IDLE: begin
				if (PSEL && !PENABLE) begin
					next_state = SETUP;
				end
			end
			SETUP: begin
				if (PSEL && PENABLE) begin
					next_state = ACCESS;
				end
			end
			ACCESS: begin
				next_state = IDLE;
			end
		endcase
	end

	// Output and memory handling
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			PREADY <= 0;
			PRDATA <= 0;
			reg_pslverr <= 0;
		end else begin
			case (state)
				IDLE: begin
					PREADY <= 0;
					PRDATA <= 0;
					reg_pslverr <= 0;
				end
				SETUP: begin
					PREADY <= 0;
				end
				ACCESS: begin
					PREADY <= 1;
					if (PWRITE) begin
						for (integer i = 0; i < DW/8; i = i + 1) begin
							if (PWSTRB[i]) begin
								memory[i*8 +: 8] <= PWDATA[i*8 +: 8];
							end
						end
					end else begin
						PRDATA <= memory;
					end
					reg_pslverr <= 0; // PSLVERR stays low for in-range accesses
				end
			endcase
		end
	end

	// PSLVERR output
	assign PSLVERR = reg_pslverr;

endmodule
