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

	// Address decode
	wire [AW-APBLSB-1:0] addr_index = PADDR[AW-1:APBLSB];

	// Write enable
	wire write_en = PSEL & PENABLE & PWRITE;

	// Read enable
	wire read_en = PSEL & PENABLE & ~PWRITE;

	// Write data with strobes
	reg [DW-1:0] write_data;
	integer i;
	always @* begin
		write_data = PWDATA;
		for (i = 0; i < DW/8; i = i + 1) begin
			if (!PWSTRB[i]) begin
				write_data[i*8 +: 8] = 8'h00;
			end
		end
	end

	// Sequential logic
	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			PREADY <= 1'b0;
			PRDATA <= {DW{1'b0}};
		end else begin
			// PREADY is asserted during access phase
			if (PSEL & PENABLE) begin
				PREADY <= 1'b1;
			end else begin
				PREADY <= 1'b0;
			end

			// Write to memory
			if (write_en) begin
				mem[addr_index] <= write_data;
			end

			// Read from memory
			if (read_en) begin
				PRDATA <= mem[addr_index];
			end
		end
	end

	// PSLVERR is always low for in-range accesses
	assign PSLVERR = 1'b0;

endmodule
