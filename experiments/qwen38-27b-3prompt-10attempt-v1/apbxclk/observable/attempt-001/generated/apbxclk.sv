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
	reg [AW-1:0] s_addr_reg;
	reg s_write_reg;
	reg [DW-1:0] s_wdata_reg;
	reg [DW/8-1:0] s_wstrb_reg;
	reg [2:0] s_pprot_reg;
	reg [DW-1:0] s_rdata_reg;
	reg s_slverr_reg;

	// Handshake signals
	reg s_req;
	reg m_ack;
	reg m_req;
	reg s_ack;

	// Master-side state machine
	localparam M_IDLE = 2'd0;
	localparam M_SETUP = 2'd1;
	localparam M_ACCESS = 2'd2;
	localparam M_DONE = 2'd3;

	reg [1:0] m_state;
	reg [AW-1:0] m_addr_reg;
	reg m_write_reg;
	reg [DW-1:0] m_wdata_reg;
	reg [DW/8-1:0] m_wstrb_reg;
	reg [2:0] m_pprot_reg;
	reg [DW-1:0] m_rdata_reg;
	reg m_slverr_reg;

	// Synchronization of s_req to master clock
	reg [1:0] s_req_sync;
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn)
			s_req_sync <= 2'b00;
		else
			s_req_sync <= {s_req_sync[0], s_req};
	end
	wire s_req_mclk = s_req_sync[1];

	// Synchronization of m_ack to slave clock
	reg [1:0] m_ack_sync;
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			m_ack_sync <= 2'b00;
		else
			m_ack_sync <= {m_ack_sync[0], m_ack};
	end
	wire m_ack_sclk = m_ack_sync[1];

	// Synchronization of m_req to slave clock
	reg [1:0] m_req_sync;
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			m_req_sync <= 2'b00;
		else
			m_req_sync <= {m_req_sync[0], m_req};
	end
	wire m_req_sclk = m_req_sync[1];

	// Synchronization of s_ack to master clock
	reg [1:0] s_ack_sync;
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn)
			s_ack_sync <= 2'b00;
		else
			s_ack_sync <= {s_ack_sync[0], s_ack};
	end
	wire s_ack_mclk = s_ack_sync[1];

	// Synchronization of response data from master to slave
	reg [DW-1:0] m_rdata_sync;
	reg m_slverr_sync;
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m_rdata_sync <= {DW{1'b0}};
			m_slverr_sync <= 1'b0;
		end else if (m_req_sclk) begin
			m_rdata_sync <= M_APB_PRDATA;
			m_slverr_sync <= M_APB_PSLVERR;
		end
	end

	// Synchronization of request payload from slave to master
	reg [AW-1:0] s_addr_sync;
	reg s_write_sync;
	reg [DW-1:0] s_wdata_sync;
	reg [DW/8-1:0] s_wstrb_sync;
	reg [2:0] s_pprot_sync;
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			s_addr_sync <= {AW{1'b0}};
			s_write_sync <= 1'b0;
			s_wdata_sync <= {DW{1'b0}};
			s_wstrb_sync <= {(DW/8){1'b0}};
			s_pprot_sync <= 3'b000;
		end else if (s_req_mclk) begin
			s_addr_sync <= S_APB_PADDR;
			s_write_sync <= S_APB_PWRITE;
			s_wdata_sync <= S_APB_PWDATA;
			s_wstrb_sync <= S_APB_PWSTRB;
			s_pprot_sync <= S_APB_PPROT;
		end
	end

	// Slave-side logic
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_state <= S_IDLE;
			S_APB_PREADY <= 1'b1;
			s_addr_reg <= {AW{1'b0}};
			s_write_reg <= 1'b0;
			s_wdata_reg <= {DW{1'b0}};
			s_wstrb_reg <= {(DW/8){1'b0}};
			s_pprot_reg <= 3'b000;
			s_rdata_reg <= {DW{1'b0}};
			s_slverr_reg <= 1'b0;
			s_req <= 1'b0;
			s_ack <= 1'b0;
		end else begin
			case (s_state)
				S_IDLE: begin
					S_APB_PREADY <= 1'b1;
					if (S_APB_PSEL) begin
						s_addr_reg <= S_APB_PADDR;
						s_write_reg <= S_APB_PWRITE;
						s_wdata_reg <= S_APB_PWDATA;
						s_wstrb_reg <= S_APB_PWSTRB;
						s_pprot_reg <= S_APB_PPROT;
						s_req <= 1'b1;
						s_state <= S_SETUP;
					end
				end
				S_SETUP: begin
					S_APB_PREADY <= 1'b0;
					if (m_ack_sclk) begin
						s_req <= 1'b0;
						s_state <= S_ACCESS;
					end
				end
				S_ACCESS: begin
					S_APB_PREADY <= 1'b0;
					if (m_req_sclk) begin
						s_rdata_reg <= m_rdata_sync;
						s_slverr_reg <= m_slverr_sync;
						s_ack <= 1'b1;
						s_state <= S_DONE;
					end
				end
				S_DONE: begin
					S_APB_PREADY <= 1'b1;
					s_ack <= 1'b0;
					s_state <= S_IDLE;
				end
				default: s_state <= S_IDLE;
			endcase
		end
	end

	// Master-side logic
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_state <= M_IDLE;
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			m_addr_reg <= {AW{1'b0}};
			m_write_reg <= 1'b0;
			m_wdata_reg <= {DW{1'b0}};
			m_wstrb_reg <= {(DW/8){1'b0}};
			m_pprot_reg <= 3'b000;
			m_rdata_reg <= {DW{1'b0}};
			m_slverr_reg <= 1'b0;
			m_ack <= 1'b0;
			m_req <= 1'b0;
		end else begin
			case (m_state)
				M_IDLE: begin
					M_APB_PSEL <= 1'b0;
					M_APB_PENABLE <= 1'b0;
					if (s_req_mclk) begin
						m_addr_reg <= s_addr_sync;
						m_write_reg <= s_write_sync;
						m_wdata_reg <= s_wdata_sync;
						m_wstrb_reg <= s_wstrb_sync;
						m_pprot_reg <= s_pprot_sync;
						m_ack <= 1'b1;
						m_state <= M_SETUP;
					end
				end
				M_SETUP: begin
					M_APB_PSEL <= 1'b1;
					M_APB_PENABLE <= 1'b0;
					m_ack <= 1'b0;
					m_state <= M_ACCESS;
				end
				M_ACCESS: begin
					M_APB_PSEL <= 1'b1;
					M_APB_PENABLE <= 1'b1;
					if (M_APB_PREADY) begin
						m_rdata_reg <= M_APB_PRDATA;
						m_slverr_reg <= M_APB_PSLVERR;
						m_req <= 1'b1;
						m_state <= M_DONE;
					end
				end
				M_DONE: begin
					M_APB_PSEL <= 1'b0;
					M_APB_PENABLE <= 1'b0;
					if (s_ack_mclk) begin
						m_req <= 1'b0;
						m_state <= M_IDLE;
					end
				end
				default: begin
					M_APB_PSEL <= 1'b0;
					M_APB_PENABLE <= 1'b0;
					m_state <= M_IDLE;
				end
			endcase
		end
	end

	// Master-side outputs
	assign M_APB_PADDR = m_addr_reg;
	assign M_APB_PWRITE = m_write_reg;
	assign M_APB_PWDATA = m_wdata_reg;
	assign M_APB_PWSTRB = m_wstrb_reg;
	assign M_APB_PPROT = m_pprot_reg;

	// Slave-side outputs
	assign S_APB_PRDATA = s_rdata_reg;
	assign S_APB_PSLVERR = s_slverr_reg;

	// M_PRESETn is tied to S_PRESETn (synchronous reset assumption)
	always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			M_PRESETn <= 1'b0;
		else
			M_PRESETn <= 1'b1;
	end

endmodule
