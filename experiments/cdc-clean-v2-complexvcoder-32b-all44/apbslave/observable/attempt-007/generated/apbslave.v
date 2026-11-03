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

	// States
	localparam	IDLE = 2'b00;
	localparam	SETUP = 2'b01;
	localparam	ACCESS = 2'b10;

	// Internal signals
	reg [1:0] state, next_state;
	reg [DW-1:0] read_data, write_data;
	reg [DW/8-1:0] write_enable;

	// Memory for storing data
	reg [DW-1:0] mem [0:(1<<AW)-1];

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
		case (state)
			IDLE: begin
				if (PSEL && !PENABLE)
					next_state = SETUP;
				else
					next_state = IDLE;
			end
			SETUP: begin
				if (PSEL && PENABLE)
					next_state = ACCESS;
				else
					next_state = IDLE;
			end
			ACCESS: begin
				next_state = IDLE;
			end
			default: next_state = IDLE;
		endcase
	end

	// Output logic
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			PREADY <= 0;
			PRDATA <= 0;
			PSLVERR <= 0;
		end else begin
			case (state)
				IDLE: begin
					PREADY <= 0;
					PRDATA <= 0;
				end
				SETUP: begin
					PREADY <= 1;
				end
				ACCESS: begin
					if (PWRITE) begin
						for (int i = 0; i < DW/8; i = i + 1) begin
							if (PWSTRB[i]) begin
								mem[PADDR][8*i +: 8] <= PWDATA[8*i +: 8];
							end
						end
					end else begin
						read_data <= mem[PADDR];
					end
					PRDATA <= PWRITE ? 0 : read_data;
				end
			endcase
		end
	end

	// PSLVERR is always deasserted for normal operations
	assign PSLVERR = 0;

endmodule
