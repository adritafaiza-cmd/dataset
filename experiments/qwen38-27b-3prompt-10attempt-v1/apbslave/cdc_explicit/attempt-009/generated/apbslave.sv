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

	// Latch address and write data during setup phase
	reg [AW-1:0] addr_latch;
	reg [DW-1:0] wdata_latch;
	reg [DW/8-1:0] wstrb_latch;
	reg write_latch;

	// PSLVERR output
	assign PSLVERR = 1'b0;

	// State machine logic
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			state <= S_IDLE;
			PREADY <= 1'b0;
			addr_latch <= {AW{1'b0}};
			wdata_latch <= {DW{1'b0}};
			wstrb_latch <= {(DW/8){1'b0}};
			write_latch <= 1'b0;
			PRDATA <= {DW{1'b0}};
		end else begin
			case (state)
				S_IDLE: begin
					PREADY <= 1'b0;
					if (PSEL) begin
						state <= S_SETUP;
						addr_latch <= PADDR;
						wdata_latch <= PWDATA;
						wstrb_latch <= PWSTRB;
						write_latch <= PWRITE;
					end
				end
				S_SETUP: begin
					PREADY <= 1'b0;
					if (PENABLE) begin
						state <= S_ACCESS;
					end else begin
						state <= S_IDLE;
					end
				end
				S_ACCESS: begin
					PREADY <= 1'b1;
					if (PENABLE) begin
						if (write_latch) begin
							// Perform write
							for (genvar i = 0; i < DW/8; i = i + 1) begin : write_loop
								if (wstrb_latch[i]) begin
									mem[addr_latch[AW-1:APBLSB]][i*8 +: 8] <= wdata_latch[i*8 +: 8];
								end
							end
						end else begin
							// Perform read
							PRDATA <= mem[addr_latch[AW-1:APBLSB]];
						end
						state <= S_IDLE;
					end else begin
						state <= S_IDLE;
					end
				end
				default: begin
					state <= S_IDLE;
					PREADY <= 1'b0;
				end
			endcase
		end
	end

endmodule
