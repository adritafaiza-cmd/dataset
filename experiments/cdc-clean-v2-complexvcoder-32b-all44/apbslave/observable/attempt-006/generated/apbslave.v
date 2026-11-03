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
	reg [1:0] state, next_state;
	reg [DW-1:0] reg_data;
	reg [DW-1:0] byte_mask;

	// State definitions
	localparam IDLE = 2'b00;
	localparam ACCESS = 2'b01;

	// State machine
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			state <= IDLE;
			PREADY <= 0;
			PRDATA <= 0;
		end else begin
			state <= next_state;
			if (state == ACCESS) begin
				PREADY <= 0;
			end
		end
	end

	// Next state logic
	always @(*) begin
		next_state = state;
		case (state)
			IDLE: begin
				if (PSEL && !PENABLE) begin
					next_state = ACCESS;
					PREADY = 1;
				end
			end
			ACCESS: begin
				next_state = IDLE;
			end
		endcase
	end

	// Byte mask generation
	always @(*) begin
		byte_mask = 0;
		for (int i = 0; i < DW/8; i = i + 1) begin
			if (PWSTRB[i])
				byte_mask[(i+1)*8-1 -: 8] = 8'b11111111;
		end
	end

	// Write operation
	always @(posedge PCLK) begin
		if (state == ACCESS && PWRITE) begin
			reg_data <= (reg_data & ~byte_mask) | (PWDATA & byte_mask);
		end
	end

	// Read operation
	always @(posedge PCLK) begin
		if (state == ACCESS && !PWRITE) begin
			PRDATA <= reg_data;
		end
	end

	// Always deassert PSLVERR
	assign PSLVERR = 0;

endmodule
