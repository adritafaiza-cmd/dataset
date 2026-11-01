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
	reg [DW-1:0] mem [0:2**AW-1];

	// APB state machine
	reg setup;
	reg access;

	// Latch inputs during setup phase
	reg [AW-1:0] addr_latch;
	reg write_latch;
	reg [DW-1:0] wdata_latch;
	reg [DW/8-1:0] wstrb_latch;

	// Read data register
	reg [DW-1:0] rdata_reg;

	// PSLVERR is always low for in-range accesses
	assign PSLVERR = 1'b0;

	// State machine
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			setup <= 1'b1;
			access <= 1'b0;
			PREADY <= 1'b0;
			addr_latch <= {AW{1'b0}};
			write_latch <= 1'b0;
			wdata_latch <= {DW{1'b0}};
			wstrb_latch <= {(DW/8){1'b0}};
			rdata_reg <= {DW{1'b0}};
		end else begin
			if (setup) begin
				if (PSEL) begin
					// Latch inputs during setup
					addr_latch <= PADDR;
					write_latch <= PWRITE;
					wdata_latch <= PWDATA;
					wstrb_latch <= PWSTRB;
					
					// Prepare read data if it's a read
					if (!PWRITE) begin
						rdata_reg <= mem[PADDR[AW-1:APBLSB]];
					end
					
					// Transition to access phase
					setup <= 1'b0;
					access <= 1'b1;
					PREADY <= 1'b1;
				end else begin
					// Stay in setup, not ready
					PREADY <= 1'b0;
				end
			end else if (access) begin
				if (PSEL && PENABLE) begin
					// Perform write if it's a write
					if (write_latch) begin
						// Apply write strobes
						for (genvar i = 0; i < DW/8; i = i + 1) begin : write_loop
							if (wstrb_latch[i]) begin
								mem[addr_latch[AW-1:APBLSB]][i*8 +: 8] <= wdata_latch[i*8 +: 8];
							end
						end
					end
					
					// Return to setup phase
					setup <= 1'b1;
					access <= 1'b0;
					PREADY <= 1'b0;
				end else begin
					// Stay in access, remain ready
					PREADY <= 1'b1;
				end
			end
		end
	end

	// Output read data
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			PRDATA <= {DW{1'b0}};
		end else begin
			PRDATA <= rdata_reg;
		end
	end

endmodule
