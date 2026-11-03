module axidma #(
		parameter	C_AXI_ID_WIDTH = 1,
		parameter	C_AXI_ADDR_WIDTH = 32,
		parameter	C_AXI_DATA_WIDTH = 32,
		localparam	C_AXIL_ADDR_WIDTH = 5,
		localparam	C_AXIL_DATA_WIDTH = 32,
		parameter [0:0]	OPT_UNALIGNED = 1'b1,
		parameter [0:0]	OPT_WRAPMEM = 1'b1,
		parameter	LGFIFO = LGMAXBURST+1,
		parameter	LGLEN = C_AXI_ADDR_WIDTH,
		parameter [0:0]	OPT_LOWPOWER = 1'b0,
		parameter [0:0]	OPT_CLKGATE = OPT_LOWPOWER,
		parameter	[C_AXI_ID_WIDTH-1:0]	AXI_READ_ID = 0,
		parameter	[C_AXI_ID_WIDTH-1:0]	AXI_WRITE_ID = 0,
		parameter	[7:0]			ABORT_KEY  = 8'h6d,
		localparam	ADDRLSB= $clog2(C_AXI_DATA_WIDTH)-3,
		localparam	AXILLSB= $clog2(C_AXIL_DATA_WIDTH)-3,
		localparam	LGLENW= LGLEN-ADDRLSB
	) (
		input	wire	S_AXI_ACLK,
		input	wire	S_AXI_ARESETN,
		input	wire				S_AXIL_AWVALID,
		output	wire				S_AXIL_AWREADY,
		input	wire [C_AXIL_ADDR_WIDTH-1:0]	S_AXIL_AWADDR,
		input	wire 	[2:0]			S_AXIL_AWPROT,
		input	wire				S_AXIL_WVALID,
		output	wire				S_AXIL_WREADY,
		input	wire [C_AXIL_DATA_WIDTH-1:0]	S_AXIL_WDATA,
		input	wire [C_AXIL_DATA_WIDTH/8-1:0]	S_AXIL_WSTRB,
		output	reg				S_AXIL_BVALID,
		input	wire				S_AXIL_BREADY,
		output	wire	[1:0]			S_AXIL_BRESP,
		input	wire				S_AXIL_ARVALID,
		output	wire				S_AXIL_ARREADY,
		input	wire [C_AXIL_ADDR_WIDTH-1:0]	S_AXIL_ARADDR,
		input	wire 	[2:0]			S_AXIL_ARPROT,
		output	reg				S_AXIL_RVALID,
		input	wire				S_AXIL_RREADY,
		output	reg [C_AXIL_DATA_WIDTH-1:0]	S_AXIL_RDATA,
		output	wire	[1:0]			S_AXIL_RRESP,
		output	reg				M_AXI_AWVALID,
		input	wire				M_AXI_AWREADY,
		output	reg	[C_AXI_ID_WIDTH-1:0]	M_AXI_AWID,
		output	reg	[C_AXI_ADDR_WIDTH-1:0]	M_AXI_AWADDR,
		output	reg	[2:0]			M_AXI_AWSIZE,
		output	reg	[1:0]			M_AXI_AWBURST,
		output	reg				M_AXI_AWLOCK,
		output	reg	[3:0]			M_AXI_AWCACHE,
		output	reg	[2:0]			M_AXI_AWPROT,
		output	reg	[3:0]			M_AXI_AWQOS,
		output	reg				M_AXI_WVALID,
		input	wire				M_AXI_WREADY,
		output	reg	[C_AXI_DATA_WIDTH-1:0]	M_AXI_WDATA,
		output	reg [C_AXI_DATA_WIDTH/8-1:0]	M_AXI_WSTRB,
		output	reg				M_AXI_WLAST,
		input	wire				M_AXI_BVALID,
		output	reg				M_AXI_BREADY,
		input	wire	[C_AXI_ID_WIDTH-1:0]	M_AXI_BID,
		input	wire	[1:0]			M_AXI_BRESP,
		output	reg				M_AXI_ARVALID,
		input	wire				M_AXI_ARREADY,
		output	wire	[C_AXI_ID_WIDTH-1:0]	M_AXI_ARID,
		output	reg	[C_AXI_ADDR_WIDTH-1:0]	M_AXI_ARADDR,
		output	wire	[2:0]			M_AXI_ARSIZE,
		output	wire	[1:0]			M_AXI_ARBURST,
		output	wire				M_AXI_ARLOCK,
		output	wire	[3:0]			M_AXI_ARCACHE,
		output	wire	[2:0]			M_AXI_ARPROT,
		output	wire	[3:0]			M_AXI_ARQOS,
		input	wire				M_AXI_RVALID,
		output	wire				M_AXI_RREADY,
		input	wire	[C_AXI_ID_WIDTH-1:0]	M_AXI_RID,
		input	wire	[C_AXI_DATA_WIDTH-1:0]	M_AXI_RDATA,
		input	wire				M_AXI_RLAST,
		input	wire	[1:0]			M_AXI_RRESP,
		output	reg				o_int
	);

	// Internal signals
	reg [1:0] control_state;
	reg [C_AXI_ADDR_WIDTH-1:0] source_address;
	reg [C_AXI_ADDR_WIDTH-1:0] destination_address;
	reg [LGLEN-1:0] transfer_length;
	reg [LGLEN-1:0] transfer_count;
	reg [C_AXIL_DATA_WIDTH-1:0] axil_wdata_reg;
	reg [C_AXIL_DATA_WIDTH/8-1:0] axil_wstrb_reg;
	reg s_axil_awready_i;
	reg s_axil_wready_i;
	reg s_axil_bvalid_i;
	wire [1:0] s_axil_bresp_i;
	reg s_axil_arready_i;
	reg s_axil_rvalid_i;
	reg [C_AXIL_DATA_WIDTH-1:0] s_axil_rdata_i;
	wire [1:0] s_axil_rresp_i;
	reg m_axi_awvalid_i;
	reg [C_AXI_ID_WIDTH-1:0] m_axi_awid_i;
	reg [C_AXI_ADDR_WIDTH-1:0] m_axi_awaddr_i;
	reg [2:0] m_axi_awsize_i;
	reg [1:0] m_axi_awburst_i;
	reg m_axi_awlock_i;
	reg [3:0] m_axi_awcache_i;
	reg [2:0] m_axi_awprot_i;
	reg [3:0] m_axi_awqos_i;
	reg m_axi_wvalid_i;
	reg [C_AXI_DATA_WIDTH-1:0] m_axi_wdata_i;
	reg [C_AXI_DATA_WIDTH/8-1:0] m_axi_wstrb_i;
	reg m_axi_wlast_i;
	reg m_axi_bready_i;
	reg m_axi_arvalid_i;
	reg [C_AXI_ID_WIDTH-1:0] m_axi_arid_i;
	reg [C_AXI_ADDR_WIDTH-1:0] m_axi_araddr_i;
	reg [2:0] m_axi_arsize_i;
	reg [1:0] m_axi_arburst_i;
	reg m_axi_arlock_i;
	reg [3:0] m_axi_arcache_i;
	reg [2:0] m_axi_arprot_i;
	reg [3:0] m_axi_arqos_i;
	reg m_axi_rready_i;

	// Control states
	localparam IDLE = 2'b00;
	localparam CONFIGURED = 2'b01;
	localparam TRANSFER = 2'b10;

	// AXI-Lite slave interface
	assign S_AXIL_AWREADY = s_axil_awready_i;
	assign S_AXIL_WREADY = s_axil_wready_i;
	assign S_AXIL_BVALID = s_axil_bvalid_i;
	assign S_AXIL_BRESP = s_axil_bresp_i;
	assign S_AXIL_ARREADY = s_axil_arready_i;
	assign S_AXIL_RVALID = s_axil_rvalid_i;
	assign S_AXIL_RDATA = s_axil_rdata_i;
	assign S_AXIL_RRESP = s_axil_rresp_i;

	// AXI master interface
	assign M_AXI_AWVALID = m_axi_awvalid_i;
	assign M_AXI_AWID = m_axi_awid_i;
	assign M_AXI_AWADDR = m_axi_awaddr_i;
	assign M_AXI_AWSIZE = m_axi_awsize_i;
	assign M_AXI_AWBURST = m_axi_awburst_i;
	assign M_AXI_AWLOCK = m_axi_awlock_i;
	assign M_AXI_AWCACHE = m_axi_awcache_i;
	assign M_AXI_AWPROT = m_axi_awprot_i;
	assign M_AXI_AWQOS = m_axi_awqos_i;
	assign M_AXI_WVALID = m_axi_wvalid_i;
	assign M_AXI_WDATA = m_axi_wdata_i;
	assign M_AXI_WSTRB = m_axi_wstrb_i;
	assign M_AXI_WLAST = m_axi_wlast_i;
	assign M_AXI_BREADY = m_axi_bready_i;
	assign M_AXI_ARVALID = m_axi_arvalid_i;
	assign M_AXI_ARID = m_axi_arid_i;
	assign M_AXI_ARADDR = m_axi_araddr_i;
	assign M_AXI_ARSIZE = m_axi_arsize_i;
	assign M_AXI_ARBURST = m_axi_arburst_i;
	assign M_AXI_ARLOCK = m_axi_arlock_i;
	assign M_AXI_ARCACHE = m_axi_arcache_i;
	assign M_AXI_ARPROT = m_axi_arprot_i;
	assign M_AXI_ARQOS = m_axi_arqos_i;
	assign M_AXI_RREADY = m_axi_rready_i;

	// AXI-Lite write transaction handling
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			s_axil_awready_i <= 0;
			s_axil_wready_i <= 0;
			s_axil_bvalid_i <= 0;
			s_axil_bresp_i <= 0;
			control_state <= IDLE;
			source_address <= 0;
			destination_address <= 0;
			transfer_length <= 0;
		end else begin
			if (control_state == IDLE) begin
				if (S_AXIL_AWVALID && S_AXIL_WVALID) begin
					case (S_AXIL_AWADDR)
						5'h00: source_address <= S_AXIL_WDATA;
						5'h04: destination_address <= S_AXIL_WDATA;
						5'h08: transfer_length <= S_AXIL_WDATA[LGLEN-1:0];
						5'h0C: if (S_AXIL_WDATA == 32'h01) control_state <= CONFIGURED;
					endcase
					s_axil_awready_i <= 1;
					s_axil_wready_i <= 1;
				end else begin
					s_axil_awready_i <= 0;
					s_axil_wready_i <= 0;
				end
			end

			if (s_axil_bvalid_i && S_AXIL_BREADY) begin
				s_axil_bvalid_i <= 0;
			end else if (S_AXIL_AWVALID && S_AXIL_WVALID) begin
				s_axil_bvalid_i <= 1;
				s_axil_bresp_i <= 2'b00;
			end
		end
	end

	// AXI read and write transactions
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			m_axi_awvalid_i <= 0;
			m_axi_awid_i <= AXI_WRITE_ID;
			m_axi_awaddr_i <= 0;
			m_axi_awsize_i <= 3'b010; // 32-bit transfers
			m_axi_awburst_i <= 2'b01; // INCR burst
			m_axi_awlock_i <= 0;
			m_axi_awcache_i <= 4'b0011; // Normal, Non-cacheable, Bufferable
			m_axi_awprot_i <= 3'b000; // Unprivileged, Non-secure, Data
			m_axi_awqos_i <= 4'b0000;
			m_axi_wvalid_i <= 0;
			m_axi_wdata_i <= 0;
			m_axi_wstrb_i <= {C_AXI_DATA_WIDTH/8{1'b1}};
			m_axi_wlast_i <= 0;
			m_axi_bready_i <= 0;
			m_axi_arvalid_i <= 0;
			m_axi_arid_i <= AXI_READ_ID;
			m_axi_araddr_i <= 0;
			m_axi_arsize_i <= 3'b010; // 32-bit transfers
			m_axi_arburst_i <= 2'b01; // INCR burst
			m_axi_arlock_i <= 0;
			m_axi_arcache_i <= 4'b0011; // Normal, Non-cacheable, Bufferable
			m_axi_arprot_i <= 3'b000; // Unprivileged, Non-secure, Data
			m_axi_arqos_i <= 4'b0000;
			m_axi_rready_i <= 0;
			transfer_count <= 0;
			o_int <= 0;
		end else begin
			case (control_state)
				CONFIGURED: begin
					if (S_AXIL_WVALID && S_AXIL_WDATA == 32'h01) begin
						m_axi_arvalid_i <= 1;
						m_axi_araddr_i <= source_address;
						control_state <= TRANSFER;
					end
				end

				TRANSFER: begin
					if (m_axi_arvalid_i && M_AXI_ARREADY) begin
						m_axi_arvalid_i <= 0;
					end

					if (M_AXI_RVALID && m_axi_rready_i) begin
						m_axi_wvalid_i <= 1;
						m_axi_wdata_i <= M_AXI_RDATA;
						m_axi_wlast_i <= (transfer_count == transfer_length - 1);
						transfer_count <= transfer_count + 1;
					end

					if (m_axi_wvalid_i && M_AXI_WREADY) begin
						m_axi_wvalid_i <= 0;
					end

					if (m_axi_wvalid_i && M_AXI_WREADY && m_axi_wlast_i) begin
						m_axi_bready_i <= 1;
						control_state <= IDLE;
						o_int <= 1;
					end

					if (M_AXI_BVALID && m_axi_bready_i) begin
						m_axi_bready_i <= 0;
						o_int <= 0;
					end

					if (M_AXI_RVALID) begin
						m_axi_rready_i <= 1;
					end else begin
						m_axi_rready_i <= 0;
					end
				end

				default: begin
					// Do nothing
				end
			endcase
		end
	end
endmodule
