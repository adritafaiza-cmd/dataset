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

	// Slave-side state machine
	localparam S_IDLE = 2'd0;
	localparam S_SETUP = 2'd1;
	localparam S_ACCESS = 2'd2;
	localparam S_DONE = 2'd3;

	reg [1:0] s_state;
	reg [1:0] s_state_next;

	// Latched slave-side request
	reg [AW-1:0] s_addr_latch;
	reg s_write_latch;
	reg [DW-1:0] s_wdata_latch;
	reg [DW/8-1:0] s_wstrb_latch;
	reg [2:0] s_pprot_latch;

	// Handshake signals
	reg s_req_valid;
	reg m_req_ready;
	reg m_resp_valid;
	reg s_resp_ready;

	// Master-side state machine
	localparam M_IDLE = 2'd0;
	localparam M_SETUP = 2'd1;
	localparam M_ACCESS = 2'd2;
	localparam M_DONE = 2'd3;

	reg [1:0] m_state;
	reg [1:0] m_state_next;

	// Latched master-side request (from slave)
	reg [AW-1:0] m_addr_latch;
	reg m_write_latch;
	reg [DW-1:0] m_wdata_latch;
	reg [DW/8-1:0] m_wstrb_latch;
	reg [2:0] m_pprot_latch;

	// Response latched on master side
	reg [DW-1:0] m_rdata_latch;
	reg m_rslverr_latch;

	// Response latched on slave side
	reg [DW-1:0] s_rdata_latch;
	reg s_rslverr_latch;

	// Synchronizers
	reg [1:0] s_req_valid_sync;
	reg [1:0] m_req_ready_sync;
	reg [1:0] m_resp_valid_sync;
	reg [1:0] s_resp_ready_sync;

	// Slave clock domain: synchronizer for m_req_ready
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			s_req_valid_sync <= 2'b00;
		else
			s_req_valid_sync <= {s_req_valid_sync[0], s_req_valid};
	end

	// Slave clock domain: synchronizer for m_resp_valid
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			m_resp_valid_sync <= 2'b00;
		else
			m_resp_valid_sync <= {m_resp_valid_sync[0], m_resp_valid};
	end

	// Master clock domain: synchronizer for s_req_valid
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn)
			m_req_ready_sync <= 2'b00;
		else
			m_req_ready_sync <= {m_req_ready_sync[0], m_req_ready};
	end

	// Master clock domain: synchronizer for s_resp_ready
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn)
			s_resp_ready_sync <= 2'b00;
		else
			s_resp_ready_sync <= {s_resp_ready_sync[0], s_resp_ready};
	end

	// Slave state machine
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_state <= S_IDLE;
			s_addr_latch <= {AW{1'b0}};
			s_write_latch <= 1'b0;
			s_wdata_latch <= {DW{1'b0}};
			s_wstrb_latch <= {(DW/8){1'b0}};
			s_pprot_latch <= 3'b000;
			s_req_valid <= 1'b0;
			s_resp_ready <= 1'b0;
			S_APB_PREADY <= 1'b0;
			s_rdata_latch <= {DW{1'b0}};
			s_rslverr_latch <= 1'b0;
		end else begin
			s_state <= s_state_next;
			case (s_state)
				S_IDLE: begin
					if (S_APB_PSEL) begin
						s_addr_latch <= S_APB_PADDR;
						s_write_latch <= S_APB_PWRITE;
						s_wdata_latch <= S_APB_PWDATA;
						s_wstrb_latch <= S_APB_PWSTRB;
						s_pprot_latch <= S_APB_PPROT;
						s_req_valid <= 1'b1;
						s_resp_ready <= 1'b0;
						S_APB_PREADY <= 1'b0;
					end else begin
						S_APB_PREADY <= 1'b1;
					end
				end
				S_SETUP: begin
					S_APB_PREADY <= 1'b0;
				end
				S_ACCESS: begin
					if (s_req_valid_sync[1]) begin
						S_APB_PREADY <= 1'b1;
					end else begin
						S_APB_PREADY <= 1'b0;
					end
				end
				S_DONE: begin
					if (m_resp_valid_sync[1]) begin
						s_rdata_latch <= m_rdata_latch;
						s_rslverr_latch <= m_rslverr_latch;
						s_req_valid <= 1'b0;
						s_resp_ready <= 1'b1;
						S_APB_PREADY <= 1'b1;
					end else begin
						S_APB_PREADY <= 1'b1;
					end
				end
				default: begin
					S_APB_PREADY <= 1'b1;
				end
			endcase
		end
	end

	always @(*) begin
		s_state_next = s_state;
		case (s_state)
			S_IDLE: begin
				if (S_APB_PSEL)
					s_state_next = S_SETUP;
			end
			S_SETUP: begin
				s_state_next = S_ACCESS;
			end
			S_ACCESS: begin
				if (s_req_valid_sync[1])
					s_state_next = S_DONE;
			end
			S_DONE: begin
				if (m_resp_valid_sync[1])
					s_state_next = S_IDLE;
			end
			default: s_state_next = S_IDLE;
		endcase
	end

	// Master state machine
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_state <= M_IDLE;
			m_addr_latch <= {AW{1'b0}};
			m_write_latch <= 1'b0;
			m_wdata_latch <= {DW{1'b0}};
			m_wstrb_latch <= {(DW/8){1'b0}};
			m_pprot_latch <= 3'b000;
			m_req_ready <= 1'b0;
			m_resp_valid <= 1'b0;
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			m_rdata_latch <= {DW{1'b0}};
			m_rslverr_latch <= 1'b0;
		end else begin
			m_state <= m_state_next;
			case (m_state)
				M_IDLE: begin
					M_APB_PSEL <= 1'b0;
					M_APB_PENABLE <= 1'b0;
					if (m_req_ready_sync[1]) begin
						m_addr_latch <= s_addr_latch;
						m_write_latch <= s_write_latch;
						m_wdata_latch <= s_wdata_latch;
						m_wstrb_latch <= s_wstrb_latch;
						m_pprot_latch <= s_pprot_latch;
						m_req_ready <= 1'b1;
						m_resp_valid <= 1'b0;
					end
				end
				M_SETUP: begin
					M_APB_PSEL <= 1'b1;
					M_APB_PENABLE <= 1'b0;
				end
				M_ACCESS: begin
					M_APB_PSEL <= 1'b1;
					M_APB_PENABLE <= 1'b1;
					if (M_APB_PREADY) begin
						m_rdata_latch <= M_APB_PRDATA;
						m_rslverr_latch <= M_APB_PSLVERR;
						m_resp_valid <= 1'b1;
						m_req_ready <= 1'b0;
					end
				end
				M_DONE: begin
					M_APB_PSEL <= 1'b0;
					M_APB_PENABLE <= 1'b0;
					if (s_resp_ready_sync[1]) begin
						m_resp_valid <= 1'b0;
					end
				end
				default: begin
					M_APB_PSEL <= 1'b0;
					M_APB_PENABLE <= 1'b0;
				end
			endcase
		end
	end

	always @(*) begin
		m_state_next = m_state;
		case (m_state)
			M_IDLE: begin
				if (m_req_ready_sync[1])
					m_state_next = M_SETUP;
			end
			M_SETUP: begin
				m_state_next = M_ACCESS;
			end
			M_ACCESS: begin
				if (M_APB_PREADY)
					m_state_next = M_DONE;
			end
			M_DONE: begin
				if (s_resp_ready_sync[1])
					m_state_next = M_IDLE;
			end
			default: m_state_next = M_IDLE;
		endcase
	end

	// Master-side outputs
	assign M_APB_PADDR = m_addr_latch;
	assign M_APB_PWRITE = m_write_latch;
	assign M_APB_PWDATA = m_wdata_latch;
	assign M_APB_PWSTRB = m_wstrb_latch;
	assign M_APB_PPROT = m_pprot_latch;

	// Slave-side outputs
	assign S_APB_PRDATA = s_rdata_latch;
	assign S_APB_PSLVERR = s_rslverr_latch;

endmodule
