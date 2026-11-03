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

	// Synchronizers for control signals
	reg [1:0] s_apb_psel_sync;
	reg [1:0] s_apb_penable_sync;

	// Registers for crossing payload and response fields
	reg [AW-1:0] s_apb_paddr_reg;
	reg [DW-1:0] s_apb_pwdata_reg;
	reg [DW/8-1:0] s_apb_pwstrb_reg;
	reg [2:0] s_apb_pprot_reg;

	reg [DW-1:0] m_apb_prdata_reg;
	reg m_apb_pslverr_reg;

	// Control signals
	reg s_apb_psel_synced;
	reg s_apb_penable_synced;
	reg m_apb_psel_reg;
	reg m_apb_penable_reg;
	reg s_apb_pready_reg;
	reg m_apb_pready_synced;

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

	// Synchronizers for control signals
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_apb_psel_sync <= 2'b00;
			s_apb_penable_sync <= 2'b00;
		end else begin
			s_apb_psel_sync <= {s_apb_psel_sync[0], S_APB_PSEL};
			s_apb_penable_sync <= {s_apb_penable_sync[0], S_APB_PENABLE};
		end
	end

	assign s_apb_psel_synced = s_apb_psel_sync[1];
	assign s_apb_penable_synced = s_apb_penable_sync[1];

	// Source APB to Destination APB transfer logic
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_apb_psel_reg <= 1'b0;
			m_apb_penable_reg <= 1'b0;
			s_apb_pready_reg <= 1'b0;
			m_apb_pready_synced <= 1'b0;
		end else begin
			if (s_apb_psel_synced && s_apb_penable_synced && !m_apb_psel_reg) begin
				m_apb_psel_reg <= 1'b1;
				m_apb_penable_reg <= 1'b0;
				s_apb_pready_reg <= 1'b0;
				m_apb_pready_synced <= 1'b0;
			end else if (m_apb_psel_reg && !m_apb_penable_reg && M_APB_PREADY) begin
				m_apb_penable_reg <= 1'b1;
				m_apb_pready_synced <= 1'b1;
			end else if (m_apb_psel_reg && m_apb_penable_reg && M_APB_PREADY) begin
				m_apb_psel_reg <= 1'b0;
				m_apb_penable_reg <= 1'b0;
				s_apb_pready_reg <= 1'b1;
				m_apb_pready_synced <= 1'b0;
			end
		end
	end

	assign S_APB_PREADY = s_apb_pready_reg;

	// Register crossing payload and response fields
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_apb_paddr_reg <= {AW{1'b0}};
			s_apb_pwdata_reg <= {DW{1'b0}};
			s_apb_pwstrb_reg <= {DW/8{1'b0}};
			s_apb_pprot_reg <= 3'b000;
		end else if (s_apb_psel_synced && !s_apb_penable_synced) begin
			s_apb_paddr_reg <= S_APB_PADDR;
			s_apb_pwdata_reg <= S_APB_PWDATA;
			s_apb_pwstrb_reg <= S_APB_PWSTRB;
			s_apb_pprot_reg <= S_APB_PPROT;
		end
	end

	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_apb_prdata_reg <= {DW{1'b0}};
			m_apb_pslverr_reg <= 1'b0;
		end else if (m_apb_pready_synced) begin
			m_apb_prdata_reg <= M_APB_PRDATA;
			m_apb_pslverr_reg <= M_APB_PSLVERR;
		end
	end

	assign M_APB_PSEL = m_apb_psel_reg;
	assign M_APB_PENABLE = m_apb_penable_reg;
	assign M_APB_PADDR = s_apb_paddr_reg;
	assign M_APB_PWRITE = S_APB_PWRITE;
	assign M_APB_PWDATA = s_apb_pwdata_reg;
	assign M_APB_PWSTRB = s_apb_pwstrb_reg;
	assign M_APB_PPROT = s_apb_pprot_reg;

	assign S_APB_PRDATA = m_apb_prdata_reg;
	assign S_APB_PSLVERR = m_apb_pslverr_reg;

endmodule
