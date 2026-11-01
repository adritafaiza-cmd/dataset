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
	wire [AW-1:0] m_addr;
	wire           m_write;
	wire [DW-1:0] m_wdata;
	wire [DW/8-1:0] m_wstrb;
	wire [2:0]    m_pprot;
	wire           m_req_valid;
	wire           m_req_ready;
	wire           m_resp_valid;
	wire           m_resp_ready;
	wire [DW-1:0] m_rdata;
	wire           m_slverr;

	// S-side: capture request when PSEL && !PENABLE (setup phase)
	// We use a handshake: S-side asserts request, M-side acknowledges.
	// Since APB is a simple protocol, we can use a 2-phase handshake.
	// S-side: when PSEL && !PENABLE, capture the request and assert m_req_valid.
	// M-side: when m_req_valid && m_req_ready, accept the request and start APB transfer.
	// After M-side completes, assert m_resp_valid.
	// S-side: when m_resp_valid && m_resp_ready, complete the transfer.

	// S-side state machine
	reg s_req_pending;
	reg [AW-1:0] s_addr_reg;
	reg s_write_reg;
	reg [DW-1:0] s_wdata_reg;
	reg [DW/8-1:0] s_wstrb_reg;
	reg [2:0] s_pprot_reg;

	// M-side state machine
	reg m_sel_reg;
	reg m_enable_reg;
	reg m_addr_reg;
	reg m_write_reg;
	reg [DW-1:0] m_wdata_reg;
	reg [DW/8-1:0] m_wstrb_reg;
	reg [2:0] m_pprot_reg;
	reg m_resp_valid_reg;

	// CDC synchronizers
	// S -> M: request valid
	reg [2:0] s2m_req_valid_sync;
	reg s2m_req_valid_sync0;
	reg s2m_req_valid_sync1;
	reg s2m_req_valid_sync2;

	// M -> S: response valid
	reg [2:0] m2s_resp_valid_sync;
	reg m2s_resp_valid_sync0;
	reg m2s_resp_valid_sync1;
	reg m2s_resp_valid_sync2;

	// M -> S: request ready (ack)
	reg [2:0] m2s_req_ready_sync;
	reg m2s_req_ready_sync0;
	reg m2s_req_ready_sync1;
	reg m2s_req_ready_sync2;

	// S -> M: response ready (ack)
	reg [2:0] s2m_resp_ready_sync;
	reg s2m_resp_ready_sync0;
	reg s2m_resp_ready_sync1;
	reg s2m_resp_ready_sync2;

	// Multi-bit data crossing: use FIFO or handshake with data valid
	// For simplicity, use a 2-deep FIFO for data crossing
	// Or use a handshake with data held stable

	// Let's use a simpler approach: 
	// S-side captures request into registers, asserts req_valid.
	// M-side synchronizes req_valid, when it sees req_valid, it reads the data 
	// from S-side registers (which are stable because S-side holds them until ack).
	// But S-side registers are in S clock domain, so M-side can't read them directly.
	// We need to cross the data too.

	// Better approach: Use a CDC FIFO for the request data.
	// Or use a handshake where data is held stable and synchronized.

	// Let's use a 2-phase handshake with data crossing via synchronizers.
	// Since data is multi-bit, we need to ensure coherence.
	// We'll use a "data valid" signal to indicate when data is stable.

	// S-side: when PSEL && !PENABLE, capture data and assert s_data_valid.
	// M-side: synchronize s_data_valid, when it sees s_data_valid, read data from 
	// synchronized data registers.

	// Synchronized data registers (M clock domain)
	reg [AW-1:0] m_addr_sync;
	reg m_write_sync;
	reg [DW-1:0] m_wdata_sync;
	reg [DW/8-1:0] m_wstrb_sync;
	reg [2:0] m_pprot_sync;
	reg m_data_valid_sync;

	// S-side data valid
	reg s_data_valid;

	// M-side response data
	reg [DW-1:0] m_rdata_reg;
	reg m_slverr_reg;
	reg m_resp_data_valid;

	// S-side response data
	reg [DW-1:0] s_rdata_sync;
	reg s_slverr_sync;
	reg s_resp_data_valid_sync;

	// Synchronizers for data valid signals
	// S -> M: s_data_valid
	reg [2:0] s2m_data_valid_sync;
	reg s2m_data_valid_sync0;
	reg s2m_data_valid_sync1;
	reg s2m_data_valid_sync2;

	// M -> S: m_resp_data_valid
	reg [2:0] m2s_resp_data_valid_sync;
	reg m2s_resp_data_valid_sync0;
	reg m2s_resp_data_valid_sync1;
	reg m2s_resp_data_valid_sync2;

	// Synchronizers for data (multi-bit)
	// We'll use a simple approach: hold data stable and synchronize a "data ready" flag
	// Then read the data when the flag is synchronized.

	// S-side: hold data in registers, assert s_data_valid when data is stable
	// M-side: synchronize s_data_valid, when it transitions 0->1, read data from 
	// synchronized data registers.

	// But we need to synchronize the data itself. Since data is multi-bit, we need 
	// to ensure all bits are synchronized together. We can use a "data valid" signal 
	// to indicate when data is stable, and then read the data.

	// Let's use a different approach: use a CDC FIFO for the request.
	// But that's complex. Let's use a simpler handshake.

	// S-side: when PSEL && !PENABLE, capture data into s_*_reg, assert s_data_valid.
	// M-side: synchronize s_data_valid. When s_data_valid_sync goes 0->1, 
	// read data from s_*_reg (which are stable) into m_*_reg, and assert m_req_valid.
	// S-side: synchronize m_req_valid. When m_req_valid_sync goes 0->1, 
	// deassert s_data_valid and wait for response.
	// M-side: when m_req_valid, start APB transfer. When M_APB_PREADY, 
	// capture response into m_rdata_reg, m_slverr_reg, assert m_resp_data_valid.
	// S-side: synchronize m_resp_data_valid. When m_resp_data_valid_sync goes 0->1, 
	// read data from m_rdata_reg, m_slverr_reg (which are stable) into s_rdata_sync, 
	// s_slverr_sync, assert S_APB_PREADY.
	// M-side: synchronize S_APB_PREADY (or a response ready signal). When it goes 0->1, 
	// deassert m_resp_data_valid.

	// This is getting complex. Let's simplify by using a 2-deep FIFO for data crossing.
	// Or use a "gray code" approach for data.

	// For simplicity, let's use a "data valid" handshake with data held stable.
	// The key is that data is held stable until the other side acknowledges.

	// S-side:
	// - When PSEL && !PENABLE, capture data into s_*_reg, set s_data_valid = 1.
	// - When m_req_ready_sync (synchronized from M-side) is 1, set s_data_valid = 0.
	// - When m_resp_data_valid_sync (synchronized from M-side) is 1, set S_APB_PREADY = 1.
	// - When PSEL && PENABLE && S_APB_PREADY, set S_APB_PREADY = 0.

	// M-side:
	// - When s_data_valid_sync (synchronized from S-side) is 1, read data from s_*_reg 
	//   (which are stable) into m_*_reg, set m_req_valid = 1.
	// - When m_req_valid && M_APB_PREADY, set m_req_valid = 0, capture response into 
	//   m_rdata_reg, m_slverr_reg, set m_resp_data_valid = 1.
	// - When s_resp_ready_sync (synchronized from S-side) is 1, set m_resp_data_valid = 0.

	// Synchronizers:
	// S -> M: s_data_valid
	// M -> S: m_req_ready (ack for s_data_valid)
	// M -> S: m_resp_data_valid
	// S -> M: s_resp_ready (ack for m_resp_data_valid)

	// Let's implement this.

	// S-side registers
	reg s_data_valid_reg;
	reg s_resp_ready_reg;

	// M-side registers
	reg m_req_valid_reg;
	reg m_resp_data_valid_reg;

	// Synchronizers
	// S -> M: s_data_valid
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			s2m_data_valid_sync0 <= 1'b0;
			s2m_data_valid_sync1 <= 1'b0;
			s2m_data_valid_sync2 <= 1'b0;
		end else begin
			s2m_data_valid_sync0 <= s_data_valid_reg;
			s2m_data_valid_sync1 <= s2m_data_valid_sync0;
			s2m_data_valid_sync2 <= s2m_data_valid_sync1;
		end
	end
	assign s2m_data_valid_sync = s2m_data_valid_sync2;

	// M -> S: m_req_ready
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m2s_req_ready_sync0 <= 1'b0;
			m2s_req_ready_sync1 <= 1'b0;
			m2s_req_ready_sync2 <= 1'b0;
		end else begin
			m2s_req_ready_sync0 <= m_req_valid_reg;
			m2s_req_ready_sync1 <= m2s_req_ready_sync0;
			m2s_req_ready_sync2 <= m2s_req_ready_sync1;
		end
	end
	assign m2s_req_ready_sync = m2s_req_ready_sync2;

	// M -> S: m_resp_data_valid
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m2s_resp_data_valid_sync0 <= 1'b0;
			m2s_resp_data_valid_sync1 <= 1'b0;
			m2s_resp_data_valid_sync2 <= 1'b0;
		end else begin
			m2s_resp_data_valid_sync0 <= m_resp_data_valid_reg;
			m2s_resp_data_valid_sync1 <= m2s_resp_data_valid_sync0;
			m2s_resp_data_valid_sync2 <= m2s_resp_data_valid_sync1;
		end
	end
	assign m2s_resp_data_valid_sync = m2s_resp_data_valid_sync2;

	// S -> M: s_resp_ready
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			s2m_resp_ready_sync0 <= 1'b0;
			s2m_resp_ready_sync1 <= 1'b0;
			s2m_resp_ready_sync2 <= 1'b0;
		end else begin
			s2m_resp_ready_sync0 <= s_resp_ready_reg;
			s2m_resp_ready_sync1 <= s2m_resp_ready_sync0;
			s2m_resp_ready_sync2 <= s2m_resp_ready_sync1;
		end
	end
	assign s2m_resp_ready_sync = s2m_resp_ready_sync2;

	// S-side logic
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_data_valid_reg <= 1'b0;
			s_resp_ready_reg <= 1'b0;
			S_APB_PREADY <= 1'b0;
			s_addr_reg <= {AW{1'b0}};
			s_write_reg <= 1'b0;
			s_wdata_reg <= {DW{1'b0}};
			s_wstrb_reg <= {(DW/8){1'b0}};
			s_pprot_reg <= 3'b0;
			s_rdata_sync <= {DW{1'b0}};
			s_slverr_sync <= 1'b0;
		end else begin
			// Capture request during setup phase
			if (S_APB_PSEL && !S_APB_PENABLE && !s_data_valid_reg) begin
				s_addr_reg <= S_APB_PADDR;
				s_write_reg <= S_APB_PWRITE;
				s_wdata_reg <= S_APB_PWDATA;
				s_wstrb_reg <= S_APB_PWSTRB;
				s_pprot_reg <= S_APB_PPROT;
				s_data_valid_reg <= 1'b1;
			end

			// Deassert s_data_valid when M-side acknowledges
			if (s_data_valid_reg && m2s_req_ready_sync) begin
				s_data_valid_reg <= 1'b0;
			end

			// Assert S_APB_PREADY when response is available
			if (m2s_resp_data_valid_sync) begin
				S_APB_PREADY <= 1'b1;
				s_rdata_sync <= m_rdata_reg;
				s_slverr_sync <= m_slverr_reg;
				s_resp_ready_reg <= 1'b1;
			end

			// Deassert S_APB_PREADY when transfer completes
			if (S_APB_PREADY && S_APB_PSEL && S_APB_PENABLE) begin
				S_APB_PREADY <= 1'b0;
				s_resp_ready_reg <= 1'b0;
			end
		end
	end

	assign S_APB_PRDATA = s_rdata_sync;
	assign S_APB_PSLVERR = s_slverr_sync;

	// M-side logic
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_req_valid_reg <= 1'b0;
			m_resp_data_valid_reg <= 1'b0;
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			m_addr_reg <= {AW{1'b0}};
			m_write_reg <= 1'b0;
			m_wdata_reg <= {DW{1'b0}};
			m_wstrb_reg <= {(DW/8){1'b0}};
			m_pprot_reg <= 3'b0;
			m_rdata_reg <= {DW{1'b0}};
			m_slverr_reg <= 1'b0;
		end else begin
			// Accept request when S-side data is valid
			if (s2m_data_valid_sync && !m_req_valid_reg) begin
				m_addr_reg <= s_addr_reg;
				m_write_reg <= s_write_reg;
				m_wdata_reg <= s_wdata_reg;
				m_wstrb_reg <= s_wstrb_reg;
				m_pprot_reg <= s_pprot_reg;
				m_req_valid_reg <= 1'b1;
				M_APB_PSEL <= 1'b1;
				M_APB_PENABLE <= 1'b0;
			end

			// Start access phase
			if (m_req_valid_reg && !M_APB_PENABLE) begin
				M_APB_PENABLE <= 1'b1;
			end

			// Complete transfer when M_APB_PREADY
			if (m_req_valid_reg && M_APB_PENABLE && M_APB_PREADY) begin
				m_req_valid_reg <= 1'b0;
				M_APB_PSEL <= 1'b0;
				M_APB_PENABLE <= 1'b0;
				m_rdata_reg <= M_APB_PRDATA;
				m_slverr_reg <= M_APB_PSLVERR;
				m_resp_data_valid_reg <= 1'b1;
			end

			// Deassert m_resp_data_valid when S-side acknowledges
			if (m_resp_data_valid_reg && s2m_resp_ready_sync) begin
				m_resp_data_valid_reg <= 1'b0;
			end
		end
	end

	assign M_APB_PADDR = m_addr_reg;
	assign M_APB_PWRITE = m_write_reg;
	assign M_APB_PWDATA = m_wdata_reg;
	assign M_APB_PWSTRB = m_wstrb_reg;
	assign M_APB_PPROT = m_pprot_reg;

	// M_PRESETn: synchronize S_PRESETn to M clock domain
	reg [2:0] m_presetn_sync;
	reg m_presetn_sync0;
	reg m_presetn_sync1;
	reg m_presetn_sync2;

	always @(posedge M_APB_PCLK) begin
		m_presetn_sync0 <= S_PRESETn;
		m_presetn_sync1 <= m_presetn_sync0;
		m_presetn_sync2 <= m_presetn_sync1;
	end
	assign M_PRESETn = m_presetn_sync2;

endmodule
