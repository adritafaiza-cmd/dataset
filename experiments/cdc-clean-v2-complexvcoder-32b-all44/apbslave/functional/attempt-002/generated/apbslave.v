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
	reg [1:0] state;
	reg [1:0] next_state;
	reg [DW-1:0] local_PRDATA;
	reg local_PSLVERR;

	// States
	localparam IDLE = 2'b00;
	localparam SETUP = 2'b01;
	localparam ACCESS = 2'b10;

	// State machine
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			state <= IDLE;
			PREADY <= 0;
			PRDATA <= 0;
			local_PSLVERR <= 0;
		end else begin
			state <= next_state;
			if (state == ACCESS) begin
				PREADY <= 1;
			end else begin
				PREADY <= 0;
			end
			if (state == ACCESS && !PWRITE) begin
				PRDATA <= local_PRDATA;
			end
			local_PSLVERR <= 0; // Keep PSLVERR low for in-range accesses
		end
	end

	// Next state logic
	always @(*) begin
		next_state = state;
		case (state)
			IDLE: begin
				if (PSEL && PENABLE) begin
					next_state = ACCESS;
				end else if (PSEL && !PENABLE) begin
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

	// Memory model (simple array for demonstration)
	reg [DW-1:0] mem [(1<<AW)-1:0];

	// Memory read/write logic
	always @(posedge PCLK) begin
		if (state == ACCESS) begin
			if (PWRITE) begin
				for (integer i = 0; i < DW/8; i = i + 1) begin
					if (PWSTRB[i]) begin
						mem[PADDR][i*8 +: 8] <= PWDATA[i*8 +: 8];
					end
				end
			end else begin
				local_PRDATA <= mem[PADDR];
			end
		end
	end

	// PSLVERR output
	assign PSLVERR = local_PSLVERR;

endmodule
