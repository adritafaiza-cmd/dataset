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
	// 1. Reset Domain Crossing: Use a 2-bit synchronizer for S_PRESETn 
	//    to generate a safe M_PRESETn. The source domain uses the raw reset.
	// 2. Request Domain Crossing: Use a 2-bit synchronizer for S_APB_PSEL 
	//    to detect the start of a transaction in the Master clock domain.
	// 3. Data/Response Crossing: Use a 2-bit synchronizer for M_APB_PREADY 
	//    to detect the completion of the transaction in the Source clock domain.
	// 4. Handshake: Once a request is detected and completed, the data 
	//    is forwarded to the output registers in the Source domain.
	// ------------------------------------------------------------------

	// ------------------------------------------------------------------
	// Synchronizers for Reset (RDC)
	// ------------------------------------------------------------------
	reg [1:0] s_preset_sync;
	reg [1:0] m_preset_sync;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			s_preset_sync <= 2'b00;
		else
			s_preset_sync <= {s_preset_sync[0], s_preset_sync[1]};
	end

	always @(posedge M_APB_PCLK or negedge s_preset_sync) begin
		if (!s_preset_sync)
			m_preset_sync <= 2'b00;
		else
			m_preset_sync <= {m_preset_sync[0], m_preset_sync[1]};
	end

	// Safe reset for Master domain
	assign M_PRESETn = m_preset_sync[1] | m_preset_sync[0];

	// ------------------------------------------------------------------
	// Synchronizers for Request (CDC)
	// ------------------------------------------------------------------
	reg [1:0] s_sel_sync;
	reg [1:0] s_enable_sync;
	reg [1:0] s_addr_sync;
	reg [1:0] s_write_sync;
	reg [1:0] s_data_sync;
	reg [1:0] s_wstrb_sync;
	reg [1:0] s_prot_sync;

	// Synchronize S_APB_PSEL to detect transaction start
	always @(posedge S_APB_PCLK) begin
		if (S_PRESETn)
			s_sel_sync <= {s_sel_sync[0], s_sel_sync[1]};
		else
			s_sel_sync <= 2'b00;
	end

	// Synchronize S_APB_PENABLE
	always @(posedge S_APB_PCLK) begin
		if (S_PRESETn)
			s_enable_sync <= {s_enable_sync[0], s_enable_sync[1]};
		else
			s_enable_sync <= 2'b00;
	end

	// Synchronize Address, Write, Data, WSTRB, PROT
	always @(posedge S_APB_PCLK) begin
		if (S_PRESETn) begin
			s_addr_sync     <= {s_addr_sync[0], s_addr_sync[1]};
			s_write_sync    <= {s_write_sync[0], s_write_sync[1]};
			s_data_sync     <= {s_data_sync[0], s_data_sync[1]};
			s_wstrb_sync    <= {s_wstrb_sync[0], s_wstrb_sync[1]};
			s_prot_sync     <= {s_prot_sync[0], s_prot_sync[1]};
		end
		else begin
			s_addr_sync     <= 2'b00;
			s_write_sync    <= 2'b00;
			s_data_sync     <= 2'b00;
			s_wstrb_sync    <= 2'b00;
			s_prot_sync     <= 2'b00;
		end
	end

	// Detect valid request in Master clock domain
	reg [1:0] m_sel_sync;
	reg [1:0] m_enable_sync;
	reg [1:0] m_addr_sync;
	reg [1:0] m_write_sync;
	reg [1:0] m_data_sync;
	reg [1:0] m_wstrb_sync;
	reg [1:0] m_prot_sync;

	always @(posedge M_APB_PCLK) begin
		if (M_PRESETn) begin
			m_sel_sync     <= {m_sel_sync[0], m_sel_sync[1]};
			m_enable_sync  <= {m_enable_sync[0], m_enable_sync[1]};
			m_addr_sync    <= {m_addr_sync[0], m_addr_sync[1]};
			m_write_sync   <= {m_write_sync[0], m_write_sync[1]};
			m_data_sync    <= {m_data_sync[0], m_data_sync[1]};
			m_wstrb_sync   <= {m_wstrb_sync[0], m_wstrb_sync[1]};
			m_prot_sync    <= {m_prot_sync[0], m_prot_sync[1]};
		end
		else begin
			m_sel_sync     <= 2'b00;
			m_enable_sync  <= 2'b00;
			m_addr_sync    <= 2'b00;
			m_write_sync   <= 2'b00;
			m_data_sync    <= 2'b00;
			m_wstrb_sync   <= 2'b00;
			m_prot_sync    <= 2'b00;
		end
	end

	// ------------------------------------------------------------------
	// Synchronizers for Response (CDC)
	// ------------------------------------------------------------------
	reg [1:0] m_ready_sync;
	reg [1:0] m_prdata_sync;
	reg [1:0] m_slverr_sync;

	always @(posedge M_APB_PCLK) begin
		if (M_PRESETn) begin
			m_ready_sync   <= {m_ready_sync[0], m_ready_sync[1]};
			m_prdata_sync  <= {m_prdata_sync[0], m_prdata_sync[1]};
			m_slverr_sync  <= {m_slverr_sync[0], m_slverr_sync[1]};
		end
		else begin
			m_ready_sync   <= 2'b00;
			m_prdata_sync  <= 2'b00;
			m_slverr_sync  <= 2'b00;
		end
	end

	// ------------------------------------------------------------------
	// State Machine and Logic
	// ------------------------------------------------------------------
	reg [1:0] state;
	parameter IDLE = 2'b00;
	parameter REQ_SENT = 2'b01;
	parameter WAIT_READY = 2'b10;
	parameter DONE = 2'b11;

	// State Register
	reg [1:0] next_state;
	reg [1:0] current_state;

	// Internal signals for forwarding
	reg [AW-1:0] fwd_addr;
	reg [DW-1:0] fwd_data;
	reg [DW/8-1:0] fwd_wstrb;
	reg fwd_write;
	reg fwd_sel;
	reg fwd_enable;
	reg fwd_prot;
	reg fwd_slverr;

	// ------------------------------------------------------------------
	// State Logic
	// ------------------------------------------------------------------
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn)
			current_state <= IDLE;
		else
			current_state <= next_state;
	end

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			next_state <= IDLE;
		else
			next_state <= current_state;
	end

	// ------------------------------------------------------------------
	// Master Side Logic (Driving M_APB)
	// ------------------------------------------------------------------
	// Drive M_APB signals based on current state and synchronized source data
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			M_APB_PSEL     <= 1'b0;
			M_APB_PENABLE  <= 1'b0;
			M_APB_PADDR    <= 0;
			M_APB_PWRITE   <= 1'b0;
			M_APB_PWDATA   <= 0;
			M_APB_PWSTRB   <= 0;
			M_APB_PPROT    <= 0;
		end
		else begin
			case (current_state)
				IDLE: begin
					// Wait for request detection
					if (m_sel_sync[1]) begin
						// Start of transaction detected
						M_APB_PSEL     <= 1'b1;
						M_APB_PENABLE  <= 1'b1;
						M_APB_PADDR    <= m_addr_sync[1] ? m_addr_sync[1] : m_addr_sync[0];
						M_APB_PWRITE   <= m_write_sync[1] ? m_write_sync[1] : m_write_sync[0];
						M_APB_PWDATA   <= m_data_sync[1] ? m_data_sync[1] : m_data_sync[0];
						M_APB_PWSTRB   <= m_wstrb_sync[1] ? m_wstrb_sync[1] : m_wstrb_sync[0];
						M_APB_PPROT    <= m_prot_sync[1] ? m_prot_sync[1] : m_prot_sync[0];
						next_state     <= REQ_SENT;
					end
					else begin
						M_APB_PSEL     <= 1'b0;
						M_APB_PENABLE  <= 1'b0;
						M_APB_PADDR    <= 0;
						M_APB_PWRITE   <= 1'b0;
						M_APB_PWDATA   <= 0;
						M_APB_PWSTRB   <= 0;
						M_APB_PPROT    <= 0;
						next_state     <= IDLE;
					end
				end

				REQ_SENT: begin
					// Wait for M_APB_PREADY
					if (m_ready_sync[1]) begin
						// Transaction complete
						M_APB_PSEL     <= 1'b0;
						M_APB_PENABLE  <= 1'b0;
						M_APB_PADDR    <= 0;
						M_APB_PWRITE   <= 1'b0;
						M_APB_PWDATA   <= 0;
						M_APB_PWSTRB   <= 0;
						M_APB_PPROT    <= 0;
						next_state     <= DONE;
					end
					else begin
						// Keep signals stable
						next_state     <= REQ_SENT;
					end
				end

				DONE: begin
					// Wait for response synchronization
					if (m_ready_sync[1]) begin
						// Response captured, return to idle
						M_APB_PSEL     <= 1'b0;
						M_APB_PENABLE  <= 1'b0;
						M_APB_PADDR    <= 0;
						M_APB_PWRITE   <= 1'b0;
						M_APB_PWDATA   <= 0;
						M_APB_PWSTRB   <= 0;
						M_APB_PPROT    <= 0;
						next_state     <= IDLE;
					end
					else begin
						next_state     <= DONE;
					end
				end

				default: begin
					M_APB_PSEL     <= 1'b0;
					M_APB_PENABLE  <= 1'b0;
					M_APB_PADDR    <= 0;
					M_APB_PWRITE   <= 1'b0;
					M_APB_PWDATA   <= 0;
					M_APB_PWSTRB   <= 0;
					M_APB_PPROT    <= 0;
					next_state     <= IDLE;
				end
			endcase
		end
	end

	// ------------------------------------------------------------------
	// Source Side Logic (Driving S_APB)
	// ------------------------------------------------------------------
	// Capture data when transaction is detected and complete
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			fwd_addr       <= 0;
			fwd_data       <= 0;
			fwd_wstrb      <= 0;
			fwd_write      <= 0;
			fwd_sel        <= 0;
			fwd_enable     <= 0;
			fwd_prot       <= 0;
			fwd_slverr     <= 0;
			S_APB_PREADY   <= 1'b0;
			S_APB_PRDATA   <= 0;
			S_APB_PSLVERR  <= 1'b0;
		end
		else begin
			case (current_state)
				IDLE: begin
					// Wait for request detection
					if (m_sel_sync[1]) begin
						// Capture data for forwarding
						fwd_addr       <= m_addr_sync[1] ? m_addr_sync[1] : m_addr_sync[0];
						fwd_data       <= m_data_sync[1] ? m_data_sync[1] : m_data_sync[0];
						fwd_wstrb      <= m_wstrb_sync[1] ? m_wstrb_sync[1] : m_wstrb_sync[0];
						fwd_write      <= m_write_sync[1] ? m_write_sync[1] : m_write_sync[0];
						fwd_sel        <= m_sel_sync[1] ? m_sel_sync[1] : m_sel_sync[0];
						fwd_enable     <= m_enable_sync[1] ? m_enable_sync[1] : m_enable_sync[0];
						fwd_prot       <= m_prot_sync[1] ? m_prot_sync[1] : m_prot_sync[0];
						S_APB_PREADY   <= 1'b0;
						S_APB_PRDATA   <= 0;
						S_APB_PSLVERR  <= 1'b0;
						next_state     <= REQ_SENT;
					end
					else begin
						S_APB_PREADY   <= 1'b0;
						S_APB_PRDATA   <= 0;
						S_APB_PSLVERR  <= 1'b0;
						next_state     <= IDLE;
					end
				end

				REQ_SENT: begin
					// Wait for completion
					if (m_ready_sync[1]) begin
						// Capture response
						fwd_slverr     <= m_slverr_sync[1] ? m_slverr_sync[1] : m_slverr_sync[0];
						S_APB_PRDATA   <= m_prdata_sync[1] ? m_prdata_sync[1] : m_prdata_sync[0];
						S_APB_PSLVERR  <= fwd_slverr;
						S_APB_PREADY   <= 1'b1;
						next_state     <= DONE;
					end
					else begin
						S_APB_PREADY   <= 1'b0;
						S_APB_PRDATA   <= 0;
						S_APB_PSLVERR  <= 1'b0;
						next_state     <= REQ_SENT;
					end
				end

				DONE: begin
					// Wait for response synchronization
					if (m_ready_sync[1]) begin
						// Response captured, return to idle
						S_APB_PREADY   <= 1'b0;
						S_APB_PRDATA   <= 0;
						S_APB_PSLVERR  <= 1'b0;
						next_state     <= IDLE;
					end
					else begin
						S_APB_PREADY   <= 1'b0;
						S_APB_PRDATA   <= 0;
						S_APB_PSLVERR  <= 1'b0;
						next_state     <= DONE;
					end
				end

				default: begin
					S_APB_PREADY   <= 1'b0;
					S_APB_PRDATA   <= 0;
					S_APB_PSLVERR  <= 1'b0;
					next_state     <= IDLE;
				end
			endcase
		end
	end

	// ------------------------------------------------------------------
	// Output Assignments
	// ------------------------------------------------------------------
	assign S_APB_PSEL     = fwd_sel;
	assign S_APB_PENABLE  = fwd_enable;
	assign S_APB_PADDR    = fwd_addr;
	assign S_APB_PWRITE   = fwd_write;
	assign S_APB_PWDATA   = fwd_data;
	assign S_APB_PWSTRB   = fwd_wstrb;
	assign S_APB_PPROT    = fwd_prot;
	assign S_APB_PRDATA   = S_APB_PRDATA; // Already assigned in state logic
	assign S_APB_PSLVERR  = S_APB_PSLVERR; // Already assigned in state logic

	assign M_APB_PSEL     = M_APB_PSEL; // Already assigned in state logic
	assign M_APB_PENABLE  = M_APB_PENABLE; // Already assigned in state logic
	assign M_APB_PADDR    = M_APB_PADDR; // Already assigned in state logic
	assign M_APB_PWRITE   = M_APB_PWRITE; // Already assigned in state logic
	assign M_APB_PWDATA   = M_APB_PWDATA; // Already assigned in state logic
	assign M_APB_PWSTRB   = M_APB_PWSTRB; // Already assigned in state logic
	assign M_APB_PPROT    = M_APB_PPROT; // Already assigned in state logic
	assign M_APB_PRDATA   = M_APB_PRDATA; // Already assigned in state logic
	assign M_APB_PSLVERR  = M_APB_PSLVERR; // Already assigned in state logic

endmodule
```<|im_end|>
