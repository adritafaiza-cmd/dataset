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

	// Registers for crossing payload and response fields
	reg [AW-1:0] s_apb_paddr_reg;
	reg [DW-1:0] s_apb_pwdata_reg;
	reg [DW/8-1:0] s_apb_pwstrb_reg;
	reg [2:0] s_apb_pprot_reg;
	reg s_apb_pwrite_reg;

	reg [DW-1:0] m_apb_prdata_reg;
	reg m_apb_pslverr_reg;

	// Control signals
	reg s_apb_psel_ff;
	reg s_apb_penable_ff;
	reg m_apb_psel_ff;
	reg m_apb_penable_ff;

	// Synchronizers for reset
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

	// Synchronizers for control signals
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

	// Source APB interface
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			S_APB_PREADY <= 1'b0;
			s_apb_psel_ff <= 1'b0;
			s_apb_penable_ff <= 1'b0;
			s_apb_paddr_reg <= {AW{1'b0}};
			s_apb_pwdata_reg <= {DW{1'b0}};
			s_apb_pwstrb_reg <= {DW/8{1'b0}};
			s_apb_pprot_reg <= 3'b0;
			s_apb_pwrite_reg <= 1'b0;
		end else begin
			if (s_apb_psel_sync2 && s_apb_penable_sync2 && !s_apb_penable_ff) begin
				s_apb_psel_ff <= 1'b1;
				s_apb_penable_ff <= 1'b1;
				s_apb_paddr_reg <= S_APB_PADDR;
				s_apb_pwdata_reg <= S_APB_PWDATA;
				s_apb_pwstrb_reg <= S_APB_PWSTRB;
				s_apb_pprot_reg <= S_APB_PPROT;
				s_apb_pwrite_reg <= S_APB_PWRITE;
			end else if (M_APB_PREADY) begin
				s_apb_psel_ff <= 1'b0;
				s_apb_penable_ff <= 1'b0;
				S_APB_PREADY <= 1'b1;
			end else begin
				S_APB_PREADY <= 1'b0;
			end
		end
	end

	// Destination APB interface
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			m_apb_psel_ff <= 1'b0;
			m_apb_penable_ff <= 1'b0;
			m_apb_prdata_reg <= {DW{1'b0}};
			m_apb_pslverr_reg <= 1'b0;
		end else begin
			if (s_apb_psel_ff && s_apb_penable_ff && !m_apb_penable_ff) begin
				M_APB_PSEL <= 1'b1;
				M_APB_PENABLE <= 1'b1;
				m_apb_psel_ff <= 1'b1;
				m_apb_penable_ff <= 1'b1;
			end else if (M_APB_PREADY) begin
				M_APB_PSEL <= 1'b0;
				M_APB_PENABLE <= 1'b0;
				m_apb_psel_ff <= 1'b0;
				m_apb_penable_ff <= 1'b0;
				m_apb_prdata_reg <= M_APB_PRDATA;
				m_apb_pslverr_reg <= M_APB_PSLVERR;
			end
		end
	end

	// Output assignments
	assign S_APB_PRDATA = m_apb_prdata_reg;
	assign S_APB_PSLVERR = m_apb_pslverr_reg;

	assign M_APB_PADDR = s_apb_paddr_reg;
	assign M_APB_PWDATA = s_apb_pwdata_reg;
	assign M_APB_PWSTRB = s_apb_pwstrb_reg;
	assign M_APB_PPROT = s_apb_pprot_reg;
	assign M_APB_PWRITE = s_apb_pwrite_reg;

endmodule
