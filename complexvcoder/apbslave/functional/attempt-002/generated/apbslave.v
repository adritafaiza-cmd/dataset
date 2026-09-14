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

reg [DW-1:0] mem [0:(1<<AW)-1];
reg [2:0] state;

parameter IDLE = 3'b000;
parameter SETUP = 3'b001;
parameter ACCESS = 3'b010;
parameter DONE = 3'b011;

always @(posedge PCLK or negedge PRESETn) begin
	if (!PRESETn) begin
		PREADY <= 1'b0;
		PRDATA <= 0;
		PSLVERR <= 1'b0;
		state <= IDLE;
	end else begin
		case (state)
			IDLE: begin
				PREADY <= 1'b0;
				PRDATA <= 0;
				PSLVERR <= 1'b0;
				if (PSEL && PENABLE) begin
					state <= SETUP;
				end
			end
			SETUP: begin
				PREADY <= 1'b0;
				PRDATA <= 0;
				PSLVERR <= 1'b0;
				if (PSEL && PENABLE) begin
					if (PWRITE) begin
						state <= ACCESS;
					end else begin
						PRDATA <= mem[PADDR];
						state <= DONE;
					end
				end else begin
					state <= IDLE;
				end
			end
			ACCESS: begin
				PREADY <= 1'b1;
				PRDATA <= 0;
				PSLVERR <= 1'b0;
				if (!PSEL || !PENABLE) begin
					state <= IDLE;
				end else begin
					if (PWRITE) begin
						for (int i = 0; i < DW/8; i++) begin
							if (PWSTRB[i]) begin
								mem[PADDR][i*8 +: 8] <= PWDATA[i*8 +: 8];
							end
						end
					end
					state <= DONE;
				end
			end
			DONE: begin
				PREADY <= 1'b1;
				PRDATA <= mem[PADDR];
				PSLVERR <= 1'b0;
				if (!PSEL || !PENABLE) begin
					state <= IDLE;
				end else begin
					state <= SETUP;
				end
			end
		endcase
	end
end

endmodule
