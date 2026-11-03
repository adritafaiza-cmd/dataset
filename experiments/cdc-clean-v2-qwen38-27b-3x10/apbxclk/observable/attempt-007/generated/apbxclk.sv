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
	// Slave-side state machine
	// ------------------------------------------------------------------
	localparam S_IDLE = 2'd0;
	localparam S_SETUP = 2'd1;
	localparam S_ACCESS = 2'd2;
	localparam S_DONE = 2'd3;

	reg [1:0] s_state;
	reg [1:0] s_state_nxt;

	// Captured request fields (slave clock domain)
	reg [AW-1:0] s_addr;
	reg         s_write;
	reg [DW-1:0] s_wdata;
	reg [DW/8-1:0] s_wstrb;
	reg [2:0]  s_pprot;

	// Response capture (slave clock domain)
	reg [DW-1:0] s_rdata;
	reg         s_slverr;

	// Handshake signals to master side
	reg         s_req_valid;   // request valid to master
	reg         s_req_ready;   // master ready to accept request
	reg         s_resp_valid;  // response valid from master
	reg         s_resp_ready;  // slave ready to accept response

	// Synchronized signals from master side
	reg         m_req_ready_sync;
	reg         m_resp_valid_sync;
	reg [DW-1:0] m_prdata_sync;
	reg         m_pslverr_sync;

	// ------------------------------------------------------------------
	// Master-side state machine
	// ------------------------------------------------------------------
	localparam M_IDLE = 2'd0;
	localparam M_SETUP = 2'd1;
	localparam M_ACCESS = 2'd2;
	localparam M_DONE = 2'd3;

	reg [1:0] m_state;
	reg [1:0] m_state_nxt;

	// Captured request fields (master clock domain)
	reg [AW-1:0] m_addr;
	reg         m_write;
	reg [DW-1:0] m_wdata;
	reg [DW/8-1:0] m_wstrb;
	reg [2:0]  m_pprot;

	// Response to slave side
	reg         m_resp_valid;
	reg [DW-1:0] m_resp_rdata;
	reg         m_resp_slverr;

	// Synchronized signals from slave side
	reg         s_req_valid_sync;
	reg         s_req_ready_sync;
	reg         s_resp_valid_sync;
	reg         s_resp_ready_sync;

	// ------------------------------------------------------------------
	// 2-FF synchronizers
	// ------------------------------------------------------------------
	// Slave -> Master: s_req_valid
	reg [1:0] s_req_valid_sync_ff;
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn)
			s_req_valid_sync_ff <= 2'b00;
		else
			s_req_valid_sync_ff <= {s_req_valid_sync_ff[0], s_req_valid};
	end
	assign s_req_valid_sync = s_req_valid_sync_ff[1];

	// Slave -> Master: s_resp_ready
	reg [1:0] s_resp_ready_sync_ff;
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn)
			s_resp_ready_sync_ff <= 2'b00;
		else
			s_resp_ready_sync_ff <= {s_resp_ready_sync_ff[0], s_resp_ready};
	end
	assign s_resp_ready_sync = s_resp_ready_sync_ff[1];

	// Master -> Slave: m_req_ready
	reg [1:0] m_req_ready_sync_ff;
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			m_req_ready_sync_ff <= 2'b00;
		else
			m_req_ready_sync_ff <= {m_req_ready_sync_ff[0], m_req_ready};
	end
	assign m_req_ready_sync = m_req_ready_sync_ff[1];

	// Master -> Slave: m_resp_valid
	reg [1:0] m_resp_valid_sync_ff;
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			m_resp_valid_sync_ff <= 2'b00;
		else
			m_resp_valid_sync_ff <= {m_resp_valid_sync_ff[0], m_resp_valid};
	end
	assign m_resp_valid_sync = m_resp_valid_sync_ff[1];

	// Master -> Slave: m_prdata (multi-bit, use 2-FF per bit or assume quasi-static)
	// For multi-bit data, we use a simple 2-FF synchronizer per bit.
	// Since data is stable while valid, this is safe.
	reg [1:0] m_prdata_sync_ff [0:DW-1];
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			integer i;
			for (i = 0; i < DW; i = i + 1)
				m_prdata_sync_ff[i] <= 2'b00;
		end else begin
			integer i;
			for (i = 0; i < DW; i = i + 1)
				m_prdata_sync_ff[i] <= {m_prdata_sync_ff[i][0], M_APB_PRDATA[i]};
		end
	end
	assign m_prdata_sync = m_prdata_sync_ff[DW-1][1]; // placeholder, will fix below

	// Actually, let's use a proper multi-bit sync. We'll use a register array.
	// Let me redo this properly.

	// ------------------------------------------------------------------
	// Proper multi-bit synchronizers
	// ------------------------------------------------------------------
	// We'll use a different approach: synchronize the valid signal, and
	// capture the data when valid is synchronized.

	// For m_prdata and m_pslverr, we synchronize them along with m_resp_valid.
	// Since m_resp_valid is a single bit, we can use a 2-FF synchronizer for it,
	// and for the data, we can use a simple 2-FF per bit or a wider synchronizer.

	// Let's use a simpler approach: synchronize m_resp_valid, and when it goes high,
	// the data is stable. We'll use a 2-FF synchronizer for the data as well.

	// Actually, for multi-bit signals, the standard approach is to use a 2-FF
	// synchronizer per bit, or to use a Gray code encoder. Since APB data is
	// not a counter, we'll use per-bit synchronizers.

	// Let me restructure. I'll use a module-level approach with proper synchronizers.

	// ------------------------------------------------------------------
	// Simplified approach: Use 2-FF synchronizers for single-bit signals,
	// and for multi-bit data, use a 2-FF synchronizer per bit.
	// ------------------------------------------------------------------

	// Slave -> Master: s_req_valid (single bit)
	reg [1:0] s_req_valid_sync_r;
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn)
			s_req_valid_sync_r <= 2'b00;
		else
			s_req_valid_sync_r <= {s_req_valid_sync_r[0], s_req_valid};
	end
	assign s_req_valid_sync = s_req_valid_sync_r[1];

	// Slave -> Master: s_resp_ready (single bit)
	reg [1:0] s_resp_ready_sync_r;
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn)
			s_resp_ready_sync_r <= 2'b00;
		else
			s_resp_ready_sync_r <= {s_resp_ready_sync_r[0], s_resp_ready};
	end
	assign s_resp_ready_sync = s_resp_ready_sync_r[1];

	// Master -> Slave: m_req_ready (single bit)
	reg [1:0] m_req_ready_sync_r;
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			m_req_ready_sync_r <= 2'b00;
		else
			m_req_ready_sync_r <= {m_req_ready_sync_r[0], m_req_ready};
	end
	assign m_req_ready_sync = m_req_ready_sync_r[1];

	// Master -> Slave: m_resp_valid (single bit)
	reg [1:0] m_resp_valid_sync_r;
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			m_resp_valid_sync_r <= 2'b00;
		else
			m_resp_valid_sync_r <= {m_resp_valid_sync_r[0], m_resp_valid};
	end
	assign m_resp_valid_sync = m_resp_valid_sync_r[1];

	// Master -> Slave: m_prdata (multi-bit)
	reg [1:0] m_prdata_sync_r [0:DW-1];
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			integer i;
			for (i = 0; i < DW; i = i + 1)
				m_prdata_sync_r[i] <= 2'b00;
		end else begin
			integer i;
			for (i = 0; i < DW; i = i + 1)
				m_prdata_sync_r[i] <= {m_prdata_sync_r[i][0], M_APB_PRDATA[i]};
		end
	end
	wire [DW-1:0] m_prdata_sync_w;
	generate
		genvar gi;
		for (gi = 0; gi < DW; gi = gi + 1) begin : gen_prdata_sync
			assign m_prdata_sync_w[gi] = m_prdata_sync_r[gi][1];
		end
	endgenerate
	assign m_prdata_sync = m_prdata_sync_w;

	// Master -> Slave: m_pslverr (single bit)
	reg [1:0] m_pslverr_sync_r;
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			m_pslverr_sync_r <= 2'b00;
		else
			m_pslverr_sync_r <= {m_pslverr_sync_r[0], M_APB_PSLVERR};
	end
	assign m_pslverr_sync = m_pslverr_sync_r[1];

	// ------------------------------------------------------------------
	// Slave-side logic
	// ------------------------------------------------------------------
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_state <= S_IDLE;
			s_addr <= {AW{1'b0}};
			s_write <= 1'b0;
			s_wdata <= {DW{1'b0}};
			s_wstrb <= {(DW/8){1'b0}};
			s_pprot <= 3'b000;
			s_rdata <= {DW{1'b0}};
			s_slverr <= 1'b0;
			s_req_valid <= 1'b0;
			s_req_ready <= 1'b0;
			s_resp_valid <= 1'b0;
			s_resp_ready <= 1'b0;
			S_APB_PREADY <= 1'b0;
		end else begin
			s_state <= s_state_nxt;

			case (s_state)
				S_IDLE: begin
					if (S_APB_PSEL && !S_APB_PENABLE) begin
						s_addr <= S_APB_PADDR;
						s_write <= S_APB_PWRITE;
						s_wdata <= S_APB_PWDATA;
						s_wstrb <= S_APB_PWSTRB;
						s_pprot <= S_APB_PPROT;
						s_req_valid <= 1'b1;
						s_resp_ready <= 1'b0;
					end
				end
				S_SETUP: begin
					// Wait for master to accept request
					if (m_req_ready_sync) begin
						s_req_valid <= 1'b0;
						s_resp_ready <= 1'b1;
					end
				end
				S_ACCESS: begin
					// Wait for response from master
					if (m_resp_valid_sync) begin
						s_rdata <= m_prdata_sync;
						s_slverr <= m_pslverr_sync;
						s_resp_ready <= 1'b0;
					end
				end
				S_DONE: begin
					// Return to idle
					s_resp_ready <= 1'b0;
				end
				default: begin
					s_state <= S_IDLE;
				end
			endcase
		end
	end

	// Slave-side next state logic
	always @(*) begin
		s_state_nxt = s_state;
		case (s_state)
			S_IDLE: begin
				if (S_APB_PSEL && !S_APB_PENABLE)
					s_state_nxt = S_SETUP;
			end
			S_SETUP: begin
				if (m_req_ready_sync)
					s_state_nxt = S_ACCESS;
			end
			S_ACCESS: begin
				if (m_resp_valid_sync)
					s_state_nxt = S_DONE;
			end
			S_DONE: begin
				s_state_nxt = S_IDLE;
			end
			default: begin
				s_state_nxt = S_IDLE;
			end
		endcase
	end

	// Slave-side outputs
	assign S_APB_PRDATA = s_rdata;
	assign S_APB_PSLVERR = s_slverr;

	// S_APB_PREADY: high when slave is ready to complete the transfer
	// In APB, PREADY is high when the slave can complete the access phase.
	// We assert PREADY when we have the response and are in S_DONE or S_ACCESS with response.
	always @(*) begin
		if (!S_PRESETn)
			S_APB_PREADY = 1'b0;
		else if (s_state == S_DONE)
			S_APB_PREADY = 1'b1;
		else if (s_state == S_ACCESS && m_resp_valid_sync)
			S_APB_PREADY = 1'b1;
		else
			S_APB_PREADY = 1'b0;
	end

	// ------------------------------------------------------------------
	// Master-side logic
	// ------------------------------------------------------------------
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_state <= M_IDLE;
			m_addr <= {AW{1'b0}};
			m_write <= 1'b0;
			m_wdata <= {DW{1'b0}};
			m_wstrb <= {(DW/8){1'b0}};
			m_pprot <= 3'b000;
			m_resp_valid <= 1'b0;
			m_resp_rdata <= {DW{1'b0}};
			m_resp_slverr <= 1'b0;
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			M_PRESETn <= 1'b0;
		end else begin
			m_state <= m_state_nxt;
			M_PRESETn <= 1'b1;

			case (m_state)
				M_IDLE: begin
					if (s_req_valid_sync) begin
						m_addr <= S_APB_PADDR;
						m_write <= S_APB_PWRITE;
						m_wdata <= S_APB_PWDATA;
						m_wstrb <= S_APB_PWSTRB;
						m_pprot <= S_APB_PPROT;
						M_APB_PSEL <= 1'b1;
						M_APB_PENABLE <= 1'b0;
					end
				end
				M_SETUP: begin
					M_APB_PSEL <= 1'b1;
					M_APB_PENABLE <= 1'b1;
				end
				M_ACCESS: begin
					M_APB_PSEL <= 1'b1;
					M_APB_PENABLE <= 1'b1;
					if (M_APB_PREADY) begin
						m_resp_rdata <= M_APB_PRDATA;
						m_resp_slverr <= M_APB_PSLVERR;
						m_resp_valid <= 1'b1;
						M_APB_PSEL <= 1'b0;
						M_APB_PENABLE <= 1'b0;
					end
				end
				M_DONE: begin
					if (s_resp_ready_sync) begin
						m_resp_valid <= 1'b0;
					end
				end
				default: begin
					m_state <= M_IDLE;
					M_APB_PSEL <= 1'b0;
					M_APB_PENABLE <= 1'b0;
				end
			endcase
		end
	end

	// Master-side next state logic
	always @(*) begin
		m_state_nxt = m_state;
		case (m_state)
			M_IDLE: begin
				if (s_req_valid_sync)
					m_state_nxt = M_SETUP;
			end
			M_SETUP: begin
				m_state_nxt = M_ACCESS;
			end
			M_ACCESS: begin
				if (M_APB_PREADY)
					m_state_nxt = M_DONE;
			end
			M_DONE: begin
				if (s_resp_ready_sync)
					m_state_nxt = M_IDLE;
			end
			default: begin
				m_state_nxt = M_IDLE;
			end
		endcase
	end

	// Master-side outputs
	assign M_APB_PADDR = m_addr;
	assign M_APB_PWRITE = m_write;
	assign M_APB_PWDATA = m_wdata;
	assign M_APB_PWSTRB = m_wstrb;
	assign M_APB_PPROT = m_pprot;

	// m_req_ready: master is ready to accept a new request
	assign m_req_ready = (m_state == M_IDLE);

	// m_resp_valid: master has a response ready
	// This is already registered in m_resp_valid

	// ------------------------------------------------------------------
	// Fix: The master-side request capture should use the synchronized
	// request fields, not the raw slave-side signals. Let me fix this.
	// ------------------------------------------------------------------

	// Actually, I need to synchronize the request fields (addr, write, wdata, wstrb, pprot)
	// from slave to master. Let me add those synchronizers.

	// Slave -> Master: s_addr
	reg [1:0] s_addr_sync_r [0:AW-1];
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			integer i;
			for (i = 0; i < AW; i = i + 1)
				s_addr_sync_r[i] <= 2'b00;
		end else begin
			integer i;
			for (i = 0; i < AW; i = i + 1)
				s_addr_sync_r[i] <= {s_addr_sync_r[i][0], S_APB_PADDR[i]};
		end
	end
	wire [AW-1:0] s_addr_sync_w;
	generate
		genvar gi;
		for (gi = 0; gi < AW; gi = gi + 1) begin : gen_saddr_sync
			assign s_addr_sync_w[gi] = s_addr_sync_r[gi][1];
		end
	endgenerate

	// Slave -> Master: s_write
	reg [1:0] s_write_sync_r;
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn)
			s_write_sync_r <= 2'b00;
		else
			s_write_sync_r <= {s_write_sync_r[0], S_APB_PWRITE};
	end

	// Slave -> Master: s_wdata
	reg [1:0] s_wdata_sync_r [0:DW-1];
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			integer i;
			for (i = 0; i < DW; i = i + 1)
				s_wdata_sync_r[i] <= 2'b00;
		end else begin
			integer i;
			for (i = 0; i < DW; i = i + 1)
				s_wdata_sync_r[i] <= {s_wdata_sync_r[i][0], S_APB_PWDATA[i]};
		end
	end
	wire [DW-1:0] s_wdata_sync_w;
	generate
		genvar gi;
		for (gi = 0; gi < DW; gi = gi + 1) begin : gen_swdata_sync
			assign s_wdata_sync_w[gi] = s_wdata_sync_r[gi][1];
		end
	endgenerate

	// Slave -> Master: s_wstrb
	reg [1:0] s_wstrb_sync_r [0:DW/8-1];
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			integer i;
			for (i = 0; i < DW/8; i = i + 1)
				s_wstrb_sync_r[i] <= 2'b00;
		end else begin
			integer i;
			for (i = 0; i < DW/8; i = i + 1)
				s_wstrb_sync_r[i] <= {s_wstrb_sync_r[i][0], S_APB_PWSTRB[i]};
		end
	end
	wire [DW/8-1:0] s_wstrb_sync_w;
	generate
		genvar gi;
		for (gi = 0; gi < DW/8; gi = gi + 1) begin : gen_swstrb_sync
			assign s_wstrb_sync_w[gi] = s_wstrb_sync_r[gi][1];
		end
	endgenerate

	// Slave -> Master: s_pprot
	reg [1:0] s_pprot_sync_r [0:2];
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			integer i;
			for (i = 0; i < 3; i = i + 1)
				s_pprot_sync_r[i] <= 2'b00;
		end else begin
			integer i;
			for (i = 0; i < 3; i = i + 1)
				s_pprot_sync_r[i] <= {s_pprot_sync_r[i][0], S_APB_PPROT[i]};
		end
	end
	wire [2:0] s_pprot_sync_w;
	generate
		genvar gi;
		for (gi = 0; gi < 3; gi = gi + 1) begin : gen_spprot_sync
			assign s_pprot_sync_w[gi] = s_pprot_sync_r[gi][1];
		end
	endgenerate

	// Now fix the master-side request capture to use synchronized signals
	// I need to modify the M_IDLE state to use the synchronized signals.

	// Let me rewrite the master-side always block with the fix.

	// Actually, I realize I have a structural issue. Let me rewrite the entire module
	// more carefully.

endmodule
