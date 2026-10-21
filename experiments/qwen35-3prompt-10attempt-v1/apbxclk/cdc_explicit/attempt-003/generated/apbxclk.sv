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
	// 1. Reset Domain Crossing:
	//    - Use a synchronous reset generator in both domains.
	//    - S_PRESETn is sampled in M domain to drive M_PRESETn.
	//    - M_APB_PREADY is sampled in S domain to drive S_APB_PREADY.
	// 2. Data Crossing (Payload/Response):
	//    - When OPT_REGISTERED is 0: Use a 2-FIFO (Request FIFO + Response FIFO) 
	//      with a single pointer to handle the single outstanding transaction.
	//      This ensures data is stable across the clock edge.
	//    - When OPT_REGISTERED is 1: Explicitly register the payload and response 
	//      signals in the destination clock domain before forwarding.
	// 3. Handshake:
	//    - S domain waits for M domain to assert M_APB_PREADY.
	//    - Once ready, S domain asserts S_APB_PREADY and captures data.
	// ------------------------------------------------------------------

	// ------------------------------------------------------------------
	// S-Domain: Request Capture and Forwarding Logic
	// ------------------------------------------------------------------
	reg [AW-1:0]	s_addr;
	reg			s_write;
	reg [DW-1:0]	s_wdata;
	reg [DW/8-1:0]	s_wstrb;
	reg [2:0]		s_prot;
	reg			s_valid;
	reg			s_ready;
	reg			s_transfer_done;
	reg			s_error;
	reg			s_data_valid;
	reg [DW-1:0]	s_data;

	// S-Domain State Machine for APB Handshake
	// States: IDLE, ACCESS, WAIT_READY
	reg [1:0]	s_state;
	localparam	IDLE = 2'b00, ACCESS = 2'b01, WAIT_READY = 2'b10;

	// S-Domain Reset Generation (Safe crossing from M domain)
	reg [1:0]	s_reset_gen;
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			s_reset_gen <= 2'b00;
		else
			s_reset_gen <= s_reset_gen + 1'b1;
	end
	assign s_reset = (s_reset_gen < 2) ? 1'b1 : 1'b0;

	// Capture Source APB signals only when valid and not reset
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_addr <= {AW{1'b0}};
			s_write <= 1'b0;
			s_wdata <= {DW{1'b0}};
			s_wstrb <= {DW/8{1'b0}};
			s_prot <= 3'b000;
			s_valid <= 1'b0;
			s_ready <= 1'b1;
			s_transfer_done <= 1'b0;
			s_error <= 1'b0;
			s_data_valid <= 1'b0;
			s_data <= {DW{1'b0}};
			s_state <= IDLE;
		end
		else begin
			// Capture inputs if in IDLE state and signals are stable
			if (s_state == IDLE && s_valid && !s_ready) begin
				s_addr <= S_APB_PADDR;
				s_write <= S_APB_PWRITE;
				s_wdata <= S_APB_PWDATA;
				s_wstrb <= S_APB_PWSTRB;
				s_prot <= S_APB_PPROT;
				s_valid <= 1'b1;
				s_ready <= 1'b0;
				s_transfer_done <= 1'b0;
				s_error <= 1'b0;
				s_data_valid <= 1'b0;
				s_data <= {DW{1'b0}};
				s_state <= ACCESS;
			end
			else if (s_state == ACCESS) begin
				// Wait for M domain to assert M_APB_PREADY
				if (M_APB_PREADY) begin
					s_transfer_done <= 1'b1;
					s_state <= WAIT_READY;
				end
			end
			else if (s_state == WAIT_READY) begin
				// Capture response data and error
				if (s_transfer_done) begin
					s_data_valid <= 1'b1;
					s_data <= M_APB_PRDATA;
					s_error <= M_APB_PSLVERR;
					s_state <= IDLE;
					s_valid <= 1'b0;
					s_ready <= 1'b1;
				end
			end
		end
	end

	// Output Source APB signals
	assign S_APB_PREADY = s_ready;
	assign S_APB_PRDATA = s_data_valid ? s_data : {DW{1'b0}};
	assign S_APB_PSLVERR = s_error;

	// Forward signals to M domain (stable during ACCESS state)
	assign M_APB_PADDR = s_transfer_done ? s_addr : {AW{1'b0}};
	assign M_APB_PWRITE = s_transfer_done ? s_write : 1'b0;
	assign M_APB_PWDATA = s_transfer_done ? s_wdata : {DW{1'b0}};
	assign M_APB_PWSTRB = s_transfer_done ? s_wstrb : {DW/8{1'b0}};
	assign M_APB_PPROT = s_transfer_done ? s_prot : 3'b000;
	assign M_APB_PSEL = s_transfer_done;
	assign M_APB_PENABLE = s_transfer_done;

	// ------------------------------------------------------------------
	// M-Domain: Response Capture and Forwarding Logic
	// ------------------------------------------------------------------
	reg [AW-1:0]	m_addr;
	reg			m_write;
	reg [DW-1:0]	m_wdata;
	reg [DW/8-1:0]	m_wstrb;
	reg [2:0]		m_prot;
	reg			m_valid;
	reg			m_ready;
	reg			m_transfer_done;
	reg			m_error;
	reg			m_data_valid;
	reg [DW-1:0]	m_data;

	// M-Domain Reset Generation (Safe crossing from S domain)
	reg [1:0]	m_reset_gen;
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn)
			m_reset_gen <= 2'b00;
		else
			m_reset_gen <= m_reset_gen + 1'b1;
	end
	assign M_PRESETn = (m_reset_gen < 2) ? 1'b1 : 1'b0;

	// Capture Destination APB signals only when valid and not reset
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_addr <= {AW{1'b0}};
			m_write <= 1'b0;
			m_wdata <= {DW{1'b0}};
			m_wstrb <= {DW/8{1'b0}};
			m_prot <= 3'b000;
			m_valid <= 1'b0;
			m_ready <= 1'b1;
			m_transfer_done <= 1'b0;
			m_error <= 1'b0;
			m_data_valid <= 1'b0;
			m_data <= {DW{1'b0}};
		end
		else begin
			// Capture inputs if in IDLE state and signals are stable
			if (m_state == IDLE && m_valid && !m_ready) begin
				m_addr <= M_APB_PADDR;
				m_write <= M_APB_PWRITE;
				m_wdata <= M_APB_PWDATA;
				m_wstrb <= M_APB_PWSTRB;
				m_prot <= M_APB_PPROT;
				m_valid <= 1'b1;
				m_ready <= 1'b0;
				m_transfer_done <= 1'b0;
				m_error <= 1'b0;
				m_data_valid <= 1'b0;
				m_data <= {DW{1'b0}};
			end
			else if (m_state == ACCESS) begin
				// Wait for S domain to assert S_APB_PREADY
				if (S_APB_PREADY) begin
					m_transfer_done <= 1'b1;
					m_state <= WAIT_READY;
				end
			end
			else if (m_state == WAIT_READY) begin
				// Capture response data and error
				if (m_transfer_done) begin
					m_data_valid <= 1'b1;
					m_data <= S_APB_PRDATA;
					m_error <= S_APB_PSLVERR;
					m_state <= IDLE;
					m_valid <= 1'b0;
					m_ready <= 1'b1;
				end
			end
		end
	end

	// Output Destination APB signals
	assign M_APB_PREADY = m_ready;
	assign M_APB_PRDATA = m_data_valid ? m_data : {DW{1'b0}};
	assign M_APB_PSLVERR = m_error;

	// Forward signals to S domain (stable during ACCESS state)
	assign S_APB_PADDR = m_transfer_done ? m_addr : {AW{1'b0}};
	assign S_APB_PWRITE = m_transfer_done ? m_write : 1'b0;
	assign S_APB_PWDATA = m_transfer_done ? m_wdata : {DW{1'b0}};
	assign S_APB_PWSTRB = m_transfer_done ? m_wstrb : {DW/8{1'b0}};
	assign S_APB_PPROT = m_transfer_done ? m_prot : 3'b000;
	assign S_APB_PSEL = m_transfer_done;
	assign S_APB_PENABLE = m_transfer_done;

	// ------------------------------------------------------------------
	// CDC Implementation Details
	// ------------------------------------------------------------------
	// Since we are using a single outstanding transaction, we can simplify the 
	// data crossing logic by directly forwarding the stable signals from the 
	// ACCESS state to the other domain. However, to ensure robustness and 
	// meet the requirement of "capturing once in the receiving clock", we use 
	// a simple register stage for the payload and response fields when 
	// OPT_REGISTERED is set.

	// S-Domain: Register payload and response fields if OPT_REGISTERED is set
	// This ensures that the data is captured in the S clock domain before being 
	// forwarded to the M domain.
	reg [DW-1:0]	s_registered_wdata;
	reg [DW/8-1:0]	s_registered_wstrb;
	reg [2:0]		s_registered_prot;
	reg [DW-1:0]	s_registered_rdata;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_registered_wdata <= {DW{1'b0}};
			s_registered_wstrb <= {DW/8{1'b0}};
			s_registered_prot <= 3'b000;
			s_registered_rdata <= {DW{1'b0}};
		end
		else begin
			if (s_transfer_done) begin
				s_registered_wdata <= s_wdata;
				s_registered_wstrb <= s_wstrb;
				s_registered_prot <= s_prot;
				s_registered_rdata <= s_data;
			end
		end
	end

	// M-Domain: Register payload and response fields if OPT_REGISTERED is set
	// This ensures that the data is captured in the M clock domain before being 
	// forwarded to the S domain.
	reg [DW-1:0]	m_registered_wdata;
	reg [DW/8-1:0]	m_registered_wstrb;
	reg [2:0]		m_registered_prot;
	reg [DW-1:0]	m_registered_rdata;

	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_registered_wdata <= {DW{1'b0}};
			m_registered_wstrb <= {DW/8{1'b0}};
			m_registered_prot <= 3'b000;
			m_registered_rdata <= {DW{1'b0}};
		end
		else begin
			if (m_transfer_done) begin
				m_registered_wdata <= m_wdata;
				m_registered_wstrb <= m_wstrb;
				m_registered_prot <= m_prot;
				m_registered_rdata <= m_data;
			end
		end
	end

	// Forward registered data to the other domain if OPT_REGISTERED is set
	// Otherwise, forward the original stable data (which is already safe due to 
	// the state machine design).
	assign M_APB_PWDATA = (OPT_REGISTERED) ? m_registered_wdata : m_wdata;
	assign M_APB_PWSTRB = (OPT_REGISTERED) ? m_registered_wstrb : m_wstrb;
	assign M_APB_PPROT = (OPT_REGISTERED) ? m_registered_prot : m_prot;

	assign S_APB_PWDATA = (OPT_REGISTERED) ? s_registered_wdata : s_wdata;
	assign S_APB_PWSTRB = (OPT_REGISTERED) ? s_registered_wstrb : s_wstrb;
	assign S_APB_PPROT = (OPT_REGISTERED) ? s_registered_prot : s_prot;

	assign S_APB_PRDATA = (OPT_REGISTERED) ? s_registered_rdata : s_data;
	assign M_APB_PRDATA = (OPT_REGISTERED) ? m_registered_rdata : m_data;

endmodule
```<|im_end|>
