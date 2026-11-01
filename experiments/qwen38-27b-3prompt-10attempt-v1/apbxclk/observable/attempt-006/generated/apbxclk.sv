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

	// Synchronous reset synchronizer for M_APB_PCLK domain
	reg [1:0] m_reset_sync;
	reg m_reset_sync_next;

	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			m_reset_sync <= 2'b00;
		else
			m_reset_sync <= {m_reset_sync[0], 1'b1};
	end

	assign M_PRESETn = m_reset_sync[1];

	// Slave-side state machine
	// States:
	//   S_IDLE: waiting for a new APB setup phase
	//   S_WAIT: waiting for master to complete the transfer
	reg [1:0] s_state;
	localparam S_IDLE = 2'b00;
	localparam S_WAIT = 2'b01;

	// Handshake signals between domains
	// s2m_req: slave requests a transfer (set in S_IDLE when PSEL & !PENABLE)
	// m2s_done: master indicates transfer complete
	reg s2m_req;
	reg m2s_done;

	// Synchronous reset for s2m_req in S_APB_PCLK domain
	reg [1:0] s_reset_sync;
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			s_reset_sync <= 2'b00;
		else
			s_reset_sync <= {s_reset_sync[0], 1'b1};
	end
	wire s_reset = !s_reset_sync[1];

	// Synchronous reset for m2s_done in M_APB_PCLK domain
	reg [1:0] m_reset_sync2;
	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			m_reset_sync2 <= 2'b00;
		else
			m_reset_sync2 <= {m_reset_sync2[0], 1'b1};
	end
	wire m_reset = !m_reset_sync2[1];

	// Slave-side logic
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_state <= S_IDLE;
			S_APB_PREADY <= 1'b0;
			s2m_req <= 1'b0;
		end else begin
			case (s_state)
				S_IDLE: begin
					S_APB_PREADY <= 1'b1;
					if (S_APB_PSEL && !S_APB_PENABLE) begin
						s2m_req <= 1'b1;
						s_state <= S_WAIT;
					end else begin
						s2m_req <= 1'b0;
					end
				end
				S_WAIT: begin
					S_APB_PREADY <= 1'b0;
					if (m2s_done) begin
						s2m_req <= 1'b0;
						s_state <= S_IDLE;
					end
				end
				default: begin
					s_state <= S_IDLE;
					S_APB_PREADY <= 1'b0;
					s2m_req <= 1'b0;
				end
			endcase
		end
	end

	// Master-side logic
	// m2s_done is set when the master-side APB transfer completes
	// The master drives PSEL and PENABLE based on s2m_req

	reg m_state;
	localparam M_IDLE = 1'b0;
	localparam M_SETUP = 1'b1;
	localparam M_ACCESS = 1'b10;

	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_state <= M_IDLE;
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			m2s_done <= 1'b0;
		end else begin
			case (m_state)
				M_IDLE: begin
					M_APB_PSEL <= 1'b0;
					M_APB_PENABLE <= 1'b0;
					m2s_done <= 1'b0;
					if (s2m_req) begin
						m_state <= M_SETUP;
					end
				end
				M_SETUP: begin
					M_APB_PSEL <= 1'b1;
					M_APB_PENABLE <= 1'b0;
					m2s_done <= 1'b0;
					m_state <= M_ACCESS;
				end
				M_ACCESS: begin
					M_APB_PSEL <= 1'b1;
					M_APB_PENABLE <= 1'b1;
					if (M_APB_PREADY) begin
						m2s_done <= 1'b1;
						m_state <= M_IDLE;
					end
				end
				default: begin
					m_state <= M_IDLE;
					M_APB_PSEL <= 1'b0;
					M_APB_PENABLE <= 1'b0;
					m2s_done <= 1'b0;
				end
			endcase
		end
	end

	// Payload crossing: capture in M_APB_PCLK domain
	// Address, write data, strobes, write flag, prot
	reg [AW-1:0] m_addr;
	reg [DW-1:0] m_wdata;
	reg [DW/8-1:0] m_wstrb;
	reg m_write;
	reg [2:0] m_prot;

	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_addr <= {AW{1'b0}};
			m_wdata <= {DW{1'b0}};
			m_wstrb <= {(DW/8){1'b0}};
			m_write <= 1'b0;
			m_prot <= 3'b000;
		end else if (s2m_req && m_state == M_IDLE) begin
			m_addr <= S_APB_PADDR;
			m_wdata <= S_APB_PWDATA;
			m_wstrb <= S_APB_PWSTRB;
			m_write <= S_APB_PWRITE;
			m_prot <= S_APB_PPROT;
		end
	end

	assign M_APB_PADDR = m_addr;
	assign M_APB_PWRITE = m_write;
	assign M_APB_PWDATA = m_wdata;
	assign M_APB_PWSTRB = m_wstrb;
	assign M_APB_PPROT = m_prot;

	// Response crossing: capture in S_APB_PCLK domain
	reg [DW-1:0] s_rdata;
	reg s_pslverr;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_rdata <= {DW{1'b0}};
			s_pslverr <= 1'b0;
		end else if (m2s_done) begin
			s_rdata <= M_APB_PRDATA;
			s_pslverr <= M_APB_PSLVERR;
		end
	end

	assign S_APB_PRDATA = s_rdata;
	assign S_APB_PSLVERR = s_pslverr;

endmodule
