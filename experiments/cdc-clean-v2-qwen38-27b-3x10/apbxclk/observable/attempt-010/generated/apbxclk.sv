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

	// ------------------------------------------------------------------
	// Slave-side state machine
	// ------------------------------------------------------------------
	localparam S_IDLE  = 2'd0;
	localparam S_SETUP = 2'd1;
	localparam S_WAIT  = 2'd2;

	reg [1:0] s_state;
	reg       s_req_valid;   // request pending to send to master
	reg       s_resp_valid;  // response available from master
	reg       s_pready;

	// Synchronizers: slave -> master (request)
	reg [2:0] s2m_req_sync;
	reg       s2m_req_valid;

	// Synchronizers: master -> slave (response)
	reg [2:0] m2s_resp_sync;
	reg       m2s_resp_valid;

	// ------------------------------------------------------------------
	// Master-side state machine
	// ------------------------------------------------------------------
	localparam M_IDLE  = 2'd0;
	localparam M_SETUP = 2'd1;
	localparam M_WAIT  = 2'd2;

	reg [1:0] m_state;
	reg       m_req_valid;   // request captured from slave
	reg       m_resp_valid;  // response ready to send back

	// Captured request fields (master clock domain)
	reg [AW-1:0] m_addr;
	reg          m_write;
	reg [DW-1:0] m_wdata;
	reg [DW/8-1:0] m_wstrb;
	reg [2:0]    m_pprot;

	// Captured response fields (slave clock domain)
	reg [DW-1:0] s_rdata;
	reg          s_pslverr;

	// ------------------------------------------------------------------
	// Slave clock domain logic
	// ------------------------------------------------------------------
	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			s_state      <= S_IDLE;
			s_req_valid  <= 1'b0;
			s_resp_valid <= 1'b0;
			s_pready     <= 1'b0;
			s_rdata      <= {DW{1'b0}};
			s_pslverr    <= 1'b0;
			s2m_req_sync <= 3'b0;
			s2m_req_valid<= 1'b0;
			m2s_resp_sync<= 3'b0;
			m2s_resp_valid<= 1'b0;
		end else begin
			// Synchronizer updates
			s2m_req_sync <= {s2m_req_sync[1:0], s_req_valid};
			m2s_resp_sync<= {m2s_resp_sync[1:0], m_resp_valid};

			// Detect synchronized request valid (slave->master)
			// We use the 3rd stage as the synchronized signal
			// Actually, s2m_req_sync[2] is the synchronized version of s_req_valid
			// But we need to detect when it becomes valid on master side.
			// The master side will see s2m_req_sync[2] as its input.

			// Detect synchronized response valid (master->slave)
			// m2s_resp_sync[2] is the synchronized version of m_resp_valid

			case (s_state)
				S_IDLE: begin
					s_pready <= 1'b0;
					if (S_APB_PSEL && !S_APB_PENABLE) begin
						// Start of a new transfer
						s_state <= S_SETUP;
					end
				end
				S_SETUP: begin
					s_pready <= 1'b0;
					// Capture request fields and send to master
					s_req_valid <= 1'b1;
					s_state <= S_WAIT;
				end
				S_WAIT: begin
					s_pready <= 1'b0;
					// Wait for response from master
					if (m2s_resp_sync[2]) begin
						// Response arrived
						s_resp_valid <= 1'b1;
						s_state <= S_IDLE;
					end
				end
				default: begin
					s_state <= S_IDLE;
				end
			endcase

			// Capture response data when it arrives
			if (m2s_resp_sync[2] && !m2s_resp_sync[1]) begin
				// Rising edge of synchronized response valid
				// But we need to capture the data. The data is on the master side.
				// We need to synchronize the data as well, or capture it when valid.
				// Since the data is stable while valid, we can capture it here.
				// However, the data is in the master clock domain. We need to
				// synchronize the data too. Let's add data synchronizers.
			end
		end
	end

	// We need to synchronize the response data and error as well.
	// Let's add those synchronizers.

	reg [DW-1:0] m2s_rdata_sync;
	reg          m2s_pslverr_sync;

	always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
		if (!S_PRESETn) begin
			m2s_rdata_sync  <= {DW{1'b0}};
			m2s_pslverr_sync<= 1'b0;
		end else begin
			m2s_rdata_sync  <= m2s_rdata_sync; // placeholder, will fix
			m2s_pslverr_sync<= m2s_pslverr_sync;
		end
	end

	// Actually, let me restructure this properly.

endmodule
