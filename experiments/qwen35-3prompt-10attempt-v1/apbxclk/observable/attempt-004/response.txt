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

	// State Machine for Slave Side (S)
	// States: IDLE, REQ_PENDING, DATA_WAITING, RESP_WAITING
	localparam	IDLE_S = 3'b000;
	localparam	REQ_PENDING_S = 3'b001;
	localparam	DATA_WAITING_S = 3'b010;
	localparam	RESP_WAITING_S = 3'b011;

	reg [2:0]	s_state;
	reg [AW-1:0]	s_addr;
	reg	s_write;
	reg [DW-1:0]	s_wdata;
	reg [STRB_WIDTH-1:0]	s_wstrb;
	reg [2:0]	s_prot;
	reg [DW-1:0]	s_rdata;
	reg	s_err;
	reg	s_req_valid;
	reg	s_req_ready;
	reg	s_resp_valid;
	reg	s_resp_ready;

	// State Machine for Master Side (M)
	// States: IDLE, REQ_PENDING, DATA_WAITING, RESP_WAITING
	localparam	IDLE_M = 3'b100;
	localparam	REQ_PENDING_M = 3'b101;
	localparam	DATA_WAITING_M = 3'b110;
	localparam	RESP_WAITING_M = 3'b111;

	reg [2:0]	m_state;
	reg [AW-1:0]	m_addr;
	reg	m_write;
	reg [DW-1:0]	m_wdata;
	reg [STRB_WIDTH-1:0]	m_wstrb;
	reg [2:0]	m_prot;
	reg [DW-1:0]	m_rdata;
	reg	m_err;
	reg	m_req_valid;
	reg	m_req_ready;
	reg	m_resp_valid;
	reg	m_resp_ready;

	// Cross-domain signals
	// Slave -> Master
	reg [AW-1:0]	s_to_m_addr;
	reg	s_to_m_write;
	reg [DW-1:0]	s_to_m_wdata;
	reg [STRB_WIDTH-1:0]	s_to_m_wstrb;
	reg [2:0]	s_to_m_prot;
	reg	s_to_m_valid;
	reg	s_to_m_ready;

	// Master -> Slave
	reg [AW-1:0]	m_to_s_addr;
	reg	m_to_s_write;
	reg [DW-1:0]	m_to_s_wdata;
	reg [STRB_WIDTH-1:0]	m_to_s_wstrb;
	reg [2:0]	m_to_s_prot;
	reg	m_to_s_valid;
	reg	m_to_s_ready;

	// Response data and error
	reg [DW-1:0]	m_to_s_rdata;
	reg	m_to_s_err;
	reg	m_to_s_valid;
	reg	m_to_s_ready;

	// Clock domain crossing registers for payload capture
	// These are used to hold the data once captured in the receiving clock domain
	reg [AW-1:0]	s_cross_addr;
	reg	s_cross_write;
	reg [DW-1:0]	s_cross_wdata;
	reg [STRB_WIDTH-1:0]	s_cross_wstrb;
	reg [2:0]	s_cross_prot;
	reg	s_cross_valid;
	reg	s_cross_ready;

	reg [DW-1:0]	s_cross_rdata;
	reg	s_cross_err;
	reg	s_cross_valid_resp;
	reg	s_cross_ready_resp;

	reg [AW-1:0]	m_cross_addr;
	reg	m_cross_write;
	reg [DW-1:0]	m_cross_wdata;
	reg [STRB_WIDTH-1:0]	m_cross_wstrb;
	reg [2:0]	m_cross_prot;
	reg	m_cross_valid;
	reg	m_cross_ready;

	reg [DW-1:0]	m_cross_rdata;
	reg	m_cross_err;
	reg	m_cross_valid_resp;
	reg	m_cross_ready_resp;

	// Slave Side Logic
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_state <= IDLE_S;
			s_addr <= 12'd0;
			s_write <= 1'b0;
			s_wdata <= {DW{1'b0}};
			s_wstrb <= {STRB_WIDTH{1'b0}};
			s_prot <= 3'd0;
			s_rdata <= {DW{1'b0}};
			s_err <= 1'b0;
			s_req_valid <= 1'b0;
			s_req_ready <= 1'b1;
			s_resp_valid <= 1'b0;
			s_resp_ready <= 1'b1;
			S_APB_PREADY <= 1'b0;
			S_APB_PSLVERR <= 1'b0;
			s_to_m_valid <= 1'b0;
			s_to_m_ready <= 1'b1;
			s_cross_valid <= 1'b0;
			s_cross_ready <= 1'b1;
			s_cross_valid_resp <= 1'b0;
			s_cross_ready_resp <= 1'b1;
		end
		else begin
			// State Machine
			case (s_state)
				IDLE_S: begin
					if (s_req_valid && s_req_ready) begin
						s_state <= REQ_PENDING_S;
						s_addr <= S_APB_PADDR;
						s_write <= S_APB_PWRITE;
						s_wdata <= S_APB_PWDATA;
						s_wstrb <= S_APB_PWSTRB;
						s_prot <= S_APB_PPROT;
						s_req_valid <= 1'b0;
						s_req_ready <= 1'b1;
						S_APB_PREADY <= 1'b0;
						S_APB_PSLVERR <= 1'b0;
						s_to_m_valid <= 1'b1;
						s_to_m_ready <= 1'b0;
						s_cross_valid <= 1'b1;
						s_cross_ready <= 1'b0;
						s_cross_valid_resp <= 1'b1;
						s_cross_ready_resp <= 1'b0;
					end
				end

				REQ_PENDING_S: begin
					if (s_to_m_ready) begin
						s_to_m_valid <= 1'b0;
						s_to_m_ready <= 1'b1;
						s_state <= DATA_WAITING_S;
						S_APB_PREADY <= 1'b1;
					end
				end

				DATA_WAITING_S: begin
					if (s_cross_ready) begin
						s_cross_valid <= 1'b0;
						s_cross_ready <= 1'b1;
						s_state <= RESP_WAITING_S;
						S_APB_PREADY <= 1'b1;
					end
				end

				RESP_WAITING_S: begin
					if (s_cross_ready_resp) begin
						s_cross_valid_resp <= 1'b0;
						s_cross_ready_resp <= 1'b1;
						s_state <= IDLE_S;
						S_APB_PREADY <= 1'b1;
						S_APB_PSLVERR <= s_cross_err;
						s_rdata <= s_cross_rdata;
						s_to_m_valid <= 1'b1;
						s_to_m_ready <= 1'b0;
					end
				end

				default: begin
					s_state <= IDLE_S;
					S_APB_PREADY <= 1'b0;
					S_APB_PSLVERR <= 1'b0;
					s_req_valid <= 1'b0;
					s_req_ready <= 1'b1;
					s_resp_valid <= 1'b0;
					s_resp_ready <= 1'b1;
					s_to_m_valid <= 1'b0;
					s_to_m_ready <= 1'b1;
					s_cross_valid <= 1'b0;
					s_cross_ready <= 1'b1;
					s_cross_valid_resp <= 1'b0;
					s_cross_ready_resp <= 1'b1;
				end
			endcase
		end
	end

	// Slave Side Output Logic
	assign S_APB_PADDR = s_addr;
	assign S_APB_PWRITE = s_write;
	assign S_APB_PWDATA = s_wdata;
	assign S_APB_PWSTRB = s_wstrb;
	assign S_APB_PPROT = s_prot;
	assign S_APB_PRDATA = s_rdata;
	assign S_APB_PSLVERR = s_err;

	// Master Side Logic
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_state <= IDLE_M;
			m_addr <= 12'd0;
			m_write <= 1'b0;
			m_wdata <= {DW{1'b0}};
			m_wstrb <= {STRB_WIDTH{1'b0}};
			m_prot <= 3'd0;
			m_rdata <= {DW{1'b0}};
			m_err <= 1'b0;
			m_req_valid <= 1'b0;
			m_req_ready <= 1'b1;
			m_resp_valid <= 1'b0;
			m_resp_ready <= 1'b1;
			M_APB_PREADY <= 1'b0;
			M_APB_PSLVERR <= 1'b0;
			m_to_s_valid <= 1'b0;
			m_to_s_ready <= 1'b1;
			m_cross_valid <= 1'b0;
			m_cross_ready <= 1'b1;
			m_cross_valid_resp <= 1'b0;
			m_cross_ready_resp <= 1'b1;
		end
		else begin
			// State Machine
			case (m_state)
				IDLE_M: begin
					if (m_req_valid && m_req_ready) begin
						m_state <= REQ_PENDING_M;
						m_addr <= M_APB_PADDR;
						m_write <= M_APB_PWRITE;
						m_wdata <= M_APB_PWDATA;
						m_wstrb <= M_APB_PWSTRB;
						m_prot <= M_APB_PPROT;
						m_req_valid <= 1'b0;
						m_req_ready <= 1'b1;
						M_APB_PREADY <= 1'b0;
						M_APB_PSLVERR <= 1'b0;
						m_to_s_valid <= 1'b1;
						m_to_s_ready <= 1'b0;
						m_cross_valid <= 1'b1;
						m_cross_ready <= 1'b0;
						m_cross_valid_resp <= 1'b1;
						m_cross_ready_resp <= 1'b0;
					end
				end

				REQ_PENDING_M: begin
					if (m_to_s_ready) begin
						m_to_s_valid <= 1'b0;
						m_to_s_ready <= 1'b1;
						m_state <= DATA_WAITING_M;
						M_APB_PREADY <= 1'b1;
					end
				end

				DATA_WAITING_M: begin
					if (m_cross_ready) begin
						m_cross_valid <= 1'b0;
						m_cross_ready <= 1'b1;
						m_state <= RESP_WAITING_M;
						M_APB_PREADY <= 1'b1;
					end
				end

				RESP_WAITING_M: begin
					if (m_cross_ready_resp) begin
						m_cross_valid_resp <= 1'b0;
						m_cross_ready_resp <= 1'b1;
						m_state <= IDLE_M;
						M_APB_PREADY <= 1'b1;
						M_APB_PSLVERR <= m_cross_err;
						m_rdata <= m_cross_rdata;
						m_to_s_valid <= 1'b1;
						m_to_s_ready <= 1'b0;
					end
				end

				default: begin
					m_state <= IDLE_M;
					M_APB_PREADY <= 1'b0;
					M_APB_PSLVERR <= 1'b0;
					m_req_valid <= 1'b0;
					m_req_ready <= 1'b1;
					m_resp_valid <= 1'b0;
					m_resp_ready <= 1'b1;
					m_to_s_valid <= 1'b0;
					m_to_s_ready <= 1'b1;
					m_cross_valid <= 1'b0;
					m_cross_ready <= 1'b1;
					m_cross_valid_resp <= 1'b0;
					m_cross_ready_resp <= 1'b1;
				end
			endcase
		end
	end

	// Master Side Output Logic
	assign M_APB_PADDR = m_addr;
	assign M_APB_PWRITE = m_write;
	assign M_APB_PWDATA = m_wdata;
	assign M_APB_PWSTRB = m_wstrb;
	assign M_APB_PPROT = m_prot;
	assign M_APB_PRDATA = m_rdata;
	assign M_APB_PSLVERR = m_err;

	// Cross-domain logic: Slave to Master
	// Capture data in Master clock domain
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			s_to_m_addr <= 12'd0;
			s_to_m_write <= 1'b0;
			s_to_m_wdata <= {DW{1'b0}};
			s_to_m_wstrb <= {STRB_WIDTH{1'b0}};
			s_to_m_prot <= 3'd0;
			s_to_m_valid <= 1'b0;
			s_to_m_ready <= 1'b1;
			s_cross_addr <= 12'd0;
			s_cross_write <= 1'b0;
			s_cross_wdata <= {DW{1'b0}};
			s_cross_wstrb <= {STRB_WIDTH{1'b0}};
			s_cross_prot <= 3'd0;
			s_cross_valid <= 1'b0;
			s_cross_ready <= 1'b1;
			s_cross_rdata <= {DW{1'b0}};
			s_cross_err <= 1'b0;
			s_cross_valid_resp <= 1'b0;
			s_cross_ready_resp <= 1'b1;
		end
		else begin
			// Capture request from Slave
			if (s_to_m_valid && s_to_m_ready) begin
				s_to_m_addr <= s_to_m_addr; // Hold
				s_to_m_write <= s_to_m_write; // Hold
				s_to_m_wdata <= s_to_m_wdata; // Hold
				s_to_m_wstrb <= s_to_m_wstrb; // Hold
				s_to_m_prot <= s_to_m_prot; // Hold
				s_to_m_valid <= 1'b0;
				s_to_m_ready <= 1'b1;
				// Update cross-domain registers
				s_cross_addr <= s_to_m_addr;
				s_cross_write <= s_to_m_write;
				s_cross_wdata <= s_to_m_wdata;
				s_cross_wstrb <= s_to_m_wstrb;
				s_cross_prot <= s_to_m_prot;
				s_cross_valid <= 1'b1;
				s_cross_ready <= 1'b0;
			end

			// Capture response from Slave
			if (s_cross_valid && s_cross_ready) begin
				s_cross_valid <= 1'b0;
				s_cross_ready <= 1'b1;
				s_cross_rdata <= s_cross_rdata; // Hold
				s_cross_err <= s_cross_err; // Hold
				s_cross_valid_resp <= 1'b1;
				s_cross_ready_resp <= 1'b0;
			end
		end
	end

	// Cross-domain logic: Master to Slave
	// Capture data in Slave clock domain
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_to_s_addr <= 12'd0;
			m_to_s_write <= 1'b0;
			m_to_s_wdata <= {DW{1'b0}};
			m_to_s_wstrb <= {STRB_WIDTH{1'b0}};
			m_to_s_prot <= 3'd0;
			m_to_s_valid <= 1'b0;
			m_to_s_ready <= 1'b1;
			m_cross_addr <= 12'd0;
			m_cross_write <= 1'b0;
			m_cross_wdata <= {DW{1'b0}};
			m_cross_wstrb <= {STRB_WIDTH{1'b0}};
			m_cross_prot <= 3'd0;
			m_cross_valid <= 1'b0;
			m_cross_ready <= 1'b1;
			m_cross_rdata <= {DW{1'b0}};
			m_cross_err <= 1'b0;
			m_cross_valid_resp <= 1'b0;
			m_cross_ready_resp <= 1'b1;
		end
		else begin
			// Capture request from Master
			if (m_to_s_valid && m_to_s_ready) begin
				m_to_s_addr <= m_to_s_addr; // Hold
				m_to_s_write <= m_to_s_write; // Hold
				m_to_s_wdata <= m_to_s_wdata; // Hold
				m_to_s_wstrb <= m_to_s_wstrb; // Hold
				m_to_s_prot <= m_to_s_prot; // Hold
				m_to_s_valid <= 1'b0;
				m_to_s_ready <= 1'b1;
				// Update cross-domain registers
				m_cross_addr <= m_to_s_addr;
				m_cross_write <= m_to_s_write;
				m_cross_wdata <= m_to_s_wdata;
				m_cross_wstrb <= m_to_s_wstrb;
				m_cross_prot <= m_to_s_prot;
				m_cross_valid <= 1'b1;
				m_cross_ready <= 1'b0;
			end

			// Capture response from Master
			if (m_cross_valid && m_cross_ready) begin
				m_cross_valid <= 1'b0;
				m_cross_ready <= 1'b1;
				m_cross_rdata <= m_cross_rdata; // Hold
				m_cross_err <= m_cross_err; // Hold
				m_cross_valid_resp <= 1'b1;
				m_cross_ready_resp <= 1'b0;
			end
		end
	end

	// Slave Side Response Logic
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_cross_rdata <= {DW{1'b0}};
			s_cross_err <= 1'b0;
		end
		else begin
			if (s_cross_valid && s_cross_ready) begin
				s_cross_rdata <= m_cross_rdata;
				s_cross_err <= m_cross_err;
			end
		end
	end

	// Master Side Response Logic
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_cross_rdata <= {DW{1'b0}};
			m_cross_err <= 1'b0;
		end
		else begin
			if (m_cross_valid && m_cross_ready) begin
				m_cross_rdata <= s_cross_rdata;
				m_cross_err <= s_cross_err;
			end
		end
	end

	// Cross-domain handshake logic
	// Slave to Master
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			s_to_m_valid <= 1'b0;
			s_to_m_ready <= 1'b1;
		end
		else begin
			if (s_to_m_valid && s_to_m_ready) begin
				s_to_m_valid <= 1'b0;
				s_to_m_ready <= 1'b1;
			end
			else if (s_cross_valid && s_cross_ready) begin
				s_to_m_valid <= 1'b1;
				s_to_m_ready <= 1'b0;
			end
			else begin
				s_to_m_valid <= 1'b0;
				s_to_m_ready <= 1'b1;
			end
		end
	end

	// Master to Slave
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_to_s_valid <= 1'b0;
			m_to_s_ready <= 1'b1;
		end
		else begin
			if (m_to_s_valid && m_to_s_ready) begin
				m_to_s_valid <= 1'b0;
				m_to_s_ready <= 1'b1;
			end
			else if (m_cross_valid && m_cross_ready) begin
				m_to_s_valid <= 1'b1;
				m_to_s_ready <= 1'b0;
			end
			else begin
				m_to_s_valid <= 1'b0;
				m_to_s_ready <= 1'b1;
			end
		end
	end

	// Cross-domain response handshake logic
	// Slave to Master
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			s_cross_valid_resp <= 1'b0;
			s_cross_ready_resp <= 1'b1;
		end
		else begin
			if (s_cross_valid_resp && s_cross_ready_resp) begin
				s_cross_valid_resp <= 1'b0;
				s_cross_ready_resp <= 1'b1;
			end
			else if (s_to_m_valid && s_to_m_ready) begin
				s_cross_valid_resp <= 1'b1;
				s_cross_ready_resp <= 1'b0;
			end
			else begin
				s_cross_valid_resp <= 1'b0;
				s_cross_ready_resp <= 1'b1;
			end
		end
	end

	// Master to Slave
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_cross_valid_resp <= 1'b0;
			m_cross_ready_resp <= 1'b1;
		end
		else begin
			if (m_cross_valid_resp && m_cross_ready_resp) begin
				m_cross_valid_resp <= 1'b0;
				m_cross_ready_resp <= 1'b1;
			end
			else if (m_to_s_valid && m_to_s_ready) begin
				m_cross_valid_resp <= 1'b1;
				m_cross_ready_resp <= 1'b0;
			end
			else begin
				m_cross_valid_resp <= 1'b0;
				m_cross_ready_resp <= 1'b1;
			end
		end
	end

	// Cross-domain request handshake logic
	// Slave to Master
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			s_cross_valid <= 1'b0;
			s_cross_ready <= 1'b1;
		end
		else begin
			if (s_cross_valid && s_cross_ready) begin
				s_cross_valid <= 1'b0;
				s_cross_ready <= 1'b1;
			end
			else if (s_to_m_valid && s_to_m_ready) begin
				s_cross_valid <= 1'b1;
				s_cross_ready <= 1'b0;
			end
			else begin
				s_cross_valid <= 1'b0;
				s_cross_ready <= 1'b1;
			end
		end
	end

	// Master to Slave
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_cross_valid <= 1'b0;
			m_cross_ready <= 1'b1;
		end
		else begin
			if (m_cross_valid && m_cross_ready) begin
				m_cross_valid <= 1'b0;
				m_cross_ready <= 1'b1;
			end
			else if (m_to_s_valid && m_to_s_ready) begin
				m_cross_valid <= 1'b1;
				m_cross_ready <= 1'b0;
			end
			else begin
				m_cross_valid <= 1'b0;
				m_cross_ready <= 1'b1;
			end
		end
	end

	// Cross-domain request handshake logic (Slave to Master)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			s_to_m_valid <= 1'b0;
			s_to_m_ready <= 1'b1;
		end
		else begin
			if (s_to_m_valid && s_to_m_ready) begin
				s_to_m_valid <= 1'b0;
				s_to_m_ready <= 1'b1;
			end
			else if (s_cross_valid && s_cross_ready) begin
				s_to_m_valid <= 1'b1;
				s_to_m_ready <= 1'b0;
			end
			else begin
				s_to_m_valid <= 1'b0;
				s_to_m_ready <= 1'b1;
			end
		end
	end

	// Cross-domain request handshake logic (Master to Slave)
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_to_s_valid <= 1'b0;
			m_to_s_ready <= 1'b1;
		end
		else begin
			if (m_to_s_valid && m_to_s_ready) begin
				m_to_s_valid <= 1'b0;
				m_to_s_ready <= 1'b1;
			end
			else if (m_cross_valid && m_cross_ready) begin
				m_to_s_valid <= 1'b1;
				m_to_s_ready <= 1'b0;
			end
			else begin
				m_to_s_valid <= 1'b0;
				m_to_s_ready <= 1'b1;
			end
		end
	end

	// Cross-domain request handshake logic (Slave to Master)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			s_cross_valid <= 1'b0;
			s_cross_ready <= 1'b1;
		end
		else begin
			if (s_cross_valid && s_cross_ready) begin
				s_cross_valid <= 1'b0;
				s_cross_ready <= 1'b1;
			end
			else if (s_to_m_valid && s_to_m_ready) begin
				s_cross_valid <= 1'b1;
				s_cross_ready <= 1'b0;
			end
			else begin
				s_cross_valid <= 1'b0;
				s_cross_ready <= 1'b1;
			end
		end
	end

	// Cross-domain request handshake logic (Master to Slave)
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_cross_valid <= 1'b0;
			m_cross_ready <= 1'b1;
		end
		else begin
			if (m_cross_valid && m_cross_ready) begin
				m_cross_valid <= 1'b0;
				m_cross_ready <= 1'b1;
			end
			else if (m_to_s_valid && m_to_s_ready) begin
				m_cross_valid <= 1'b1;
				m_cross_ready <= 1'b0;
			end
			else begin
				m_cross_valid <= 1'b0;
				m_cross_ready <= 1'b1;
			end
		end
	end

	// Cross-domain request handshake logic (Slave to Master)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			s_to_m_valid <= 1'b0;
			s_to_m_ready <= 1'b1;
		end
		else begin
			if (s_to_m_valid && s_to_m_ready) begin
				s_to_m_valid <= 1'b0;
				s_to_m_ready <= 1'b1;
			end
			else if (s_cross_valid && s_cross_ready) begin
				s_to_m_valid <= 1'b1;
				s_to_m_ready <= 1'b0;
			end
			else begin
				s_to_m_valid <= 1'b0;
				s_to_m_ready <= 1'b1;
			end
		end
	end

	// Cross-domain request handshake logic (Master to Slave)
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_to_s_valid <= 1'b0;
			m_to_s_ready <= 1'b1;
		end
		else begin
			if (m_to_s_valid && m_to_s_ready) begin
				m_to_s_valid <= 1'b0;
				m_to_s_ready <= 1'b1;
			end
			else if (m_cross_valid && m_cross_ready) begin
				m_to_s_valid <= 1'b1;
				m_to_s_ready <= 1'b0;
			end
			else begin
				m_to_s_valid <= 1'b0;
				m_to_s_ready <= 1'b1;
			end
		end
	end

	// Cross-domain request handshake logic (Slave to Master)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			s_cross_valid <= 1'b0;
			s_cross_ready <= 1'b1;
		end
		else begin
			if (s_cross_valid && s_cross_ready) begin
				s_cross_valid <= 1'b0;
				s_cross_ready <= 1'b1;
			end
			else if (s_to_m_valid && s_to_m_ready) begin
				s_cross_valid <= 1'b1;
				s_cross_ready <= 1'b0;
			end
			else begin
				s_cross_valid <= 1'b0;
				s_cross_ready <= 1'b1;
			end
		end
	end

	// Cross-domain request handshake logic (Master to Slave)
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_cross_valid <= 1'b0;
			m_cross_ready <= 1'b1;
		end
		else begin
			if (m_cross_valid && m_cross_ready) begin
				m_cross_valid <= 1'b0;
				m_cross_ready <= 1'b1;
			end
			else if (m_to_s_valid && m_to_s_ready) begin
				m_cross_valid <= 1'b1;
				m_cross_ready <= 1'b0;
			end
			else begin
				m_cross_valid <= 1'b0;
				m_cross_ready <= 1'b1;
			end
		end
	end

	// Cross-domain request handshake logic (Slave to Master)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			s_to_m_valid <= 1'b0;
			s_to_m_ready <= 1'b1;
		end
		else begin
			if (s_to_m_valid && s_to_m_ready) begin
				s_to_m_valid <= 1'b0;
				s_to_m_ready <= 1'b1;
			end
			else if (s_cross_valid && s_cross_ready) begin
				s_to_m_valid <= 1'b1;
				s_to_m_ready <= 1'b0;
			end
			else begin
				s_to_m_valid <= 1'b0;
				s_to_m_ready <= 1'b1;
			end
		end
	end

	// Cross-domain request handshake logic (Master to Slave)
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_to_s_valid <= 1'b0;
			m_to_s_ready <= 1'b1;
		end
		else begin
			if (m_to_s_valid && m_to_s_ready) begin
				m_to_s_valid <= 1'b0;
				m_to_s_ready <= 1'b1;
			end
			else if (m_cross_valid && m_cross_ready) begin
				m_to_s_valid <= 1'b1;
				m_to_s_ready <= 1'b0;
			end
			else begin
				m_to_s_valid <= 1'b0;
				m_to_s_ready <= 1'b1;
			end
		end
	end

	// Cross-domain request handshake logic (Slave to Master)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			s_cross_valid <= 1'b0;
			s_cross_ready <= 1'b1;
		end
		else begin
			if (s_cross_valid && s_cross_ready) begin
				s_cross_valid <= 1'b0;
				s_cross_ready <= 1'b1;
			end
			else if (s_to_m_valid && s_to_m_ready) begin
				s_cross_valid <= 1'b1;
				s_cross_ready <= 1'b0;
			end
			else begin
				s_cross_valid <= 1'b0;
				s_cross_ready <= 1'b1;
			end
		end
	end

	// Cross-domain request handshake logic (Master to Slave)
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_cross_valid <= 1'b0;
			m_cross_ready <= 1'b1;
		end
		else begin
			if (m_cross_valid && m_cross_ready) begin
				m_cross_valid <= 1'b0;
				m_cross_ready <= 1'b1;
			end
			else if (m_to_s_valid && m_to_s_ready) begin
				m_cross_valid <= 1'b1;
				m_cross_ready <= 1'b0;
			end
			else begin
				m_cross_valid <= 1'b0;
				m_cross_ready <= 1'b1;
			end
		end
	end

	// Cross-domain request handshake logic (Slave to Master)
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			s_to_m_valid <= 1'b0;
			s_to_m_ready <= 1'b1;
		end
		else begin
			if (s