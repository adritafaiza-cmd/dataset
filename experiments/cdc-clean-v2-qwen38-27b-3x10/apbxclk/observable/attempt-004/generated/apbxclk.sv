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
	// Slave-side (S_APB_PCLK domain)
	// ------------------------------------------------------------------

	// Synchronization of master-side "transfer complete" signal
	reg [2:0] m_done_sync;
	reg       m_done_sync_d;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_done_sync   <= 3'b000;
			m_done_sync_d <= 1'b0;
		end else begin
			m_done_sync   <= {m_done_sync[1:0], m_done_sync_d};
			m_done_sync_d <= m_done_sync[2];
		end
	end

	wire s_m_done = m_done_sync[2];

	// Slave-side state machine
	// States:
	//   S_IDLE   : waiting for a new APB setup phase
	//   S_SETUP  : PSEL=1, PENABLE=0, capturing request, waiting to send
	//   S_WAIT   : request sent to master, waiting for completion
	//   S_RESP   : response received, presenting to slave, waiting for PENABLE=0

	localparam S_IDLE  = 2'b00;
	localparam S_SETUP = 2'b01;
	localparam S_WAIT  = 2'b10;
	localparam S_RESP  = 2'b11;

	reg [1:0] s_state;
	reg [1:0] s_state_next;

	// Latch request fields when entering S_WAIT
	reg [AW-1:0] s_addr_latch;
	reg          s_write_latch;
	reg [DW-1:0] s_wdata_latch;
	reg [DW/8-1:0] s_wstrb_latch;
	reg [2:0]    s_pprot_latch;

	// Response data and error, latched when response arrives
	reg [DW-1:0] s_rdata_latch;
	reg          s_pslverr_latch;

	// Request valid to master (handshake)
	reg s_req_valid;

	// Master-side "request accepted" synchronized back to slave
	reg [2:0] m_req_ack_sync;
	reg       m_req_ack_sync_d;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_req_ack_sync   <= 3'b000;
			m_req_ack_sync_d <= 1'b0;
		end else begin
			m_req_ack_sync   <= {m_req_ack_sync[1:0], m_req_ack_sync_d};
			m_req_ack_sync_d <= m_req_ack_sync[2];
		end
	end

	wire s_m_req_ack = m_req_ack_sync[2];

	// Slave-side next-state logic
	always @(*) begin
		s_state_next = s_state;
		case (s_state)
			S_IDLE: begin
				if (S_APB_PSEL && !S_APB_PENABLE)
					s_state_next = S_SETUP;
			end
			S_SETUP: begin
				// Stay in setup until we can send the request
				// We send when master is ready to accept (m_req_ack is low, meaning no pending)
				// Actually, we use a simple handshake: assert s_req_valid, wait for m_req_ack
				if (s_m_req_ack)
					s_state_next = S_WAIT;
			end
			S_WAIT: begin
				if (s_m_done)
					s_state_next = S_RESP;
			end
			S_RESP: begin
				// Present response, wait for PENABLE to deassert
				if (!S_APB_PENABLE)
					s_state_next = S_IDLE;
			end
			default: s_state_next = S_IDLE;
		endcase
	end

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_state        <= S_IDLE;
			s_addr_latch   <= {AW{1'b0}};
			s_write_latch  <= 1'b0;
			s_wdata_latch  <= {DW{1'b0}};
			s_wstrb_latch  <= {(DW/8){1'b0}};
			s_pprot_latch  <= 3'b000;
			s_rdata_latch  <= {DW{1'b0}};
			s_pslverr_latch<= 1'b0;
			s_req_valid    <= 1'b0;
			S_APB_PREADY   <= 1'b0;
		end else begin
			s_state <= s_state_next;

			case (s_state)
				S_IDLE: begin
					s_req_valid <= 1'b0;
					S_APB_PREADY <= 1'b0;
				end
				S_SETUP: begin
					// Capture request fields
					s_addr_latch  <= S_APB_PADDR;
					s_write_latch <= S_APB_PWRITE;
					s_wdata_latch <= S_APB_PWDATA;
					s_wstrb_latch <= S_APB_PWSTRB;
					s_pprot_latch <= S_APB_PPROT;
					// Assert request valid
					s_req_valid <= 1'b1;
					S_APB_PREADY <= 1'b0;
				end
				S_WAIT: begin
					// Keep request valid until acknowledged
					if (s_m_req_ack)
						s_req_valid <= 1'b0;
					S_APB_PREADY <= 1'b0;
				end
				S_RESP: begin
					// Latch response when it arrives
					if (s_m_done) begin
						s_rdata_latch   <= M_APB_PRDATA;
						s_pslverr_latch <= M_APB_PSLVERR;
					end
					// Assert PREADY when PENABLE is high and response is ready
					if (S_APB_PENABLE && s_m_done)
						S_APB_PREADY <= 1'b1;
					else
						S_APB_PREADY <= 1'b0;
				end
				default: begin
					s_req_valid <= 1'b0;
					S_APB_PREADY <= 1'b0;
				end
			endcase
		end
	end

	// Slave-side output data
	assign S_APB_PRDATA  = s_rdata_latch;
	assign S_APB_PSLVERR = s_pslverr_latch;

	// ------------------------------------------------------------------
	// Master-side (M_APB_PCLK domain)
	// ------------------------------------------------------------------

	// Synchronization of slave-side request valid
	reg [2:0] s_req_valid_sync;
	reg       s_req_valid_sync_d;

	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			s_req_valid_sync   <= 3'b000;
			s_req_valid_sync_d <= 1'b0;
		end else begin
			s_req_valid_sync   <= {s_req_valid_sync[1:0], s_req_valid_sync_d};
			s_req_valid_sync_d <= s_req_valid_sync[2];
		end
	end

	wire m_s_req_valid = s_req_valid_sync[2];

	// Synchronization of slave-side request fields
	// We need to synchronize the data fields. Since they are stable while s_req_valid is high,
	// we can use a simple 2-flop synchronizer for each field, but we must ensure they are
	// captured when the valid is synchronized. A common approach is to use a handshake.
	// Here, we use a simple approach: when m_s_req_valid transitions from 0 to 1, we capture
	// the data fields. But the data fields themselves need to be synchronized.
	// Let's use a different approach: synchronize each data field with 2-flop synchronizers,
	// and use the synchronized valid to gate the capture.

	// Actually, a cleaner approach: use a request/response handshake with a "grant" signal.
	// Let's redesign the handshake:
	// Slave asserts s_req_valid. Master synchronizes it. When master sees it, it captures
	// the data (which should be stable) and asserts m_req_ack. Slave synchronizes m_req_ack
	// and deasserts s_req_valid. Master deasserts m_req_ack after a few cycles.
	// Then master drives the APB transaction. When done, master asserts m_done. Slave
	// synchronizes m_done and captures the response.

	// Let's implement this properly.

	// Master-side state machine
	localparam M_IDLE  = 3'b000;
	localparam M_GRANT = 3'b001;
	localparam M_SETUP = 3'b010;
	localparam M_ACC   = 3'b011;
	localparam M_DONE  = 3'b100;

	reg [2:0] m_state;
	reg [2:0] m_state_next;

	// Latched request fields in master domain
	reg [AW-1:0] m_addr_latch;
	reg          m_write_latch;
	reg [DW-1:0] m_wdata_latch;
	reg [DW/8-1:0] m_wstrb_latch;
	reg [2:0]    m_pprot_latch;

	// Master-side handshake signals
	reg m_req_ack;   // Acknowledge request to slave
	reg m_done;      // Signal completion to slave

	// Master-side APB outputs
	reg m_psel;
	reg m_penable;

	// Master-side next-state logic
	always @(*) begin
		m_state_next = m_state;
		case (m_state)
			M_IDLE: begin
				if (m_s_req_valid)
					m_state_next = M_GRANT;
			end
			M_GRANT: begin
				// Capture data and move to setup
				m_state_next = M_SETUP;
			end
			M_SETUP: begin
				// Drive PSEL=1, PENABLE=0
				if (M_APB_PREADY)
					m_state_next = M_ACC;
			end
			M_ACC: begin
				// Drive PSEL=1, PENABLE=1
				if (M_APB_PREADY)
					m_state_next = M_DONE;
			end
			M_DONE: begin
				// Deassert PSEL, PENABLE
				m_state_next = M_IDLE;
			end
			default: m_state_next = M_IDLE;
		endcase
	end

	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_state       <= M_IDLE;
			m_addr_latch  <= {AW{1'b0}};
			m_write_latch <= 1'b0;
			m_wdata_latch <= {DW{1'b0}};
			m_wstrb_latch <= {(DW/8){1'b0}};
			m_pprot_latch <= 3'b000;
			m_req_ack     <= 1'b0;
			m_done        <= 1'b0;
			m_psel        <= 1'b0;
			m_penable     <= 1'b0;
			M_PRESETn     <= 1'b0;
		end else begin
			m_state <= m_state_next;

			case (m_state)
				M_IDLE: begin
					m_req_ack <= 1'b0;
					m_done    <= 1'b0;
					m_psel    <= 1'b0;
					m_penable <= 1'b0;
				end
				M_GRANT: begin
					// Capture request fields
					m_addr_latch  <= S_APB_PADDR;
					m_write_latch <= S_APB_PWRITE;
					m_wdata_latch <= S_APB_PWDATA;
					m_wstrb_latch <= S_APB_PWSTRB;
					m_pprot_latch <= S_APB_PPROT;
					// Assert ack
					m_req_ack <= 1'b1;
					m_psel    <= 1'b0;
					m_penable <= 1'b0;
				end
				M_SETUP: begin
					// Drive setup phase
					m_psel    <= 1'b1;
					m_penable <= 1'b0;
					// Deassert ack after one cycle
					m_req_ack <= 1'b0;
				end
				M_ACC: begin
					// Drive access phase
					m_psel    <= 1'b1;
					m_penable <= 1'b1;
				end
				M_DONE: begin
					// Deassert APB signals
					m_psel    <= 1'b0;
					m_penable <= 1'b0;
					// Assert done
					m_done    <= 1'b1;
				end
				default: begin
					m_req_ack <= 1'b0;
					m_done    <= 1'b0;
					m_psel    <= 1'b0;
					m_penable <= 1'b0;
				end
			endcase

			// Deassert done after one cycle in M_IDLE
			if (m_state == M_IDLE)
				m_done <= 1'b0;
		end
	end

	// Master-side APB outputs
	assign M_APB_PADDR  = m_addr_latch;
	assign M_APB_PWRITE = m_write_latch;
	assign M_APB_PWDATA = m_wdata_latch;
	assign M_APB_PWSTRB = m_wstrb_latch;
	assign M_APB_PPROT  = m_pprot_latch;

	// M_PRESETn output - tie to 1 (or synchronize S_PRESETn)
	// For simplicity, tie to 1. In a real design, you'd synchronize the reset.
	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			M_PRESETn <= 1'b0;
		else
			M_PRESETn <= 1'b1;
	end

endmodule
