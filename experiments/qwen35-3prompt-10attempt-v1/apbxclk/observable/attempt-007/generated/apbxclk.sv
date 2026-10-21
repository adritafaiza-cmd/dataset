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

	// State Machine for Slave Side (S_APB)
	// States: IDLE, WAITING_FOR_MASTER, DATA_TRANSFER
	localparam	IDLE_S = 2'b00;
	localparam	WAITING_S = 2'b01;
	localparam	DATA_S = 2'b10;

	reg [1:0]	s_state;
	reg		s_psel;
	reg		s_penable;
	reg		s_pwrite;
	reg	[AW-1:0]	s_paddr;
	reg	[DW-1:0]	s_pdata;
	reg	[DW/8-1:0]	s_pstrb;
	reg	[2:0]	s_pprot;
	reg		s_pready;
	reg		s_pslverr;
	reg		s_req_valid;
	reg		s_req_addr;
	reg		s_req_write;
	reg		s_req_data;
	reg	[DW/8-1:0]	s_req_strb;
	reg	[2:0]	s_req_prot;
	reg		s_resp_ready;
	reg		s_resp_data;
	reg	[DW/8-1:0]	s_resp_strb;
	reg		s_resp_prot;
	reg		s_resp_err;
	reg		s_master_active;

	// State Machine for Master Side (M_APB)
	// States: IDLE, WAITING_FOR_SLAVE, DATA_TRANSFER
	localparam	IDLE_M = 2'b00;
	localparam	WAITING_M = 2'b01;
	localparam	DATA_M = 2'b10;

	reg [1:0]	m_state;
	reg		m_psel;
	reg		m_penable;
	reg		m_pwrite;
	reg	[AW-1:0]	m_paddr;
	reg	[DW-1:0]	m_pdata;
	reg	[DW/8-1:0]	m_pstrb;
	reg	[2:0]	m_pprot;
	reg		m_pready;
	reg		m_pslverr;
	reg		m_req_valid;
	reg		m_req_addr;
	reg		m_req_write;
	reg		m_req_data;
	reg	[DW/8-1:0]	m_req_strb;
	reg	[2:0]	m_req_prot;
	reg		m_resp_ready;
	reg		m_resp_data;
	reg	[DW/8-1:0]	m_resp_strb;
	reg		m_resp_prot;
	reg		m_resp_err;
	reg		m_slave_active;

	// Clock Domain Crossing Registers (Slave -> Master)
	reg		cdc_req_valid;
	reg		cdc_req_addr;
	reg		cdc_req_write;
	reg	[DW-1:0]	cdc_req_data;
	reg	[DW/8-1:0]	cdc_req_strb;
	reg	[2:0]	cdc_req_prot;
	reg		cdc_resp_ready;
	reg	[DW-1:0]	cdc_resp_data;
	reg	[DW/8-1:0]	cdc_resp_strb;
	reg	[2:0]	cdc_resp_prot;
	reg		cdc_resp_err;

	// Clock Domain Crossing Registers (Master -> Slave)
	reg		cdc2_req_valid;
	reg		cdc2_req_addr;
	reg		cdc2_req_write;
	reg	[DW-1:0]	cdc2_req_data;
	reg	[DW/8-1:0]	cdc2_req_strb;
	reg	[2:0]	cdc2_req_prot;
	reg		cdc2_resp_ready;
	reg	[DW-1:0]	cdc2_resp_data;
	reg	[DW/8-1:0]	cdc2_resp_strb;
	reg	[2:0]	cdc2_resp_prot;
	reg		cdc2_resp_err;

	// Slave Side Logic
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_state <= IDLE_S;
			s_psel <= 1'b0;
			s_penable <= 1'b0;
			s_pready <= 1'b1;
			s_pslverr <= 1'b0;
			s_master_active <= 1'b0;
		end else begin
			// State Transition
			case (s_state)
				IDLE_S: begin
					if (S_APB_PSEL && S_APB_PENABLE) begin
						s_state <= WAITING_S;
						s_psel <= S_APB_PSEL;
						s_penable <= S_APB_PENABLE;
						s_paddr <= S_APB_PADDR;
						s_pwrite <= S_APB_PWRITE;
						s_pdata <= S_APB_PWDATA;
						s_pstrb <= S_APB_PWSTRB;
						s_pprot <= S_APB_PPROT;
						s_req_valid <= 1'b1;
						s_req_addr <= S_APB_PADDR;
						s_req_write <= S_APB_PWRITE;
						s_req_data <= S_APB_PWDATA;
						s_req_strb <= S_APB_PWSTRB;
						s_req_prot <= S_APB_PPROT;
						s_master_active <= 1'b1;
					end else begin
						s_state <= IDLE_S;
						s_psel <= 1'b0;
						s_penable <= 1'b0;
						s_pready <= 1'b1;
						s_pslverr <= 1'b0;
						s_master_active <= 1'b0;
					end
				end

				WAITING_S: begin
					if (cdc_resp_ready) begin
						s_state <= DATA_S;
						s_pready <= 1'b0;
						s_pslverr <= cdc_resp_err;
						s_paddr <= cdc_resp_addr;
						s_pwrite <= cdc_resp_write;
						s_pdata <= cdc_resp_data;
						s_pstrb <= cdc_resp_strb;
						s_pprot <= cdc_resp_prot;
						s_master_active <= 1'b1;
					end else begin
						s_pready <= 1'b1;
						s_pslverr <= 1'b0;
						s_master_active <= 1'b0;
					end
				end

				DATA_S: begin
					if (cdc_resp_ready) begin
						s_state <= IDLE_S;
						s_psel <= 1'b0;
						s_penable <= 1'b0;
						s_pready <= 1'b1;
						s_pslverr <= 1'b0;
						s_master_active <= 1'b0;
					end else begin
						s_pready <= 1'b1;
						s_pslverr <= 1'b0;
						s_master_active <= 1'b0;
					end
				end
			endcase
		end
	end

	// Master Side Logic
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_state <= IDLE_M;
			m_psel <= 1'b0;
			m_penable <= 1'b0;
			m_pready <= 1'b1;
			m_pslverr <= 1'b0;
			m_slave_active <= 1'b0;
		end else begin
			// State Transition
			case (m_state)
				IDLE_M: begin
					if (cdc_req_valid) begin
						m_state <= WAITING_M;
						m_psel <= 1'b1;
						m_penable <= 1'b1;
						m_paddr <= cdc_req_addr;
						m_pwrite <= cdc_req_write;
						m_pdata <= cdc_req_data;
						m_pstrb <= cdc_req_strb;
						m_pprot <= cdc_req_prot;
						m_req_valid <= 1'b1;
						m_req_addr <= cdc_req_addr;
						m_req_write <= cdc_req_write;
						m_req_data <= cdc_req_data;
						m_req_strb <= cdc_req_strb;
						m_req_prot <= cdc_req_prot;
						m_slave_active <= 1'b1;
					end else begin
						m_state <= IDLE_M;
						m_psel <= 1'b0;
						m_penable <= 1'b0;
						m_pready <= 1'b1;
						m_pslverr <= 1'b0;
						m_slave_active <= 1'b0;
					end
				end

				WAITING_M: begin
					if (cdc2_resp_ready) begin
						m_state <= DATA_M;
						m_pready <= 1'b0;
						m_pslverr <= cdc2_resp_err;
						m_paddr <= cdc2_resp_addr;
						m_pwrite <= cdc2_resp_write;
						m_pdata <= cdc2_resp_data;
						m_pstrb <= cdc2_resp_strb;
						m_pprot <= cdc2_resp_prot;
						m_slave_active <= 1'b1;
					end else begin
						m_pready <= 1'b1;
						m_pslverr <= 1'b0;
						m_slave_active <= 1'b0;
					end
				end

				DATA_M: begin
					if (cdc2_resp_ready) begin
						m_state <= IDLE_M;
						m_psel <= 1'b0;
						m_penable <= 1'b0;
						m_pready <= 1'b1;
						m_pslverr <= 1'b0;
						m_slave_active <= 1'b0;
					end else begin
						m_pready <= 1'b1;
						m_pslverr <= 1'b0;
						m_slave_active <= 1'b0;
					end
				end
			endcase
		end
	end

	// Slave Side Output Logic
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			S_APB_PRDATA <= 1'b0;
			S_APB_PSLVERR <= 1'b0;
		end else begin
			if (s_state == DATA_S) begin
				S_APB_PRDATA <= s_pdata;
				S_APB_PSLVERR <= s_pslverr;
			end else begin
				S_APB_PRDATA <= 1'b0;
				S_APB_PSLVERR <= 1'b0;
			end
		end
	end

	// Master Side Output Logic
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			M_APB_PADDR <= 1'b0;
			M_APB_PWRITE <= 1'b0;
			M_APB_PWDATA <= 1'b0;
			M_APB_PWSTRB <= 1'b0;
			M_APB_PPROT <= 1'b0;
		end else begin
			if (m_state == DATA_M) begin
				M_APB_PADDR <= m_paddr;
				M_APB_PWRITE <= m_pwrite;
				M_APB_PWDATA <= m_pdata;
				M_APB_PWSTRB <= m_pstrb;
				M_APB_PPROT <= m_pprot;
			end else begin
				M_APB_PADDR <= 1'b0;
				M_APB_PWRITE <= 1'b0;
				M_APB_PWDATA <= 1'b0;
				M_APB_PWSTRB <= 1'b0;
				M_APB_PPROT <= 1'b0;
			end
		end
	end

	// Clock Domain Crossing: Slave Request -> Master
	// Capture request on Slave clock, output on Master clock
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			cdc_req_valid <= 1'b0;
			cdc_req_addr <= 1'b0;
			cdc_req_write <= 1'b0;
			cdc_req_data <= 1'b0;
			cdc_req_strb <= 1'b0;
			cdc_req_prot <= 1'b0;
			cdc_resp_ready <= 1'b0;
			cdc_resp_data <= 1'b0;
			cdc_resp_strb <= 1'b0;
			cdc_resp_prot <= 1'b0;
			cdc_resp_err <= 1'b0;
		end else begin
			// Capture request
			if (s_req_valid && !cdc_req_valid) begin
				cdc_req_valid <= 1'b1;
				cdc_req_addr <= s_req_addr;
				cdc_req_write <= s_req_write;
				cdc_req_data <= s_req_data;
				cdc_req_strb <= s_req_strb;
				cdc_req_prot <= s_req_prot;
			end

			// Capture response (from Master side logic)
			if (cdc_resp_ready && !s_resp_ready) begin
				s_resp_ready <= 1'b1;
				cdc_resp_data <= s_resp_data;
				cdc_resp_strb <= s_resp_strb;
				cdc_resp_prot <= s_resp_prot;
				cdc_resp_err <= s_resp_err;
			end
		end
	end

	// Clock Domain Crossing: Master Request -> Slave
	// Capture request on Master clock, output on Slave clock
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			cdc2_req_valid <= 1'b0;
			cdc2_req_addr <= 1'b0;
			cdc2_req_write <= 1'b0;
			cdc2_req_data <= 1'b0;
			cdc2_req_strb <= 1'b0;
			cdc2_req_prot <= 1'b0;
			cdc2_resp_ready <= 1'b0;
			cdc2_resp_data <= 1'b0;
			cdc2_resp_strb <= 1'b0;
			cdc2_resp_prot <= 1'b0;
			cdc2_resp_err <= 1'b0;
		end else begin
			// Capture request
			if (m_req_valid && !cdc2_req_valid) begin
				cdc2_req_valid <= 1'b1;
				cdc2_req_addr <= m_req_addr;
				cdc2_req_write <= m_req_write;
				cdc2_req_data <= m_req_data;
				cdc2_req_strb <= m_req_strb;
				cdc2_req_prot <= m_req_prot;
			end

			// Capture response (from Slave side logic)
			if (cdc2_resp_ready && !s_resp_ready) begin
				s_resp_ready <= 1'b1;
				cdc2_resp_data <= s_resp_data;
				cdc2_resp_strb <= s_resp_strb;
				cdc2_resp_prot <= s_resp_prot;
				cdc2_resp_err <= s_resp_err;
			end
		end
	end

	// Internal Logic for Slave Side Response Generation
	// This logic generates the response that will be sent back to the master
	// It is triggered when the master is ready and the slave has the data
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_resp_ready <= 1'b0;
			s_resp_data <= 1'b0;
			s_resp_strb <= 1'b0;
			s_resp_prot <= 1'b0;
			s_resp_err <= 1'b0;
		end else begin
			// Generate response when master is ready and we are in WAITING_S state
			if (s_state == WAITING_S && M_APB_PREADY) begin
				s_resp_ready <= 1'b1;
				s_resp_data <= s_pdata;
				s_resp_strb <= s_pstrb;
				s_resp_prot <= s_pprot;
				s_resp_err <= 1'b0; // Assume success unless specific error conditions
			end else begin
				s_resp_ready <= 1'b0;
				s_resp_data <= 1'b0;
				s_resp_strb <= 1'b0;
				s_resp_prot <= 1'b0;
				s_resp_err <= 1'b0;
			end
		end
	end

	// Internal Logic for Master Side Response Generation
	// This logic generates the response that will be sent back to the slave
	// It is triggered when the slave is ready and the master has the data
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_resp_ready <= 1'b0;
			m_resp_data <= 1'b0;
			m_resp_strb <= 1'b0;
			m_resp_prot <= 1'b0;
			m_resp_err <= 1'b0;
		end else begin
			// Generate response when slave is ready and we are in WAITING_M state
			if (m_state == WAITING_M && S_APB_PREADY) begin
				m_resp_ready <= 1'b1;
				m_resp_data <= m_pdata;
				m_resp_strb <= m_pstrb;
				m_resp_prot <= m_pprot;
				m_resp_err <= 1'b0; // Assume success unless specific error conditions
			end else begin
				m_resp_ready <= 1'b0;
				m_resp_data <= 1'b0;
				m_resp_strb <= 1'b0;
				m_resp_prot <= 1'b0;
				m_resp_err <= 1'b0;
			end
		end
	end

	// Clock Domain Crossing: Slave Response -> Master
	// Capture response on Slave clock, output on Master clock
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			cdc_resp_ready <= 1'b0;
			cdc_resp_data <= 1'b0;
			cdc_resp_strb <= 1'b0;
			cdc_resp_prot <= 1'b0;
			cdc_resp_err <= 1'b0;
		end else begin
			// Capture response
			if (s_resp_ready && !cdc_resp_ready) begin
				cdc_resp_ready <= 1'b1;
				cdc_resp_data <= s_resp_data;
				cdc_resp_strb <= s_resp_strb;
				cdc_resp_prot <= s_resp_prot;
				cdc_resp_err <= s_resp_err;
			end
		end
	end

	// Clock Domain Crossing: Master Response -> Slave
	// Capture response on Master clock, output on Slave clock
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			cdc2_resp_ready <= 1'b0;
			cdc2_resp_data <= 1'b0;
			cdc2_resp_strb <= 1'b0;
			cdc2_resp_prot <= 1'b0;
			cdc2_resp_err <= 1'b0;
		end else begin
			// Capture response
			if (m_resp_ready && !cdc2_resp_ready) begin
				cdc2_resp_ready <= 1'b1;
				cdc2_resp_data <= m_resp_data;
				cdc2_resp_strb <= m_resp_strb;
				cdc2_resp_prot <= m_resp_prot;
				cdc2_resp_err <= m_resp_err;
			end
		end
	end

endmodule
```<|im_end|>
