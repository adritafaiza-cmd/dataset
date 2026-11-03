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

	typedef enum reg [1:0] {IDLE, SETUP, ACCESS} state_t;
	
	reg [1:0] state, next_state;
	reg [DW-1:0] data_reg;
	reg ready_reg, error_reg;

	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			state <= IDLE;
			data_reg <= 0;
			ready_reg <= 0;
			error_reg <= 0;
		end else begin
			state <= next_state;
			if (state == ACCESS && PWRITE)
				data_reg <= PWDATA;
			ready_reg <= (state == ACCESS);
			error_reg <= 0; // Assuming no error for simplicity
		end
	end

	always @(*) begin
		next_state = state;
		case (state)
			IDLE: begin
				if (PSEL && !PENABLE)
					next_state = SETUP;
			end
			SETUP: begin
				if (PENABLE)
					next_state = ACCESS;
			end
			ACCESS: begin
				next_state = IDLE;
			end
		endcase
	end

	assign PREADY = ready_reg;
	assign PRDATA = data_reg;
	assign PSLVERR = error_reg;

endmodule
