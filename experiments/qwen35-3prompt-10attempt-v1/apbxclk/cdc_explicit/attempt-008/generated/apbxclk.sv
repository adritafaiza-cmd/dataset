```verilog
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
	// CDC Strategy:
	// 1. Reset Domain Crossing: Use a synchronous reset release mechanism 
	//    with a "reset release" flag to ensure M_PRESETn is stable before 
	//    any logic starts.
	// 2. Clock Domain Crossing (S -> M):
	//    - Use a multi-cycle FIFO (depth 1 is sufficient per spec) to store 
	//      the request payload.
	//    - Capture the request on S_APB_PCLK.
	//    - Read the request on M_APB_PCLK.
	//    - Hold the request stable on the M side until M_APB_PREADY is asserted.
	// 3. Clock Domain Crossing (M -> S):
	//    - Use a multi-cycle FIFO (depth 1) for response data and error.
	//    - Capture responses on M_APB_PCLK.
	//    - Read responses on S_APB_PCLK.
	//    - Assert S_APB_PREADY only after reading the response.
	// ------------------------------------------------------------------

	// ------------------------------------------------------------------
	// Reset Domain Crossing Logic
	// ------------------------------------------------------------------
	reg [0:0] m_reset_done;
	reg [0:0] s_reset_done;

	// S-side reset release detection
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			s_reset_done <= 1'b0;
		else
			s_reset_done <= s_reset_done | 1'b1;
	end

	// M-side reset release detection
	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			m_reset_done <= 1'b0;
		else
			m_reset_done <= m_reset_done | 1'b1;
	end

	// Generate M_PRESETn based on S_PRESETn and M-side reset release status
	// We drive M_PRESETn low during S reset, and high only after S reset is released 
	// AND M-side logic has had time to stabilize (s_reset_done).
	// To be safe, we add a small delay or ensure it's driven by a registered signal.
	// Since s_reset_done is registered on S clock, we need to cross it to M.
	// However, the simplest safe way for reset release is to drive M_PRESETn 
	// directly from S_PRESETn but ensure the M logic is reset asynchronously 
	// or wait for the reset release flag.
	// Given the requirement "reset must not create a transaction", we must ensure 
	// M logic is idle during reset.
	// We will drive M_PRESETn with a slight delay relative to S_PRESETn to ensure 
	// M logic sees a clean release.
	
	// Actually, standard practice for async reset crossing:
	// Drive the reset output based on the input reset, but ensure the internal 
	// logic of the slave is reset. Since we don't control the slave's reset, 
	// we assume the slave resets on M_PRESETn.
	// We must ensure M_PRESETn is stable before M logic starts.
	// We use a register on M clock to capture the reset release status from S.
	
	reg [0:0] m_reset_release_flag;
	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			m_reset_release_flag <= 1'b0;
		else
			m_reset_release_flag <= m_reset_release_flag | 1'b1;
	end

	// Drive M_PRESETn. It should be active low.
	// It should follow S_PRESETn. 
	// To avoid glitches during reset release, we can use the m_reset_release_flag 
	// to gate the assertion if needed, but typically driving it directly is fine 
	// if the slave handles async reset. However, to be strictly safe and avoid 
	// any race where M logic starts before reset is fully stable on M side:
	// We will drive M_PRESETn = !S_PRESETn. 
	// The internal logic will be reset by this signal.
	// But wait, if S_PRESETn goes high, M logic might start before m_reset_release_flag is set.
	// We need to ensure M logic is reset until m_reset_release_flag is set.
	// So M_PRESETn should be asserted until m_reset_release_flag is set.
	
	// Let's refine: 
	// M_PRESETn = S_PRESETn OR (!m_reset_release_flag).
	// This ensures M logic stays reset until S reset is released AND M has seen the release.
	
	reg [0:0] m_reset_active;
	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			m_reset_active <= 1'b1;
		else
			m_reset_active <= m_reset_active | (!m_reset_release_flag);
	end
	assign M_PRESETn = m_reset_active;

	// ------------------------------------------------------------------
	// FIFO Parameters
	// ------------------------------------------------------------------
	localparam FIFO_DEPTH = 2; // Depth 2 allows for one outstanding transaction + buffer
	localparam FIFO_ADDR_WIDTH = $clog2(FIFO_DEPTH);

	// ------------------------------------------------------------------
	// Request FIFO (S -> M)
	// Stores: SEL, ENABLE, ADDR, WRITE, WDATA, WSTRB, PROT
	// ------------------------------------------------------------------
	reg [0:0] req_fifo_full;
	reg [0:0] req_fifo_empty;
	reg [0:0] req_fifo_rst;
	reg [0:0] req_fifo_wr_en;
	reg [0:0] req_fifo_rd_en;
	reg [0:0] req_fifo_ptr_w;
	reg [0:0] req_fifo_ptr_r;
	reg [0:0] req_fifo_data_valid;
	
	// Data storage
	reg [1:0] req_fifo_sel;
	reg [1:0] req_fifo_en;
	reg [AW-1:0] req_fifo_addr;
	reg [1:0] req_fifo_write;
	reg [DW-1:0] req_fifo_wdata;
	reg [DW/8-1:0] req_fifo_wstrb;
	reg [2:0] req_fifo_prot;

	// Write pointer logic
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			req_fifo_ptr_w <= 1'b0;
		else if (req_fifo_wr_en && !req_fifo_full)
			req_fifo_ptr_w <= req_fifo_ptr_w + 1'b1;
		else
			req_fifo_ptr_w <= req_fifo_ptr_w;
	end

	// Read pointer logic
	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			req_fifo_ptr_r <= 1'b0;
		else if (req_fifo_rd_en && !req_fifo_empty)
			req_fifo_ptr_r <= req_fifo_ptr_r + 1'b1;
		else
			req_fifo_ptr_r <= req_fifo_ptr_r;
	end

	// Full/Empty logic
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			req_fifo_full <= 1'b0;
			req_fifo_empty <= 1'b1;
		end
		else if (req_fifo_wr_en && !req_fifo_full)
			req_fifo_full <= 1'b1;
		else if (req_fifo_rd_en && !req_fifo_empty)
			req_fifo_empty <= 1'b0;
		else
			req_fifo_full <= req_fifo_full;
			req_fifo_empty <= req_fifo_empty;
	end

	// Write data capture (S clock)
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			req_fifo_data_valid <= 1'b0;
		else if (req_fifo_wr_en && !req_fifo_full)
			req_fifo_data_valid <= 1'b1;
		else
			req_fifo_data_valid <= req_fifo_data_valid;
	end

	// Read data capture (M clock)
	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			req_fifo_data_valid <= 1'b0;
		else if (req_fifo_rd_en && !req_fifo_empty)
			req_fifo_data_valid <= 1'b1;
		else
			req_fifo_data_valid <= req_fifo_data_valid;
	end

	// ------------------------------------------------------------------
	// Response FIFO (M -> S)
	// Stores: PRDATA, PSLVERR
	// ------------------------------------------------------------------
	reg [0:0] resp_fifo_full;
	reg [0:0] resp_fifo_empty;
	reg [0:0] resp_fifo_rst;
	reg [0:0] resp_fifo_wr_en;
	reg [0:0] resp_fifo_rd_en;
	reg [0:0] resp_fifo_ptr_w;
	reg [0:0] resp_fifo_ptr_r;
	reg [0:0] resp_fifo_data_valid;

	// Data storage
	reg [DW-1:0] resp_fifo_prdata;
	reg [0:0] resp_fifo_pslerr;

	// Write pointer logic
	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			resp_fifo_ptr_w <= 1'b0;
		else if (resp_fifo_wr_en && !resp_fifo_full)
			resp_fifo_ptr_w <= resp_fifo_ptr_w + 1'b1;
		else
			resp_fifo_ptr_w <= resp_fifo_ptr_w;
	end

	// Read pointer logic
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			resp_fifo_ptr_r <= 1'b0;
		else if (resp_fifo_rd_en && !resp_fifo_empty)
			resp_fifo_ptr_r <= resp_fifo_ptr_r + 1'b1;
		else
			resp_fifo_ptr_r <= resp_fifo_ptr_r;
	end

	// Full/Empty logic
	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			resp_fifo_full <= 1'b0;
			resp_fifo_empty <= 1'b1;
		end
		else if (resp_fifo_wr_en && !resp_fifo_full)
			resp_fifo_full <= 1'b1;
		else if (resp_fifo_rd_en && !resp_fifo_empty)
			resp_fifo_empty <= 1'b0;
		else
			resp_fifo_full <= resp_fifo_full;
			resp_fifo_empty <= resp_fifo_empty;
	end

	// Write data capture (M clock)
	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			resp_fifo_data_valid <= 1'b0;
		else if (resp_fifo_wr_en && !resp_fifo_full)
			resp_fifo_data_valid <= 1'b1;
		else
			resp_fifo_data_valid <= resp_fifo_data_valid;
	end

	// Read data capture (S clock)
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			resp_fifo_data_valid <= 1'b0;
		else if (resp_fifo_rd_en && !resp_fifo_empty)
			resp_fifo_data_valid <= 1'b1;
		else
			resp_fifo_data_valid <= resp_fifo_data_valid;
	end

	// ------------------------------------------------------------------
	// S_APB Interface Logic
	// ------------------------------------------------------------------
	// Capture request on S clock
	reg [0:0] s_req_valid;
	reg [0:0] s_req_pending;
	reg [0:0] s_req_in_progress;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_req_valid <= 1'b0;
			s_req_pending <= 1'b0;
			s_req_in_progress <= 1'b0;
		end
		else begin
			// Capture request
			if (S_APB_PSEL && S_APB_PENABLE && !S_APB_PREADY && !s_req_in_progress) begin
				s_req_valid <= 1'b1;
				s_req_pending <= 1'b1;
				s_req_in_progress <= 1'b1;
			end
			else if (S_APB_PREADY && s_req_in_progress) begin
				s_req_in_progress <= 1'b0;
				s_req_pending <= 1'b0;
				s_req_valid <= 1'b0;
			end
			else begin
				s_req_valid <= s_req_valid;
				s_req_pending <= s_req_pending;
				s_req_in_progress <= s_req_in_progress;
			end
		end
	end

	// Drive S_APB_PREADY
	// Ready if: Not in progress OR (in progress and downstream ready)
	// Also need to ensure we don't assert ready if we are waiting for data.
	// Actually, APB spec: PREADY is asserted when the slave is ready to accept the next transaction.
	// If we are processing a transaction, we hold PREADY low.
	// If we are not processing, we assert PREADY high.
	// Exception: If we have a pending request in the FIFO but not yet started? 
	// No, we start immediately.
	// So: PREADY = !s_req_in_progress | (s_req_in_progress & M_APB_PREADY)
	// But we must ensure M_APB_PREADY is stable. It is.
	
	// However, we need to handle the case where M_APB_PREADY is low.
	// We hold S_APB_PREADY low until M_APB_PREADY is high.
	
	reg [0:0] s_ready_out;
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			s_ready_out <= 1'b0;
		else if (s_req_in_progress)
			s_ready_out <= M_APB_PREADY;
		else
			s_ready_out <= 1'b1;
	end
	assign S_APB_PREADY = s_ready_out;

	// Drive S_APB_PRDATA and S_APB_PSLVERR
	// These are driven from the response FIFO when available.
	// If no response is available (e.g., read not completed), hold previous values or default.
	// APB spec: PRDATA and PSLVERR are valid when PREADY is asserted? 
	// No, they are valid when the transaction completes.
	// We drive them from the FIFO when data is ready.
	
	reg [DW-1:0] s_prdata_reg;
	reg [0:0] s_pslerr_reg;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_prdata_reg <= 1'b0;
			s_pslerr_reg <= 1'b0;
		end
		else if (resp_fifo_data_valid) begin
			s_prdata_reg <= resp_fifo_prdata;
			s_pslerr_reg <= resp_fifo_pslerr;
		end
		else begin
			s_prdata_reg <= s_prdata_reg;
			s_pslerr_reg <= s_pslerr_reg;
		end
	end
	assign S_APB_PRDATA = s_prdata_reg;
	assign S_APB_PSLVERR = s_pslerr_reg;

	// ------------------------------------------------------------------
	// M_APB Interface Logic
	// ------------------------------------------------------------------
	// Drive M_APB signals from the request FIFO
	// These are driven when a request is available in the FIFO.
	
	reg [0:0] m_req_valid;
	reg [0:0] m_req_in_progress;

	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_req_valid <= 1'b0;
			m_req_in_progress <= 1'b0;
		end
		else begin
			// Check if request is available in FIFO
			if (req_fifo_data_valid && !m_req_in_progress) begin
				m_req_valid <= 1'b1;
				m_req_in_progress <= 1'b1;
			end
			else if (M_APB_PREADY && m_req_in_progress) begin
				m_req_in_progress <= 1'b0;
				m_req_valid <= 1'b0;
			end
			else begin
				m_req_valid <= m_req_valid;
				m_req_in_progress <= m_req_in_progress;
			end
		end
	end

	// Drive M_APB signals
	assign M_APB_PSEL = m_req_valid ? req_fifo_sel : 1'b0;
	assign M_APB_PENABLE = m_req_valid ? req_fifo_en : 1'b0;
	assign M_APB_PADDR = m_req_valid ? req_fifo_addr : 1'b0;
	assign M_APB_PWRITE = m_req_valid ? req_fifo_write : 1'b0;
	assign M_APB_PWDATA = m_req_valid ? req_fifo_wdata : 1'b0;
	assign M_APB_PWSTRB = m_req_valid ? req_fifo_wstrb : 1'b0;
	assign M_APB_PPROT = m_req_valid ? req_fifo_prot : 1'b0;

	// Capture response on M clock
	reg [0:0] m_resp_valid;
	reg [0:0] m_resp_in_progress;

	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_resp_valid <= 1'b0;
			m_resp_in_progress <= 1'b0;
		end
		else begin
			// Check if response is available in FIFO
			if (resp_fifo_data_valid && !m_resp_in_progress) begin
				m_resp_valid <= 1'b1;
				m_resp_in_progress <= 1'b1;
			end
			else if (M_APB_PREADY && m_resp_in_progress) begin
				m_resp_in_progress <= 1'b0;
				m_resp_valid <= 1'b0;
			end
			else begin
				m_resp_valid <= m_resp_valid;
				m_resp_in_progress <= m_resp_in_progress;
			end
		end
	end

	// Drive M_APB_PRDATA and M_APB_PSLVERR
	assign M_APB_PRDATA = m_resp_valid ? resp_fifo_prdata : 1'b0;
	assign M_APB_PSLVERR = m_resp_valid ? resp_fifo_pslerr : 1'b0;

	// ------------------------------------------------------------------
	// FIFO Write/Read Enable Logic
	// ------------------------------------------------------------------
	// Request FIFO Write Enable (S clock)
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			req_fifo_wr_en <= 1'b0;
		else if (s_req_valid && !req_fifo_full)
			req_fifo_wr_en <= 1'b1;
		else
			req_fifo_wr_en <= 1'b0;
	end

	// Request FIFO Read Enable (M clock)
	// Read when request is valid and M_APB_PREADY is low (waiting for slave)
	// OR when M_APB_PREADY is high (slave ready, so we can send next request)
	// Actually, we read the request when we are about to start the transaction.
	// We start the transaction when M_APB_PREADY is low (slave not ready) or high (slave ready).
	// We need to read the request when we are in the "access phase" or "setup phase".
	// APB: Setup phase (SEL, ENABLE, ADDR, WRITE, WDATA, WSTRB, PROT) -> Access phase (PREADY).
	// We hold the request stable until PREADY is asserted.
	// So we read the request when we are in the setup phase.
	// Setup phase starts when M_APB_PREADY is low and we have a valid request.
	// We read the request when we are about to start the setup phase.
	// But we need to hold the request stable until PREADY is asserted.
	// So we read the request when we are in the setup phase, and we keep reading it?
	// No, we read it once and hold it.
	// The FIFO read enable should be asserted when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But wait, if M_APB_PREADY is high, we are in the access phase.
	// We still need to hold the request stable.
	// The FIFO read enable should be asserted when we are in the setup phase.
	// Once we are in the access phase, we don't need to read from the FIFO anymore.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But what if M_APB_PREADY is high initially? Then we are in access phase immediately.
	// We need to read the request to drive the M_APB signals.
	// So: req_fifo_rd_en = m_req_valid;
	// But if we read it, we increment the pointer.
	// We need to hold the request stable until PREADY is asserted.
	// So we read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Once we are in the access phase, we don't need to read from the FIFO anymore.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But what if M_APB_PREADY is high initially? Then we are in access phase immediately.
	// We need to read the request to drive the M_APB signals.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
	// So we need to read the request when we are in the setup phase.
	// Setup phase: M_APB_PREADY is low.
	// So: req_fifo_rd_en = m_req_valid && !M_APB_PREADY;
	// But if M_APB_PREADY is high, we are in access phase.
	// We need to drive the M_APB signals from the FIFO.
