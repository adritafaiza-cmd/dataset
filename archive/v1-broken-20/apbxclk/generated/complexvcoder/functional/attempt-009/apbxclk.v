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

	wire [AW-1:0] m_apb_paddr;
	wire m_apb_pwrite;
	wire [DW-1:0] m_apb_pwdata;
	wire [DW/8-1:0] m_apb_pwstrb;
	wire [2:0] m_apb_pprot;
	wire [DW-1:0] m_apb_prdata;
	wire m_apb_pslverr;
	wire m_apb_penable;
	wire m_apb_psel;
	reg m_apb_pready;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			S_APB_PREADY <= 0;
			M_APB_PSEL <= 0;
			M_APB_PENABLE <= 0;
			M_PRESETn <= 1;
		end else begin
			if (S_APB_PSEL && S_APB_PENABLE) begin
				m_apb_paddr <= S_APB_PADDR;
				m_apb_pwrite <= S_APB_PWRITE;
				m_apb_pwdata <= S_APB_PWDATA;
				m_apb_pwstrb <= S_APB_PWSTRB;
				m_apb_pprot <= S_APB_PPROT;
				m_apb_psel <= 1;
				m_apb_penable <= 1;
				S_APB_PREADY <= 0;
			end else begin
				m_apb_psel <= 0;
				m_apb_penable <= 0;
			end

			if (M_APB_PREADY) begin
				m_apb_pready <= 0;
				S_APB_PREADY <= 1;
				S_APB_PRDATA <= M_APB_PRDATA;
				S_APB_PSLVERR <= M_APB_PSLVERR;
			end else begin
				m_apb_pready <= 1;
				S_APB_PREADY <= 0;
			end
		end
	end

	always @(posedge M_APB_PCLK) begin
		if (M_APB_PSEL && M_APB_PENABLE) begin
			M_APB_PADDR <= m_apb_paddr;
			M_APB_PWRITE <= m_apb_pwrite;
			M_APB_PWDATA <= m_apb_pwdata;
			M_APB_PWSTRB <= m_apb_pwstrb;
			M_APB_PPROT <= m_apb_pprot;
			M_APB_PSEL <= m_apb_psel;
			M_APB_PENABLE <= m_apb_penable;
		end else begin
			M_APB_PSEL <= 0;
			M_APB_PENABLE <= 0;
		end
	end

	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			M_PRESETn <= 1;
		end else begin
			M_PRESETn <= 0;
		end
	end

endmodule
