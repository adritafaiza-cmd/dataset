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

	// Slave-side state
	reg [1:0] s_state;
	localparam S_IDLE = 2'b00;
	localparam S_SETUP = 2'b01;
	localparam S_ACCESS = 2'b10;

	// Master-side state
	reg [1:0] m_state;
	localparam M_IDLE = 2'b00;
	localparam M_SETUP = 2'b01;
	localparam M_ACCESS = 2'b10;

	// Handshake signals
	reg s_req;
	reg m_req;
	reg s_ack;
	reg m_ack;

	// Synchronizers
	reg [1:0] s_req_sync;
	reg [1:0] m_ack_sync;
	reg [1:0] m_req_sync;
	reg [1:0] s_ack_sync;

	// Payload registers (slave side)
	reg [AW-1:0] s_addr_reg;
	reg s_write_reg;
	reg [DW-1:0] s_wdata_reg;
	reg [DW/8-1:0] s_wstrb_reg;
	reg [2:0] s_pprot_reg;

	// Payload registers (master side)
	reg [AW-1:0] m_addr_reg;
	reg m_write_reg;
	reg [DW-1:0] m_wdata_reg;
	reg [DW/8-1:0] m_wstrb_reg;
	reg [2:0] m_pprot_reg;

	// Response registers (master side)
	reg [DW-1:0] m_rdata_reg;
	reg m_slverr_reg;

	// Response registers (slave side)
	reg [DW-1:0] s_rdata_reg;
	reg s_slverr_reg;

	// Synchronizer for s_req
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			s_req_sync <= 2'b00;
		else
			s_req_sync <= {s_req_sync[0], s_req};
	end

	// Synchronizer for m_ack
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			m_ack_sync <= 2'b00;
		else
			m_ack_sync <= {m_ack_sync[0], m_ack};
	end

	// Synchronizer for m_req
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn)
			m_req_sync <= 2'b00;
		else
			m_req_sync <= {m_req_sync[0], m_req};
	end

	// Synchronizer for s_ack
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn)
			s_ack_sync <= 2'b00;
		else
			s_ack_sync <= {s_ack_sync[0], s_ack};
	end

	// Slave-side logic
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_state <= S_IDLE;
			s_req <= 1'b0;
			s_ack <= 1'b0;
			S_APB_PREADY <= 1'b1;
			s_addr_reg <= {AW{1'b0}};
			s_write_reg <= 1'b0;
			s_wdata_reg <= {DW{1'b0}};
			s_wstrb_reg <= {(DW/8){1'b0}};
			s_pprot_reg <= 3'b000;
			s_rdata_reg <= {DW{1'b0}};
			s_slverr_reg <= 1'b0;
		end else begin
			case (s_state)
				S_IDLE: begin
					S_APB_PREADY <= 1'b1;
					if (S_APB_PSEL) begin
						s_state <= S_SETUP;
						s_addr_reg <= S_APB_PADDR;
						s_write_reg <= S_APB_PWRITE;
						s_wdata_reg <= S_APB_PWDATA;
						s_wstrb_reg <= S_APB_PWSTRB;
						s_pprot_reg <= S_APB_PPROT;
						s_req <= 1'b1;
					end
				end
				S_SETUP: begin
					S_APB_PREADY <= 1'b0;
					if (m_ack_sync[1]) begin
						s_state <= S_ACCESS;
						s_req <= 1'b0;
						s_ack <= 1'b1;
					end
				end
				S_ACCESS: begin
					S_APB_PREADY <= 1'b0;
					if (m_ack_sync[1]) begin
						s_state <= S_IDLE;
						s_ack <= 1'b0;
						S_APB_PREADY <= 1'b1;
						s_rdata_reg <= m_rdata_reg;
						s_slverr_reg <= m_slverr_reg;
					end
				end
				default: s_state <= S_IDLE;
			endcase
		end
	end

	// Master-side logic
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_state <= M_IDLE;
			m_req <= 1'b0;
			m_ack <= 1'b0;
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			M_PRESETn <= 1'b0;
			m_addr_reg <= {AW{1'b0}};
			m_write_reg <= 1'b0;
			m_wdata_reg <= {DW{1'b0}};
			m_wstrb_reg <= {(DW/8){1'b0}};
			m_pprot_reg <= 3'b000;
			m_rdata_reg <= {DW{1'b0}};
			m_slverr_reg <= 1'b0;
		end else begin
			M_PRESETn <= 1'b1;
			case (m_state)
				M_IDLE: begin
					M_APB_PSEL <= 1'b0;
					M_APB_PENABLE <= 1'b0;
					if (s_req_sync[1]) begin
						m_state <= M_SETUP;
						m_req <= 1'b1;
						m_addr_reg <= s_addr_reg;
						m_write_reg <= s_write_reg;
						m_wdata_reg <= s_wdata_reg;
						m_wstrb_reg <= s_wstrb_reg;
						m_pprot_reg <= s_pprot_reg;
					end
				end
				M_SETUP: begin
					M_APB_PSEL <= 1'b1;
					M_APB_PENABLE <= 1'b0;
					if (s_ack_sync[1]) begin
						m_state <= M_ACCESS;
						m_req <= 1'b0;
						m_ack <= 1'b1;
					end
				end
				M_ACCESS: begin
					M_APB_PSEL <= 1'b1;
					M_APB_PENABLE <= 1'b1;
					if (M_APB_PREADY) begin
						m_state <= M_IDLE;
						m_ack <= 1'b0;
						M_APB_PSEL <= 1'b0;
						M_APB_PENABLE <= 1'b0;
						m_rdata_reg <= M_APB_PRDATA;
						m_slverr_reg <= M_APB_PSLVERR;
					end
				end
				default: m_state <= M_IDLE;
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

endmodule
