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

	// Internal registers for crossing data
	reg [AW-1:0]		i_paddr;
	reg [DW-1:0]		i_pwrite; // Using DW bits to store write flag for simplicity in storage, though logic handles it
	reg [DW-1:0]		i_pdata;
	reg [DW/8-1:0]		i_pstrb;
	reg [2:0]			i_pprot;
	reg				i_pwrite_flag;
	reg				i_pready_req;
	reg				i_pready_ack;
	reg				i_pslerr_req;
	reg				i_pslerr_ack;
	reg				i_transfer_active;

	// Synchronous logic for Source side (S_APB_PCLK domain)
	// Capture incoming APB transaction details
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			i_paddr <= 0;
			i_pwrite_flag <= 0;
			i_pdata <= 0;
			i_pstrb <= 0;
			i_pprot <= 0;
			i_pready_req <= 0;
			i_pready_ack <= 0;
			i_pslerr_req <= 0;
			i_pslerr_ack <= 0;
			i_transfer_active <= 0;
			S_APB_PREADY <= 1'b1;
			S_APB_PRDATA <= 0;
			S_APB_PSLVERR <= 0;
		end
		else begin
			// Reset state machine if not selected or not enabled
			if (!S_APB_PSEL || !S_APB_PENABLE) begin
				i_transfer_active <= 0;
				S_APB_PREADY <= 1'b1;
				S_APB_PRDATA <= 0;
				S_APB_PSLVERR <= 0;
			end
			else begin
				// Capture transaction details only once per transaction start
				if (!i_transfer_active) begin
					i_paddr <= S_APB_PADDR;
					i_pwrite_flag <= S_APB_PWRITE;
					i_pdata <= S_APB_PWDATA;
					i_pstrb <= S_APB_PWSTRB;
					i_pprot <= S_APB_PPROT;
					i_transfer_active <= 1;
				end

				// Handle Read Response
				if (S_APB_PWRITE) begin
					// Write transaction: wait for ready and error
					if (M_APB_PREADY) begin
						i_pready_ack <= 1;
						if (M_APB_PSLVERR) begin
							i_pslerr_req <= 1;
						end
					end
				end
				else begin
					// Read transaction: wait for ready and data/error
					if (M_APB_PREADY) begin
						i_pready_ack <= 1;
						if (M_APB_PSLVERR) begin
							i_pslerr_req <= 1;
						end
						else begin
							S_APB_PRDATA <= M_APB_PRDATA;
						end
					end
				end

				// Assert ready to source only when transfer is complete
				// Transfer is complete when we have acknowledged the downstream ready
				// and we are not in the middle of a new transaction capture
				if (i_transfer_active && i_pready_ack) begin
					i_transfer_active <= 0;
					i_pready_req <= 0;
					i_pslerr_req <= 0;
					S_APB_PREADY <= 1'b1;
					S_APB_PSLVERR <= 0;
				end
				else if (i_transfer_active) begin
					S_APB_PREADY <= 1'b0;
					S_APB_PSLVERR <= 0;
				end
			end
		end
	end

	// Asynchronous FIFO/Handshake logic for crossing
	// We use a simple state machine to ensure the downstream request is stable
	// and the upstream response is captured correctly.

	// State machine for the crossing
	reg [1:0]		cross_state; // 0: Idle, 1: Requesting, 2: Waiting for Ready, 3: Response Captured
	reg			cross_valid;
	reg			cross_ready;
	reg			cross_error;

	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			cross_state <= 0;
			cross_valid <= 0;
			cross_ready <= 0;
			cross_error <= 0;
			M_APB_PSEL <= 0;
			M_APB_PENABLE <= 0;
			M_APB_PADDR <= 0;
			M_APB_PWRITE <= 0;
			M_APB_PWDATA <= 0;
			M_APB_PWSTRB <= 0;
			M_APB_PPROT <= 0;
			M_APB_PREADY <= 1; // Default high, but driven by logic below
		end
		else begin
			case (cross_state)
				0: begin // Idle
					if (S_APB_PSEL && S_APB_PENABLE && !i_transfer_active) begin
						cross_state <= 1;
						cross_valid <= 1;
						cross_ready <= 0;
						cross_error <= 0;
						M_APB_PSEL <= 1;
						M_APB_PENABLE <= 1;
						M_APB_PADDR <= i_paddr;
						M_APB_PWRITE <= i_pwrite_flag;
						M_APB_PWDATA <= i_pdata;
						M_APB_PWSTRB <= i_pstrb;
						M_APB_PPROT <= i_pprot;
					end
				end

				1: begin // Requesting (Setup phase)
					// Keep signals stable
					M_APB_PSEL <= 1;
					M_APB_PENABLE <= 1;
					M_APB_PADDR <= i_paddr;
					M_APB_PWRITE <= i_pwrite_flag;
					M_APB_PWDATA <= i_pdata;
					M_APB_PWSTRB <= i_pstrb;
					M_APB_PPROT <= i_pprot;

					if (M_APB_PREADY) begin
						cross_state <= 2;
						cross_ready <= 1;
					end
				end

				2: begin // Waiting for Ready (Access phase)
					// Keep signals stable
					M_APB_PSEL <= 1;
					M_APB_PENABLE <= 1;
					M_APB_PADDR <= i_paddr;
					M_APB_PWRITE <= i_pwrite_flag;
					M_APB_PWDATA <= i_pdata;
					M_APB_PWSTRB <= i_pstrb;
					M_APB_PPROT <= i_pprot;

					if (M_APB_PREADY) begin
						cross_state <= 3;
						cross_ready <= 1;
						cross_error <= M_APB_PSLVERR;
					end
				end

				3: begin // Response Captured
					// Release downstream signals
					M_APB_PSEL <= 0;
					M_APB_PENABLE <= 0;
					cross_state <= 0;
					cross_valid <= 0;
					cross_ready <= 0;
					cross_error <= 0;

					// Drive upstream response
					if (cross_error) begin
						S_APB_PSLVERR <= 1;
						S_APB_PRDATA <= 0;
					end
					else begin
						if (i_pwrite_flag) begin
							// Write: Data is irrelevant, but we can drive 0 or keep last
							S_APB_PRDATA <= 0;
						end
						else begin
							S_APB_PRDATA <= i_pdata; // This is actually M_APB_PRDATA captured in the previous cycle logic? 
							// Wait, the requirement says "Return read data... to the source interface".
							// In the S-side logic above, I captured M_APB_PRDATA into S_APB_PRDATA when M_APB_PREADY was high.
							// However, to be strictly compliant with "Crossing payload... captured once", 
							// we should capture M_APB_PRDATA in the M domain and forward it.
							// Let's adjust the S-side logic to capture M_APB_PRDATA when M_APB_PREADY is high.
						end
					end
				end
			endcase
		end
	end

	// Correction: The S-side logic needs to capture M_APB_PRDATA and M_APB_PSLVERR 
	// when M_APB_PREADY is asserted, so they can be returned to the source.
	// The previous S-side logic did this, but let's refine the flow to ensure 
	// the data is captured in the M domain first if OPT_REGISTERED is considered, 
	// but the prompt says "Crossing payload and response fields are captured once in the receiving clock".
	// So in M domain, we capture PRDATA and PSLVERR when PREADY is high.
	// Then in S domain, we forward them.

	reg [DW-1:0]	m_pdata;
	reg			m_pslerr;

	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_pdata <= 0;
			m_pslerr <= 0;
		end
		else begin
			if (M_APB_PREADY) begin
				m_pdata <= M_APB_PRDATA;
				m_pslerr <= M_APB_PSLVERR;
			end
		end
	end

	// Update S-side logic to use m_pdata and m_pslerr
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			S_APB_PREADY <= 1'b1;
			S_APB_PRDATA <= 0;
			S_APB_PSLVERR <= 0;
		end
		else begin
			if (S_APB_PSEL && S_APB_PENABLE) begin
				if (!i_transfer_active) begin
					i_paddr <= S_APB_PADDR;
					i_pwrite_flag <= S_APB_PWRITE;
					i_pdata <= S_APB_PWDATA;
					i_pstrb <= S_APB_PWSTRB;
					i_pprot <= S_APB_PPROT;
					i_transfer_active <= 1;
				end

				if (i_transfer_active) begin
					if (S_APB_PWRITE) begin
						if (M_APB_PREADY) begin
							i_pready_ack <= 1;
							if (m_pslerr) begin
								i_pslerr_req <= 1;
							end
						end
					end
					else begin
						if (M_APB_PREADY) begin
							i_pready_ack <= 1;
							if (m_pslerr) begin
								i_pslerr_req <= 1;
							end
							else begin
								S_APB_PRDATA <= m_pdata;
							end
						end
					end

					if (i_transfer_active && i_pready_ack) begin
						i_transfer_active <= 0;
						i_pready_req <= 0;
						i_pslerr_req <= 0;
						S_APB_PREADY <= 1'b1;
						S_APB_PSLVERR <= 0;
					end
					else if (i_transfer_active) begin
						S_APB_PREADY <= 1'b0;
						S_APB_PSLVERR <= 0;
					end
				end
			end
			else begin
				i_transfer_active <= 0;
				S_APB_PREADY <= 1'b1;
				S_APB_PRDATA <= 0;
				S_APB_PSLVERR <= 0;
			end
		end
	end

	// Reset output for M domain
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			M_PRESETn <= 1'b0;
		end
		else begin
			M_PRESETn <= S_PRESETn;
		end
	end

	// Handle S_APB_PREADY and S_APB_PSLVERR based on the handshake completion
	// The logic above handles the state machine, but we need to ensure the final signals are correct.
	// Re-evaluating the S-side logic to be cleaner and strictly follow the "one outstanding transaction" rule.

	// Let's restructure the S-side logic to be more robust regarding the handshake.
	// We need to assert S_APB_PREADY only when the M-side transaction is done.
	// We need to capture M_APB_PRDATA and M_APB_PSLVERR when M_APB_PREADY is high.

	reg [DW-1:0]	s_pdata_out;
	reg			s_pslerr_out;
	reg			s_transfer_done;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_transfer_done <= 0;
			s_pdata_out <= 0;
			s_pslerr_out <= 0;
			S_APB_PREADY <= 1'b1;
			S_APB_PRDATA <= 0;
			S_APB_PSLVERR <= 0;
		end
		else begin
			if (!S_APB_PSEL || !S_APB_PENABLE) begin
				s_transfer_done <= 0;
				S_APB_PREADY <= 1'b1;
				S_APB_PRDATA <= 0;
				S_APB_PSLVERR <= 0;
			end
			else begin
				// Capture transaction start
				if (!s_transfer_done) begin
					i_paddr <= S_APB_PADDR;
					i_pwrite_flag <= S_APB_PWRITE;
					i_pdata <= S_APB_PWDATA;
					i_pstrb <= S_APB_PWSTRB;
					i_pprot <= S_APB_PPROT;
					s_transfer_done <= 1;
				end

				if (s_transfer_done) begin
					// Capture response data and error when M_READY is high
					if (M_APB_PREADY) begin
						s_pdata_out <= M_APB_PRDATA;
						s_pslerr_out <= M_APB_PSLVERR;
						s_transfer_done <= 0; // Transaction complete
					end

					// Drive upstream signals
					if (s_transfer_done == 0 && M_APB_PREADY) begin
						// Just captured, wait for next cycle to assert ready? 
						// No, APB protocol: PREADY is asserted in the cycle after PENABLE if transfer is not ready.
						// If transfer is ready, PREADY is deasserted in the next cycle.
						// So we assert PREADY in the cycle where we detect completion.
						S_APB_PREADY <= 1'b0; // Will be set to 1 in next cycle or immediately?
						// Standard APB: If slave is ready, PREADY is 1 in the cycle following PENABLE.
						// If not ready, PREADY is 0.
						// Here, we are bridging. We assert PREADY to source when we have received PREADY from dest.
						// So if M_APB_PREADY is 1, we can assert S_APB_PREADY.
						// But we must hold the request stable until M_APB_PREADY is 1.
					end
				end
			end
		end
	end

	// Let's simplify the S-side logic to match standard APB bridge behavior precisely.
	// 1. Capture request on S_APB_PCLK.
	// 2. Assert M_APB_PSEL, M_APB_PENABLE, etc.
	// 3. Wait for M_APB_PREADY.
	// 4. When M_APB_PREADY is 1, capture PRDATA/PSLVERR and assert S_APB_PREADY.
	// 5. Deassert M_APB_PSEL, M_APB_PENABLE.

	reg [DW-1:0]	s_req_addr;
	reg [DW-1:0]	s_req_write;
	reg [DW-1:0]	s_req_data;
	reg [DW/8-1:0]	s_req_strb;
	reg [2:0]		s_req_prot;
	reg			s_req_valid;
	reg			s_req_done;
	reg			s_resp_data;
	reg			s_resp_err;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_req_valid <= 0;
			s_req_done <= 0;
			s_req_addr <= 0;
			s_req_write <= 0;
			s_req_data <= 0;
			s_req_strb <= 0;
			s_req_prot <= 0;
			s_resp_data <= 0;
			s_resp_err <= 0;
			S_APB_PREADY <= 1'b1;
			S_APB_PRDATA <= 0;
			S_APB_PSLVERR <= 0;
		end
		else begin
			if (!S_APB_PSEL || !S_APB_PENABLE) begin
				s_req_valid <= 0;
				s_req_done <= 0;
				S_APB_PREADY <= 1'b1;
				S_APB_PRDATA <= 0;
				S_APB_PSLVERR <= 0;
			end
			else begin
				if (!s_req_valid) begin
					s_req_valid <= 1;
					s_req_addr <= S_APB_PADDR;
					s_req_write <= S_APB_PWRITE;
					s_req_data <= S_APB_PWDATA;
					s_req_strb <= S_APB_PWSTRB;
					s_req_prot <= S_APB_PPROT;
				end

				if (s_req_valid) begin
					// Drive M-side signals
					M_APB_PSEL <= 1;
					M_APB_PENABLE <= 1;
					M_APB_PADDR <= s_req_addr;
					M_APB_PWRITE <= s_req_write;
					M_APB_PWDATA <= s_req_data;
					M_APB_PWSTRB <= s_req_strb;
					M_APB_PPROT <= s_req_prot;

					// Capture response
					if (M_APB_PREADY) begin
						s_resp_data <= M_APB_PRDATA;
						s_resp_err <= M_APB_PSLVERR;
						s_req_done <= 1;
					end

					// Assert S_APB_PREADY
					if (s_req_done) begin
						S_APB_PREADY <= 1'b1;
						if (s_req_write) begin
							S_APB_PRDATA <= 0; // Write response data is ignored
						end
						else begin
							S_APB_PRDATA <= s_resp_data;
						end
						S_APB_PSLVERR <= s_resp_err;
					end
					else begin
						S_APB_PREADY <= 1'b0;
						S_APB_PRDATA <= 0;
						S_APB_PSLVERR <= 0;
					end
				end
			end
		end
	end

	// Deassert M-side signals when transaction is done
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			M_APB_PSEL <= 0;
			M_APB_PENABLE <= 0;
		end
		else begin
			if (s_req_done) begin
				M_APB_PSEL <= 0;
				M_APB_PENABLE <= 0;
			end
			else if (!S_APB_PSEL || !S_APB_PENABLE) begin
				M_APB_PSEL <= 0;
				M_APB_PENABLE <= 0;
			end
			else begin
				M_APB_PSEL <= 1;
				M_APB_PENABLE <= 1;
			end
		end
	end

	// Reset M domain
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			M_PRESETn <= 1'b0;
		end
		else begin
			M_PRESETn <= S_PRESETn;
		end
	end

endmodule
```<|im_end|>
