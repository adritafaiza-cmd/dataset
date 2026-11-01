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
	reg [AW-1:0] m_addr_reg;
	reg m_write_reg;
	reg [DW-1:0] m_wdata_reg;
	reg [DW/8-1:0] m_wstrb_reg;
	reg [2:0] m_pprot_reg;
	reg m_req_valid;
	reg m_req_ack;
	reg m_done_valid;
	reg m_done_ack;
	reg [DW-1:0] m_rdata_reg;
	reg m_pslverr_reg;

	// S-domain: capture request on setup phase
	// APB setup phase: PSEL=1, PENABLE=0
	// APB access phase: PSEL=1, PENABLE=1
	// We capture the request when PSEL=1 and PENABLE=0 (setup phase)
	// and hold it until the transfer is complete.

	// S-domain state machine
	reg s_busy;
	reg s_req_pending;

	// S-domain: detect setup phase and capture request
	// We use a handshake: S-domain asserts req_valid, M-domain acks with req_ack
	// Then M-domain performs the APB transfer, and asserts done_valid
	// S-domain acks with done_ack, and asserts PREADY

	// S-domain logic
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_busy <= 1'b0;
			s_req_pending <= 1'b0;
			S_APB_PREADY <= 1'b0;
		end else begin
			if (s_busy) begin
				// Wait for done_ack to be cleared (i.e., done_valid from M-domain is acked)
				if (m_done_valid && !m_done_ack) begin
					// Capture response
					m_rdata_reg <= M_APB_PRDATA;
					m_pslverr_reg <= M_APB_PSLVERR;
					m_done_ack <= 1'b1;
					S_APB_PREADY <= 1'b1;
				end else if (m_done_valid && m_done_ack) begin
					// Done acked, clear busy
					m_done_ack <= 1'b0;
					s_busy <= 1'b0;
					S_APB_PREADY <= 1'b0;
				end
			end else begin
				// Not busy, check for new request in setup phase
				if (S_APB_PSEL && !S_APB_PENABLE) begin
					// Setup phase, capture request
					m_addr_reg <= S_APB_PADDR;
					m_write_reg <= S_APB_PWRITE;
					m_wdata_reg <= S_APB_PWDATA;
					m_wstrb_reg <= S_APB_PWSTRB;
					m_pprot_reg <= S_APB_PPROT;
					m_req_valid <= 1'b1;
					s_busy <= 1'b1;
					S_APB_PREADY <= 1'b0;
				end else begin
					S_APB_PREADY <= 1'b0;
				end
			end
		end
	end

	// M-domain: reset synchronizer
	reg [1:0] m_reset_sync;
	always @(posedge M_APB_PCLK) begin
		m_reset_sync <= {m_reset_sync[0], S_PRESETn};
	end
	wire m_reset_n = m_reset_sync[1];

	// M-domain: APB state machine
	// States: IDLE, SETUP, ACCESS
	reg [1:0] m_state;
	localparam M_IDLE = 2'b00;
	localparam M_SETUP = 2'b01;
	localparam M_ACCESS = 2'b10;

	always @(posedge M_APB_PCLK or negedge m_reset_n) begin
		if (!m_reset_n) begin
			m_state <= M_IDLE;
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			M_PRESETn <= 1'b0;
			m_req_ack <= 1'b0;
			m_done_valid <= 1'b0;
		end else begin
			M_PRESETn <= 1'b1;
			case (m_state)
				M_IDLE: begin
					M_APB_PSEL <= 1'b0;
					M_APB_PENABLE <= 1'b0;
					m_done_valid <= 1'b0;
					if (m_req_valid && !m_req_ack) begin
						// New request, start setup phase
						m_req_ack <= 1'b1;
						M_APB_PSEL <= 1'b1;
						M_APB_PENABLE <= 1'b0;
						m_state <= M_SETUP;
					end
				end
				M_SETUP: begin
					// Setup phase: PSEL=1, PENABLE=0
					// Move to access phase
					M_APB_PSEL <= 1'b1;
					M_APB_PENABLE <= 1'b1;
					m_state <= M_ACCESS;
				end
				M_ACCESS: begin
					// Access phase: PSEL=1, PENABLE=1
					// Wait for PREADY
					if (M_APB_PREADY) begin
						// Transfer complete
						M_APB_PSEL <= 1'b0;
						M_APB_PENABLE <= 1'b0;
						m_done_valid <= 1'b1;
						m_state <= M_IDLE;
					end
				end
				default: begin
					m_state <= M_IDLE;
					M_APB_PSEL <= 1'b0;
					M_APB_PENABLE <= 1'b0;
					m_done_valid <= 1'b0;
				end
			endcase
		end
	end

	// M-domain: output assignment
	assign M_APB_PADDR = m_addr_reg;
	assign M_APB_PWRITE = m_write_reg;
	assign M_APB_PWDATA = m_wdata_reg;
	assign M_APB_PWSTRB = m_wstrb_reg;
	assign M_APB_PPROT = m_pprot_reg;

	// S-domain: output assignment
	assign S_APB_PRDATA = m_rdata_reg;
	assign S_APB_PSLVERR = m_pslverr_reg;

endmodule
