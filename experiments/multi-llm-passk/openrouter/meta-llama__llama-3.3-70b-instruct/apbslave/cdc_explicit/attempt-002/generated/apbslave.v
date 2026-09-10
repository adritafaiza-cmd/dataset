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

	reg [DW-1:0] data;
	reg [AW-1:0] addr;
	reg write;
	reg [DW/8-1:0] wstrb;
	reg [2:0] prot;
	reg slv_err;
	reg [DW-1:0] rdata;

	always @(posedge PCLK or negedge PRESETn) begin
		if (~PRESETn) begin
			PREADY <= 1'b0;
			PRDATA <= {DW{1'b0}};
			PSLVERR <= 1'b0;
			slv_err <= 1'b0;
			rdata <= {DW{1'b0}};
		end else if (PSEL) begin
			if (PENABLE) begin
				PREADY <= 1'b1;
				if (PWRITE) begin
					data <= PWDATA;
					addr <= PADDR;
					write <= 1'b1;
					wstrb <= PWSTRB;
					prot <= PPROT;
				end else begin
					write <= 1'b0;
				end
			end else begin
				if (write) begin
					// Handle write operation
					if (PADDR[AW-1:APBLSB] == {AW-APBLSB{1'b0}}) begin
						// In-range access
						slv_err <= 1'b0;
						if (PWSTRB[DW/8-1] == 1'b1) begin
							// Write to register
							rdata[DW-1:DW/2] <= PWDATA[DW-1:DW/2];
						end
						if (PWSTRB[DW/8-2] == 1'b1) begin
							// Write to register
							rdata[DW/2-1:DW/4] <= PWDATA[DW/2-1:DW/4];
						end
						if (PWSTRB[DW/8-3] == 1'b1) begin
							// Write to register
							rdata[DW/4-1:0] <= PWDATA[DW/4-1:0];
						end
					end else begin
						// Out-of-range access
						slv_err <= 1'b1;
					end
				end else begin
					// Handle read operation
					if (PADDR[AW-1:APBLSB] == {AW-APBLSB{1'b0}}) begin
						// In-range access
						slv_err <= 1'b0;
						PRDATA <= rdata;
					end else begin
						// Out-of-range access
						slv_err <= 1'b1;
						PRDATA <= {DW{1'b0}};
					end
				end
				PREADY <= 1'b0;
			end
		end else begin
			PREADY <= 1'b0;
		end
	end

	assign PSLVERR = slv_err;

endmodule
