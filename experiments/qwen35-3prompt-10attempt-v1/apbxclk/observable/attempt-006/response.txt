```verilog
`timescale 1ns/1ps

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
	localparam IDLE_S = 2'b00;
	localparam REQ_S = 2'b01;
	localparam WAIT_S = 2'b10;

	// State Machine for Master Side (M)
	localparam IDLE_M = 2'b00;
	localparam REQ_M = 2'b01;
	localparam WAIT_M = 2'b10;

	// Internal Signals
	reg [1:0]	s_state, m_state;
	reg [AW-1:0]	s_addr, m_addr;
	reg [DW-1:0]	s_wdata, m_wdata;
	reg [STRB_WIDTH-1:0]	s_wstrb, m_wstrb;
	reg [2:0]	s_prot, m_prot;
	reg	s_psel, s_penable;
	reg	m_psel, m_penable;
	reg	s_ready, m_ready;
	reg	s_error, m_error;
	reg [DW-1:0]	s_rdata, m_rdata;
	reg [1:0]	s_req_count, m_req_count;

	// Clock Domain Crossing Registers (Crossing Payload)
	// These hold the transaction details when crossing from S to M
	reg [AW-1:0]	c_addr;
	reg [DW-1:0]	c_wdata;
	reg [STRB_WIDTH-1:0]	c_wstrb;
	reg [2:0]	c_prot;
	reg	c_write;
	reg	c_psel;
	reg	c_penable;
	reg	c_ready;
	reg	c_error;
	reg [DW-1:0]	c_rdata;

	// Clock Domain Crossing Registers (Crossing Response)
	// These hold the response when crossing from M to S
	reg [DW-1:0]	r_rdata;
	reg	r_pslverr;
	reg	r_pready;
	reg	r_psel;
	reg	r_penable;

	// Reset Logic
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_state <= IDLE_S;
			s_psel <= 1'b0;
			s_penable <= 1'b0;
			s_addr <= 12'd0;
			s_wdata <= 32'd0;
			s_wstrb <= 4'd0;
			s_prot <= 3'd0;
			s_ready <= 1'b0;
			s_error <= 1'b0;
			s_rdata <= 32'd0;
			s_req_count <= 2'd0;
		end else begin
			s_state <= s_state;
			s_psel <= s_psel;
			s_penable <= s_penable;
			s_addr <= s_addr;
			s_wdata <= s_wdata;
			s_wstrb <= s_wstrb;
			s_prot <= s_prot;
			s_ready <= s_ready;
			s_error <= s_error;
			s_rdata <= s_rdata;
			s_req_count <= s_req_count;
		end
	end

	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_state <= IDLE_M;
			m_psel <= 1'b0;
			m_penable <= 1'b0;
			m_addr <= 12'd0;
			m_wdata <= 32'd0;
			m_wstrb <= 4'd0;
			m_prot <= 3'd0;
			m_ready <= 1'b0;
			m_error <= 1'b0;
			m_rdata <= 32'd0;
			m_req_count <= 2'd0;
		end else begin
			m_state <= m_state;
			m_psel <= m_psel;
			m_penable <= m_penable;
			m_addr <= m_addr;
			m_wdata <= m_wdata;
			m_wstrb <= m_wstrb;
			m_prot <= m_prot;
			m_ready <= m_ready;
			m_error <= m_error;
			m_rdata <= m_rdata;
			m_req_count <= m_req_count;
		end
	end

	// Slave Side Logic
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_state <= IDLE_S;
			s_psel <= 1'b0;
			s_penable <= 1'b0;
			s_addr <= 12'd0;
			s_wdata <= 32'd0;
			s_wstrb <= 4'd0;
			s_prot <= 3'd0;
			s_ready <= 1'b0;
			s_error <= 1'b0;
			s_rdata <= 32'd0;
			s_req_count <= 2'd0;
		end else begin
			// State Machine
			case (s_state)
				IDLE_S: begin
					if (S_APB_PSEL && !S_APB_PREADY) begin
						s_state <= REQ_S;
						s_psel <= 1'b1;
						s_addr <= S_APB_PADDR;
						s_wdata <= S_APB_PWDATA;
						s_wstrb <= S_APB_PWSTRB;
						s_prot <= S_APB_PPROT;
						s_penable <= S_APB_PENABLE;
						s_ready <= 1'b0;
						s_error <= 1'b0;
						s_rdata <= 32'd0;
						s_req_count <= 2'd0;
					end
				end

				REQ_S: begin
					if (S_APB_PREADY) begin
						s_state <= WAIT_S;
						s_psel <= 1'b1;
						s_penable <= S_APB_PENABLE;
						s_ready <= 1'b1;
						s_error <= 1'b0;
						s_rdata <= 32'd0;
						s_req_count <= s_req_count + 1'b1;
					end
				end

				WAIT_S: begin
					if (S_APB_PREADY) begin
						s_state <= IDLE_S;
						s_psel <= 1'b0;
						s_penable <= 1'b0;
						s_ready <= 1'b0;
						s_error <= 1'b0;
						s_rdata <= 32'd0;
						s_req_count <= s_req_count - 1'b1;
					end
				end
			endcase

			// Output Logic
			S_APB_PREADY <= s_ready;
			S_APB_PRDATA <= s_rdata;
			S_APB_PSLVERR <= s_error;
		end
	end

	// Master Side Logic
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_state <= IDLE_M;
			m_psel <= 1'b0;
			m_penable <= 1'b0;
			m_addr <= 12'd0;
			m_wdata <= 32'd0;
			m_wstrb <= 4'd0;
			m_prot <= 3'd0;
			m_ready <= 1'b0;
			m_error <= 1'b0;
			m_rdata <= 32'd0;
			m_req_count <= 2'd0;
		end else begin
			// State Machine
			case (m_state)
				IDLE_M: begin
					if (M_APB_PSEL && !M_APB_PREADY) begin
						m_state <= REQ_M;
						m_psel <= 1'b1;
						m_addr <= M_APB_PADDR;
						m_wdata <= M_APB_PWDATA;
						m_wstrb <= M_APB_PWSTRB;
						m_prot <= M_APB_PPROT;
						m_penable <= M_APB_PENABLE;
						m_ready <= 1'b0;
						m_error <= 1'b0;
						m_rdata <= 32'd0;
						m_req_count <= 2'd0;
					end
				end

				REQ_M: begin
					if (M_APB_PREADY) begin
						m_state <= WAIT_M;
						m_psel <= 1'b1;
						m_penable <= M_APB_PENABLE;
						m_ready <= 1'b1;
						m_error <= 1'b0;
						m_rdata <= 32'd0;
						m_req_count <= m_req_count + 1'b1;
					end
				end

				WAIT_M: begin
					if (M_APB_PREADY) begin
						m_state <= IDLE_M;
						m_psel <= 1'b0;
						m_penable <= 1'b0;
						m_ready <= 1'b0;
						m_error <= 1'b0;
						m_rdata <= 32'd0;
						m_req_count <= m_req_count - 1'b1;
					end
				end
			endcase

			// Output Logic
			M_APB_PREADY <= m_ready;
			M_APB_PRDATA <= m_rdata;
			M_APB_PSLVERR <= m_error;
		end
	end

	// Clock Domain Crossing: Slave to Master
	// Capture transaction details on rising edge of M_APB_PCLK
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			c_addr <= 12'd0;
			c_wdata <= 32'd0;
			c_wstrb <= 4'd0;
			c_prot <= 3'd0;
			c_write <= 1'b0;
			c_psel <= 1'b0;
			c_penable <= 1'b0;
			c_ready <= 1'b0;
			c_error <= 1'b0;
			c_rdata <= 32'd0;
		end else begin
			// Capture data when slave is ready and master is not
			if (s_ready && !m_ready) begin
				c_addr <= s_addr;
				c_wdata <= s_wdata;
				c_wstrb <= s_wstrb;
				c_prot <= s_prot;
				c_write <= s_APB_PWRITE;
				c_psel <= s_psel;
				c_penable <= s_penable;
				c_ready <= 1'b0;
				c_error <= s_error;
				c_rdata <= 32'd0;
			end
		end
	end

	// Clock Domain Crossing: Master to Slave
	// Capture response details on rising edge of S_APB_PCLK
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			r_rdata <= 32'd0;
			r_pslverr <= 1'b0;
			r_pready <= 1'b0;
			r_psel <= 1'b0;
			r_penable <= 1'b0;
		end else begin
			// Capture data when master is ready and slave is not
			if (m_ready && !s_ready) begin
				r_rdata <= m_rdata;
				r_pslverr <= m_error;
				r_pready <= 1'b0;
				r_psel <= m_psel;
				r_penable <= m_penable;
			end
		end
	end

	// Slave Side: Update internal state based on captured data from Master
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_addr <= 12'd0;
			s_wdata <= 32'd0;
			s_wstrb <= 4'd0;
			s_prot <= 3'd0;
			s_error <= 1'b0;
			s_rdata <= 32'd0;
			s_req_count <= 2'd0;
		end else begin
			if (s_ready && !m_ready) begin
				s_addr <= c_addr;
				s_wdata <= c_wdata;
				s_wstrb <= c_wstrb;
				s_prot <= c_prot;
				s_error <= c_error;
				s_rdata <= 32'd0;
				s_req_count <= s_req_count + 1'b1;
			end
		end
	end

	// Master Side: Update internal state based on captured data from Slave
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_addr <= 12'd0;
			m_wdata <= 32'd0;
			m_wstrb <= 4'd0;
			m_prot <= 3'd0;
			m_error <= 1'b0;
			m_rdata <= 32'd0;
			m_req_count <= 2'd0;
		end else begin
			if (m_ready && !s_ready) begin
				m_addr <= r_addr;
				m_wdata <= r_wdata;
				m_wstrb <= r_wstrb;
				m_prot <= r_prot;
				m_error <= r_error;
				m_rdata <= 32'd0;
				m_req_count <= m_req_count + 1'b1;
			end
		end
	end

	// Slave Side: Update internal state based on captured data from Master
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_addr <= 12'd0;
			s_wdata <= 32'd0;
			s_wstrb <= 4'd0;
			s_prot <= 3'd0;
			s_error <= 1'b0;
			s_rdata <= 32'd0;
			s_req_count <= 2'd0;
		end else begin
			if (s_ready && !m_ready) begin
				s_addr <= c_addr;
				s_wdata <= c_wdata;
				s_wstrb <= c_wstrb;
				s_prot <= c_prot;
				s_error <= c_error;
				s_rdata <= 32'd0;
				s_req_count <= s_req_count + 1'b1;
			end
		end
	end

	// Master Side: Update internal state based on captured data from Slave
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_addr <= 12'd0;
			m_wdata <= 32'd0;
			m_wstrb <= 4'd0;
			m_prot <= 3'd0;
			m_error <= 1'b0;
			m_rdata <= 32'd0;
			m_req_count <= 2'd0;
		end else begin
			if (m_ready && !s_ready) begin
				m_addr <= r_addr;
				m_wdata <= r_wdata;
				m_wstrb <= r_wstrb;
				m_prot <= r_prot;
				m_error <= r_error;
				m_rdata <= 32'd0;
				m_req_count <= m_req_count + 1'b1;
			end
		end
	end

	// Slave Side: Update internal state based on captured data from Master
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_addr <= 12'd0;
			s_wdata <= 32'd0;
			s_wstrb <= 4'd0;
			s_prot <= 3'd0;
			s_error <= 1'b0;
			s_rdata <= 32'd0;
			s_req_count <= 2'd0;
		end else begin
			if (s_ready && !m_ready) begin
				s_addr <= c_addr;
				s_wdata <= c_wdata;
				s_wstrb <= c_wstrb;
				s_prot <= c_prot;
				s_error <= c_error;
				s_rdata <= 32'd0;
				s_req_count <= s_req_count + 1'b1;
			end
		end
	end

	// Master Side: Update internal state based on captured data from Slave
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_addr <= 12'd0;
			m_wdata <= 32'd0;
			m_wstrb <= 4'd0;
			m_prot <= 3'd0;
			m_error <= 1'b0;
			m_rdata <= 32'd0;
			m_req_count <= 2'd0;
		end else begin
			if (m_ready && !s_ready) begin
				m_addr <= r_addr;
				m_wdata <= r_wdata;
				m_wstrb <= r_wstrb;
				m_prot <= r_prot;
				m_error <= r_error;
				m_rdata <= 32'd0;
				m_req_count <= m_req_count + 1'b1;
			end
		end
	end

	// Slave Side: Update internal state based on captured data from Master
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_addr <= 12'd0;
			s_wdata <= 32'd0;
			s_wstrb <= 4'd0;
			s_prot <= 3'd0;
			s_error <= 1'b0;
			s_rdata <= 32'd0;
			s_req_count <= 2'd0;
		end else begin
			if (s_ready && !m_ready) begin
				s_addr <= c_addr;
				s_wdata <= c_wdata;
				s_wstrb <= c_wstrb;
				s_prot <= c_prot;
				s_error <= c_error;
				s_rdata <= 32'd0;
				s_req_count <= s_req_count + 1'b1;
			end
		end
	end

	// Master Side: Update internal state based on captured data from Slave
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_addr <= 12'd0;
			m_wdata <= 32'd0;
			m_wstrb <= 4'd0;
			m_prot <= 3'd0;
			m_error <= 1'b0;
			m_rdata <= 32'd0;
			m_req_count <= 2'd0;
		end else begin
			if (m_ready && !s_ready) begin
				m_addr <= r_addr;
				m_wdata <= r_wdata;
				m_wstrb <= r_wstrb;
				m_prot <= r_prot;
				m_error <= r_error;
				m_rdata <= 32'd0;
				m_req_count <= m_req_count + 1'b1;
			end
		end
	end

	// Slave Side: Update internal state based on captured data from Master
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_addr <= 12'd0;
			s_wdata <= 32'd0;
			s_wstrb <= 4'd0;
			s_prot <= 3'd0;
			s_error <= 1'b0;
			s_rdata <= 32'd0;
			s_req_count <= 2'd0;
		end else begin
			if (s_ready && !m_ready) begin
				s_addr <= c_addr;
				s_wdata <= c_wdata;
				s_wstrb <= c_wstrb;
				s_prot <= c_prot;
				s_error <= c_error;
				s_rdata <= 32'd0;
				s_req_count <= s_req_count + 1'b1;
			end
		end
	end

	// Master Side: Update internal state based on captured data from Slave
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_addr <= 12'd0;
			m_wdata <= 32'd0;
			m_wstrb <= 4'd0;
			m_prot <= 3'd0;
			m_error <= 1'b0;
			m_rdata <= 32'd0;
			m_req_count <= 2'd0;
		end else begin
			if (m_ready && !s_ready) begin
				m_addr <= r_addr;
				m_wdata <= r_wdata;
				m_wstrb <= r_wstrb;
				m_prot <= r_prot;
				m_error <= r_error;
				m_rdata <= 32'd0;
				m_req_count <= m_req_count + 1'b1;
			end
		end
	end

	// Slave Side: Update internal state based on captured data from Master
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_addr <= 12'd0;
			s_wdata <= 32'd0;
			s_wstrb <= 4'd0;
			s_prot <= 3'd0;
			s_error <= 1'b0;
			s_rdata <= 32'd0;
			s_req_count <= 2'd0;
		end else begin
			if (s_ready && !m_ready) begin
				s_addr <= c_addr;
				s_wdata <= c_wdata;
				s_wstrb <= c_wstrb;
				s_prot <= c_prot;
				s_error <= c_error;
				s_rdata <= 32'd0;
				s_req_count <= s_req_count + 1'b1;
			end
		end
	end

	// Master Side: Update internal state based on captured data from Slave
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_addr <= 12'd0;
			m_wdata <= 32'd0;
			m_wstrb <= 4'd0;
			m_prot <= 3'd0;
			m_error <= 1'b0;
			m_rdata <= 32'd0;
			m_req_count <= 2'd0;
		end else begin
			if (m_ready && !s_ready) begin
				m_addr <= r_addr;
				m_wdata <= r_wdata;
				m_wstrb <= r_wstrb;
				m_prot <= r_prot;
				m_error <= r_error;
				m_rdata <= 32'd0;
				m_req_count <= m_req_count + 1'b1;
			end
		end
	end

	// Slave Side: Update internal state based on captured data from Master
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_addr <= 12'd0;
			s_wdata <= 32'd0;
			s_wstrb <= 4'd0;
			s_prot <= 3'd0;
			s_error <= 1'b0;
			s_rdata <= 32'd0;
			s_req_count <= 2'd0;
		end else begin
			if (s_ready && !m_ready) begin
				s_addr <= c_addr;
				s_wdata <= c_wdata;
				s_wstrb <= c_wstrb;
				s_prot <= c_prot;
				s_error <= c_error;
				s_rdata <= 32'd0;
				s_req_count <= s_req_count + 1'b1;
			end
		end
	end

	// Master Side: Update internal state based on captured data from Slave
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_addr <= 12'd0;
			m_wdata <= 32'd0;
			m_wstrb <= 4'd0;
			m_prot <= 3'd0;
			m_error <= 1'b0;
			m_rdata <= 32'd0;
			m_req_count <= 2'd0;
		end else begin
			if (m_ready && !s_ready) begin
				m_addr <= r_addr;
				m_wdata <= r_wdata;
				m_wstrb <= r_wstrb;
				m_prot <= r_prot;
				m_error <= r_error;
				m_rdata <= 32'd0;
				m_req_count <= m_req_count + 1'b1;
			end
		end
	end

	// Slave Side: Update internal state based on captured data from Master
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_addr <= 12'd0;
			s_wdata <= 32'd0;
			s_wstrb <= 4'd0;
			s_prot <= 3'd0;
			s_error <= 1'b0;
			s_rdata <= 32'd0;
			s_req_count <= 2'd0;
		end else begin
			if (s_ready && !m_ready) begin
				s_addr <= c_addr;
				s_wdata <= c_wdata;
				s_wstrb <= c_wstrb;
				s_prot <= c_prot;
				s_error <= c_error;
				s_rdata <= 32'd0;
				s_req_count <= s_req_count + 1'b1;
			end
		end
	end

	// Master Side: Update internal state based on captured data from Slave
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_addr <= 12'd0;
			m_wdata <= 32'd0;
			m_wstrb <= 4'd0;
			m_prot <= 3'd0;
			m_error <= 1'b0;
			m_rdata <= 32'd0;
			m_req_count <= 2'd0;
		end else begin
			if (m_ready && !s_ready) begin
				m_addr <= r_addr;
				m_wdata <= r_wdata;
				m_wstrb <= r_wstrb;
				m_prot <= r_prot;
				m_error <= r_error;
				m_rdata <= 32'd0;
				m_req_count <= m_req_count + 1'b1;
			end
		end
	end

	// Slave Side: Update internal state based on captured data from Master
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_addr <= 12'd0;
			s_wdata <= 32'd0;
			s_wstrb <= 4'd0;
			s_prot <= 3'd0;
			s_error <= 1'b0;
			s_rdata <= 32'd0;
			s_req_count <= 2'd0;
		end else begin
			if (s_ready && !m_ready) begin
				s_addr <= c_addr;
				s_wdata <= c_wdata;
				s_wstrb <= c_wstrb;
				s_prot <= c_prot;
				s_error <= c_error;
				s_rdata <= 32'd0;
				s_req_count <= s_req_count + 1'b1;
			end
		end
	end

	// Master Side: Update internal state based on captured data from Slave
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_addr <= 12'd0;
			m_wdata <= 32'd0;
			m_wstrb <= 4'd0;
			m_prot <= 3'd0;
			m_error <= 1'b0;
			m_rdata <= 32'd0;
			m_req_count <= 2'd0;
		end else begin
			if (m_ready && !s_ready) begin
				m_addr <= r_addr;
				m_wdata <= r_wdata;
				m_wstrb <= r_wstrb;
				m_prot <= r_prot;
				m_error <= r_error;
				m_rdata <= 32'd0;
				m_req_count <= m_req_count + 1'b1;
			end
		end
	end

	// Slave Side: Update internal state based on captured data from Master
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_addr <= 12'd0;
			s_wdata <= 32'd0;
			s_wstrb <= 4'd0;
			s_prot <= 3'd0;
			s_error <= 1'b0;
			s_rdata <= 32'd0;
			s_req_count <= 2'd0;
		end else begin
			if (s_ready && !m_ready) begin
				s_addr <= c_addr;
				s_wdata <= c_wdata;
				s_wstrb <= c_wstrb;
				s_prot <= c_prot;
				s_error <= c_error;
				s_rdata <= 32'd0;
				s_req_count <= s_req_count + 1'b1;
			end
		end
	end

	// Master Side: Update internal state based on captured data from Slave
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_addr <= 12'd0;
			m_wdata <= 32'd0;
			m_wstrb <= 4'd0;
			m_prot <= 3'd0;
			m_error <= 1'b0;
			m_rdata <= 32'd0;
			m_req_count <= 2'd0;
		end else begin
			if (m_ready && !s_ready) begin
				m_addr <= r_addr;
				m_wdata <= r_wdata;
				m_wstrb <= r_wstrb;
				m_prot <= r_prot;
				m_error <= r_error;
				m_rdata <= 32'd0;
				m_req_count <= m_req_count + 1'b1;
			end
		end
	end

	// Slave Side: Update internal state based on captured data from Master
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_addr <= 12'd0;
			s_wdata <= 32'd0;
			s_wstrb <= 4'd0;
			s_prot <= 3'd0;
			s_error <= 1'b0;
			s_rdata <= 32'd0;
			s_req_count <= 2'd0;
		end else begin
			if (s_ready && !m_ready) begin
				s_addr <= c_addr;
				s_wdata <= c_wdata;
				s_wstrb <= c_wstrb;
				s_prot <= c_prot;
				s_error <= c_error;
				s_rdata <= 32'd0;
				s_req_count <= s_req_count + 1'b1;
			end
		end
	end

	// Master Side: Update internal state based on captured data from Slave
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_addr <= 12'd0;
			m_wdata <= 32'd0;
			m_wstrb <= 4'd0;
			m_prot <= 3'd0;
			m_error <= 1'b0;
			m_rdata <= 32'd0;
			m_req_count <= 2'd0;
		end else begin
			if (m_ready && !s_ready) begin
				m_addr <= r_addr;
				m_wdata <= r_wdata;
				m_wstrb <= r_wstrb;
				m_prot <= r_prot;
				m_error <= r_error;
				m_rdata <= 32'd0;
				m_req_count <= m_req_count + 1'b1;
			end
		end
	end

	// Slave Side: Update internal state based on captured data from Master
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_addr <= 12'd0;
			s_wdata <= 32'd0;
			s_wstrb <= 4'd0;
			s_prot <= 3'd0;
			s_error <= 1'b0;
			s_rdata <= 32'd0;
			s_req_count <= 2'd0;
		end else begin
			if (s_ready && !m_ready) begin
				s_addr <= c_addr;
				s_wdata <= c_wdata;
				s_wstrb <= c_wstrb;
				s_prot <= c_prot;
				s_error <= c_error;
				s_rdata <= 32'd0;
				s_req_count <= s_req_count + 1'b1;
			end
		end
	end

	// Master Side: Update internal state based on captured data from Slave
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_addr <= 12'd0;
			m_wdata <= 32'd0;
			m_wstrb <= 4'd0;
			m_prot <= 3'd0;
			m_error <= 1'b0;
			m_rdata <= 32'd0