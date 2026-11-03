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
	reg [DW-1:0] data_reg [0:(1<<AW)-1]; // Memory array
	reg [1:0] state, next_state;
	reg [DW-1:0] read_data;
	reg [AW-1:0] AW;
	reg [DW-1:0] DW;
	reg [1:0] APBLSB;

	// State definitions
	localparam IDLE = 2'b00;
	localparam SETUP = 2'b01;
	localparam ACCESS = 2'b10;

	// State machine
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			state <= IDLE;
			data_reg <= '{default:0}; // Reset memory array
			PRDATA <= 0;
			PREADY <= 0;
		end else begin
			state <= next_state;
		end
	end

	// Next state logic
	always @(*) begin
		next_state = state;
		case (state)
			IDLE: begin
				if (PSEL && !PENABLE)
					next_state = SETUP;
			end
			SETUP: begin
				if (PSEL && PENABLE)
					next_state = ACCESS;
			end
			ACCESS: begin
				next_state = IDLE;
			end
			default: begin
				next_state = IDLE;
			end
		endcase
	end

	// Output logic
	always @(posedge PCLK) begin
		if (state == ACCESS) begin
			if (PWRITE) begin
				for (int i = 0; i < DW/8; i = i + 1) begin
					if (PWSTRB[i])
						data_reg[PADDR][8*i +: 8] <= PWDATA[8*i +: 8];
				end
				PRDATA <= 0;
			end else begin
				PRDATA <= data_reg[PADDR];
			end
			PREADY <= 1;
		end else begin
			PREADY <= 0;
		end
	end

	// Error signal
	assign PSLVERR = (state == ACCESS) && (PADDR >= (1<<AW));

endmodule
