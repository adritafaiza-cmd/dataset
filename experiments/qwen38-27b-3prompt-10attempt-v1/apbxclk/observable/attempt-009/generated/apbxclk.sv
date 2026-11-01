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
	reg m_ack;
	reg m_done;

	// Synchronizers
	reg [1:0] s_req_sync;
	reg [1:0] m_ack_sync;
	reg [1:0] m_done_sync;

	// Payload registers (captured in slave clock, held)
	reg [AW-1:0] s_addr_reg;
	reg s_write_reg;
	reg [DW-1:0] s_wdata_reg;
	reg [DW/8-1:0] s_wstrb_reg;
	reg [2:0] s_pprot_reg;

	// Response registers (captured in master clock, held)
	reg [DW-1:0] m_rdata_reg;
	reg m_rslverr_reg;

	// Synchronizer for request
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			s_req_sync <= 2'b00;
		else
			s_req_sync <= {s_req_sync[0], s_req};
	end

	// Synchronizer for ack
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			m_ack_sync <= 2'b00;
		else
			m_ack_sync <= {m_ack_sync[0], m_ack};
	end

	// Synchronizer for done
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn)
			m_done_sync <= 2'b00;
		else
			m_done_sync <= {m_done_sync[0], m_done};
	end

	// Slave-side logic
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_state <= S_IDLE;
			s_req <= 1'b0;
			S_APB_PREADY <= 1'b0;
			s_addr_reg <= {AW{1'b0}};
			s_write_reg <= 1'b0;
			s_wdata_reg <= {DW{1'b0}};
			s_wstrb_reg <= {(DW/8){1'b0}};
			s_pprot_reg <= 3'b000;
		end else begin
			case (s_state)
				S_IDLE: begin
					S_APB_PREADY <= 1'b0;
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
					if (m_ack_sync[1]) begin
						s_req <= 1'b0;
						s_state <= S_ACCESS;
					end
				end
				S_ACCESS: begin
					S_APB_PREADY <= 1'b0;
					if (m_done_sync[1]) begin
						S_APB_PREADY <= 1'b1;
						s_state <= S_IDLE;
					end
				end
				default: begin
					s_state <= S_IDLE;
					S_APB_PREADY <= 1'b0;
					s_req <= 1'b0;
				end
			endcase
		end
	end

	// Master-side reset
	always @(posedge M_APB_PCLK) begin
		M_PRESETn <= S_PRESETn;
	end

	// Master-side logic
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn) begin
			m_state <= M_IDLE;
			m_ack <= 1'b0;
			m_done <= 1'b0;
			M_APB_PSEL <= 1'b0;
			M_APB_PENABLE <= 1'b0;
			M_APB_PADDR <= {AW{1'b0}};
			M_APB_PWRITE <= 1'b0;
			M_APB_PWDATA <= {DW{1'b0}};
			M_APB_PWSTRB <= {(DW/8){1'b0}};
			M_APB_PPROT <= 3'b000;
			m_rdata_reg <= {DW{1'b0}};
			m_rslverr_reg <= 1'b0;
		end else begin
			case (m_state)
				M_IDLE: begin
					M_APB_PSEL <= 1'b0;
					M_APB_PENABLE <= 1'b0;
					m_ack <= 1'b0;
					m_done <= 1'b0;
					if (s_req_sync[1]) begin
						M_APB_PSEL <= 1'b1;
						M_APB_PENABLE <= 1'b0;
						M_APB_PADDR <= s_addr_reg;
						M_APB_PWRITE <= s_write_reg;
						M_APB_PWDATA <= s_wdata_reg;
						M_APB_PWSTRB <= s_wstrb_reg;
						M_APB_PPROT <= s_pprot_reg;
						m_ack <= 1'b1;
						m_state <= M_SETUP;
					end
				end
				M_SETUP: begin
					M_APB_PSEL <= 1'b1;
					M_APB_PENABLE <= 1'b1;
					m_ack <= 1'b0;
					m_done <= 1'b0;
					m_state <= M_ACCESS;
				end
				M_ACCESS: begin
					M_APB_PSEL <= 1'b1;
					M_APB_PENABLE <= 1'b1;
					if (M_APB_PREADY) begin
						m_rdata_reg <= M_APB_PRDATA;
						m_rslverr_reg <= M_APB_PSLVERR;
						m_done <= 1'b1;
						M_APB_PSEL <= 1'b0;
						M_APB_PENABLE <= 1'b0;
						m_state <= M_IDLE;
					end
				end
				default: begin
					m_state <= M_IDLE;
					M_APB_PSEL <= 1'b0;
					M_APB_PENABLE <= 1'b0;
					m_ack <= 1'b0;
					m_done <= 1'b0;
				end
			endcase
		end
	end

	// Synchronizer for request (master side)
	reg [1:0] s_req_sync_m;
	always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
		if (!M_PRESETn)
			s_req_sync_m <= 2'b00;
		else
			s_req_sync_m <= {s_req_sync_m[0], s_req};
	end

	// Output assignments
	assign S_APB_PRDATA = m_rdata_reg;
	assign S_APB_PSLVERR = m_rslverr_reg;

endmodule
