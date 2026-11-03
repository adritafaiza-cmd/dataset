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
	reg	[1:0]			state, next_state;
	reg	[DW-1:0]		prdata_reg;
	reg	[DW-1:0]		write_data;
	reg				pready_reg;
	reg				pslverr_reg;

	// Memory array
	reg [DW-1:0]		memory [0:(1<<AW)-1];

	// State machine
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			state <= 2'b00; // IDLE
			PREADY <= 1'b0;
			prdata_reg <= {DW{1'b0}};
			pslverr_reg <= 1'b0;
		end else begin
			state <= next_state;
			if (PREADY && PSEL && PENABLE) begin
				PREADY <= 1'b0;
			end else if (next_state == 2'b01) begin // ACCESS
				PREADY <= 1'b1;
			end
		end
	end

	// Next state logic
	always @(*) begin
		next_state = state;
		case (state)
			2'b00: begin // IDLE
				if (PSEL && PENABLE)
					next_state = 2'b01; // ACCESS
			end
			2'b01: begin // ACCESS
				next_state = 2'b00; // IDLE
			end
		endcase
	end

	// Write data generation
	always @(*) begin
		write_data = PWDATA;
		for (integer i = 0; i < DW/8; i = i + 1) begin
			if (!PWSTRB[i])
				write_data[i*8 +: 8] = memory[PADDR][i*8 +: 8];
		end
	end

	// Memory write operation
	always @(posedge PCLK) begin
		if (PREADY && PSEL && PENABLE && PWRITE) begin
			memory[PADDR] <= write_data;
		end
	end

	// Memory read operation
	always @(posedge PCLK) begin
		if (PREADY && PSEL && PENABLE && !PWRITE) begin
			prdata_reg <= memory[PADDR];
		end
	end

	// Output assignments
	assign PRDATA = prdata_reg;
	assign PSLVERR = pslverr_reg;

endmodule
