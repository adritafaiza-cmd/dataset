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
	reg	[DW-1:0]	data_reg;
	reg			ready_reg;
	reg			slverr_reg;
	reg	[1:0]		state;
	reg	[1:0]		next_state;

	// State definitions
	localparam	IDLE = 2'b00;
	localparam	ACCESS = 2'b01;

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
		case (state)
			IDLE: begin
				if (PSEL && PENABLE)
					next_state = ACCESS;
				else
					next_state = IDLE;
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
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			PREADY <= 1'b0;
			PRDATA <= {DW{1'b0}};
			PSLVERR <= 1'b0;
		end else begin
			case (state)
				IDLE: begin
					if (PSEL && PENABLE) begin
						PREADY <= 1'b1;
						if (PWRITE) begin
							// Perform write operation using PWSTRB
							for (integer i = 0; i < DW/8; i = i + 1) begin
								if (PWSTRB[i]) begin
									data_reg[i*8 +: 8] <= PWDATA[i*8 +: 8];
								end
							end
						end else begin
							// Perform read operation
							PRDATA <= data_reg;
						end
					end else begin
						PREADY <= 1'b0;
					end
				end
				ACCESS: begin
					PREADY <= 1'b0;
				end
			endcase
		end
	end

	// PSLVERR is low for in-range accesses
	assign PSLVERR = 1'b0;

endmodule
