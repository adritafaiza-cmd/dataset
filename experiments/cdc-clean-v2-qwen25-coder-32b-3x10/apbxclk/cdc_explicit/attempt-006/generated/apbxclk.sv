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

	// Synchronizers for reset
	reg s_reset_sync1, s_reset_sync2;
	reg m_reset_sync1, m_reset_sync2;

	// Synchronizers for control signals
	reg s_apb_psel_sync1, s_apb_psel_sync2;
	reg s_apb_penable_sync1, s_apb_penable_sync2;

	// Synchronizers for data signals
	reg [AW-1:0] s_apb_paddr_sync1, s_apb_paddr_sync2;
	reg s_apb_pwrite_sync1, s_apb_pwrite_sync2;
	reg [DW-1:0] s_apb_pwdata_sync1, s_apb_pwdata_sync2;
	reg [DW/8-1:0] s_apb_pwstrb_sync1, s_apb_pwstrb_sync2;
	reg [2:0] s_apb_pprot_sync1, s_apb_pprot_sync2;

	// Registered signals for crossing
	reg [AW-1:0] m_apb_paddr_reg;
	reg m_apb_pwrite_reg;
	reg [DW-1:0] m_apb_pwdata_reg;
	reg [DW/8-1:0] m_apb_pwstrb_reg;
	reg [2:0] m_apb_pprot_reg;

	// Control signals for transaction handling
	reg s_transaction_started;
	reg m_transaction_started;

	// Response signals
	reg [DW-1:0] s_apb_prdata_reg;
	reg s_apb_pslverr_reg;

	// Reset synchronization
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_reset_sync1 <= 1'b1;
			s_reset_sync2 <= 1'b1;
		end else begin
			s_reset_sync1 <= 1'b0;
			s_reset_sync2 <= s_reset_sync1;
		end
	end

	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_reset_sync1 <= 1'b1;
			m_reset_sync2 <= 1'b1;
		end else begin
			m_reset_sync1 <= 1'b0;
			m_reset_sync2 <= m_reset_sync1;
		end
	end

	assign M_PRESETn = ~m_reset_sync2;

	// Control signal synchronization
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_apb_psel_sync1 <= 1'b0;
			s_apb_psel_sync2 <= 1'b0;
			s_apb_penable_sync1 <= 1'b0;
			s_apb_penable_sync2 <= 1'b0;
		end else begin
			s_apb_psel_sync1 <= S_APB_PSEL;
			s_apb_psel_sync2 <= s_apb_psel_sync1;
			s_apb_penable_sync1 <= S_APB_PENABLE;
			s_apb_penable_sync2 <= s_apb_penable_sync1;
		end
	end

	// Data signal synchronization
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_apb_paddr_sync1 <= {AW{1'b0}};
			s_apb_paddr_sync2 <= {AW{1'b0}};
			s_apb_pwrite_sync1 <= 1'b0;
			s_apb_pwrite_sync2 <= 1'b0;
			s_apb_pwdata_sync1 <= {DW{1'b0}};
			s_apb_pwdata_sync2 <= {DW{1'b0}};
			s_apb_pwstrb_sync1 <= {DW/8{1'b0}};
			s_apb_pwstrb_sync2 <= {DW/8{1'b0}};
			s_apb_pprot_sync1 <= 3'b0;
			s_apb_pprot_sync2 <= 3'b0;
		end else begin
			s_apb_paddr_sync1 <= S_APB_PADDR;
			s_apb_paddr_sync2 <= s_apb_paddr_sync1;
			s_apb_pwrite_sync1 <= S_APB_PWRITE;
			s_apb_pwrite_sync2 <= s_apb_pwrite_sync1;
			s_apb_pwdata_sync1 <= S_APB_PWDATA;
			s_apb_pwdata_sync2 <= s_apb_pwdata_sync1;
			s_apb_pwstrb_sync1 <= S_APB_PWSTRB;
			s_apb_pwstrb_sync2 <= s_apb_pwstrb_sync1;
			s_apb_pprot_sync1 <= S_APB_PPROT;
			s_apb_pprot_sync2 <= s_apb_pprot_sync1;
		end
	end

	// Register crossing for payload and response fields
	generate
		if (OPT_REGISTERED == 1'b1) begin
			always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
				if (!M_PRESETn) begin
					m_apb_paddr_reg <= {AW{1'b0}};
					m_apb_pwrite_reg <= 1'b0;
					m_apb_pwdata_reg <= {DW{1'b0}};
					m_apb_pwstrb_reg <= {DW/8{1'b0}};
					m_apb_pprot_reg <= 3'b0;
				end else begin
					if (!m_transaction_started && s_apb_psel_sync2 && s_apb_penable_sync2) begin
						m_apb_paddr_reg <= s_apb_paddr_sync2;
						m_apb_pwrite_reg <= s_apb_pwrite_sync2;
						m_apb_pwdata_reg <= s_apb_pwdata_sync2;
						m_apb_pwstrb_reg <= s_apb_pwstrb_sync2;
						m_apb_pprot_reg <= s_apb_pprot_sync2;
						m_transaction_started <= 1'b1;
					end
				end
			end
		end else begin
			assign m_apb_paddr_reg = s_apb_paddr_sync2;
			assign m_apb_pwrite_reg = s_apb_pwrite_sync2;
			assign m_apb_pwdata_reg = s_apb_pwdata_sync2;
			assign m_apb_pwstrb_reg = s_apb_pwstrb_sync2;
			assign m_apb_pprot_reg = s_apb_pprot_sync2;
			always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
				if (!M_PRESETn) begin
					m_transaction_started <= 1'b0;
				end else begin
					if (!m_transaction_started && s_apb_psel_sync2 && s_apb_penable_sync2) begin
						m_transaction_started <= 1'b1;
					end
				end
			end
		end
	endgenerate

	// Control signals for M_APB
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
		end else begin
			if (m_transaction_started && M_APB_PREADY) begin
				M_APB_PSEL <= 1'b0;
				M_APB_PENABLE <= 1'b0;
				m_transaction_started <= 1'b0;
			end else if (m_transaction_started) begin
				M_APB_PSEL <= 1'b1;
				M_APB_PENABLE <= 1'b1;
			end else begin
				M_APB_PSEL <= 1'b0;
				M_APB_PENABLE <= 1'b0;
			end
		end
	end

	// Control signals for S_APB
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			S_APB_PREADY <= 1'b0;
			s_transaction_started <= 1'b0;
		end else begin
			if (s_transaction_started && M_APB_PREADY) begin
				S_APB_PREADY <= 1'b1;
				s_transaction_started <= 1'b0;
			end else if (s_apb_psel_sync2 && s_apb_penable_sync2 && !s_transaction_started) begin
				s_transaction_started <= 1'b1;
				S_APB_PREADY <= 1'b0;
			end else begin
				S_APB_PREADY <= 1'b0;
			end
		end
	end

	// Response signals
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_apb_prdata_reg <= {DW{1'b0}};
			s_apb_pslverr_reg <= 1'b0;
		end else if (M_APB_PREADY) begin
			s_apb_prdata_reg <= M_APB_PRDATA;
			s_apb_pslverr_reg <= M_APB_PSLVERR;
		end
	end

	assign S_APB_PRDATA = s_apb_prdata_reg;
	assign S_APB_PSLVERR = s_apb_pslverr_reg;

	assign M_APB_PADDR = m_apb_paddr_reg;
	assign M_APB_PWRITE = m_apb_pwrite_reg;
	assign M_APB_PWDATA = m_apb_pwdata_reg;
	assign M_APB_PWSTRB = m_apb_pwstrb_reg;
	assign M_APB_PPROT = m_apb_pprot_reg;

endmodule
