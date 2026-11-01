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

	// Internal register file
	reg [DW-1:0] mem [0:(2**(AW-APBLSB)-1)];

	// State machine
	reg [1:0] state;
	localparam S_IDLE = 2'd0;
	localparam S_SETUP = 2'd1;
	localparam S_ACCESS = 2'd2;

	// Latch signals during setup phase
	reg [AW-1:0] addr_latched;
	reg write_latched;
	reg [DW-1:0] wdata_latched;
	reg [DW/8-1:0] wstrb_latched;

	// PSLVERR output
	assign PSLVERR = 1'b0;

	// Main state machine
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			state <= S_IDLE;
			PREADY <= 1'b0;
			PRDATA <= {DW{1'b0}};
			addr_latched <= {AW{1'b0}};
			write_latched <= 1'b0;
			wdata_latched <= {DW{1'b0}};
			wstrb_latched <= {(DW/8){1'b0}};
		end else begin
			case (state)
				S_IDLE: begin
					PREADY <= 1'b0;
					if (PSEL) begin
						state <= S_SETUP;
						addr_latched <= PADDR;
						write_latched <= PWRITE;
						wdata_latched <= PWDATA;
						wstrb_latched <= PWSTRB;
					end
				end
				S_SETUP: begin
					PREADY <= 1'b0;
					if (PENABLE) begin
						state <= S_ACCESS;
					end else begin
						state <= S_IDLE;
						PREADY <= 1'b1;
					end
				end
				S_ACCESS: begin
					PREADY <= 1'b1;
					if (write_latched) begin
						// Perform write
						for (integer i = 0; i < DW/8; i = i + 1) begin
							if (wstrb_latched[i]) begin
								mem[addr_latched[AW-1:APBLSB]][i*8 +: 8] <= wdata_latched[i*8 +: 8];
							end
						end
					end else begin
						// Perform read
						PRDATA <= mem[addr_latched[AW-1:APBLSB]];
					end
					state <= S_IDLE;
				end
				default: begin
					state <= S_IDLE;
					PREADY <= 1'b0;
				end
			endcase
		end
	end

endmodule
