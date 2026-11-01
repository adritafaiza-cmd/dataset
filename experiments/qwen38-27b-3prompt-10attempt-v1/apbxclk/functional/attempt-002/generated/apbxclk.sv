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

	// Synchronous reset for M domain
	reg [1:0] m_reset_sync;
	reg m_reset_n;

	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_reset_sync <= 2'b00;
		end else begin
			m_reset_sync <= {m_reset_sync[0], 1'b1};
		end
	end

	assign M_PRESETn = m_reset_sync[1];

	// Handshake signals
	reg s_req;
	reg [1:0] m_req_sync;
	reg m_req;
	reg m_done;
	reg [1:0] s_done_sync;
	reg s_done;

	// Capture request in M domain
	reg [AW-1:0] m_addr;
	reg m_write;
	reg [DW-1:0] m_wdata;
	reg [DW/8-1:0] m_wstrb;
	reg [2:0] m_pprot;

	// Response in S domain
	reg [DW-1:0] s_rdata;
	reg s_pslverr;

	// M domain: synchronize s_req
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_req_sync <= 2'b00;
		end else begin
			m_req_sync <= {m_req_sync[0], s_req};
		end
	end
	assign m_req = m_req_sync[1];

	// M domain: synchronize s_done
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			s_done_sync <= 2'b00;
		end else begin
			s_done_sync <= {s_done_sync[0], s_done};
		end
		end
	assign s_done = s_done_sync[1];

	// M domain: APB master state machine
	// States: IDLE, SETUP, ACCESS
	localparam IDLE = 2'b00;
	localparam SETUP = 2'b01;
	localparam ACCESS = 2'b10;

	reg [1:0] m_state;
	reg m_sel;
	reg m_enable;

	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_state <= IDLE;
			m_sel <= 1'b0;
			m_enable <= 1'b0;
			m_addr <= {AW{1'b0}};
			m_write <= 1'b0;
			m_wdata <= {DW{1'b0}};
			m_wstrb <= {(DW/8){1'b0}};
			m_pprot <= 3'b000;
			m_done <= 1'b0;
		end else begin
			m_done <= 1'b0;
			case (m_state)
				IDLE: begin
					m_sel <= 1'b0;
					m_enable <= 1'b0;
					if (m_req) begin
						m_state <= SETUP;
						m_sel <= 1'b1;
						m_enable <= 1'b0;
						m_addr <= S_APB_PADDR;
						m_write <= S_APB_PWRITE;
						m_wdata <= S_APB_PWDATA;
						m_wstrb <= S_APB_PWSTRB;
						m_pprot <= S_APB_PPROT;
					end
				end
				SETUP: begin
					m_sel <= 1'b1;
					m_enable <= 1'b1;
					m_state <= ACCESS;
				end
				ACCESS: begin
					m_sel <= 1'b1;
					m_enable <= 1'b1;
					if (M_APB_PREADY) begin
						m_state <= IDLE;
						m_sel <= 1'b0;
						m_enable <= 1'b0;
						m_done <= 1'b1;
					end
				end
				default: begin
					m_state <= IDLE;
					m_sel <= 1'b0;
					m_enable <= 1'b0;
				end
			endcase
		end
	end

	assign M_APB_PSEL = m_sel;
	assign M_APB_PENABLE = m_enable;
	assign M_APB_PADDR = m_addr;
	assign M_APB_PWRITE = m_write;
	assign M_APB_PWDATA = m_wdata;
	assign M_APB_PWSTRB = m_wstrb;
	assign M_APB_PPROT = m_pprot;

	// S domain: synchronize m_done
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_done_sync <= 2'b00;
		end else begin
			m_done_sync <= {m_done_sync[0], m_done};
		end
	end
	reg [1:0] m_done_sync;
	assign s_done = m_done_sync[1];

	// S domain: APB slave state machine
	// States: IDLE, SETUP, ACCESS
	localparam S_IDLE = 2'b00;
	localparam S_SETUP = 2'b01;
	localparam S_ACCESS = 2'b10;

	reg [1:0] s_state;
	reg s_sel;
	reg s_enable;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_state <= S_IDLE;
			s_sel <= 1'b0;
			s_enable <= 1'b0;
			S_APB_PREADY <= 1'b0;
			s_rdata <= {DW{1'b0}};
			s_pslverr <= 1'b0;
			s_req <= 1'b0;
		end else begin
			s_req <= 1'b0;
			case (s_state)
				S_IDLE: begin
					s_sel <= 1'b0;
					s_enable <= 1'b0;
					S_APB_PREADY <= 1'b0;
					if (S_APB_PSEL) begin
						s_state <= S_SETUP;
						s_sel <= 1'b1;
						s_enable <= 1'b0;
						s_req <= 1'b1;
					end
				end
				S_SETUP: begin
					s_sel <= 1'b1;
					s_enable <= 1'b1;
					S_APB_PREADY <= 1'b0;
					s_state <= S_ACCESS;
				end
				S_ACCESS: begin
					s_sel <= 1'b1;
					s_enable <= 1'b1;
					if (s_done) begin
						s_state <= S_IDLE;
						s_sel <= 1'b0;
						s_enable <= 1'b0;
						S_APB_PREADY <= 1'b1;
						s_rdata <= M_APB_PRDATA;
						s_pslverr <= M_APB_PSLVERR;
					end else begin
						S_APB_PREADY <= 1'b0;
					end
				end
				default: begin
					s_state <= S_IDLE;
					s_sel <= 1'b0;
					s_enable <= 1'b0;
					S_APB_PREADY <= 1'b0;
				end
			endcase
		end
	end

	assign S_APB_PRDATA = s_rdata;
	assign S_APB_PSLVERR = s_pslverr;

endmodule
