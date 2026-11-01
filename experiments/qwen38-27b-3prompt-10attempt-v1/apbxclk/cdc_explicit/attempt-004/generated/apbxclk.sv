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

	// ------------------------------------------------------------------
	// Reset synchronization for M_APB_PCLK domain
	// ------------------------------------------------------------------
	reg [1:0] m_reset_sync;
	reg       m_reset_active;

	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_reset_sync   <= 2'b00;
			m_reset_active <= 1'b1;
		end else begin
			m_reset_sync   <= {m_reset_sync[0], 1'b1};
			m_reset_active <= ~m_reset_sync[1];
		end
	end

	assign M_PRESETn = ~m_reset_active;

	// ------------------------------------------------------------------
	// Source-side (S_APB_PCLK) state machine
	// ------------------------------------------------------------------
	localparam S_IDLE  = 1'b0;
	localparam S_BUSY  = 1'b1;

	reg       s_state;
	reg       s_req_valid;

	// Handshake signals to M domain
	reg       s_to_m_req;
	reg       s_to_m_ack;

	// Capture of source request fields (held stable during transfer)
	reg [AW-1:0] s_addr;
	reg          s_write;
	reg [DW-1:0] s_wdata;
	reg [DW/8-1:0] s_wstrb;
	reg [2:0]    s_pprot;

	// Response from M domain (synchronized back)
	reg [DW-1:0] s_rdata;
	reg          s_pslverr;

	// ------------------------------------------------------------------
	// Destination-side (M_APB_PCLK) state machine
	// ------------------------------------------------------------------
	localparam M_IDLE  = 1'b0;
	localparam M_SETUP = 1'b1;
	localparam M_ACCESS= 1'b2;

	reg [1:0] m_state;
	reg       m_req_valid;

	// Handshake signals from S domain
	reg       m_to_s_req;
	reg       m_to_s_ack;

	// Captured request fields in M domain
	reg [AW-1:0] m_addr;
	reg          m_write;
	reg [DW-1:0] m_wdata;
	reg [DW/8-1:0] m_wstrb;
	reg [2:0]    m_pprot;

	// Response to S domain
	reg [DW-1:0] m_rdata;
	reg          m_pslverr;

	// ------------------------------------------------------------------
	// S_APB_PCLK domain logic
	// ------------------------------------------------------------------
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_state     <= S_IDLE;
			s_req_valid <= 1'b0;
			s_to_m_req  <= 1'b0;
			s_to_m_ack  <= 1'b0;
			s_addr      <= {AW{1'b0}};
			s_write     <= 1'b0;
			s_wdata     <= {DW{1'b0}};
			s_wstrb     <= {(DW/8){1'b0}};
			s_pprot     <= 3'b000;
			s_rdata     <= {DW{1'b0}};
			s_pslverr   <= 1'b0;
			S_APB_PREADY<= 1'b0;
		end else begin
			case (s_state)
				S_IDLE: begin
					S_APB_PREADY <= 1'b1;
					if (S_APB_PSEL && S_APB_PENABLE) begin
						// Capture request
						s_addr    <= S_APB_PADDR;
						s_write   <= S_APB_PWRITE;
						s_wdata   <= S_APB_PWDATA;
						s_wstrb   <= S_APB_PWSTRB;
						s_pprot   <= S_APB_PPROT;
						s_req_valid <= 1'b1;
						s_to_m_req  <= 1'b1;
						s_state     <= S_BUSY;
						S_APB_PREADY<= 1'b0;
					end
				end
				S_BUSY: begin
					S_APB_PREADY <= 1'b0;
					if (s_to_m_ack) begin
						// Transfer complete, return response
						s_rdata     <= m_rdata;
						s_pslverr   <= m_pslverr;
						s_to_m_req  <= 1'b0;
						s_req_valid <= 1'b0;
						s_state     <= S_IDLE;
						S_APB_PREADY<= 1'b1;
					end
				end
				default: begin
					s_state <= S_IDLE;
				end
			endcase
		end
	end

	// ------------------------------------------------------------------
	// M_APB_PCLK domain logic
	// ------------------------------------------------------------------
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_state     <= M_IDLE;
			m_req_valid <= 1'b0;
			m_to_s_req  <= 1'b0;
			m_to_s_ack  <= 1'b0;
			m_addr      <= {AW{1'b0}};
			m_write     <= 1'b0;
			m_wdata     <= {DW{1'b0}};
			m_wstrb     <= {(DW/8){1'b0}};
			m_pprot     <= 3'b000;
			m_rdata     <= {DW{1'b0}};
			m_pslverr   <= 1'b0;
			M_APB_PSEL  <= 1'b0;
			M_APB_PENABLE<= 1'b0;
		end else begin
			case (m_state)
				M_IDLE: begin
					M_APB_PSEL    <= 1'b0;
					M_APB_PENABLE <= 1'b0;
					if (s_to_m_req) begin
						// Capture request from S domain
						m_addr      <= s_addr;
						m_write     <= s_write;
						m_wdata     <= s_wdata;
						m_wstrb     <= s_wstrb;
						m_pprot     <= s_pprot;
						m_req_valid <= 1'b1;
						m_to_s_req  <= 1'b1;
						m_state     <= M_SETUP;
						M_APB_PSEL  <= 1'b1;
						M_APB_PENABLE<= 1'b0;
					end
				end
				M_SETUP: begin
					M_APB_PSEL    <= 1'b1;
					M_APB_PENABLE <= 1'b1;
					m_state       <= M_ACCESS;
				end
				M_ACCESS: begin
					M_APB_PSEL    <= 1'b1;
					M_APB_PENABLE <= 1'b1;
					if (M_APB_PREADY) begin
						// Transfer complete
						m_rdata     <= M_APB_PRDATA;
						m_pslverr   <= M_APB_PSLVERR;
						m_to_s_ack  <= 1'b1;
						m_req_valid <= 1'b0;
						m_state     <= M_IDLE;
						M_APB_PSEL  <= 1'b0;
						M_APB_PENABLE<= 1'b0;
					end
				end
				default: begin
					m_state       <= M_IDLE;
					M_APB_PSEL    <= 1'b0;
					M_APB_PENABLE <= 1'b0;
				end
			endcase
		end
	end

	// ------------------------------------------------------------------
	// Output assignments
	// ------------------------------------------------------------------
	assign M_APB_PADDR  = m_addr;
	assign M_APB_PWRITE = m_write;
	assign M_APB_PWDATA = m_wdata;
	assign M_APB_PWSTRB = m_wstrb;
	assign M_APB_PPROT  = m_pprot;

	assign S_APB_PRDATA  = s_rdata;
	assign S_APB_PSLVERR = s_pslverr;

endmodule
