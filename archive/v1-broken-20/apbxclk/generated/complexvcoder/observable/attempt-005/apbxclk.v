module apbxclk #(
	parameter	C_APB_ADDR_WIDTH = 12,
	parameter	C_APB_DATA_WIDTH = 32,
	parameter [0:0]	OPT_REGISTERED = 1'b0,
	localparam	AW = C_APB_ADDR_WIDTH,
	localparam	DW = C_APB_DATA_WIDTH
) (
		input	wire			S_APB_PCLK, S_PRESETn,
		input	wire			S_APB_PSEL,
		input	wire			S_APB_PENABLE,
		output	reg			S_APB_PREADY,
		input	wire	[AW-1:0]	S_APB_PADDR,
		input	wire			S_APB_PWRITE,
		input	wire	[DW-1:0]	S_APB_PWDATA,
		input	wire	[DW/8-1:0]	S_APB_PWSTRB,
		input	wire	[2:0]		S_APB_PPROT,
		output	wire	[DW-1:0]	S_APB_PRDATA,
		output	wire			S_APB_PSLVERR,
		input	wire			M_APB_PCLK,
		output	reg			M_PRESETn,
		output	reg			M_APB_PSEL,
		output	reg			M_APB_PENABLE,
		input	wire			M_APB_PREADY,
		output	wire	[AW-1:0]	M_APB_PADDR,
		output	wire			M_APB_PWRITE,
		output	wire	[DW-1:0]	M_APB_PWDATA,
		output	wire	[DW/8-1:0]	M_APB_PWSTRB,
		output	wire	[2:0]		M_APB_PPROT,
		input	wire	[DW-1:0]	M_APB_PRDATA,
		input	wire			M_APB_PSLVERR
	);

	// Internal signals
	reg	[AW-1:0]	m_addr;
	reg			m_write;
	reg	[DW-1:0]	m_wdata;
	reg	[DW/8-1:0]	m_wstrb;
	reg	[2:0]		m_prot;
	reg			m_psel;
	reg			m_penable;
	wire			m_pready;
	wire	[DW-1:0]	m_prdata;
	wire			m_pslverr;

	// Clock domain crossing for master signals
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_addr <= 0;
			m_write <= 0;
			m_wdata <= 0;
			m_wstrb <= 0;
			m_prot <= 0;
			m_psel <= 0;
			m_penable <= 0;
		end else begin
			m_addr <= S_APB_PADDR;
			m_write <= S_APB_PWRITE;
			m_wdata <= S_APB_PWDATA;
			m_wstrb <= S_APB_PWSTRB;
			m_prot <= S_APB_PPROT;
			m_psel <= S_APB_PSEL;
			m_penable <= S_APB_PENABLE;
		end
	end

	// Clock domain crossing for slave signals
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			S_APB_PREADY <= 0;
			S_APB_PRDATA <= 0;
			S_APB_PSLVERR <= 0;
		end else begin
			S_APB_PREADY <= m_pready;
			S_APB_PRDATA <= m_prdata;
			S_APB_PSLVERR <= m_pslverr;
		end
	end

	// Instantiate the master and slave bridge modules
	apbxclk_master master_bridge (
		.S_APB_PCLK(S_APB_PCLK),
		.S_PRESETn(S_PRESETn),
		.M_APB_PCLK(M_APB_PCLK),
		.M_APB_PSEL(m_psel),
		.M_APB_PENABLE(m_penable),
		.M_APB_PREADY(m_pready),
		.M_APB_PADDR(m_addr),
		.M_APB_PWRITE(m_write),
		.M_APB_PWDATA(m_wdata),
		.M_APB_PWSTRB(m_wstrb),
		.M_APB_PPROT(m_prot),
		.M_APB_PRDATA(m_prdata),
		.M_APB_PSLVERR(m_pslverr)
	);

	apbxclk_slave slave_bridge (
		.S_APB_PCLK(S_APB_PCLK),
		.S_PRESETn(S_PRESETn),
		.S_APB_PSEL(S_APB_PSEL),
		.S_APB_PENABLE(S_APB_PENABLE),
		.S_APB_PREADY(S_APB_PREADY),
		.S_APB_PADDR(S_APB_PADDR),
		.S_APB_PWRITE(S_APB_PWRITE),
		.S_APB_PWDATA(S_APB_PWDATA),
		.S_APB_PWSTRB(S_APB_PWSTRB),
		.S_APB_PPROT(S_APB_PPROT),
		.S_APB_PRDATA(S_APB_PRDATA),
		.S_APB_PSLVERR(S_APB_PSLVERR)
	);

endmodule

module apbxclk_master (
		input	wire			S_APB_PCLK,
		input	wire			S_PRESETn,
		input	wire			M_APB_PCLK,
		output	reg			M_APB_PSEL,
		output	reg			M_APB_PENABLE,
		input	wire			M_APB_PREADY,
		output	reg	[11:0]	M_APB_PADDR,
		output	reg			M_APB_PWRITE,
		output	reg	[31:0]	M_APB_PWDATA,
		output	reg	[3:0]		M_APB_PWSTRB,
		output	reg	[2:0]		M_APB_PPROT,
		input	wire	[31:0]	M_APB_PRDATA,
		input	wire			M_APB_PSLVERR
	);

	// Internal signals
	reg			state;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			M_APB_PSEL <= 0;
			M_APB_PENABLE <= 0;
			state <= 0;
		end else begin
			case (state)
				0: // IDLE
					if (M_APB_PREADY) begin
						M_APB_PSEL <= 1;
						M_APB_PENABLE <= 0;
						state <= 1;
					end
				1: // TRANSFER
					if (M_APB_PREADY) begin
						M_APB_PENABLE <= 1;
						state <= 2;
					end
				2: // WAIT_FOR_READY
					if (!M_APB_PREADY) begin
						M_APB_PENABLE <= 0;
						state <= 0;
					end
			endcase
		end
	end

endmodule

module apbxclk_slave (
		input	wire			S_APB_PCLK,
		input	wire			S_PRESETn,
		input	wire			S_APB_PSEL,
		input	wire			S_APB_PENABLE,
		input	wire			S_APB_PREADY,
		input	wire	[11:0]	S_APB_PADDR,
		input	wire			S_APB_PWRITE,
		input	wire	[31:0]	S_APB_PWDATA,
		input	wire	[3:0]		S_APB_PWSTRB,
		input	wire	[2:0]		S_APB_PPROT,
		output	reg	[31:0]	S_APB_PRDATA,
		output	reg			S_APB_PSLVERR
	);

	// Internal signals
	reg			state;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			S_APB_PRDATA <= 0;
			S_APB_PSLVERR <= 0;
			state <= 0;
		end else begin
			case (state)
				0: // IDLE
					if (S_APB_PSEL && S_APB_PENABLE && S_APB_PREADY) begin
						S_APB_PRDATA <= S_APB_PWDATA;
						S_APB_PSLVERR <= 0;
						state <= 1;
					end
				1: // RESPONSE
					state <= 0;
			endcase
		end
	end

endmodule
