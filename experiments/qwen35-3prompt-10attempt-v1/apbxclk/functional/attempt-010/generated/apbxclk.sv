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
	reg [AW-1:0]		i_addr;
	reg [DW-1:0]		i_write_data;
	reg [DW/8-1:0]		i_write_strb;
	reg [2:0]			i_prot;
	reg				i_write;
	reg				i_sel;
	reg				i_enable;
	reg				i_ready;
	reg				i_err;
	reg				i_data_valid;
	reg [DW-1:0]		i_data;

	// State machine for source side (S_APB)
	// States: IDLE, SETUP, ACCESS
	localparam	IDLE = 2'b00;
	localparam	SETUP = 2'b01;
	localparam	ACCESS = 2'b10;

	reg [1:0]		s_state;
	reg			s_req_valid;
	reg			s_req_ready;
	reg			s_data_valid;
	reg			s_data_ready;
	reg			s_err;
	reg			s_addr;
	reg			s_write;
	reg			s_write_data;
	reg			s_write_strb;
	reg			s_prot;

	// S_APB Clock Domain Logic
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_state <= IDLE;
			s_req_valid <= 1'b0;
			s_req_ready <= 1'b1;
			s_data_valid <= 1'b0;
			s_data_ready <= 1'b1;
			s_err <= 1'b0;
			s_addr <= 1'b0;
			s_write <= 1'b0;
			s_write_data <= 1'b0;
			s_write_strb <= 1'b0;
			s_prot <= 1'b0;
			S_APB_PREADY <= 1'b1;
			S_APB_PRDATA <= 1'b0;
			S_APB_PSLVERR <= 1'b0;
		end
		else begin
			// Request Handshake
			s_req_ready <= s_state == IDLE;
			if (s_req_valid && s_req_ready) begin
				s_req_valid <= 1'b0;
				s_state <= SETUP;
			end

			// Setup Phase Logic
			if (s_state == SETUP) begin
				if (S_APB_PENABLE) begin
					s_addr <= S_APB_PADDR;
					s_write <= S_APB_PWRITE;
					s_write_data <= S_APB_PWDATA;
					s_write_strb <= S_APB_PWSTRB;
					s_prot <= S_APB_PPROT;
					s_state <= ACCESS;
				end
			end

			// Access Phase Logic
			if (s_state == ACCESS) begin
				if (M_APB_PREADY) begin
					s_state <= IDLE;
					s_data_valid <= 1'b1;
					s_data_ready <= 1'b0;
					if (M_APB_PSLVERR) begin
						s_err <= 1'b1;
					end
				end
			end

			// Data Handshake
			s_data_ready <= s_state == IDLE;
			if (s_data_valid && s_data_ready) begin
				s_data_valid <= 1'b0;
				s_data_ready <= 1'b1;
				S_APB_PRDATA <= M_APB_PRDATA;
				S_APB_PSLVERR <= s_err;
			end

			// Ready Output
			S_APB_PREADY <= (s_state == IDLE);
		end
	end

	// M_APB Clock Domain Logic
	// State machine for M_APB side
	// States: IDLE, SETUP, ACCESS
	localparam	IDLE_M = 2'b00;
	localparam	SETUP_M = 2'b01;
	localparam	ACCESS_M = 2'b10;

	reg [1:0]		m_state;
	reg			m_req_valid;
	reg			m_req_ready;
	reg			m_data_valid;
	reg			m_data_ready;
	reg			m_err;
	reg			m_addr;
	reg			m_write;
	reg			m_write_data;
	reg			m_write_strb;
	reg			m_prot;

	// Cross-domain registers for M_APB side
	reg [AW-1:0]		m_cross_addr;
	reg [DW-1:0]		m_cross_write_data;
	reg [DW/8-1:0]		m_cross_write_strb;
	reg [2:0]			m_cross_prot;
	reg				m_cross_write;
	reg				m_cross_sel;
	reg				m_cross_enable;
	reg				m_cross_ready;
	reg				m_cross_err;
	reg				m_cross_data_valid;
	reg [DW-1:0]		m_cross_data;

	// M_APB Clock Domain Logic
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_state <= IDLE_M;
			m_req_valid <= 1'b0;
			m_req_ready <= 1'b1;
			m_data_valid <= 1'b0;
			m_data_ready <= 1'b1;
			m_err <= 1'b0;
			m_addr <= 1'b0;
			m_write <= 1'b0;
			m_write_data <= 1'b0;
			m_write_strb <= 1'b0;
			m_prot <= 1'b0;
			M_APB_PREADY <= 1'b1;
			M_APB_PRDATA <= 1'b0;
			M_APB_PSLVERR <= 1'b0;
		end
		else begin
			// Request Handshake
			m_req_ready <= m_state == IDLE_M;
			if (m_req_valid && m_req_ready) begin
				m_req_valid <= 1'b0;
				m_state <= SETUP_M;
			end

			// Setup Phase Logic
			if (m_state == SETUP_M) begin
				if (M_APB_PENABLE) begin
					m_addr <= M_APB_PADDR;
					m_write <= M_APB_PWRITE;
					m_write_data <= M_APB_PWDATA;
					m_write_strb <= M_APB_PWSTRB;
					m_prot <= M_APB_PPROT;
					m_state <= ACCESS_M;
				end
			end

			// Access Phase Logic
			if (m_state == ACCESS_M) begin
				if (S_APB_PREADY) begin
					m_state <= IDLE_M;
					m_data_valid <= 1'b1;
					m_data_ready <= 1'b0;
					if (S_APB_PSLVERR) begin
						m_err <= 1'b1;
					end
				end
			end

			// Data Handshake
			m_data_ready <= m_state == IDLE_M;
			if (m_data_valid && m_data_ready) begin
				m_data_valid <= 1'b0;
				m_data_ready <= 1'b1;
				M_APB_PRDATA <= S_APB_PRDATA;
				M_APB_PSLVERR <= m_err;
			end

			// Ready Output
			M_APB_PREADY <= (m_state == IDLE_M);
		end
	end

	// Cross-domain synchronization logic
	// Capture S_APB signals on M_APB clock
	reg [AW-1:0]		c_addr;
	reg [DW-1:0]		c_write_data;
	reg [DW/8-1:0]		c_write_strb;
	reg [2:0]			c_prot;
	reg				c_write;
	reg				c_sel;
	reg				c_enable;
	reg				c_ready;
	reg				c_err;
	reg				c_data_valid;
	reg [DW-1:0]		c_data;

	// S_APB to M_APB crossing
	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			c_addr <= 1'b0;
			c_write_data <= 1'b0;
			c_write_strb <= 1'b0;
			c_prot <= 1'b0;
			c_write <= 1'b0;
			c_sel <= 1'b0;
			c_enable <= 1'b0;
			c_ready <= 1'b1;
			c_err <= 1'b0;
			c_data_valid <= 1'b0;
			c_data <= 1'b0;
			M_PRESETn <= 1'b1;
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
		end
		else begin
			// Capture source signals
			if (S_APB_PCLK) begin
				c_addr <= S_APB_PADDR;
				c_write_data <= S_APB_PWDATA;
				c_write_strb <= S_APB_PWSTRB;
				c_prot <= S_APB_PPROT;
				c_write <= S_APB_PWRITE;
				c_sel <= S_APB_PSEL;
				c_enable <= S_APB_PENABLE;
				c_ready <= S_APB_PREADY;
				c_err <= S_APB_PSLVERR;
				c_data_valid <= S_APB_PRDATA[0]; // Dummy to capture data if needed
				c_data <= S_APB_PRDATA;
			end

			// Reset output
			M_PRESETn <= S_PRESETn;

			// Request generation
			if (c_sel && c_enable && c_ready) begin
				M_APB_PSEL <= 1'b1;
				M_APB_PENABLE <= 1'b1;
				M_APB_PADDR <= c_addr;
				M_APB_PWRITE <= c_write;
				M_APB_PWDATA <= c_write_data;
				M_APB_PWSTRB <= c_write_strb;
				M_APB_PPROT <= c_prot;
			end else begin
				M_APB_PSEL <= 1'b0;
				M_APB_PENABLE <= 1'b0;
			end

			// Response capture
			if (M_APB_PREADY) begin
				S_APB_PRDATA <= M_APB_PRDATA;
				S_APB_PSLVERR <= M_APB_PSLVERR;
				S_APB_PREADY <= 1'b1;
			end else begin
				S_APB_PREADY <= 1'b0;
			end
		end
	end

	// M_APB to S_APB crossing
	always @(posedge S_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_cross_addr <= 1'b0;
			m_cross_write_data <= 1'b0;
			m_cross_write_strb <= 1'b0;
			m_cross_prot <= 1'b0;
			m_cross_write <= 1'b0;
			m_cross_sel <= 1'b0;
			m_cross_enable <= 1'b0;
			m_cross_ready <= 1'b1;
			m_cross_err <= 1'b0;
			m_cross_data_valid <= 1'b0;
			m_cross_data <= 1'b0;
			S_APB_PREADY <= 1'b1;
			S_APB_PRDATA <= 1'b0;
			S_APB_PSLVERR <= 1'b0;
		end
		else begin
			// Capture destination signals
			if (M_APB_PCLK) begin
				m_cross_addr <= M_APB_PADDR;
				m_cross_write_data <= M_APB_PWDATA;
				m_cross_write_strb <= M_APB_PWSTRB;
				m_cross_prot <= M_APB_PPROT;
				m_cross_write <= M_APB_PWRITE;
				m_cross_sel <= M_APB_PSEL;
				m_cross_enable <= M_APB_PENABLE;
				m_cross_ready <= M_APB_PREADY;
				m_cross_err <= M_APB_PSLVERR;
				m_cross_data_valid <= M_APB_PRDATA[0]; // Dummy to capture data if needed
				m_cross_data <= M_APB_PRDATA;
			end

			// Reset output
			M_PRESETn <= S_PRESETn;

			// Request generation
			if (m_cross_sel && m_cross_enable && m_cross_ready) begin
				S_APB_PSEL <= 1'b1;
				S_APB_PENABLE <= 1'b1;
				S_APB_PADDR <= m_cross_addr;
				S_APB_PWRITE <= m_cross_write;
				S_APB_PWDATA <= m_cross_write_data;
				S_APB_PWSTRB <= m_cross_write_strb;
				S_APB_PPROT <= m_cross_prot;
			end else begin
				S_APB_PSEL <= 1'b0;
				S_APB_PENABLE <= 1'b0;
			end

			// Response capture
			if (S_APB_PREADY) begin
				M_APB_PRDATA <= S_APB_PRDATA;
				M_APB_PSLVERR <= S_APB_PSLVERR;
				M_APB_PREADY <= 1'b1;
			end else begin
				M_APB_PREADY <= 1'b0;
			end
		end
	end

endmodule
```<|im_end|>
