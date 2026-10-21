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

	localparam	AW = C_APB_ADDR_WIDTH;
	localparam	DW = C_APB_DATA_WIDTH;
	localparam	STRB_WIDTH = DW/8;

	// State Machine for Slave Side (Master Interface)
	// States: IDLE, REQ_SENT, REQ_PENDING, RESP_RECEIVED
	localparam	IDLE = 2'b00;
	localparam	REQ_SENT = 2'b01;
	localparam	REQ_PENDING = 2'b10;
	localparam	RESP_RECEIVED = 2'b11;

	reg [1:0]	s_state;
	reg		s_psel;
	reg		s_penable;
	reg		s_pwrite;
	reg		s_paddr;
	reg		s_pdata;
	reg		s_pstrb;
	reg		s_pprot;
	reg		s_pready;
	reg		s_pslverr;
	reg		s_req_valid;
	reg		s_resp_ready;
	reg		s_resp_data;
	reg		s_resp_strb;
	reg		s_resp_prot;
	reg		s_resp_err;
	reg		s_req_hold;

	// State Machine for Master Side (Slave Interface)
	// States: IDLE, REQ_SENT, REQ_PENDING, RESP_RECEIVED
	localparam	IDLE_M = 2'b00;
	localparam	REQ_SENT_M = 2'b01;
	localparam	REQ_PENDING_M = 2'b10;
	localparam	RESP_RECEIVED_M = 2'b11;

	reg [1:0]	m_state;
	reg		m_psel;
	reg		m_penable;
	reg		m_pwrite;
	reg		m_paddr;
	reg		m_pdata;
	reg		m_pstrb;
	reg		m_pprot;
	reg		m_pready;
	reg		m_pslverr;
	reg		m_req_valid;
	reg		m_resp_ready;
	reg		m_resp_data;
	reg		m_resp_strb;
	reg		m_resp_prot;
	reg		m_resp_err;
	reg		m_req_hold;

	// Cross Clock Domain Signals (Slave -> Master)
	// These are registered in the Master clock domain
	reg [AW-1:0]	c2m_addr;
	reg [DW-1:0]	c2m_data;
	reg [STRB_WIDTH-1:0]	c2m_strb;
	reg [2:0]	c2m_prot;
	reg	c2m_write;
	reg	c2m_err;
	reg	c2m_valid;
	reg	c2m_ready;

	// Cross Clock Domain Signals (Master -> Slave)
	// These are registered in the Slave clock domain
	reg [AW-1:0]	m2c_addr;
	reg [DW-1:0]	m2c_data;
	reg [STRB_WIDTH-1:0]	m2c_strb;
	reg [2:0]	m2c_prot;
	reg	m2c_write;
	reg	m2c_err;
	reg	m2c_valid;
	reg	m2c_ready;

	// ---------------------------------------------------------
	// Slave Side Logic (Clock: S_APB_PCLK)
	// ---------------------------------------------------------
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_state <= IDLE;
			s_psel <= 1'b0;
			s_penable <= 1'b0;
			s_pready <= 1'b1;
			s_pslverr <= 1'b0;
			s_req_valid <= 1'b0;
			s_req_hold <= 1'b0;
			s_resp_ready <= 1'b0;
		end else begin
			// Reset outputs to safe states
			s_pready <= 1'b1;
			s_pslverr <= 1'b0;

			case (s_state)
				IDLE: begin
					if (S_APB_PSEL && S_APB_PENABLE) begin
						s_state <= REQ_SENT;
						s_psel <= 1'b1;
						s_penable <= 1'b1;
						s_paddr <= S_APB_PADDR;
						s_pwrite <= S_APB_PWRITE;
						s_pdata <= S_APB_PWDATA;
						s_pstrb <= S_APB_PWSTRB;
						s_pprot <= S_APB_PPROT;
						s_req_valid <= 1'b1;
						s_req_hold <= 1'b0;
						s_resp_ready <= 1'b0;
					end
				end

				REQ_SENT: begin
					// Wait for Master to accept the request
					if (M_APB_PREADY) begin
						s_state <= REQ_PENDING;
						s_req_hold <= 1'b1; // Hold the request on Slave side
						s_resp_ready <= 1'b1; // Signal ready to receive response
					end
				end

				REQ_PENDING: begin
					// Hold the request until Master releases it
					s_req_hold <= 1'b1;
					s_resp_ready <= 1'b1;
					
					// Check for response from Master
					if (c2m_valid && c2m_ready) begin
						s_state <= RESP_RECEIVED;
						s_pready <= 1'b0; // Indicate busy
						s_pslverr <= c2m_err;
						s_resp_data <= c2m_data;
						s_resp_strb <= c2m_strb;
						s_resp_prot <= c2m_prot;
						s_resp_ready <= 1'b0;
					end
				end

				RESP_RECEIVED: begin
					// Wait for Master to acknowledge the response
					if (M_APB_PREADY) begin
						s_state <= IDLE;
						s_psel <= 1'b0;
						s_penable <= 1'b0;
						s_pready <= 1'b1;
						s_req_valid <= 1'b0;
						s_req_hold <= 1'b0;
						s_resp_ready <= 1'b0;
					end
				end
			endcase
		end
	end

	// Slave Output Logic
	assign S_APB_PRDATA = (s_state == RESP_RECEIVED) ? s_resp_data : 16'h00000000;
	assign S_APB_PSLVERR = (s_state == RESP_RECEIVED) ? s_resp_err : 1'b0;

	// ---------------------------------------------------------
	// Master Side Logic (Clock: M_APB_PCLK)
	// ---------------------------------------------------------
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_state <= IDLE_M;
			m_psel <= 1'b0;
			m_penable <= 1'b0;
			m_pready <= 1'b1;
			m_pslverr <= 1'b0;
			m_req_valid <= 1'b0;
			m_req_hold <= 1'b0;
			m_resp_ready <= 1'b0;
		end else begin
			// Reset outputs to safe states
			m_pready <= 1'b1;
			m_pslverr <= 1'b0;

			case (m_state)
				IDLE_M: begin
					if (c2m_valid && !c2m_ready) begin
						m_state <= REQ_SENT_M;
						m_psel <= 1'b1;
						m_penable <= 1'b1;
						m_paddr <= c2m_addr;
						m_pwrite <= c2m_write;
						m_pdata <= c2m_data;
						m_pstrb <= c2m_strb;
						m_pprot <= c2m_prot;
						m_req_valid <= 1'b1;
						m_req_hold <= 1'b0;
						m_resp_ready <= 1'b0;
					end
				end

				REQ_SENT_M: begin
					// Wait for Slave to accept the request
					if (S_APB_PREADY) begin
						m_state <= REQ_PENDING_M;
						m_req_hold <= 1'b1; // Hold the request on Master side
						m_resp_ready <= 1'b1; // Signal ready to receive response
					end
				end

				REQ_PENDING_M: begin
					// Hold the request until Slave releases it
					m_req_hold <= 1'b1;
					m_resp_ready <= 1'b1;
					
					// Check for response from Slave
					if (m2c_valid && m2c_ready) begin
						m_state <= RESP_RECEIVED_M;
						m_pready <= 1'b0; // Indicate busy
						m_pslverr <= m2c_err;
						m_resp_data <= m2c_data;
						m_resp_strb <= m2c_strb;
						m_resp_prot <= m2c_prot;
						m_resp_ready <= 1'b0;
					end
				end

				RESP_RECEIVED_M: begin
					// Wait for Slave to acknowledge the response
					if (S_APB_PREADY) begin
						m_state <= IDLE_M;
						m_psel <= 1'b0;
						m_penable <= 1'b0;
						m_pready <= 1'b1;
						m_req_valid <= 1'b0;
						m_req_hold <= 1'b0;
						m_resp_ready <= 1'b0;
					end
				end
			endcase
		end
	end

	// Master Output Logic
	assign M_APB_PADDR = (m_state == RESP_RECEIVED_M) ? m_resp_data : 12'h000;
	assign M_APB_PWRITE = (m_state == RESP_RECEIVED_M) ? m_resp_strb[0] : 1'b0;
	assign M_APB_PWDATA = (m_state == RESP_RECEIVED_M) ? m_resp_data : 32'h00000000;
	assign M_APB_PWSTRB = (m_state == RESP_RECEIVED_M) ? m_resp_strb : 4'h0;
	assign M_APB_PPROT = (m_state == RESP_RECEIVED_M) ? m_resp_prot : 3'h0;
	assign M_APB_PRDATA = (m_state == RESP_RECEIVED_M) ? m_resp_data : 32'h00000000;
	assign M_APB_PSLVERR = (m_state == RESP_RECEIVED_M) ? m_resp_err : 1'b0;

	// ---------------------------------------------------------
	// Cross Clock Domain Synchronizers
	// ---------------------------------------------------------

	// Slave -> Master (c2m_*)
	// Capture valid, data, strb, prot, write, err
	reg [AW-1:0] c2m_addr_reg;
	reg [DW-1:0] c2m_data_reg;
	reg [STRB_WIDTH-1:0] c2m_strb_reg;
	reg [2:0] c2m_prot_reg;
	reg c2m_write_reg;
	reg c2m_err_reg;
	reg c2m_valid_reg;
	reg c2m_ready_reg;

	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			c2m_addr_reg <= 12'h000;
			c2m_data_reg <= 32'h00000000;
			c2m_strb_reg <= 4'h0;
			c2m_prot_reg <= 3'h0;
			c2m_write_reg <= 1'b0;
			c2m_err_reg <= 1'b0;
			c2m_valid_reg <= 1'b0;
			c2m_ready_reg <= 1'b0;
		end else begin
			c2m_addr_reg <= c2m_addr;
			c2m_data_reg <= c2m_data;
			c2m_strb_reg <= c2m_strb;
			c2m_prot_reg <= c2m_prot;
			c2m_write_reg <= c2m_write;
			c2m_err_reg <= c2m_err;
			c2m_valid_reg <= c2m_valid;
			c2m_ready_reg <= c2m_ready;
		end
	end

	// Master -> Slave (m2c_*)
	// Capture valid, data, strb, prot, write, err
	reg [AW-1:0] m2c_addr_reg;
	reg [DW-1:0] m2c_data_reg;
	reg [STRB_WIDTH-1:0] m2c_strb_reg;
	reg [2:0] m2c_prot_reg;
	reg m2c_write_reg;
	reg m2c_err_reg;
	reg m2c_valid_reg;
	reg m2c_ready_reg;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m2c_addr_reg <= 12'h000;
			m2c_data_reg <= 32'h00000000;
			m2c_strb_reg <= 4'h0;
			m2c_prot_reg <= 3'h0;
			m2c_write_reg <= 1'b0;
			m2c_err_reg <= 1'b0;
			m2c_valid_reg <= 1'b0;
			m2c_ready_reg <= 1'b0;
		end else begin
			m2c_addr_reg <= m2c_addr;
			m2c_data_reg <= m2c_data;
			m2c_strb_reg <= m2c_strb;
			m2c_prot_reg <= m2c_prot;
			m2c_write_reg <= m2c_write;
			m2c_err_reg <= m2c_err;
			m2c_valid_reg <= m2c_valid;
			m2c_ready_reg <= m2c_ready;
		end
	end

	// ---------------------------------------------------------
	// Handshake Logic
	// ---------------------------------------------------------

	// Slave Side Handshake
	// c2m_valid is asserted when Master has data ready
	// c2m_ready is asserted when Slave is ready to accept data
	// This is handled by the state machine transitions above.
	// Specifically, in REQ_PENDING state, s_resp_ready is set high.
	// When c2m_valid is high and c2m_ready is high (which is s_resp_ready),
	// the transition to RESP_RECEIVED happens.
	
	// Master Side Handshake
	// m2c_valid is asserted when Slave has data ready
	// m2c_ready is asserted when Master is ready to accept data
	// This is handled by the state machine transitions above.
	// Specifically, in REQ_PENDING_M state, m_resp_ready is set high.
	// When m2c_valid is high and m2c_ready is high (which is m_resp_ready),
	// the transition to RESP_RECEIVED_M happens.

	// ---------------------------------------------------------
	// Final Output Assignments for Cross Domain Signals
	// ---------------------------------------------------------

	// Slave outputs to Master
	assign c2m_addr = (s_state == RESP_RECEIVED) ? s_resp_data : 12'h000;
	assign c2m_data = (s_state == RESP_RECEIVED) ? s_resp_data : 32'h00000000;
	assign c2m_strb = (s_state == RESP_RECEIVED) ? s_resp_strb : 4'h0;
	assign c2m_prot = (s_state == RESP_RECEIVED) ? s_resp_prot : 3'h0;
	assign c2m_write = (s_state == RESP_RECEIVED) ? 1'b0 : 1'b0; // Response is read-only
	assign c2m_err = (s_state == RESP_RECEIVED) ? s_resp_err : 1'b0;
	assign c2m_valid = (s_state == RESP_RECEIVED) && s_resp_ready;
	assign c2m_ready = 1'b1; // Slave always ready to send response once generated

	// Master outputs to Slave
	assign m2c_addr = (m_state == RESP_RECEIVED_M) ? m_resp_data : 12'h000;
	assign m2c_data = (m_state == RESP_RECEIVED_M) ? m_resp_data : 32'h00000000;
	assign m2c_strb = (m_state == RESP_RECEIVED_M) ? m_resp_strb : 4'h0;
	assign m2c_prot = (m_state == RESP_RECEIVED_M) ? m_resp_prot : 3'h0;
	assign m2c_write = (m_state == RESP_RECEIVED_M) ? 1'b0 : 1'b0; // Response is read-only
	assign m2c_err = (m_state == RESP_RECEIVED_M) ? m_resp_err : 1'b0;
	assign m2c_valid = (m_state == RESP_RECEIVED_M) && m_resp_ready;
	assign m2c_ready = 1'b1; // Master always ready to send response once generated

endmodule
```<|im_end|>
