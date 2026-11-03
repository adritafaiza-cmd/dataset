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
	reg [1:0] s_reset_sync;
	reg [1:0] m_reset_sync;

	// Synchronizers for APB signals
	reg [1:0] s_apb_psel_sync;
	reg [1:0] s_apb_penable_sync;

	// Registers for crossing
	reg [AW-1:0] s_apb_paddr_reg;
	reg [DW-1:0] s_apb_pwdata_reg;
	reg [DW/8-1:0] s_apb_pwstrb_reg;
	reg [2:0] s_apb_pprot_reg;
	reg s_apb_pwrite_reg;

	// Registers for response
	reg [DW-1:0] m_apb_prdata_reg;
	reg m_apb_pslverr_reg;

	// Control signals
	reg s_apb_request;
	reg m_apb_request;
	reg m_apb_response;

	// Synchronizers for reset
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_reset_sync <= 2'b00;
		end else begin
			s_reset_sync <= {s_reset_sync[0], 1'b1};
		end
	end

	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_reset_sync <= 2'b00;
		end else begin
			m_reset_sync <= {m_reset_sync[0], 1'b1};
		end
	end

	assign M_PRESETn = m_reset_sync[1];

	// Synchronizers for APB signals
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_apb_psel_sync <= 2'b00;
			s_apb_penable_sync <= 2'b00;
		end else begin
			s_apb_psel_sync <= {s_apb_psel_sync[0], S_APB_PSEL};
			s_apb_penable_sync <= {s_apb_penable_sync[0], S_APB_PENABLE};
		end
	end

	// Detect request on source APB
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_apb_request <= 1'b0;
		end else begin
			if (s_apb_psel_sync[1] && s_apb_penable_sync[0] && !s_apb_penable_sync[1]) begin
				s_apb_request <= 1'b1;
			end else if (M_APB_PREADY) begin
				s_apb_request <= 1'b0;
			end
		end
	end

	// Register crossing payload and response fields
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			s_apb_paddr_reg <= {AW{1'b0}};
			s_apb_pwdata_reg <= {DW{1'b0}};
			s_apb_pwstrb_reg <= {DW/8{1'b0}};
			s_apb_pprot_reg <= 3'b000;
			s_apb_pwrite_reg <= 1'b0;
			m_apb_prdata_reg <= {DW{1'b0}};
			m_apb_pslverr_reg <= 1'b0;
			m_apb_request <= 1'b0;
			m_apb_response <= 1'b0;
		end else begin
			if (s_apb_request && !m_apb_request) begin
				s_apb_paddr_reg <= S_APB_PADDR;
				s_apb_pwdata_reg <= S_APB_PWDATA;
				s_apb_pwstrb_reg <= S_APB_PWSTRB;
				s_apb_pprot_reg <= S_APB_PPROT;
				s_apb_pwrite_reg <= S_APB_PWRITE;
				m_apb_request <= 1'b1;
			end else if (M_APB_PREADY) begin
				m_apb_request <= 1'b0;
				m_apb_response <= 1'b1;
				m_apb_prdata_reg <= M_APB_PRDATA;
				m_apb_pslverr_reg <= M_APB_PSLVERR;
			end else if (m_apb_response) begin
				m_apb_response <= 1'b0;
			end
		end
	end

	// Source APB ready signal
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			S_APB_PREADY <= 1'b0;
		end else begin
			S_APB_PREADY <= m_apb_response;
		end
	end

	// Source APB response signals
	assign S_APB_PRDATA = m_apb_prdata_reg;
	assign S_APB_PSLVERR = m_apb_pslverr_reg;

	// Destination APB signals
	assign M_APB_PSEL = m_apb_request;
	assign M_APB_PENABLE = m_apb_request;
	assign M_APB_PADDR = s_apb_paddr_reg;
	assign M_APB_PWRITE = s_apb_pwrite_reg;
	assign M_APB_PWDATA = s_apb_pwdata_reg;
	assign M_APB_PWSTRB = s_apb_pwstrb_reg;
	assign M_APB_PPROT = s_apb_pprot_reg;

endmodule
