module apbslave #(
		parameter	C_APB_ADDR_WIDTH = 12,
		parameter	C_APB_DATA_WIDTH = 32,
		localparam	AW = C_APB_ADDR_WIDTH,
		localparam	DW = C_APB_DATA_WIDTH,
		localparam	APBLSB = $clog2(C_APB_DATA_WIDTH)-3
	) (
		input	wire			PCLK,
		input	wire			PRESETn,
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
	reg [1:0] state, next_state;
	reg [DW-1:0] data_reg;
	reg pslverr_reg;
	reg [DW-1:0] prdata_reg;

	// State encoding
	localparam IDLE = 2'b00;
	localparam ACCESS = 2'b01;

	// State machine
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
				if (PSEL && PENABLE) begin
					next_state = ACCESS;
				end
			end
			ACCESS: begin
				next_state = IDLE;
			end
		endcase
	end

	// Output logic
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			PREADY <= 0;
			PRDATA <= 0;
			pslverr_reg <= 0;
		end else begin
			case (state)
				IDLE: begin
					PREADY <= 0;
				end
				ACCESS: begin
					PREADY <= 1;
					if (PWRITE) begin
						for (integer i = 0; i < DW/8; i = i + 1) begin
							if (PWSTRB[i]) begin
								data_reg[i*8 +: 8] <= PWDATA[i*8 +: 8];
							end
						end
					end else begin
						PRDATA <= data_reg;
					end
				end
			endcase
		end
	end

	// PSLVERR is low for in-range accesses
	assign PSLVERR = 0;

endmodule
