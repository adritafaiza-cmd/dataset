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

	// Internal state
	reg [DW-1:0] mem [0:2**AW-1];
	reg [DW-1:0] rdata_reg;
	reg           rdata_valid;

	// APB state machine
	reg [1:0] state;
	localparam S_IDLE = 2'd0;
	localparam S_SETUP = 2'd1;
	localparam S_ACCESS = 2'd2;

	// PSLVERR is always low for in-range accesses
	assign PSLVERR = 1'b0;

	// PREADY is high when in IDLE or when access phase completes
	// In APB, PREADY can be asserted during setup or access phase
	// For a simple slave, we assert PREADY during setup phase to indicate ready
	// and complete the transfer in access phase
	// Standard APB: PREADY high during setup means slave is ready, transfer completes in access
	// PREADY high during access means transfer is complete

	// We'll use a simple approach:
	// - In IDLE: PREADY = 1
	// - In SETUP: PREADY = 1 (slave is ready)
	// - In ACCESS: PREADY = 1 (transfer completes)

	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			state <= S_IDLE;
			PREADY <= 1'b1;
			rdata_reg <= {DW{1'b0}};
			rdata_valid <= 1'b0;
		end else begin
			case (state)
				S_IDLE: begin
					PREADY <= 1'b1;
					if (PSEL) begin
						state <= S_SETUP;
					end
				end
				S_SETUP: begin
					PREADY <= 1'b1;
					if (PENABLE) begin
						state <= S_ACCESS;
						if (PWRITE) begin
							// Perform write
							for (integer i = 0; i < DW/8; i = i + 1) begin
								if (PWSTRB[i]) begin
									mem[PADDR[AW-1:APBLSB]][i*8 +: 8] <= PWDATA[i*8 +: 8];
								end
							end
						end else begin
							// Perform read
							rdata_reg <= mem[PADDR[AW-1:APBLSB]];
							rdata_valid <= 1'b1;
						end
					end
				end
				S_ACCESS: begin
					PREADY <= 1'b1;
					state <= S_IDLE;
				end
				default: begin
					state <= S_IDLE;
					PREADY <= 1'b1;
				end
			endcase
		end
	end

	// Output data
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			PRDATA <= {DW{1'b0}};
		end else begin
			if (rdata_valid) begin
				PRDATA <= rdata_reg;
				rdata_valid <= 1'b0;
			end
		end
	end

endmodule
