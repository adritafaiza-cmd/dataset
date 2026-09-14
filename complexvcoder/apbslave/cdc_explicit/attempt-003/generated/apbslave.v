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

	localparam	IDLE = 2'b00,
				READ = 2'b01,
				WRITE = 2'b10;

	reg [1:0] state;
	reg [DW-1:0] data_reg;
	reg [AW-1:0] addr_reg;
	reg ready_reg;
	reg slverr_reg;

	always @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			state <= IDLE;
			data_reg <= 0;
			addr_reg <= 0;
			ready_reg <= 0;
			slverr_reg <= 0;
			PREADY <= 0;
			PRDATA <= 0;
			PSLVERR <= 0;
		end else begin
			case (state)
				IDLE:
					if (PSEL && PENABLE) begin
						addr_reg <= PADDR;
						if (PWRITE) begin
							state <= WRITE;
						end else begin
							state <= READ;
						end
					end else begin
						PREADY <= 0;
					end

				READ:
					begin
						PREADY <= 1;
						PRDATA <= data_reg;
						slverr_reg <= 0; // May stay low for in-range accesses
						state <= IDLE;
					end

				WRITE:
					begin
						data_reg[PWSTRB] <= PWDATA[PWSTRB];
						PREADY <= 1;
						state <= IDLE;
					end

				default:
					state <= IDLE;
			endcase
		end
	end

endmodule
